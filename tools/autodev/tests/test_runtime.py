from __future__ import annotations

import io
import json
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

from tools.autodev.runtime import CodexRunner
from tools.autodev.state import Store


def sample_ticket(ticket_id: str) -> dict:
    return {
        "id": ticket_id,
        "title": "Runtime lease test",
        "type": "bugfix",
        "priority": "P1",
        "project": "app",
        "request": "test",
        "goal": "runtime lease remains while process cleanup is unverified",
        "acceptance_criteria": ["process state stays tracked"],
        "allowed_scope": ["lib/**"],
        "forbidden_scope": ["server/**"],
        "tests": ["test"],
        "test_targets": ["test/sample_test.dart"],
        "dependencies": [],
        "risk": "low",
        "max_repair_cycles": 2,
        "write_permission": True,
        "specification_source": None,
        "specification_checked_at": None,
        "current_state": {},
    }


class FakeProcess:
    pid = 912345
    returncode = 0

    def __init__(self, polls: list[int | None]):
        self.stdin = io.BytesIO()
        self._polls = iter(polls)

    def poll(self):
        return next(self._polls, self.returncode)

    def wait(self, timeout=None):
        return self.returncode


class RuntimeTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.store = Store(self.root / "control" / "tickets.sqlite3")
        self.binary = self.root / "codex"
        self.binary.touch()
        self.schema = self.root / "schema.json"
        self.schema.write_text("{}")
        self.workdir = self.root / "repo"
        self.workdir.mkdir()
        self.logs = self.root / "logs"
        self.runner = CodexRunner(
            self.store,
            {"codex": {"binary": str(self.binary), "timeout_seconds": 2}},
            self.logs,
        )

    def tearDown(self):
        self.temp.cleanup()

    def call(self, ticket_id: str, role: str = "ticket_intake"):
        return self.runner.run(
            ticket_id=ticket_id,
            role=role,
            phase="test",
            model="gpt-6-luna" if role == "ticket_intake" else "gpt-6.1-sol",
            reasoning="low",
            prompt="return the required JSON",
            schema=self.schema,
            workdir=self.workdir,
            write=False,
        )

    def test_ticket_intake_runs_without_a_nonexistent_ticket_lease(self):
        process = FakeProcess([None, 0])
        with patch.dict("os.environ", {"OPENAI_API_KEY": "secret", "GITHUB_TOKEN": "secret", "LANG": "en_US.UTF-8"}), \
             patch("tools.autodev.runtime.subprocess.run", return_value=SimpleNamespace(returncode=0, stdout="codex-cli 0.159.2")), \
             patch("tools.autodev.runtime.subprocess.Popen", return_value=process) as popen, \
             patch("tools.autodev.runtime.CodexRunner._process_start_identity", return_value=None), \
             patch("tools.autodev.runtime.CodexRunner._terminate_process_group", return_value=True), \
             patch("tools.autodev.runtime.time.sleep"):
            result = self.call("INTAKE")

        self.assertEqual(result.exit_code, 0)
        self.assertFalse(result.cancelled)
        self.assertEqual(self.store.active_leases(), [])
        self.assertEqual(self.store.running_agent_runs(), [])
        command = popen.call_args.args[0]
        child_env = popen.call_args.kwargs["env"]
        self.assertIn("--ignore-user-config", command)
        self.assertIn("--ephemeral", command)
        self.assertTrue(any(item.startswith("sqlite_home=") for item in command))
        self.assertNotIn("OPENAI_API_KEY", child_env)
        self.assertNotIn("GITHUB_TOKEN", child_env)

    def test_unverified_process_cleanup_keeps_run_and_lease_for_recovery(self):
        self.store.create_ticket(sample_ticket("LEASE-RETAIN"), "READY")
        process = FakeProcess([0])
        with patch("tools.autodev.runtime.subprocess.run", return_value=SimpleNamespace(returncode=0, stdout="codex-cli 0.159.2")), \
             patch("tools.autodev.runtime.subprocess.Popen", return_value=process), \
             patch("tools.autodev.runtime.CodexRunner._process_start_identity", return_value="start"), \
             patch("tools.autodev.runtime.CodexRunner._terminate_process_group", return_value=False), \
             patch("tools.autodev.runtime.CodexRunner._terminate_group", return_value=False):
            with self.assertRaises(RuntimeError):
                self.call("LEASE-RETAIN", role="developer")

        self.assertTrue(any(lease["kind"] == "process_group" for lease in self.store.active_leases("LEASE-RETAIN")))
        self.assertEqual(len(self.store.running_agent_runs("LEASE-RETAIN")), 1)

    def test_cli_version_gate_rejects_versions_before_validated_baseline(self):
        with patch("tools.autodev.runtime.subprocess.run", return_value=SimpleNamespace(returncode=0, stdout="codex-cli 0.159.1")):
            with self.assertRaisesRegex(RuntimeError, "0.159.2 or newer"):
                self.runner._validate_cli_version(str(self.binary))

    def test_cli_version_gate_accepts_validated_baseline(self):
        with patch("tools.autodev.runtime.subprocess.run", return_value=SimpleNamespace(returncode=0, stdout="codex-cli 0.159.2")):
            self.runner._validate_cli_version(str(self.binary))

    def test_runtime_rejects_old_cli_before_starting_agent(self):
        with patch("tools.autodev.runtime.subprocess.run", return_value=SimpleNamespace(returncode=0, stdout="codex-cli 0.159.1")), \
             patch("tools.autodev.runtime.subprocess.Popen") as popen:
            with self.assertRaisesRegex(RuntimeError, "0.159.2 or newer"):
                self.call("OLD-CLI")

        popen.assert_not_called()

    def test_orphaned_raw_output_is_sanitized_on_startup(self):
        directory = self.logs / "OLD"
        directory.mkdir(parents=True)
        raw = directory / ".run-development.raw"
        raw.write_text('{"type":"item.completed","item":{"type":"agent_message","text":"sk-proj-abcdefghijklmnopqrstuvwxyz"}}\n')
        stderr = directory / "run.stderr.log"
        stderr.write_text("authorization: Bearer token-secret-value\n")

        self.runner.sanitize_orphaned_logs()

        safe_log = directory / "run-development.jsonl"
        self.assertTrue(safe_log.is_file())
        self.assertNotIn("sk-proj-", safe_log.read_text())
        self.assertFalse(raw.exists())
        self.assertNotIn("token-secret-value", stderr.read_text())

    def test_structured_error_and_worklog_cells_are_redacted_before_audit_write(self):
        settings = {'spreadsheet_id': 'sheet', 'worklog_sheet_name': 'log'}
        source = self.root / 'synthetic.raw'
        destination = self.root / 'audit.jsonl'
        events = [{'type': 'turn.failed', 'error': {'access_token': 'synthetic-error-token'}},
                  {'type': 'item.completed', 'item': {'type': 'mcp_tool_call',
                   'status': 'completed', 'tool': 'google_drive.get_spreadsheet_range',
                   'arguments': {'spreadsheet_id': 'sheet', 'sheet_name': 'log', 'range': 'A2:G2'},
                   'result': {'structured_content': {'range': "'log'!A2:G2",
                     'values': [['password=synthetic-cell-secret'] + ['ok'] * 6]}}}}]
        source.write_text('\n'.join(json.dumps(event) for event in events))
        CodexRunner._sanitize_cli_log(source, destination, settings)
        result = destination.read_text()
        self.assertNotIn('synthetic-error-token', result)
        self.assertNotIn('synthetic-cell-secret', result)
        self.assertIn('[REDACTED]', result)


if __name__ == "__main__":
    unittest.main()
