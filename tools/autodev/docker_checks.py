"""Isolated Docker mechanical checks; no Docker daemon or DB work at import time.

Optional sandbox keys: docker_image (default Flutter 3.27.4),
pub_cache_seed, gradle_cache_seed. Seeds must live below workspace.root/cache.
The caller owns temp_dir's lifetime, including failed preparations.
recover_intent(lease) -> bool recovers a persisted docker_intent by unique name;
failed/uncertain recovery keeps the intent and never removes host directories.
"""
from __future__ import annotations

import csv
import io
import json
from pathlib import Path
import re
import subprocess
import tempfile
import uuid


class DockerCheck:
    LABEL = "io.bluesharks.autodev"
    SCRIPT = '''set -eu
mkdir -p "$HOME" "$XDG_CONFIG_HOME"
mkdir -p "$GRADLE_USER_HOME/init.d"
export GRADLE_OPTS="$GRADLE_OPTS -Dorg.gradle.java.home=$JAVA_HOME"
printf '%s\n' 'gradle.startParameter.offline = true' > "$GRADLE_USER_HOME/init.d/autodev-offline.gradle"
# Host package_config.json contains macOS paths; regenerate offline on Linux.
"$1" pub get --offline --enforce-lockfile
exec "$@"
'''

    def __init__(self, config, store):
        self.config = config
        self.store = store

    @staticmethod
    def _path(value):
        raw = Path(value)
        if not raw.is_absolute() or ".." in raw.parts or "\x00" in str(raw):
            raise ValueError("Expected an absolute path without traversal")
        resolved = raw.resolve(strict=True)
        if raw != resolved:
            raise ValueError("Symlinked paths are not permitted")
        return resolved

    @staticmethod
    def _run(argv):
        return subprocess.run(argv, capture_output=True, text=True, timeout=600)

    @staticmethod
    def _mount(source, target, readonly=False):
        # Docker --mount uses CSV parsing, not shell escaping.
        stream = io.StringIO()
        csv.writer(stream, lineterminator="").writerow(
            ["type=bind", f"source={source}", f"target={target}"]
            + (["readonly"] if readonly else [])
        )
        return ["--mount", stream.getvalue()]

    def _labels(self, ticket_id, run_id):
        return {self.LABEL: "docker-check", f"{self.LABEL}.ticket": str(ticket_id),
                f"{self.LABEL}.run": str(run_id)}

    def prepare(self, ticket, argv, worktree, temp_dir, run_id):
        if ticket.get("project") != "app" or not argv or any(
            not isinstance(arg, str) or "\x00" in arg for arg in argv
        ):
            raise ValueError("Expected an app Flutter/Dart argv")
        root = self._path(self.config["workspace"]["root"])
        tree_root = self._path(self.config["workspace"]["worktrees_dir"])
        tree = self._path(worktree)
        temporary = self._path(temp_dir)
        if (root not in tree_root.parents or tree_root not in tree.parents
                or root / "tmp" not in temporary.parents
                or tree in temporary.parents or temporary in tree.parents
                or not tree.is_dir() or not temporary.is_dir()):
            raise ValueError("Worktree/temp must be isolated runner-owned directories")
        marker = tree / ".git"
        if marker.is_symlink() or not marker.is_file():
            raise ValueError("Expected a regular worktree .git marker")
        executable = argv[0]
        tool = Path(executable).name
        if executable not in ("flutter", "dart"):
            sdk_binary = self._path(executable)
            if (root / "toolchains" not in sdk_binary.parents
                    or sdk_binary.parent.name != "bin" or tool not in ("flutter", "dart")):
                raise ValueError("Executable must be a dedicated runner Flutter/Dart binary")
        if tool not in ("flutter", "dart"):
            raise ValueError("Unsupported executable")
        sandbox = self.config.get("sandbox", {})
        source = Path(self.config["projects"]["app"].get("source_directory", "."))
        if source.is_absolute() or ".." in source.parts:
            raise ValueError("Source directory must stay inside the worktree")
        cwd = self._path(tree / source)
        if not cwd.is_dir() or (cwd != tree and tree not in cwd.parents):
            raise ValueError("Source directory escaped worktree")
        image = sandbox.get("docker_image", "bluesharks-autodev-flutter:3.27.4")
        if not isinstance(image, str) or not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_./:@-]*", image):
            raise ValueError("Invalid Docker image")
        # Fresh directory prevents reusing any writable cache from a prior check.
        check_temp = Path(tempfile.mkdtemp(prefix="docker-check-", dir=temporary))
        for name, key in (("pub", "pub_cache_seed"), ("gradle", "gradle_cache_seed")):
            destination = check_temp / name
            destination.mkdir(mode=0o700)
            seed_value = sandbox.get(key)
            if not seed_value and name == "pub":
                seed_value = self.config["projects"]["app"].get("environment", {}).get("PUB_CACHE")
            if seed_value:
                seed = self._path(seed_value)
                if root / "cache" not in seed.parents or not seed.is_dir():
                    raise ValueError("Cache seed must be runner-owned")
                # Absolute/macOS symlinks are unusable on Linux and can expose host inputs.
                for entry in seed.rglob("*"):
                    if entry.is_symlink():
                        raise ValueError("Cache seeds must not contain symlinks")
                result = self._run(["/bin/cp", "-cR", f"{seed}/.", str(destination)])
                if result.returncode:
                    raise RuntimeError("Unable to clone isolated cache seed")
        container_name = f"autodev-check-{uuid.uuid4().hex}"
        command = ["docker", "create", "--pull=never", "--name", container_name,
                   "--network=none", "--cap-drop=ALL", "--security-opt=no-new-privileges",
                   "--pids-limit=512", "--memory=4g", "--memory-swap=4g", "--cpus=2",
                   f"--workdir={Path('/workspace') / source}",
                   "--entrypoint=/bin/sh"]
        labels = self._labels(ticket["id"], run_id)
        for key, value in labels.items():
            command += ["--label", f"{key}={value}"]
        command += self._mount(tree, "/workspace")
        command += self._mount(marker, "/workspace/.git", readonly=True)
        command += self._mount(check_temp, "/tmp/autodev")
        for key, value in {"HOME": "/tmp/autodev/home", "PUB_CACHE": "/tmp/autodev/pub",
                           "GRADLE_USER_HOME": "/tmp/autodev/gradle", "TMPDIR": "/tmp/autodev",
                           "ANDROID_USER_HOME": "/tmp/autodev/android-user",
                           "XDG_CONFIG_HOME": "/tmp/autodev/config", "CI": "true",
                           "GIT_CONFIG_GLOBAL": "/dev/null", "GIT_CONFIG_NOSYSTEM": "1",
                           "GRADLE_OPTS": "-Dorg.gradle.daemon=false -Dorg.gradle.offline=true"}.items():
            command += ["--env", f"{key}={value}"]
        script = self.SCRIPT
        if 'pub' in argv[1:]:
            index = argv.index('pub')
            if index + 1 < len(argv) and argv[index + 1] == 'get':
                script = script.replace('"$1" pub get --offline --enforce-lockfile\n', '')
        command += [image, "-c", script, "autodev-check", tool, *argv[1:]]
        # This durable name survives DB failure after create, ambiguous CLI
        # timeouts, and failed removal. Never create before the intent commits.
        intent_id = self.store.lease(ticket["id"], "docker_intent", container_name,
                                     {"run_id": str(run_id), "labels": labels,
                                      "name": container_name})
        result = self._run(command)
        if result.returncode:
            raise RuntimeError("Docker container creation failed: " + result.stderr)
        cid = result.stdout.strip()
        if not re.fullmatch(r"[0-9a-f]{64}", cid):
            raise RuntimeError("Docker returned an invalid container ID")
        try:
            lease_id = self.store.lease(ticket["id"], "docker_container", cid,
                                        {"run_id": str(run_id), "labels": labels})
        except Exception:
            # Keep the durable intent even if best-effort removal succeeds.
            # Recovery can prove absence later, once the store is available.
            if self._owned(cid, labels) is True:
                try:
                    self._run(["docker", "rm", "--force", cid])
                except (OSError, subprocess.SubprocessError):
                    pass
            raise
        self.store.release_lease(intent_id)
        return {"command": ["docker", "start", "--attach", cid],
                "container_id": cid, "lease_id": lease_id}

    def recover_intent(self, lease):
        """Remove only a verified owned container; retain uncertain intents.

        Accepts a Store.active_leases row (or equivalent dict). The active
        durable record, rather than caller-provided labels, is authoritative.
        No cache, source, or temporary directory is removed here.
        """
        try:
            lease = dict(lease)
            if lease["kind"] != "docker_intent":
                return False
            rows = self.store.active_leases(lease["ticket_id"])
            matching = [dict(row) for row in rows if row["id"] == lease["id"]
                        and row["ticket_id"] == lease["ticket_id"]
                        and row["kind"] == "docker_intent"
                        and row["resource_key"] == lease["resource_key"]]
            if len(matching) != 1:
                return False
            details = json.loads(matching[0]["details_json"])
            name = details["name"]
            if (not isinstance(name, str)
                    or not re.fullmatch(r"autodev-check-[0-9a-f]{32}", name)
                    or name != lease["resource_key"]
                    or not isinstance(details["run_id"], str)
                    or details["labels"] != self._labels(lease["ticket_id"], details["run_id"])):
                return False
            labels = details["labels"]
        except Exception:
            # Includes DB_DOWN: without durable ownership proof do not act.
            return False
        try:
            result = self._run(["docker", "container", "inspect", name])
        except (OSError, subprocess.SubprocessError):
            return False
        if result.returncode:
            # An absent name does not prove that a timed-out create was
            # cancelled by the daemon. Keep ownership durable so a late
            # container remains recoverable; never free mounted resources.
            return False
        else:
            try:
                objects = json.loads(result.stdout)
                if len(objects) != 1:
                    return False
                container = objects[0]
                cid = container["Id"]
                if (container["Name"] != "/" + name
                        or not isinstance(cid, str) or not re.fullmatch(r"[0-9a-f]{64}", cid)
                        or any(container["Config"]["Labels"].get(key) != value
                               for key, value in labels.items())):
                    return False
            except (ValueError, KeyError, TypeError, AttributeError):
                return False
            # Re-inspect the full ID before removal; never rm by mutable name.
            if self._owned(cid, labels) is not True:
                return False
            try:
                result = self._run(["docker", "rm", "--force", cid])
            except (OSError, subprocess.SubprocessError):
                return False
            if result.returncode:
                return False
        try:
            self.store.release_lease(lease["id"])
        except Exception:
            return False
        return True

    def _owned(self, cid, labels):
        try:
            result = self._run(["docker", "container", "inspect", cid])
        except (OSError, subprocess.SubprocessError):
            return False
        if result.returncode:
            # Only a definite absence permits releasing a lease.
            if f"No such container: {cid}" in result.stderr or f"No such object: {cid}" in result.stderr:
                return None
            return False
        try:
            objects = json.loads(result.stdout)
            return (len(objects) == 1 and objects[0]["Id"] == cid
                    and all(objects[0]["Config"]["Labels"].get(key) == value
                            for key, value in labels.items()))
        except (ValueError, KeyError, TypeError, AttributeError):
            return False

    def cleanup(self, container_id, lease_id, ticket_id, run_id):
        if not re.fullmatch(r"[0-9a-f]{64}", container_id):
            return False
        labels = self._labels(ticket_id, run_id)
        matching = [row for row in self.store.active_leases(ticket_id)
                    if row["id"] == lease_id and row["ticket_id"] == ticket_id
                    and row["kind"] == "docker_container" and row["resource_key"] == container_id]
        if len(matching) != 1:
            return False
        try:
            details = json.loads(matching[0]["details_json"])
            if details.get("run_id") != str(run_id) or details.get("labels") != labels:
                return False
        except (ValueError, TypeError, AttributeError):
            return False
        owned = self._owned(container_id, labels)
        if owned is False:
            return False
        if owned is True:
            try:
                result = self._run(["docker", "rm", "--force", container_id])
            except (OSError, subprocess.SubprocessError):
                return False
            if result.returncode and self._owned(container_id, labels) is not None:
                return False
        self.store.release_lease(lease_id)
        return True
