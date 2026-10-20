"""Verify the selected endpoints in real JIT and Release AOT executables."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
DART = os.environ.get("DART_BIN") or shutil.which("dart")
PROBE = ROOT / "test/support/app_environment_probe.dart"


@unittest.skipUnless(DART, "Dart SDK is required")
class AppEnvironmentTest(unittest.TestCase):
    def run_probe(self, defines, release=False):
        flags = [f"-D{key}={value}" for key, value in defines.items()]
        if release:
            flags.append("-DEXPECT_PRODUCT=true")
        with tempfile.TemporaryDirectory() as directory:
            executable = str(Path(directory) / "probe")
            command = ([DART, "compile", "exe", *flags, str(PROBE), "-o", executable]
                       if release else [DART, *flags, str(PROBE)])
            result = subprocess.run(command, cwd=ROOT, text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            if release:
                result = subprocess.run([executable], text=True, capture_output=True)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn("PASS:", result.stdout)

    def test_each_environment_and_default_are_independent_of_build_mode(self):
        for release in (False, True):
            for environment in (None, "local", "test", "production"):
                with self.subTest(release=release, environment=environment):
                    defines = {} if environment is None else {"APP_ENV": environment}
                    if environment == "local":
                        defines.update(LOCAL_AUTH_API_HOST="192.168.1.20", EXPECT_LOCAL="true")
                    if environment == "production":
                        defines["EXPECT_PRODUCTION_SERVICES"] = "true"
                    self.run_probe(defines, release)

    def test_legacy_ota_name_still_selects_test(self):
        self.run_probe({"APP_ENV": "ota-test"}, release=True)

    def test_invalid_or_conflicting_environments_are_rejected_in_release(self):
        for defines in [
            {"APP_ENV": "prod"}, {"APP_ENV": ""}, {"APP_ENV": "local"},
            {"APP_ENV": "local", "LOCAL_AUTH_API_HOST": "https://host"},
            {"APP_ENV": "local", "LOCAL_AUTH_API_HOST": "999.1.1.1"},
            {"APP_ENV": "production", "LOCAL_AUTH_API_HOST": "localhost"},
            {"APP_ENV": "test", "USE_LOCAL_AUTH_API": "true"},
        ]:
            with self.subTest(defines=defines):
                self.run_probe({**defines, "EXPECT_INVALID": "true"}, release=True)


if __name__ == "__main__":
    unittest.main()
