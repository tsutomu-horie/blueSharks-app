from __future__ import annotations

from dataclasses import dataclass
import fnmatch
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import shutil
import subprocess
import tarfile
from typing import Any, Sequence


class GitSafetyError(RuntimeError):
    pass


class GitIdentityError(GitSafetyError):
    pass


@dataclass
class QCResult:
    passed: bool
    findings: list[dict[str, Any]]
    commands: list[dict[str, Any]]
    changed_files: list[str]


class GitManager:
    def __init__(self, config: dict[str, Any]):
        self.config = config

    @staticmethod
    def git(cwd: Path, args: Sequence[str], timeout: int = 60) -> str:
        result = subprocess.run(
            ["git", "-C", str(cwd), *args],
            text=True, capture_output=True, timeout=timeout, check=False,
        )
        if result.returncode:
            raise GitSafetyError(result.stderr.strip() or f"git command failed ({result.returncode})")
        return result.stdout.strip()

    def project(self, project_id: str) -> dict[str, Any]:
        if project_id not in self.config["projects"]:
            raise GitSafetyError(f"project is not configured: {project_id}")
        return self.config["projects"][project_id]

    def validate_worktree_identity(self, project_id: str, ticket_id: str, worktree: Path) -> None:
        project = self.project(project_id)
        repository = Path(project["repository"]).resolve(strict=True)
        expected = self.expected_worktree_path(project_id, ticket_id)
        actual = worktree.resolve(strict=True)
        if actual != expected:
            raise GitIdentityError("Ticket worktree path does not match its isolated workspace location")
        pointer = actual / ".git"
        if pointer.is_symlink() or not pointer.is_file():
            raise GitIdentityError("Ticket worktree .git pointer is missing or not a regular file")
        try:
            contents = pointer.read_text(errors="strict").strip()
            if not contents.startswith("gitdir:"):
                raise GitIdentityError("Ticket worktree .git pointer has an invalid format")
            git_dir_value = Path(contents.partition(":")[2].strip())
            git_dir = (git_dir_value if git_dir_value.is_absolute() else actual / git_dir_value).resolve(strict=True)
            common_value = Path((git_dir / "commondir").read_text(errors="strict").strip())
            common_dir = (common_value if common_value.is_absolute() else git_dir / common_value).resolve(strict=True)
            marker_value = Path((git_dir / "gitdir").read_text(errors="strict").strip())
            marker = (marker_value if marker_value.is_absolute() else git_dir / marker_value).resolve(strict=True)
            head = (git_dir / "HEAD").read_text(errors="strict").strip()
        except (OSError, UnicodeError, ValueError) as exc:
            raise GitIdentityError("Ticket worktree Git metadata could not be verified") from exc
        expected_common_value = Path(self.git(repository, ["rev-parse", "--git-common-dir"]))
        expected_common = (expected_common_value if expected_common_value.is_absolute() else repository / expected_common_value).resolve(strict=True)
        expected_branch = f"{self.config['git'].get('branch_prefix', 'bot')}/{re.sub(r'[^A-Za-z0-9._-]', '-', ticket_id)}"
        if common_dir != expected_common or marker != pointer.resolve() or head != f"ref: refs/heads/{expected_branch}":
            raise GitIdentityError("Ticket worktree Git pointer, repository, or branch changed unexpectedly")

    def source_workdir(self, project_id: str, worktree: Path) -> Path:
        subdir = str(self.project(project_id).get("source_directory", ""))
        target = (worktree / subdir).resolve() if subdir else worktree.resolve()
        if worktree.resolve() not in target.parents and target != worktree.resolve():
            raise GitSafetyError("project source_directory escapes its Git worktree")
        if not target.is_dir():
            raise GitSafetyError(f"project source directory is missing: {target}")
        return target

    def create_worktree(self, ticket: dict[str, Any]) -> tuple[Path, str]:
        project = self.project(ticket["project"])
        repo = Path(project["repository"]).resolve(strict=True)
        workspace = Path(self.config["workspace"]["worktrees_dir"])
        target = self.expected_worktree_path(ticket["project"], ticket["id"])
        if workspace.resolve() not in target.parents:
            raise GitSafetyError("worktree path escapes configured workspace")
        if target.exists():
            raise GitSafetyError(f"worktree path already exists; refusing to overwrite: {target}")
        base = str(project.get("base_ref", self.config["git"].get("base_ref", "origin/main")))
        remote, separator, branch_name = base.partition("/")
        if separator:
            if remote not in self.git(repo, ["remote"]).splitlines():
                raise GitSafetyError(f"configured base remote is missing: {remote}")
            self.git(repo, ["fetch", "--no-tags", remote, f"{branch_name}:refs/remotes/{remote}/{branch_name}"], timeout=180)
        self.git(repo, ["rev-parse", "--verify", base])
        safe_id = re.sub(r"[^A-Za-z0-9._-]", "-", ticket["id"])
        branch = f"{self.config['git'].get('branch_prefix', 'bot')}/{safe_id}"
        self.git(repo, ["check-ref-format", "--branch", branch])
        branches = self.git(repo, ["branch", "--list", branch])
        if branches.strip():
            raise GitSafetyError(f"branch already exists; refusing to reuse it: {branch}")
        target.parent.mkdir(parents=True, exist_ok=True)
        self.git(repo, ["worktree", "add", "-b", branch, str(target), base], timeout=180)
        self.validate_worktree_identity(ticket["project"], ticket["id"], target)
        return target, branch

    def expected_worktree_path(self, project_id: str, ticket_id: str) -> Path:
        workspace = Path(self.config["workspace"]["worktrees_dir"]).resolve()
        target = (workspace / project_id / ticket_id).resolve()
        if workspace not in target.parents:
            raise GitSafetyError("Ticket ID escapes configured worktree directory")
        return target

    def validate_resume_worktree(self, ticket: dict[str, Any]) -> tuple[Path, str]:
        expected = self.expected_worktree_path(ticket["project"], ticket["id"])
        recorded = Path(str(ticket.get("worktree") or "")).resolve()
        if recorded != expected or not recorded.is_dir():
            raise GitSafetyError("recorded worktree path does not match this Ticket's isolated workspace")
        self.validate_worktree_identity(ticket["project"], ticket["id"], recorded)
        if ticket.get("pr_url"):
            raise GitSafetyError("Ticket already has a pull request; resume by creating a follow-up Ticket")
        branch = self.git(recorded, ["branch", "--show-current"])
        expected_branch = f"{self.config['git'].get('branch_prefix', 'bot')}/{re.sub(r'[^A-Za-z0-9._-]', '-', ticket['id'])}"
        if branch != expected_branch:
            raise GitSafetyError(f"recorded worktree branch mismatch: {branch}")
        head = self.git(recorded, ["rev-parse", "HEAD"])
        if not ticket.get("base_commit") or head != ticket["base_commit"]:
            raise GitSafetyError("worktree contains a commit beyond its saved base; preserving it for separate review")
        root = Path(self.project(ticket["project"])["repository"]).resolve(strict=True)
        registered = self.git(root, ["worktree", "list", "--porcelain"])
        if f"worktree {recorded}" not in registered.splitlines():
            raise GitSafetyError("recorded worktree is not registered to the configured repository")
        return recorded, branch

    def changed_files(self, worktree: Path, base_revision: str | None = None) -> list[str]:
        base = base_revision or "HEAD"
        tracked = self.git(worktree, ["diff", "--no-renames", "--name-only", "--diff-filter=ACDMRTUXB", "-z", base]).split("\0")
        untracked = self.git(worktree, ["ls-files", "--others", "--exclude-standard", "-z"]).split("\0")
        return sorted({item for item in tracked + untracked if item})

    def scope_findings(
        self,
        worktree: Path,
        allowed: list[str],
        forbidden: list[str],
        source_directory: str = "",
        base_revision: str | None = None,
    ) -> list[dict[str, Any]]:
        findings: list[dict[str, Any]] = []
        for relative in self.changed_files(worktree, base_revision):
            normalized = PurePosixPath(relative).as_posix()
            prefix = PurePosixPath(source_directory).as_posix().strip("./") if source_directory else ""
            scoped_path = normalized[len(prefix) + 1:] if prefix and normalized.startswith(prefix + "/") else normalized
            if normalized.startswith("/") or ".." in PurePosixPath(normalized).parts:
                findings.append({"kind": "unsafe_path", "path": normalized})
                continue
            resolved = (worktree / normalized).resolve()
            if worktree.resolve() not in resolved.parents and resolved != worktree.resolve():
                findings.append({"kind": "path_escapes_worktree", "path": normalized})
                continue
            if any(self._matches(scoped_path, pattern) for pattern in forbidden):
                findings.append({"kind": "forbidden_scope", "path": normalized, "scope_path": scoped_path})
                continue
            if allowed and not any(self._matches(scoped_path, pattern) for pattern in allowed):
                findings.append({"kind": "outside_allowed_scope", "path": normalized, "scope_path": scoped_path})
        return findings

    @staticmethod
    def _matches(path: str, pattern: str) -> bool:
        pattern = PurePosixPath(pattern).as_posix().rstrip("/")
        return fnmatch.fnmatchcase(path, pattern) or path == pattern or path.startswith(pattern + "/")

    def snapshot(self, ticket_id: str, worktree: Path, base_revision: str = "HEAD") -> Path:
        root = Path(self.config["workspace"]["snapshots_dir"]) / ticket_id
        root.mkdir(parents=True, exist_ok=True)
        path = root / f"snapshot-{len(list(root.glob('snapshot-*.tar')))+1:03d}.tar"
        with tarfile.open(path, "w") as archive:
            patch = subprocess.run(
                ["git", "-C", str(worktree), "diff", "--binary", base_revision],
                check=True, capture_output=True,
            ).stdout
            import io
            info = tarfile.TarInfo("worktree.diff")
            info.size = len(patch)
            archive.addfile(info, io.BytesIO(patch))
            for relative in self.changed_files(worktree, base_revision):
                file_path = (worktree / relative).resolve()
                if worktree.resolve() not in file_path.parents or not file_path.is_file():
                    continue
                if relative not in self.git(worktree, ["ls-files", "--others", "--exclude-standard"]).splitlines():
                    continue
                archive.add(file_path, arcname=f"untracked/{relative}", recursive=False)
        return path

    def mechanical_scope_check(self, ticket: dict[str, Any], worktree: Path) -> list[dict[str, Any]]:
        self.validate_worktree_identity(ticket["project"], ticket["id"], worktree)
        source_directory = str(self.project(ticket["project"]).get("source_directory", ""))
        base_revision = ticket.get("base_commit")
        if not base_revision:
            return [{"kind": "missing_base_commit", "message": "Ticket has no recorded worktree base commit"}]
        if self.git(worktree, ["rev-parse", "HEAD"]) != base_revision:
            findings = [{"kind": "unapproved_intermediate_commit", "message": "Developer created a commit before Orchestrator review"}]
        else:
            findings = []
        findings.extend(self.scope_findings(worktree, ticket["allowed_scope"], ticket["forbidden_scope"], source_directory, base_revision))
        files = self.changed_files(worktree, base_revision)
        approved_gates = set(ticket.get("current_state", {}).get("approved_supervisor_gates", []))
        for category, paths in self.supervisor_gates(files).items():
            if category not in approved_gates:
                findings.append({"kind": "supervisor_gate", "category": category, "files": paths})
        maximum = int(self.config["git"].get("max_changed_files", 80))
        if len(files) > maximum:
            findings.append({"kind": "diff_size", "changed_files": len(files), "maximum": maximum})
        numstat = self.git(worktree, ["diff", "--numstat", base_revision])
        diff_lines = 0
        for row in numstat.splitlines():
            columns = row.split("\t", 2)
            if len(columns) >= 2:
                diff_lines += sum(int(value) for value in columns[:2] if value.isdigit())
        line_limit = int(self.config["git"].get("max_diff_lines", 12000))
        if diff_lines > line_limit:
            findings.append({"kind": "diff_size", "changed_lines": diff_lines, "maximum": line_limit})
        review_bytes = len(subprocess.run(
            ["git", "-C", str(worktree), "diff", "--binary", base_revision],
            check=True, capture_output=True,
        ).stdout)
        for relative in self.git_untracked_files(worktree):
            candidate = worktree / relative
            if candidate.is_file():
                review_bytes += candidate.stat().st_size
        byte_limit = int(self.config["git"].get("max_diff_bytes", 300000))
        if review_bytes > byte_limit:
            findings.append({"kind": "diff_size", "changed_bytes": review_bytes, "maximum": byte_limit})
        try:
            self.git(worktree, ["diff", "--check", base_revision])
        except GitSafetyError as exc:
            findings.append({"kind": "diff_check_failed", "summary": str(exc)[:500]})
        findings.extend(self._secret_findings(worktree, files))
        return findings

    def git_untracked_files(self, worktree: Path) -> list[str]:
        return [item for item in self.git(worktree, ["ls-files", "--others", "--exclude-standard", "-z"]).split("\0") if item]

    def diff_digest(self, worktree: Path, base_revision: str) -> str:
        digest = hashlib.sha256()
        tracked = self.git(worktree, ["diff", "--no-renames", "--name-only", "--diff-filter=ACDMRTUXB", base_revision, "-z"]).split("\0")
        untracked = self.git_untracked_files(worktree)
        paths = sorted({item for item in tracked + untracked if item})
        for relative in paths:
            digest.update(relative.encode("utf-8", errors="replace"))
            path = worktree / relative
            resolved = path.resolve()
            if worktree.resolve() not in resolved.parents:
                digest.update(b"unsafe-path")
            elif path.is_symlink():
                digest.update(b"symlink\0")
                digest.update(path.readlink().as_posix().encode("utf-8", errors="replace"))
            elif path.is_file():
                digest.update(b"file\0")
                digest.update(b"executable\0" if path.stat().st_mode & 0o111 else b"not-executable\0")
                with path.open("rb") as stream:
                    for chunk in iter(lambda: stream.read(65536), b""):
                        digest.update(chunk)
            else:
                digest.update(b"deleted-or-non-file\0")
        return digest.hexdigest()

    @staticmethod
    def supervisor_gates(files: list[str]) -> dict[str, list[str]]:
        gates: dict[str, list[str]] = {}
        for path in files:
            lower = path.lower().replace("\\", "/")
            name = PurePosixPath(lower).name
            categories = []
            if name in {"pubspec.yaml", "pubspec.lock", "composer.json", "composer.lock", "package.json", "package-lock.json", "npm-shrinkwrap.json", "yarn.lock", "pnpm-lock.yaml", "podfile.lock", "gemfile", "gemfile.lock", "go.mod", "go.sum", "cargo.toml", "cargo.lock"} or name.endswith((".gradle", ".gradle.kts")):
                categories.append("dependency_change")
            if "/database/migrations/" in f"/{lower}/" or name.endswith(".sql"):
                categories.append("database_schema")
            if ".github/workflows/" in lower or lower.endswith((".gitlab-ci.yml", "dockerfile")) or "/fastlane/" in f"/{lower}/":
                categories.append("ci_cd")
            if any(token in lower for token in ("openapi", "swagger", "routes/api", "resources/api/")):
                categories.append("api_contract")
            if any(token in lower for token in ("/auth/", "auth_", "login", "token", "secure_storage")):
                categories.append("authentication_or_credential")
            for category in categories:
                gates.setdefault(category, []).append(path)
        return gates

    @classmethod
    def patterns_overlap(cls, left: str, right: str) -> bool:
        left = PurePosixPath(left).as_posix().rstrip("/")
        right = PurePosixPath(right).as_posix().rstrip("/")
        return (
            cls._matches(left, right)
            or cls._matches(right, left)
            or fnmatch.fnmatchcase(left, right)
            or fnmatch.fnmatchcase(right, left)
        )

    @staticmethod
    def _secret_findings(worktree: Path, files: list[str]) -> list[dict[str, Any]]:
        # Report paths only; never copy suspected secret values into logs.
        patterns = (
            re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----"),
            re.compile(r"\bgh[pousr]_[A-Za-z0-9]{30,}\b"),
            re.compile(r"\bAIza[0-9A-Za-z_-]{30,}\b"),
            re.compile(r"\bsk-(?:proj-)?[A-Za-z0-9_-]{24,}\b"),
        )
        hits: list[dict[str, Any]] = []
        for relative in files:
            path = worktree / relative
            resolved = path.resolve()
            if worktree.resolve() not in resolved.parents:
                continue
            if not path.is_file():
                continue
            if path.stat().st_size > 2_000_000:
                hits.append({"kind": "unscanned_large_file", "path": relative})
                continue
            try:
                data = path.read_text(errors="ignore")
            except OSError:
                continue
            if any(pattern.search(data) for pattern in patterns):
                hits.append({"kind": "secret_pattern", "path": relative})
        return hits

    def stage_and_commit(
        self,
        ticket: dict[str, Any],
        worktree: Path,
        title: str,
        *,
        base_revision: str,
        expected_reviewed_digest: str,
    ) -> str:
        self.validate_worktree_identity(ticket["project"], ticket["id"], worktree)
        if self.git(worktree, ["rev-parse", "HEAD"]) != base_revision:
            raise GitSafetyError("Developer-created commits are not allowed before independent review")
        if self.diff_digest(worktree, base_revision) != expected_reviewed_digest:
            raise GitSafetyError("worktree changed after adversarial review; refusing to commit an unreviewed diff")
        files = self.changed_files(worktree, base_revision)
        if not files:
            raise GitSafetyError("no changes to commit")
        findings = self.mechanical_scope_check(ticket, worktree)
        if findings:
            raise GitSafetyError("mechanical scope check failed: " + json.dumps(findings, ensure_ascii=False))
        self.git(worktree, ["add", "--", *[f"./{item}" for item in files]])
        self.git(worktree, ["diff", "--cached", "--check"])
        if self.diff_digest(worktree, base_revision) != expected_reviewed_digest:
            raise GitSafetyError("staged worktree differs from the Reviewer-approved diff")
        self.git(worktree, ["commit", "-m", self.commit_message(ticket, title)], timeout=180)
        commit = self.git(worktree, ["rev-parse", "HEAD"])
        if self.git(worktree, ["status", "--porcelain", "--untracked-files=all"]):
            raise GitSafetyError("commit hook left additional worktree changes; preserving the unreviewed state")
        if self.diff_digest(worktree, base_revision) != expected_reviewed_digest:
            raise GitSafetyError("created commit differs from the Reviewer-approved diff; refusing to push")
        return commit

    @staticmethod
    def commit_message(ticket: dict[str, Any], title: str) -> str:
        kinds = {"bugfix": "fix", "feature": "feat", "investigation": "docs", "maintenance": "chore"}
        subject = re.sub(r"[\r\n]+", " ", title).strip()[:68]
        return f"{kinds.get(ticket['type'], 'chore')}({ticket['id']}): {subject}"

    def push_and_open_pr(self, ticket: dict[str, Any], worktree: Path) -> str:
        self.validate_worktree_identity(ticket["project"], ticket["id"], worktree)
        branch = self.git(worktree, ["branch", "--show-current"])
        if not branch.startswith(self.config["git"].get("branch_prefix", "bot") + "/"):
            raise GitSafetyError(f"branch does not use the autonomous prefix: {branch}")
        self.git(worktree, ["push", "--set-upstream", "origin", branch], timeout=180)
        gh = str(self.config["git"].get("github_cli", "gh"))
        existing = subprocess.run(
            [gh, "pr", "list", "--head", branch, "--state", "open", "--json", "url"],
            cwd=worktree, text=True, capture_output=True, timeout=45,
        )
        if existing.returncode == 0:
            try:
                rows = json.loads(existing.stdout)
            except json.JSONDecodeError:
                rows = []
            if rows:
                return str(rows[0]["url"])
        title = f"[{ticket['id']}] {ticket['title']}"[:240]
        body = self._pr_body(ticket)
        base = str(self.project(ticket["project"]).get("base_ref", "origin/main")).removeprefix("origin/")
        created = subprocess.run(
            [gh, "pr", "create", "--base", base, "--head", branch, "--title", title, "--body", body],
            cwd=worktree, text=True, capture_output=True, timeout=90,
        )
        if created.returncode:
            raise GitSafetyError(created.stderr.strip() or created.stdout.strip() or "gh pr create failed")
        return created.stdout.strip().splitlines()[-1]

    @staticmethod
    def _pr_body(ticket: dict[str, Any]) -> str:
        criteria = "\n".join(f"- [x] {item}" for item in ticket["acceptance_criteria"])
        scope = "\n".join(f"- `{item}`" for item in ticket["allowed_scope"])
        return (
            f"## 変更内容\n{ticket['title']}\n\n"
            f"## 目的\n{ticket['goal']}\n\n"
            f"## 期待される効果・確認項目\n{criteria}\n\n"
            f"## 対象範囲\n{scope}\n\n"
            "## 確認\n機械的QCと独立した敵対的レビューをOrchestratorが記録します。"
        )

    def merge_if_green(self, ticket: dict[str, Any], worktree: Path, pr_url: str, reviewed_sha: str | None) -> tuple[bool, str]:
        self.validate_worktree_identity(ticket["project"], ticket["id"], worktree)
        if not reviewed_sha:
            return False, "reviewed commit SHA is missing"
        local_head = self.git(worktree, ["rev-parse", "HEAD"])
        if local_head != reviewed_sha:
            return False, "local branch no longer matches the reviewed commit"
        gh = str(self.config["git"].get("github_cli", "gh"))
        view = subprocess.run(
            [gh, "pr", "view", pr_url, "--json", "state,mergeable,reviewDecision,statusCheckRollup,headRefOid"],
            cwd=worktree, text=True, capture_output=True, timeout=45,
        )
        if view.returncode:
            return False, view.stderr.strip() or "unable to read pull request state"
        try:
            data = json.loads(view.stdout)
        except json.JSONDecodeError:
            return False, "GitHub returned invalid pull request status JSON"
        if data.get("headRefOid") != reviewed_sha:
            return False, "pull request head changed after review; rerun QC and adversarial review"
        if data.get("state") == "MERGED":
            return True, "already merged at the reviewed commit"
        if data.get("state") != "OPEN":
            return False, f"pull request state is {data.get('state')}"
        if data.get("mergeable") == "UNKNOWN":
            return False, "pull request mergeability is pending"
        if data.get("mergeable") != "MERGEABLE":
            return False, f"pull request is not mergeable: {data.get('mergeable')}"
        decision = data.get("reviewDecision")
        if decision in {"REVIEW_REQUIRED", "CHANGES_REQUESTED"}:
            return False, f"GitHub review gate: {decision}"
        checks = data.get("statusCheckRollup") or []
        failed_states = {"FAILURE", "CANCELLED", "TIMED_OUT", "ACTION_REQUIRED", "ERROR"}
        if any(item.get("conclusion") in failed_states or item.get("state") in failed_states for item in checks):
            return False, "one or more GitHub checks failed"
        if (not checks and bool(self.config["git"].get("require_github_checks", False))) or any(
            item.get("conclusion") != "SUCCESS" and item.get("state") != "SUCCESS" for item in checks
        ):
            return False, "GitHub checks are pending"
        method = str(self.config["git"].get("merge_method", "squash"))
        if method not in {"merge", "squash", "rebase"}:
            return False, f"unsupported merge method: {method}"
        merge = subprocess.run(
            [gh, "pr", "merge", pr_url, f"--{method}", "--delete-branch", "--match-head-commit", reviewed_sha],
            cwd=worktree, text=True, capture_output=True, timeout=120,
        )
        if merge.returncode:
            return False, merge.stderr.strip() or merge.stdout.strip() or "GitHub merge failed"
        return True, merge.stdout.strip() or "merged"

    def remove_merged_worktree(self, project_id: str, worktree: Path) -> None:
        self.remove_clean_worktree(project_id, worktree, allow_unmerged=False)

    def remove_clean_worktree(self, project_id: str, worktree: Path, allow_unmerged: bool) -> None:
        project = self.project(project_id)
        repo = Path(project["repository"]).resolve(strict=True)
        worktree = worktree.resolve(strict=True)
        workspace = Path(self.config["workspace"]["worktrees_dir"]).resolve()
        if workspace not in worktree.parents:
            raise GitSafetyError("refusing to remove a path outside the autonomous worktree directory")
        if worktree == repo:
            raise GitSafetyError("refusing to remove the primary repository checkout")
        self.validate_worktree_identity(project_id, worktree.name, worktree)
        status = self.git(worktree, ["status", "--porcelain", "--untracked-files=all"])
        if status.strip():
            raise GitSafetyError("worktree contains changes after merge; preserving it")
        if allow_unmerged:
            base = str(project.get("base_ref", self.config["git"].get("base_ref", "origin/main")))
            try:
                ahead = int(self.git(worktree, ["rev-list", "--count", f"{base}..HEAD"]))
            except (ValueError, GitSafetyError) as exc:
                raise GitSafetyError("cannot prove that the unmerged worktree has no commits; preserving it") from exc
            if ahead:
                raise GitSafetyError("worktree contains unmerged commits; preserving it")
        # For code Tickets, the caller confirms GitHub MERGED before using this path.
        self.git(repo, ["worktree", "remove", str(worktree)], timeout=120)
