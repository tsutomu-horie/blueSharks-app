from pathlib import Path
import fcntl
import plistlib
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

from tools.autodev import service
from tools.autodev import cli


class ServiceTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.config = {"_config_path": str(self.root / "config with spaces.toml"),
                       "workspace": {"logs_dir": str(self.root / "logs"),
                                     "state_dir": str(self.root / "state")}}
        self.plist = service.build_plist(self.config, self.root)
        self.path = service.install(self.plist, self.root / "agents")

    def result(self, code=0, config=None):
        config = self.config if config is None else config
        environment = service.build_plist(config, self.root)["EnvironmentVariables"]
        output = "state = running\n\tenvironment = {\n" + "".join(
            f"\t\t{key} => {value}\n" for key, value in environment.items()) + "\t}\n"
        return subprocess.CompletedProcess(["launchctl"], code, output, "")

    def test_plist_paths_arguments_and_pause_policy(self):
        value = service.read(self.path)
        self.assertEqual(value["ProgramArguments"], [sys.executable, "-m", "tools.autodev.cli",
            "--config", self.config["_config_path"], "run", "--continuous"])
        self.assertEqual(value["WorkingDirectory"], str(self.root))
        self.assertEqual(value["StandardOutPath"], str(self.root / "logs/orchestrator.stdout.log"))
        self.assertEqual(value["StandardErrorPath"], str(self.root / "logs/orchestrator.stderr.log"))
        self.assertEqual(value["EnvironmentVariables"]["BLUE_SHARKS_AUTODEV_CONFIG"], self.config["_config_path"])
        self.assertEqual(value["EnvironmentVariables"][service.STATE_ENV], str(self.root / "state"))
        self.assertEqual(value["KeepAlive"], {"SuccessfulExit": False})
        self.assertTrue(value["RunAtLoad"])

    def test_idempotent_install_and_backup_before_update(self):
        service.install(self.plist, self.path.parent)
        self.assertEqual(list(self.path.parent.glob("*.backup-*")), [])
        before = self.path.read_bytes()
        changed = dict(self.plist, ThrottleInterval=30)
        service.install(changed, self.path.parent)
        backups = list(self.path.parent.glob("*.backup-*"))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_bytes(), before)
        self.assertEqual(service.read(self.path)["ThrottleInterval"], 30)

    def test_foreign_and_symlink_preserved(self):
        self.path.write_bytes(plistlib.dumps({"Label": "user.service"}))
        before = self.path.read_bytes()
        with self.assertRaises(FileExistsError):
            service.install(self.plist, self.path.parent)
        self.assertEqual(self.path.read_bytes(), before)
        self.path.unlink()
        target = self.root / "user.plist"
        target.write_bytes(before)
        self.path.symlink_to(target)
        with self.assertRaises(FileExistsError):
            service.install(self.plist, self.path.parent)
        self.assertEqual(target.read_bytes(), before)

    @patch.object(service.subprocess, "run")
    def test_bootstrap_commands_and_existing_reuse(self, run):
        run.side_effect = [self.result(113), self.result(113), self.result()]
        self.assertTrue(service.bootstrap(self.path, self.root / "state", uid=123))
        self.assertEqual(run.call_args_list[0].args[0], ["launchctl", "print", f"gui/123/{service.LABEL}"])
        self.assertEqual(run.call_args_list[2].args[0], ["launchctl", "bootstrap", "gui/123", str(self.path)])
        run.reset_mock()
        run.side_effect = None
        run.return_value = self.result()
        self.assertTrue(service.bootstrap(self.path, self.root / "state", uid=123))
        self.assertEqual(run.call_count, 3)
        self.assertEqual(run.call_args.args[0], ["launchctl", "kickstart", f"gui/123/{service.LABEL}"])

    @patch.object(service.subprocess, "run")
    def test_unload_and_missing_service(self, run):
        run.side_effect = [self.result(), self.result(), self.result()]
        self.assertTrue(service.unload(self.root / "state", uid=123, config_path=Path(self.config["_config_path"])))
        self.assertEqual(run.call_args.args[0], ["launchctl", "bootout", f"gui/123/{service.LABEL}"])
        run.side_effect = [self.result(113)]
        self.assertFalse(service.unload(self.root / "state"))

    @patch.object(service.subprocess, "run")
    def test_active_lock_prevents_bootstrap_and_unload(self, run):
        state = self.root / "state"
        state.mkdir()
        with (state / "orchestrator.lock").open("a+") as stream:
            fcntl.flock(stream, fcntl.LOCK_EX | fcntl.LOCK_NB)
            run.return_value = self.result(113)
            self.assertFalse(service.bootstrap(self.path, state))
            run.return_value = self.result()
            self.assertFalse(service.bootstrap(self.path, state))
            with self.assertRaises(RuntimeError):
                service.unload(state, config_path=Path(self.config["_config_path"]))
        self.assertTrue(all(call.args[0][1] == "print" for call in run.call_args_list))

    @patch.object(service.subprocess, "run")
    def test_reinstall_requires_safe_unload_to_apply_registered_definition(self, run):
        changed = dict(self.plist, ThrottleInterval=30)
        service.install(changed, self.path.parent)
        run.return_value = self.result()
        self.assertTrue(service.bootstrap(self.path, self.root / "state", uid=123))
        self.assertEqual([call.args[0][1] for call in run.call_args_list], ["print", "print", "kickstart"])
        run.reset_mock()
        run.side_effect = [self.result(), self.result(), self.result(), self.result(113), self.result(113), self.result()]
        self.assertTrue(service.unload(self.root / "state", uid=123, config_path=Path(self.config["_config_path"])))
        self.assertTrue(service.bootstrap(self.path, self.root / "state", uid=123))
        self.assertEqual([call.args[0][1] for call in run.call_args_list],
                         ["print", "print", "bootout", "print", "print", "bootstrap"])
        self.assertEqual(service.read(self.path)["ThrottleInterval"], 30)

    @patch.object(service.subprocess, "run")
    def test_kickstart_failure_is_propagated(self, run):
        run.side_effect = [self.result(), self.result(), self.result(1)]
        with self.assertRaises(subprocess.CalledProcessError):
            service.bootstrap(self.path, self.root / "state")

    @patch.object(service.subprocess, "run")
    def test_errors_are_not_treated_as_absent(self, run):
        run.return_value = self.result(1)
        with self.assertRaises(subprocess.CalledProcessError):
            service.bootstrap(self.path, self.root / "state")
        self.assertEqual(run.call_count, 1)

    @patch.object(service, "unload", return_value=True)
    @patch.object(service.subprocess, "run")
    def test_stop_requests_pause_before_unload(self, run, unload):
        run.return_value = self.result()
        self.assertTrue(service.stop(self.config, self.root))
        self.assertEqual(run.call_args.args[0][-1], "pause")
        self.assertEqual(run.call_args.args[0][3:5], ["--config", self.config["_config_path"]])
        unload.assert_called_once_with(self.root / "state", None,
                                       config_path=Path(self.config["_config_path"]))

    @patch.object(service, "unload", side_effect=RuntimeError("active"))
    @patch.object(service.subprocess, "run")
    def test_stop_timeout_preserves_running_job(self, run, unload):
        run.return_value = self.result()
        with self.assertRaises(TimeoutError):
            service.stop(self.config, self.root, timeout=0)
        self.assertEqual(run.call_count, 2)

    def other_config(self, *, same_state=False):
        return {"_config_path": str(self.root / "config-B.toml"),
                "workspace": {"logs_dir": str(self.root / "logs-B"),
                              "state_dir": self.config["workspace"]["state_dir"] if same_state
                              else str(self.root / "state-B")}}

    @patch.object(service.subprocess, "run")
    def test_active_loaded_a_stop_b_rejected_before_pause_or_b_lock(self, run):
        state = self.root / "state"
        state.mkdir()
        other = self.other_config()
        run.return_value = self.result()
        with (state / "orchestrator.lock").open("a+") as stream:
            fcntl.flock(stream, fcntl.LOCK_EX | fcntl.LOCK_NB)
            with self.assertRaises(service.ServiceIdentityError):
                service.stop(other, self.root, timeout=0)
        self.assertEqual([call.args[0][1] for call in run.call_args_list], ["print"])
        self.assertFalse(Path(other["workspace"]["state_dir"]).exists())

    @patch.object(service.subprocess, "run")
    def test_loaded_a_reinstalled_b_cannot_kickstart_or_unload(self, run):
        other = self.other_config()
        service.install(service.build_plist(other, self.root), self.path.parent)
        run.return_value = self.result()
        with self.assertRaises(service.ServiceIdentityError):
            service.bootstrap(self.path, Path(other["workspace"]["state_dir"]))
        with self.assertRaises(service.ServiceIdentityError):
            service.unload(Path(other["workspace"]["state_dir"]),
                           config_path=Path(other["_config_path"]))
        self.assertTrue(all(call.args[0][1] == "print" for call in run.call_args_list))

    @patch.object(service.subprocess, "run")
    def test_loaded_a_can_stop_as_a_after_disk_plist_changes_to_b(self, run):
        service.install(service.build_plist(self.other_config(), self.root), self.path.parent)
        run.return_value = self.result()
        self.assertTrue(service.stop(self.config, self.root, timeout=0))
        self.assertEqual(run.call_args.args[0][1], "bootout")
        pause_args = run.call_args_list[1].args[0]
        self.assertEqual(pause_args[4], self.config["_config_path"])

    @patch.object(service.subprocess, "run")
    def test_pause_failure_never_boots_out(self, run):
        run.side_effect = [self.result(), subprocess.CalledProcessError(1, ["pause"])]
        with self.assertRaises(subprocess.CalledProcessError):
            service.stop(self.config, self.root, timeout=0)
        self.assertEqual(run.call_count, 2)

    @patch.object(service.subprocess, "run")
    def test_config_mismatch_rejected_even_when_state_matches(self, run):
        other = self.other_config(same_state=True)
        run.return_value = self.result()
        with self.assertRaises(service.ServiceIdentityError):
            service.stop(other, self.root)
        with self.assertRaises(service.ServiceIdentityError):
            service.unload(self.root / "state", config_path=Path(other["_config_path"]))
        self.assertTrue(all(call.args[0][1] == "print" for call in run.call_args_list))

    @patch.object(service.subprocess, "run")
    def test_state_mismatch_rejected_even_when_config_matches(self, run):
        other = self.other_config()
        other["_config_path"] = self.config["_config_path"]
        run.return_value = self.result()
        with self.assertRaises(service.ServiceIdentityError):
            service.stop(other, self.root)
        with self.assertRaises(service.ServiceIdentityError):
            service.bootstrap(self.path, Path(other["workspace"]["state_dir"]))
        self.assertTrue(all(call.args[0][1] == "print" for call in run.call_args_list))

    @patch.object(service.subprocess, "run")
    def test_unknown_legacy_inherited_and_duplicate_identity_refused(self, run):
        valid = self.result().stdout
        unknowns = ["state = running", valid.replace(service.STATE_ENV, "OLD_STATE_ENV"),
                    valid.replace("environment =", "inherited environment ="),
                    valid.replace("\tenvironment = {", "\tenvironment = {\n"
                                  f"\t\t{service.CONFIG_ENV} => /foreign.toml")]
        for output in unknowns:
            run.reset_mock()
            run.return_value = subprocess.CompletedProcess([], 0, output, "")
            with self.subTest(output=output):
                with self.assertRaises(service.ServiceIdentityError):
                    service.stop(self.config, self.root)
                with self.assertRaises(service.ServiceIdentityError):
                    service.unload(self.root / "state", config_path=Path(self.config["_config_path"]))
                with self.assertRaises(service.ServiceIdentityError):
                    service.bootstrap(self.path, self.root / "state")
                self.assertTrue(all(call.args[0][1] == "print" for call in run.call_args_list))

    @patch.object(service.subprocess, "run")
    def test_unload_requires_explicit_config_identity(self, run):
        run.return_value = self.result()
        with self.assertRaises(service.ServiceIdentityError):
            service.unload(self.root / "state")
        self.assertEqual(run.call_count, 1)

    @patch.object(service.subprocess, "run")
    def test_loaded_identity_rechecked_under_lock(self, run):
        for operation in (lambda: service.bootstrap(self.path, self.root / "state"),
                          lambda: service.unload(self.root / "state",
                              config_path=Path(self.config["_config_path"]))):
            run.reset_mock()
            run.side_effect = [self.result(), self.result(config=self.other_config())]
            with self.assertRaises(service.ServiceIdentityError):
                operation()
            self.assertEqual([call.args[0][1] for call in run.call_args_list], ["print", "print"])

    @patch.object(service.subprocess, "run")
    def test_matching_stop_pauses_then_verifies_and_boots_out(self, run):
        run.return_value = self.result()
        self.assertTrue(service.stop(self.config, self.root, timeout=0))
        self.assertEqual([call.args[0][1] if call.args[0][0] == "launchctl" else call.args[0][-1]
                          for call in run.call_args_list],
                         ["print", "pause", "print", "print", "bootout"])

    @patch.object(service.subprocess, "run")
    def test_matching_active_stop_retains_pause_and_loaded_job(self, run):
        state = self.root / "state"
        state.mkdir()
        run.return_value = self.result()
        with (state / "orchestrator.lock").open("a+") as stream:
            fcntl.flock(stream, fcntl.LOCK_EX | fcntl.LOCK_NB)
            with self.assertRaises(TimeoutError):
                service.stop(self.config, self.root, timeout=0)
        self.assertEqual(run.call_count, 2)
        self.assertEqual(run.call_args.args[0][-1], "pause")

    @patch.object(service.subprocess, "run")
    def test_stop_refuses_replacement_after_pause(self, run):
        run.side_effect = [self.result(), self.result(), self.result(config=self.other_config())]
        with self.assertRaises(service.ServiceIdentityError):
            service.stop(self.config, self.root, timeout=0)
        self.assertEqual(run.call_count, 3)
        self.assertEqual(run.call_args.args[0][1], "print")

    @patch.object(service.subprocess, "run")
    def test_quoted_loaded_paths_and_default_environment_do_not_override_identity(self, run):
        output = self.result().stdout
        for value in (self.config["_config_path"], self.config["workspace"]["state_dir"]):
            output = output.replace(f"=> {value}\n", f'=> "{value}"\n')
        output += f"\tdefault environment = {{\n\t\t{service.CONFIG_ENV} => /foreign\n\t}}\n"
        run.return_value = subprocess.CompletedProcess([], 0, output, "")
        self.assertTrue(service.unload(self.root / "state", config_path=Path(self.config["_config_path"])))

    @patch.object(service.subprocess, "run")
    def test_bootstrap_rejects_inconsistent_plist_arguments(self, run):
        changed = dict(self.plist, ProgramArguments=[sys.executable, "-m", "tools.autodev.cli",
                            "--config", "/foreign.toml", "run", "--continuous"])
        service.install(changed, self.path.parent)
        with self.assertRaises(service.ServiceIdentityError):
            service.bootstrap(self.path, self.root / "state")
        run.assert_not_called()

    @patch.object(service.subprocess, "run")
    def test_cli_kickstart_rejects_loaded_a_operation_b(self, run):
        for other in (self.other_config(), self.other_config(same_state=True)):
            run.reset_mock()
            run.return_value = self.result()
            with self.assertRaises(service.ServiceIdentityError):
                cli.kickstart_if_loaded(other)
            self.assertEqual([call.args[0][1] for call in run.call_args_list], ["print"])
        self.assertFalse((self.root / "state-B").exists())

    @patch.object(service.subprocess, "run")
    def test_cli_kickstart_rejects_state_mismatch_and_unknown_job(self, run):
        other = self.other_config()
        other["_config_path"] = self.config["_config_path"]
        run.return_value = self.result()
        with self.assertRaises(service.ServiceIdentityError):
            cli.kickstart_if_loaded(other)
        run.reset_mock()
        run.return_value = subprocess.CompletedProcess([], 0, "state = running", "")
        with self.assertRaises(service.ServiceIdentityError):
            cli.kickstart_if_loaded(self.config)
        self.assertEqual([call.args[0][1] for call in run.call_args_list], ["print"])

    @patch.object(service.subprocess, "run")
    def test_cli_kickstart_missing_job_is_noop(self, run):
        for code in (3, 113):
            run.reset_mock()
            run.return_value = self.result(code)
            cli.kickstart_if_loaded(self.config)
            self.assertEqual([call.args[0][1] for call in run.call_args_list], ["print"])
        self.assertFalse((self.root / "state").exists())

    @patch.object(service.subprocess, "run")
    def test_cli_kickstart_active_matching_job_is_noop(self, run):
        state = self.root / "state"
        state.mkdir()
        run.return_value = self.result()
        with (state / "orchestrator.lock").open("a+") as stream:
            fcntl.flock(stream, fcntl.LOCK_EX | fcntl.LOCK_NB)
            cli.kickstart_if_loaded(self.config)
        self.assertEqual([call.args[0][1] for call in run.call_args_list], ["print"])

    @patch.object(service.subprocess, "run")
    def test_cli_kickstart_idle_matching_job_releases_lock_before_launch(self, run):
        def response(argv, **kwargs):
            if argv[1] == "kickstart":
                with service._idle_lock(self.root / "state"):
                    pass
            return self.result()
        run.side_effect = response
        cli.kickstart_if_loaded(self.config)
        self.assertEqual([call.args[0][1] for call in run.call_args_list], ["print", "print", "kickstart"])
        self.assertEqual(run.call_args.args[0], ["launchctl", "kickstart", service._target(None)])
        self.assertNotIn("-k", run.call_args.args[0])

    @patch.object(service.subprocess, "run")
    def test_cli_kickstart_rechecks_replaced_or_removed_loaded_job(self, run):
        run.side_effect = [self.result(), self.result(config=self.other_config())]
        with self.assertRaises(service.ServiceIdentityError):
            cli.kickstart_if_loaded(self.config)
        self.assertEqual([call.args[0][1] for call in run.call_args_list], ["print", "print"])
        run.reset_mock()
        run.side_effect = [self.result(), self.result(113)]
        cli.kickstart_if_loaded(self.config)
        self.assertEqual([call.args[0][1] for call in run.call_args_list], ["print", "print"])

    @patch.object(service.subprocess, "run")
    def test_cli_kickstart_uses_loaded_environment_after_reinstall(self, run):
        other = self.other_config()
        service.install(service.build_plist(other, self.root), self.path.parent)
        run.return_value = self.result()
        with self.assertRaises(service.ServiceIdentityError):
            cli.kickstart_if_loaded(other)
        run.reset_mock()
        cli.kickstart_if_loaded(self.config)
        self.assertEqual([call.args[0][1] for call in run.call_args_list], ["print", "print", "kickstart"])

    @patch.object(service.subprocess, "run")
    def test_cli_kickstart_print_and_start_failures_propagate(self, run):
        run.return_value = self.result(1)
        with self.assertRaises(subprocess.CalledProcessError):
            cli.kickstart_if_loaded(self.config)
        self.assertEqual(run.call_count, 1)
        run.side_effect = [self.result(), self.result(), self.result(1)]
        with self.assertRaises(subprocess.CalledProcessError):
            cli.kickstart_if_loaded(self.config)


if __name__ == "__main__":
    unittest.main()
