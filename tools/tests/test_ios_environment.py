import base64
import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import socket
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
import urllib.request


SCRIPT = Path(__file__).resolve().parents[1] / "ios_environment.py"
SPEC = importlib.util.spec_from_file_location("ios_environment", SCRIPT)
env = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = env
SPEC.loader.exec_module(env)


def encode(value):
    return base64.b64encode(value.encode()).decode()


class EnvironmentSwitchTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.root = Path(self.directory.name)
        self.other = [encode("EXISTING_FLAG=true"), encode("PRIVATE_CANARY=do-not-print")]
        self.make_files()

    def tearDown(self):
        self.directory.cleanup()

    def make_files(self, managed=(), newline="\n"):
        for index, name in enumerate(env.FILES):
            path = self.root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            value = ",".join(self.other + [encode(v) for v in managed])
            line = f'export "DART_DEFINES={value}"' if index == 1 else f"DART_DEFINES={value}"
            path.write_bytes(newline.join(["# existing comment", line, "OTHER_SETTING=preserve", ""]).encode())
            path.chmod(0o755)

    def snapshots(self):
        return [(self.root / name).read_bytes() for name in env.FILES]

    def select(self, preset, host=None, dry_run=False):
        return env.select(env.read_all(self.root), env.desired(preset, host), dry_run)

    def test_all_presets_and_repeated_switches_preserve_other_settings(self):
        for preset in ["local", "ota-test", "test-server", "local", "test-server"]:
            with self.subTest(preset=preset):
                self.select(preset)
                configs = env.read_all(self.root)
                self.assertEqual(env.verify(configs, preset)["preset"], preset)
                for config in configs:
                    self.assertEqual([t for t, k, _ in config.tokens if k not in env.KEYS], self.other)
                    self.assertIn("OTHER_SETTING=preserve", config.text)
                    self.assertEqual(config.mode, 0o755)

    def test_local_host_is_customizable_without_network(self):
        self.select("local", "dev-mac.local")
        self.assertEqual(env.verify(env.read_all(self.root))["managed_defines"]["LOCAL_AUTH_API_HOST"], "dev-mac.local")

    def test_dry_run_makes_no_change(self):
        before = self.snapshots()
        result = self.select("local", dry_run=True)
        self.assertEqual(result["files_to_change"], 3)
        self.assertEqual(self.snapshots(), before)

    def test_current_test_server_selection_is_idempotent(self):
        before = [(self.root / name).stat().st_mtime_ns for name in env.FILES]
        self.assertEqual(self.select("test-server")["files_changed"], 0)
        self.assertEqual([(self.root / name).stat().st_mtime_ns for name in env.FILES], before)

    def test_managed_duplicates_and_stale_values_are_removed(self):
        self.make_files(["APP_ENV=ota-test", "USE_LOCAL_AUTH_API=true", "USE_LOCAL_AUTH_API=false", "LOCAL_AUTH_API_HOST=old-host"])
        with self.assertRaises(env.ConfigurationError):
            env.verify(env.read_all(self.root))
        self.select("test-server")
        self.assertEqual(env.verify(env.read_all(self.root))["managed_defines"], {})

    def test_ota_preflight_rejects_missing_flag_local_and_conflicting_flags(self):
        for managed in [[], ["USE_LOCAL_AUTH_API=true", "LOCAL_AUTH_API_HOST=192.168.11.20"],
                        ["APP_ENV=ota-test", "USE_LOCAL_AUTH_API=true"],
                        ["APP_ENV=ota-test", "LOCAL_AUTH_API_HOST=192.168.11.20"]]:
            with self.subTest(managed=managed):
                self.make_files(managed)
                with self.assertRaises(env.ConfigurationError):
                    env.verify(env.read_all(self.root), "ota-test")

    def test_three_file_disagreement_and_inherited_override_are_rejected(self):
        self.select("ota-test")
        configs = env.read_all(self.root)
        configs[0].path.write_bytes(configs[0].replacement({}))
        with self.assertRaises(env.ConfigurationError):
            env.verify(env.read_all(self.root), "ota-test")
        self.select("ota-test")
        with self.assertRaises(env.ConfigurationError):
            env.verify(env.read_all(self.root), "ota-test", encode("USE_LOCAL_AUTH_API=true"))
        env.verify(env.read_all(self.root), "ota-test", encode("APP_ENV=ota-test"))

    def test_invalid_file_aborts_before_any_write(self):
        for defect in ["DART_DEFINES=not-base64!\n", "DART_DEFINES=\nDART_DEFINES=\n"]:
            self.make_files()
            (self.root / env.FILES[2]).write_text(defect)
            before = self.snapshots()
            with self.assertRaises(env.ConfigurationError):
                self.select("local")
            self.assertEqual(self.snapshots(), before)

    def test_missing_file_and_symlink_are_rejected(self):
        target = self.root / env.FILES[2]
        target.unlink()
        with self.assertRaises(env.ConfigurationError):
            self.select("local")
        target.symlink_to(self.root / env.FILES[0])
        with self.assertRaises(env.ConfigurationError):
            self.select("local")

    def test_line_endings_and_non_managed_bytes_are_preserved(self):
        self.make_files(newline="\r\n")
        self.select("local")
        self.assertTrue(all(b"\r\nOTHER_SETTING=preserve\r\n" in data for data in self.snapshots()))

    def test_concurrent_edit_and_write_failure_do_not_overwrite_user_changes(self):
        configs = env.read_all(self.root)
        configs[0].path.write_bytes(configs[0].original + b"USER_EDIT=1\n")
        before = self.snapshots()
        with self.assertRaises(env.ConfigurationError):
            env.select(configs, env.desired("local"))
        self.assertEqual(self.snapshots(), before)
        self.make_files()
        before = self.snapshots()
        original = env.atomic_write
        calls = 0

        def fail_second(*args):
            nonlocal calls
            calls += 1
            if calls == 2:
                raise OSError("simulated failure")
            return original(*args)

        with patch.object(env, "atomic_write", side_effect=fail_second):
            with self.assertRaises(env.ConfigurationError):
                self.select("local")
        self.assertEqual(self.snapshots(), before)

    def test_no_subprocess_or_network_is_started(self):
        forbidden = AssertionError("No build, subprocess, or network permitted")
        with patch.object(subprocess, "Popen", side_effect=forbidden), \
                patch.object(socket, "create_connection", side_effect=forbidden), \
                patch.object(urllib.request, "urlopen", side_effect=forbidden):
            self.select("local", dry_run=True)
            self.select("local")
            env.verify(env.read_all(self.root), "local")
            self.select("ota-test")
            env.verify(env.read_all(self.root), "ota-test")

    def test_bad_hosts_and_nonlocal_host_argument_are_rejected(self):
        for host in ["", "http://host", "host:8000", "user@host", "host/path", "999.999.999.999", "$(touch bad)"]:
            with self.subTest(host=host), self.assertRaises(env.ConfigurationError):
                env.desired("local", host)
        for preset in ["test-server", "ota-test"]:
            with self.assertRaises(env.ConfigurationError):
                env.desired(preset, env.DEFAULT_HOST)

    def test_cli_ota_gate_and_output_do_not_expose_other_defines(self):
        script = self.root / "tools/ios_environment.py"
        script.parent.mkdir(parents=True)
        script.write_bytes(SCRIPT.read_bytes())
        process_env = os.environ.copy()
        process_env.pop("DART_DEFINES", None)
        for arguments, expected in [(["ota-check"], 2), (["select", "ota-test", "--dry-run"], 0),
                                    (["select", "ota-test"], 0), (["ota-check"], 0)]:
            result = subprocess.run([sys.executable, "-B", str(script), *arguments], env=process_env,
                                    text=True, capture_output=True)
            self.assertEqual(result.returncode, expected, result.stdout + result.stderr)
            self.assertNotIn("PRIVATE_CANARY", result.stdout)
            self.assertNotIn("do-not-print", result.stdout)
            self.assertNotIn(self.other[1], result.stdout)
            if expected == 0:
                self.assertFalse(json.loads(result.stdout)["build_or_network_started"])
        with patch.dict(os.environ, {"DART_DEFINES": encode("USE_LOCAL_AUTH_API=true")}):
            output = io.StringIO()
            with patch.object(env, "__file__", str(script)), contextlib.redirect_stdout(output):
                self.assertEqual(env.main(["select", "ota-test"]), 2)


class PersistentSelectionTest(unittest.TestCase):
    setUp = EnvironmentSwitchTest.setUp
    tearDown = EnvironmentSwitchTest.tearDown
    make_files = EnvironmentSwitchTest.make_files
    snapshots = EnvironmentSwitchTest.snapshots

    def persist(self, preset="ota-test", dry_run=False):
        return env.select(env.read_all(self.root), env.desired(preset), dry_run, self.root)

    def selection(self):
        return env.read_selection(self.root)

    def test_persistent_snapshot_preserves_other_defines_and_survives_regeneration(self):
        self.persist()
        selection = self.selection()
        self.assertEqual(env.unrelated(selection["tokens"]), self.other)
        # Flutter may regenerate all three files without APP_ENV. The persistent
        # resolved Xcode setting remains ota-test and the guard accepts it.
        self.make_files()
        result = env.verify_persistent(env.read_all(self.root), selection, "ota-test",
                                      ",".join(t for t, _, _ in selection["tokens"]))
        self.assertEqual(result["preset"], "ota-test")
        self.assertTrue(result["persistent_selection"])

    def test_new_other_define_after_regeneration_requires_explicit_reselection(self):
        self.persist()
        self.other.append(encode("NEW_FLAG=keep-me"))
        self.make_files()
        with self.assertRaises(env.ConfigurationError):
            env.verify_persistent(env.read_all(self.root), self.selection())
        self.persist()
        self.assertEqual(env.unrelated(self.selection()["tokens"]), self.other)
        env.verify_persistent(env.read_all(self.root), self.selection(), "ota-test")

    def test_inconsistent_other_defines_abort_before_any_mutation(self):
        path = self.root / env.FILES[1]
        path.write_text(path.read_text().replace(self.other[0], encode("UNIQUE=1")))
        before = self.snapshots()
        with self.assertRaises(env.ConfigurationError):
            self.persist()
        self.assertEqual(self.snapshots(), before)
        self.assertFalse((self.root / env.SELECTION).exists())

    def test_stale_managed_flags_and_resolved_overrides_are_rejected(self):
        self.persist()
        selection = self.selection()
        self.make_files(["USE_LOCAL_AUTH_API=true", "LOCAL_AUTH_API_HOST=old-host"])
        with self.assertRaises(env.ConfigurationError):
            env.verify_persistent(env.read_all(self.root), selection)
        self.persist()
        for inherited in ["", ",".join(self.other), ",".join(self.other + [encode("APP_ENV=wrong")])]:
            with self.subTest(inherited=inherited), self.assertRaises(env.ConfigurationError):
                env.verify_persistent(env.read_all(self.root), self.selection(), inherited=inherited)

    def test_persistent_dry_run_does_not_create_selection(self):
        before = self.snapshots()
        result = self.persist(dry_run=True)
        self.assertEqual(result["files_to_change"], 4)
        self.assertEqual(self.snapshots(), before)
        self.assertFalse((self.root / env.SELECTION).exists())

    def test_malformed_or_symlink_selection_is_not_overwritten(self):
        p = self.root / env.SELECTION
        for text in ["USER_EDIT=keep\n", env.SELECTION_HEADER + "BS_IOS_PRESET=ota-test\nDART_DEFINES=" +
                     ",".join([encode("APP_ENV=ota-test")] * 2) + "\n"]:
            p.write_text(text)
            before = self.snapshots()
            with self.assertRaises(env.ConfigurationError):
                self.persist()
            self.assertEqual(self.snapshots(), before)
            self.assertEqual(p.read_text(), text)
        p.unlink()
        p.symlink_to(self.root / env.FILES[0])
        with self.assertRaises(env.ConfigurationError):
            self.persist()

    def test_missing_define_lines_are_appended_without_losing_existing_bytes(self):
        for name in env.FILES:
            (self.root / name).write_bytes(b"# Flutter regenerated\r\nOTHER_SETTING=preserve\r\n")
        self.persist()
        for name in env.FILES:
            data = (self.root / name).read_bytes()
            self.assertTrue(data.startswith(b"# Flutter regenerated\r\nOTHER_SETTING=preserve\r\n"))
            self.assertEqual(data.count(b"DART_DEFINES="), 1)
        env.verify_persistent(env.read_all(self.root), self.selection(), "ota-test")

    def test_fourth_file_write_failure_restores_three_originals(self):
        before = self.snapshots()
        original = env.atomic_write
        calls = 0

        def fail_fourth(*args):
            nonlocal calls
            calls += 1
            if calls == 4:
                raise OSError("simulated selection failure")
            return original(*args)

        with patch.object(env, "atomic_write", side_effect=fail_fourth):
            with self.assertRaises(env.ConfigurationError):
                self.persist()
        self.assertEqual(self.snapshots(), before)
        self.assertFalse((self.root / env.SELECTION).exists())

    def test_status_and_ota_check_report_persistent_effective_selection(self):
        script = self.root / "tools/ios_environment.py"
        script.parent.mkdir(parents=True)
        script.write_bytes(SCRIPT.read_bytes())
        self.persist()
        self.make_files()
        process_env = os.environ.copy()
        process_env.pop("DART_DEFINES", None)
        for command in ["status", "ota-check"]:
            result = subprocess.run([sys.executable, "-B", str(script), command], env=process_env,
                                    text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stdout)
            value = json.loads(result.stdout)
            self.assertEqual(value["preset"], "ota-test")
            self.assertTrue(value["persistent_selection"])
            self.assertNotIn("PRIVATE_CANARY", result.stdout)
            self.assertNotIn("do-not-print", result.stdout)

    def test_actual_project_guard_prevents_backend_on_mismatch(self):
        script = self.root / "tools/ios_environment.py"
        script.parent.mkdir(parents=True)
        script.write_bytes(SCRIPT.read_bytes())
        self.persist()
        backend_root = self.root / "fake-sdk"
        backend = backend_root / "packages/flutter_tools/bin/xcode_backend.sh"
        backend.parent.mkdir(parents=True)
        marker = self.root / "backend-ran"
        backend.write_text('printf passed > "$GUARD_TEST_MARKER"\n')
        project = SCRIPT.parents[1] / "ios/Runner.xcodeproj/project.pbxproj"
        import re
        line = next(line for line in project.read_text().splitlines() if 'xcode-check || exit' in line)
        phase = json.loads(line.split('shellScript = ', 1)[1].rstrip(';'))
        process_env = {**os.environ, "SRCROOT": str(self.root / "ios"),
                       "FLUTTER_ROOT": str(backend_root), "GUARD_TEST_MARKER": str(marker),
                       "DART_DEFINES": ""}
        bad = subprocess.run(["/bin/sh", "-c", phase], env=process_env, capture_output=True)
        self.assertNotEqual(bad.returncode, 0)
        self.assertFalse(marker.exists())
        process_env["DART_DEFINES"] = ",".join(t for t, _, _ in self.selection()["tokens"])
        good = subprocess.run(["/bin/sh", "-c", phase], env=process_env, capture_output=True)
        self.assertEqual(good.returncode, 0, good.stdout + good.stderr)
        self.assertEqual(marker.read_text(), "passed")

    def test_without_persistent_selection_default_build_guard_is_noop(self):
        script = self.root / "tools/ios_environment.py"
        script.parent.mkdir(parents=True)
        script.write_bytes(SCRIPT.read_bytes())
        for name in env.FILES:
            (self.root / name).unlink()
        result = subprocess.run([sys.executable, "-B", str(script), "xcode-check"],
                                text=True, capture_output=True)
        self.assertEqual(result.returncode, 0)
        self.assertTrue(json.loads(result.stdout)["default_build_unchanged"])


if __name__ == "__main__":
    unittest.main()
