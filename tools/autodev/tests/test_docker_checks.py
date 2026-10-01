import csv
import io
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import Mock, patch

from tools.autodev.docker_checks import DockerCheck


CID = "a" * 64


class DockerCheckTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name).resolve()
        self.tree = self.root / "worktrees" / 'ticket, with "quotes"'
        self.tree.mkdir(parents=True)
        (self.tree / ".git").write_text("gitdir: /not/mounted/repository\n")
        self.temp = self.root / "tmp" / "ticket" / "run"
        self.temp.mkdir(parents=True)
        self.config = {"workspace": {"root": str(self.root),
                                    "worktrees_dir": str(self.root / "worktrees")},
                       "projects": {"app": {}}, "sandbox": {}}
        self.store = Mock()
        self.store.lease.return_value = 7
        self.check = DockerCheck(self.config, self.store)
        self.ticket = {"id": "ticket", "project": "app"}
        self.calls = []
        self.mock_run = patch.object(self.check, "_run", side_effect=self.run_command).start()
        self.addCleanup(patch.stopall)

    def run_command(self, command):
        self.calls.append(command)
        return subprocess.CompletedProcess(command, 0, CID + "\n", "")

    def prepare(self, argv=None):
        return self.check.prepare(self.ticket, argv or ["flutter", "test", "--no-pub"],
                                  self.tree, self.temp, "run")

    def lease(self):
        self.store.active_leases.return_value = [{"id": 7, "ticket_id": "ticket",
            "kind": "docker_container", "resource_key": CID,
            "details_json": json.dumps({"run_id": "run",
                "labels": self.check._labels("ticket", "run")})}]

    def inspection(self, labels=None, cid=CID):
        return subprocess.CompletedProcess([], 0, json.dumps([
            {"Id": cid, "Config": {"Labels": labels if labels is not None
                                    else self.check._labels("ticket", "run")}}]), "")

    def test_isolation_mount_escaping_and_argv_boundaries(self):
        args = ["flutter", "test", 'test/a space;$(touch pwn)".dart']
        prepared = self.prepare(args)
        command = self.calls[-1]
        self.assertEqual(prepared, {"command": ["docker", "start", "--attach", CID],
                                   "container_id": CID, "lease_id": 7})
        for flag in ("--network=none", "--cap-drop=ALL", "--security-opt=no-new-privileges",
                     "--pids-limit=512", "--memory=4g", "--cpus=2", "--pull=never"):
            self.assertIn(flag, command)
        mounts = [next(csv.reader(io.StringIO(command[i + 1])))
                  for i, value in enumerate(command) if value == "--mount"]
        self.assertEqual(len(mounts), 3)
        self.assertEqual(mounts[0], ["type=bind", f"source={self.tree}", "target=/workspace"])
        self.assertEqual(mounts[1], ["type=bind", f"source={self.tree / '.git'}",
                                    "target=/workspace/.git", "readonly"])
        self.assertTrue(mounts[2][1].startswith(f"source={self.temp}/docker-check-"))
        self.assertEqual(command[-len(args):], args)
        self.assertIn('exec "$@"', self.check.SCRIPT)
        self.assertIn("PUB_CACHE=/tmp/autodev/pub", command)
        self.assertIn("GRADLE_USER_HOME=/tmp/autodev/gradle", command)
        self.assertNotIn("--privileged", command)
        self.assertEqual(self.store.lease.call_count, 2)
        self.assertEqual(self.store.lease.call_args_list[0].args[1], 'docker_intent')
        self.assertEqual(self.store.lease.call_args_list[1].args[1], 'docker_container')

    def test_maps_dedicated_binary_without_mounting_sdk(self):
        executable = self.root / "toolchains" / "flutter" / "bin" / "dart"
        executable.parent.mkdir(parents=True)
        executable.touch()
        self.prepare([str(executable), "analyze"])
        self.assertEqual(self.calls[-1][-2:], ["dart", "analyze"])
        self.assertFalse(any(str(executable.parent) in value for value in self.calls[-1]))

    def test_rejects_other_executables_and_host_binaries(self):
        for executable in ("sh", "/usr/bin/flutter", "./flutter"):
            with self.subTest(executable=executable), self.assertRaises((ValueError, FileNotFoundError)):
                self.prepare([executable, "test"])
        self.assertEqual(self.calls, [])

    def test_rejects_path_escape_and_symlink(self):
        for path in (self.root, self.tree / "..", self.temp):
            with self.subTest(path=path), self.assertRaises(ValueError):
                self.check.prepare(self.ticket, ["flutter", "test"], path, self.temp, "run")
        link = self.root / "worktrees" / "link"
        link.symlink_to(self.tree, target_is_directory=True)
        with self.assertRaises(ValueError):
            self.check.prepare(self.ticket, ["flutter", "test"], link, self.temp, "run")
        self.assertEqual(self.calls, [])

    def test_rejects_git_marker_symlink(self):
        marker = self.tree / ".git"
        marker.unlink()
        marker.symlink_to(self.root)
        with self.assertRaises(ValueError):
            self.prepare()
        self.assertEqual(self.calls, [])

    def test_clones_both_seeds_and_never_mounts_shared_cache(self):
        for name in ("pub", "gradle"):
            seed = self.root / "cache" / name
            seed.mkdir(parents=True)
            self.config["sandbox"][f"{name}_cache_seed"] = str(seed)
        self.prepare()
        copies = self.calls[:-1]
        self.assertEqual(len(copies), 2)
        for command in copies:
            self.assertEqual(command[:2], ["/bin/cp", "-cR"])
            self.assertTrue(command[-1].startswith(str(self.temp)))
        self.assertFalse(any(str(self.root / "cache") in arg for arg in self.calls[-1]))
        first_mount = self.calls[-1]
        self.prepare()
        self.assertNotEqual([a for a in first_mount if "target=/tmp/autodev" in a],
                            [a for a in self.calls[-1] if "target=/tmp/autodev" in a])

    def test_seed_symlink_or_clone_failure_prevents_create(self):
        seed = self.root / "cache" / "pub"
        seed.mkdir(parents=True)
        self.config["sandbox"]["pub_cache_seed"] = str(seed)
        (seed / "foreign").symlink_to(self.root)
        with self.assertRaises(ValueError):
            self.prepare()
        (seed / "foreign").unlink()
        self.mock_run.side_effect = lambda argv: subprocess.CompletedProcess(argv, 1, "", "failed")
        with self.assertRaises(RuntimeError):
            self.prepare()
        self.store.lease.assert_not_called()

    def test_cleanup_verifies_lease_cid_and_labels(self):
        self.lease()
        self.mock_run.side_effect = [self.inspection(), subprocess.CompletedProcess([], 0, "", "")]
        self.assertTrue(self.check.cleanup(CID, 7, "ticket", "run"))
        self.assertEqual(self.mock_run.call_args.args[0], ["docker", "rm", "--force", CID])
        self.store.release_lease.assert_called_once_with(7)

    def test_foreign_labels_or_cid_never_removed(self):
        self.lease()
        for inspection in (self.inspection({}), self.inspection(cid="b" * 64),
                           self.inspection(self.check._labels("ticket", "foreign"))):
            self.mock_run.side_effect = None
            self.mock_run.return_value = inspection
            self.assertFalse(self.check.cleanup(CID, 7, "ticket", "run"))
            self.assertNotEqual(self.mock_run.call_args.args[0][1], "rm")
        self.store.release_lease.assert_not_called()

    def test_wrong_lease_or_run_does_not_contact_docker(self):
        self.lease()
        self.assertFalse(self.check.cleanup(CID, 8, "ticket", "run"))
        self.assertFalse(self.check.cleanup(CID, 7, "ticket", "foreign"))
        self.assertFalse(self.check.cleanup("a", 7, "ticket", "run"))
        self.mock_run.assert_not_called()

    def test_absent_container_releases_but_daemon_failure_retains_lease(self):
        self.lease()
        self.mock_run.side_effect = None
        self.mock_run.return_value = subprocess.CompletedProcess([], 1, "", "daemon unavailable")
        self.assertFalse(self.check.cleanup(CID, 7, "ticket", "run"))
        self.store.release_lease.assert_not_called()
        self.mock_run.return_value = subprocess.CompletedProcess([], 1, "", f"Error: No such container: {CID}")
        self.assertTrue(self.check.cleanup(CID, 7, "ticket", "run"))
        self.store.release_lease.assert_called_once_with(7)

    def test_failed_removal_retains_lease(self):
        self.lease()
        self.mock_run.side_effect = [self.inspection(),
            subprocess.CompletedProcess([], 1, "", "failed"), self.inspection()]
        self.assertFalse(self.check.cleanup(CID, 7, "ticket", "run"))
        self.store.release_lease.assert_not_called()

    def test_cleanup_timeout_retains_lease(self):
        self.lease()
        self.mock_run.side_effect = subprocess.TimeoutExpired("docker", 600)
        self.assertFalse(self.check.cleanup(CID, 7, "ticket", "run"))
        self.store.release_lease.assert_not_called()

    def test_source_directory_escape_rejected(self):
        self.config["projects"]["app"]["source_directory"] = "../foreign"
        with self.assertRaises(ValueError):
            self.prepare()
        self.mock_run.assert_not_called()

    def test_foreign_seed_rejected(self):
        self.config["sandbox"]["pub_cache_seed"] = str(self.tree)
        with self.assertRaises(ValueError):
            self.prepare()
        self.mock_run.assert_not_called()

    def test_create_failure_or_short_cid_retains_durable_intent(self):
        self.mock_run.side_effect = None
        for result in (subprocess.CompletedProcess([], 1, "", "missing image"),
                       subprocess.CompletedProcess([], 0, "abcdef", "")):
            self.mock_run.return_value = result
            with self.assertRaises(RuntimeError):
                self.prepare()
        self.assertEqual(self.store.lease.call_count, 2)
        self.assertTrue(all(call.args[1] == 'docker_intent' for call in self.store.lease.call_args_list))
        self.store.release_lease.assert_not_called()

    def test_lease_failure_removes_only_verified_container(self):
        self.store.lease.side_effect = [7, RuntimeError("lease failed")]
        self.mock_run.side_effect = [subprocess.CompletedProcess([], 0, CID, ""),
                                    self.inspection(), subprocess.CompletedProcess([], 0, "", "")]
        with self.assertRaisesRegex(RuntimeError, "lease failed"):
            self.prepare()
        self.assertEqual(self.mock_run.call_args.args[0], ["docker", "rm", "--force", CID])

    def test_absent_intent_retained_for_late_daemon_creation(self):
        name = 'autodev-check-' + 'b' * 32
        lease = {'id': 7, 'ticket_id': 'ticket', 'kind': 'docker_intent',
                 'resource_key': name, 'details_json': json.dumps({
                     'name': name, 'run_id': 'run',
                     'labels': self.check._labels('ticket', 'run')})}
        self.store.active_leases.return_value = [lease]
        self.mock_run.side_effect = None
        self.mock_run.return_value = subprocess.CompletedProcess(
            [], 1, '', f'Error: No such container: {name}')
        self.assertFalse(self.check.recover_intent(lease))
        self.store.release_lease.assert_not_called()


if __name__ == "__main__":
    unittest.main()
