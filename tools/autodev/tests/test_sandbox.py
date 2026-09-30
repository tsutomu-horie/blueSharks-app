from __future__ import annotations

import subprocess
import tempfile
import unittest
from pathlib import Path

from tools.autodev.engine import Orchestrator


@unittest.skipUnless(Path("/usr/bin/sandbox-exec").is_file(), "macOS sandbox-exec is unavailable")
class SandboxTests(unittest.TestCase):
    def test_mechanical_check_can_write_only_inside_ticket_paths(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve()
            worktree = root / "worktree"
            temp_dir = root / "ticket-temp"
            worktree.mkdir()
            temp_dir.mkdir()
            git_ref = worktree / ".git"
            git_ref.write_text("gitdir: /Users/work/private/.git/worktrees/ticket\n")
            outside = root / "outside.txt"
            orchestrator = object.__new__(Orchestrator)
            orchestrator.config = {
                "sandbox": {"exec_binary": "/usr/bin/sandbox-exec", "read_paths": ["/usr", "/System", "/Library"]}
            }

            allowed = orchestrator._sandboxed_check_command(
                ["/usr/bin/touch", str(worktree / "allowed.txt")], worktree, temp_dir,
            )
            result = subprocess.run(allowed, capture_output=True, text=True, timeout=15)
            if "sandbox_apply: Operation not permitted" in result.stderr:
                self.skipTest("the host execution sandbox does not allow nested macOS sandboxes")
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue((worktree / "allowed.txt").is_file())

            denied = orchestrator._sandboxed_check_command(
                ["/usr/bin/touch", str(outside)], worktree, temp_dir,
            )
            result = subprocess.run(denied, capture_output=True, text=True, timeout=15)
            if "sandbox_apply: Operation not permitted" in result.stderr:
                self.skipTest("the host execution sandbox does not allow nested macOS sandboxes")
            self.assertNotEqual(result.returncode, 0)
            self.assertFalse(outside.exists())

            protected_git_ref = orchestrator._sandboxed_check_command(
                ["/usr/bin/touch", str(git_ref)], worktree, temp_dir,
            )
            result = subprocess.run(protected_git_ref, capture_output=True, text=True, timeout=15)
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(git_ref.read_text(), "gitdir: /Users/work/private/.git/worktrees/ticket\n")

            target = subprocess.Popen(["/bin/sleep", "30"], start_new_session=True)
            try:
                signal_attempt = orchestrator._sandboxed_check_command(
                    ["/bin/kill", "-TERM", str(target.pid)], worktree, temp_dir,
                )
                result = subprocess.run(signal_attempt, capture_output=True, text=True, timeout=15)
                self.assertNotEqual(result.returncode, 0)
                self.assertIsNone(target.poll())
            finally:
                target.terminate()
                target.wait(timeout=5)


if __name__ == "__main__":
    unittest.main()
