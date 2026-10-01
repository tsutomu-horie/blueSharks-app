from __future__ import annotations

import subprocess
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

from tools.autodev.git_manager import GitIdentityError, GitManager, GitSafetyError
from tools.autodev.runtime import CodexRunner


class ModelPolicyTests(unittest.TestCase):
    def test_gpt_5_6_is_forbidden(self):
        with self.assertRaises(ValueError):
            CodexRunner._validate_model("gpt-5.6-luna", "low")

    def test_luna_cannot_use_medium_reasoning(self):
        with self.assertRaises(ValueError):
            CodexRunner._validate_model("gpt-6-luna", "medium")

    def test_sol_low_is_allowed(self):
        CodexRunner._validate_model("gpt-6.1-sol", "low")

    def test_legacy_sol_model_id_is_forbidden(self):
        with self.assertRaises(ValueError):
            CodexRunner._validate_model("gpt-6-sol", "low")


class GitManagerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.repo = self.root / "repo"
        self.repo.mkdir()
        self._git(self.repo, "init", "-b", "main")
        self._git(self.repo, "config", "user.email", "autodev-test@example.invalid")
        self._git(self.repo, "config", "user.name", "Autodev Test")
        (self.repo / "lib").mkdir()
        (self.repo / "lib" / "base.dart").write_text("void main() {}\n")
        (self.repo / "server").mkdir()
        (self.repo / "server" / "base.php").write_text("<?php\n")
        (self.repo / "bluesharks-develop" / "app").mkdir(parents=True)
        (self.repo / "bluesharks-develop" / "app" / "base.php").write_text("<?php\n")
        self._git(self.repo, "add", ".")
        self._git(self.repo, "commit", "-m", "base")
        self._git(self.repo, "update-ref", "refs/remotes/origin/main", "HEAD")
        self._git(self.repo, "remote", "add", "origin", str(self.repo))
        self.worktrees = self.root / "workspace" / "worktrees"
        self.config = {
            "workspace": {"worktrees_dir": str(self.worktrees)},
            "git": {"branch_prefix": "bot", "base_ref": "origin/main", "max_changed_files": 80, "max_diff_lines": 1000},
            "projects": {"app": {"repository": str(self.repo), "base_ref": "origin/main"}},
        }
        self.manager = GitManager(self.config)

    def tearDown(self):
        self.temp.cleanup()

    def _git(self, cwd, *args):
        return subprocess.run(["git", "-C", str(cwd), *args], check=True, capture_output=True, text=True).stdout

    def ticket(self, ticket_id="BS-TEST-1"):
        return {
            "id": ticket_id,
            "type": "bugfix",
            "title": "テスト修正",
            "project": "app",
            "allowed_scope": ["lib/**"],
            "forbidden_scope": ["server/**"],
        }

    def test_worktree_isolated_and_allowed_path_passes(self):
        worktree, branch = self.manager.create_worktree(self.ticket())
        self.assertEqual(branch, "bot/BS-TEST-1")
        (worktree / "lib" / "change.dart").write_text("void changed() {}\n")
        self.assertEqual(self.manager.scope_findings(worktree, ["lib/**"], ["server/**"]), [])

    def test_worktree_uses_fresh_remote_base_ref(self):
        (self.repo / "lib" / "latest.dart").write_text("void latest() {}\n")
        self._git(self.repo, "add", "lib/latest.dart")
        self._git(self.repo, "commit", "-m", "remote latest")
        latest = self._git(self.repo, "rev-parse", "HEAD").strip()

        worktree, _ = self.manager.create_worktree(self.ticket("LATEST"))

        self.assertEqual(self._git(worktree, "rev-parse", "HEAD").strip(), latest)

    def test_tampered_worktree_git_pointer_is_rejected_before_git_commands(self):
        worktree, _ = self.manager.create_worktree(self.ticket())
        (worktree / ".git").write_text("gitdir: /private/tmp/not-a-worktree\n")
        with patch.object(self.manager, "git") as git:
            with self.assertRaises(GitIdentityError):
                self.manager.validate_worktree_identity("app", "BS-TEST-1", worktree)
        git.assert_not_called()

    def test_forbidden_path_is_reported(self):
        worktree, _ = self.manager.create_worktree(self.ticket())
        (worktree / "server").mkdir(exist_ok=True)
        (worktree / "server" / "change.php").write_text("<?php\n")
        findings = self.manager.scope_findings(worktree, ["lib/**"], ["server/**"])
        self.assertTrue(any(item["kind"] == "forbidden_scope" for item in findings))

    def test_gate_approval_only_covers_the_reviewed_paths_and_diff(self):
        ticket = self.ticket('GATE-DIGEST')
        ticket['allowed_scope'] += ['pubspec.yaml', 'pubspec.lock']
        worktree, _ = self.manager.create_worktree(ticket)
        ticket['base_commit'] = self._git(worktree, 'rev-parse', 'HEAD').strip()
        (worktree / 'pubspec.yaml').write_text('name: fixture\n')
        gates = [item for item in self.manager.mechanical_scope_check(ticket, worktree) if item['kind'] == 'supervisor_gate']
        self.assertTrue(gates)
        ticket['current_state'] = {'approved_gate_evidence': [{'category': item['category'], 'files': sorted(item['files']), 'digest': item['digest']} for item in gates]}
        self.assertFalse(any(item['kind'] == 'supervisor_gate' for item in self.manager.mechanical_scope_check(ticket, worktree)))
        (worktree / 'pubspec.lock').write_text('new dependency\n')
        self.assertTrue(any(item['kind'] == 'supervisor_gate' for item in self.manager.mechanical_scope_check(ticket, worktree)))

    def test_clean_but_unmerged_commit_is_preserved(self):
        worktree, _ = self.manager.create_worktree(self.ticket())
        (worktree / "lib" / "change.dart").write_text("void changed() {}\n")
        self._git(worktree, "add", ".")
        self._git(worktree, "commit", "-m", "unmerged")
        with self.assertRaises(GitSafetyError):
            self.manager.remove_clean_worktree("app", worktree, allow_unmerged=True)
        self.assertTrue(worktree.exists())

    def test_server_scope_is_relative_to_configured_source_directory(self):
        config = {
            **self.config,
            "projects": {
                "server": {
                    "repository": str(self.repo),
                    "base_ref": "origin/main",
                    "source_directory": "bluesharks-develop",
                }
            },
        }
        manager = GitManager(config)
        worktree, _ = manager.create_worktree({"id": "BS-SERVER-1", "project": "server"})
        (worktree / "bluesharks-develop" / "app" / "Feature.php").write_text("<?php\n")
        findings = manager.scope_findings(worktree, ["app/**"], ["routes/api/**"], "bluesharks-develop")
        self.assertEqual(findings, [])
        self.assertEqual(manager.source_workdir("server", worktree), worktree / "bluesharks-develop")

    def test_deleted_files_are_in_scope_check_and_commit_set(self):
        worktree, _ = self.manager.create_worktree(self.ticket())
        (worktree / "server" / "base.php").unlink()
        base_revision = self._git(worktree, "rev-parse", "HEAD").strip()
        ticket = {**self.ticket(), "base_commit": base_revision, "current_state": {}}

        self.assertIn("server/base.php", self.manager.changed_files(worktree, base_revision))
        findings = self.manager.mechanical_scope_check(ticket, worktree)
        self.assertTrue(any(item.get("kind") == "forbidden_scope" for item in findings))
        with self.assertRaises(GitSafetyError):
            self.manager.stage_and_commit(
                ticket, worktree, "test", base_revision=base_revision,
                expected_reviewed_digest=self.manager.diff_digest(worktree, base_revision),
            )

    def test_commit_rejects_a_precommit_hook_that_changes_the_reviewed_diff(self):
        worktree, _ = self.manager.create_worktree(self.ticket())
        changed = worktree / "lib" / "change.dart"
        changed.write_text("void reviewed() {}\n")
        base_revision = self._git(worktree, "rev-parse", "HEAD").strip()
        reviewed_digest = self.manager.diff_digest(worktree, base_revision)
        ticket = {**self.ticket(), "base_commit": base_revision, "current_state": {}}
        hooks = self.root / "hooks"
        hooks.mkdir()
        hook = hooks / "pre-commit"
        hook.write_text("#!/bin/sh\nprintf 'void unreviewed() {}\\n' > lib/change.dart\ngit add lib/change.dart\n")
        hook.chmod(0o755)
        self._git(worktree, "config", "core.hooksPath", str(hooks))

        with self.assertRaises(GitSafetyError):
            self.manager.stage_and_commit(
                ticket, worktree, "test", base_revision=base_revision,
                expected_reviewed_digest=reviewed_digest,
            )
        self.assertNotEqual(self._git(worktree, "rev-parse", "HEAD").strip(), base_revision)

    def test_stage_commit_preserves_exact_reviewed_content(self):
        worktree, _ = self.manager.create_worktree(self.ticket())
        (worktree / "lib" / "change.dart").write_text("void reviewed() {}\n")
        base_revision = self._git(worktree, "rev-parse", "HEAD").strip()
        reviewed_digest = self.manager.diff_digest(worktree, base_revision)
        ticket = {**self.ticket(), "base_commit": base_revision, "current_state": {}}

        commit = self.manager.stage_and_commit(
            ticket, worktree, "test", base_revision=base_revision,
            expected_reviewed_digest=reviewed_digest,
        )

        self.assertEqual(self._git(worktree, "rev-parse", "HEAD").strip(), commit)
        self.assertEqual(self.manager.diff_digest(worktree, base_revision), reviewed_digest)
        self.assertEqual(self._git(worktree, "status", "--porcelain"), "")

    def test_scope_check_includes_intermediate_commits_against_ticket_base(self):
        worktree, _ = self.manager.create_worktree(self.ticket())
        base_revision = self._git(worktree, "rev-parse", "HEAD").strip()
        changed = worktree / "server" / "committed.php"
        changed.write_text("<?php\n")
        self._git(worktree, "add", "server/committed.php")
        self._git(worktree, "commit", "-m", "unapproved intermediate commit")
        ticket = {**self.ticket(), "base_commit": base_revision, "current_state": {}}

        self.assertIn("server/committed.php", self.manager.changed_files(worktree, base_revision))
        findings = self.manager.mechanical_scope_check(ticket, worktree)
        self.assertTrue(any(item.get("kind") == "forbidden_scope" and item.get("path") == "server/committed.php" for item in findings))

    def test_rename_checks_both_source_and_destination_paths(self):
        worktree, _ = self.manager.create_worktree(self.ticket())
        base_revision = self._git(worktree, "rev-parse", "HEAD").strip()
        (worktree / "server" / "base.php").rename(worktree / "lib" / "moved.php")

        changed = self.manager.changed_files(worktree, base_revision)
        self.assertIn("server/base.php", changed)
        self.assertIn("lib/moved.php", changed)
        findings = self.manager.scope_findings(worktree, ["lib/**"], ["server/**"], base_revision=base_revision)
        self.assertTrue(any(item.get("kind") == "forbidden_scope" and item.get("path") == "server/base.php" for item in findings))

    def test_merge_requires_the_exact_reviewed_pr_head_and_supports_status_contexts(self):
        worktree, _ = self.manager.create_worktree(self.ticket())
        sha = self._git(worktree, "rev-parse", "HEAD").strip()
        responses = [
            SimpleNamespace(returncode=0, stdout=(
                '{"state":"OPEN","mergeable":"MERGEABLE","reviewDecision":null,'
                f'"headRefOid":"{sha}","statusCheckRollup":[{{"__typename":"StatusContext","state":"SUCCESS"}}]}}'
            ), stderr=""),
            SimpleNamespace(returncode=0, stdout="merged", stderr=""),
        ]
        original_run = subprocess.run
        def fake_run(command, *args, **kwargs):
            if command[0] == "gh":
                return responses.pop(0)
            return original_run(command, *args, **kwargs)
        with patch("tools.autodev.git_manager.subprocess.run", side_effect=fake_run) as run:
            merged, _ = self.manager.merge_if_green(self.ticket(), worktree, "https://example.invalid/pr/1", sha)

        self.assertTrue(merged)
        gh_calls = [call for call in run.call_args_list if call.args[0][0] == "gh"]
        self.assertIn("--match-head-commit", gh_calls[1].args[0])
        self.assertIn(sha, gh_calls[1].args[0])

    def test_merge_refuses_a_pr_head_that_changed_after_review(self):
        worktree, _ = self.manager.create_worktree(self.ticket())
        sha = self._git(worktree, "rev-parse", "HEAD").strip()
        response = SimpleNamespace(returncode=0, stdout=(
            '{"state":"OPEN","mergeable":"MERGEABLE","reviewDecision":null,'
            '"headRefOid":"different-sha","statusCheckRollup":[]}'
        ), stderr="")
        original_run = subprocess.run
        def fake_run(command, *args, **kwargs):
            if command[0] == "gh":
                return response
            return original_run(command, *args, **kwargs)
        with patch("tools.autodev.git_manager.subprocess.run", side_effect=fake_run) as run:
            merged, message = self.manager.merge_if_green(self.ticket(), worktree, "https://example.invalid/pr/1", sha)

        self.assertFalse(merged)
        self.assertIn("head changed", message)
        self.assertEqual(sum(call.args[0][0] == "gh" for call in run.call_args_list), 1)


if __name__ == "__main__":
    unittest.main()
