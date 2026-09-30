from __future__ import annotations

import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from tools.autodev.engine import Orchestrator, ticket_from_row
from tools.autodev.state import Store


def ticket(ticket_id: str) -> dict:
    return {
        "id": ticket_id,
        "title": "Cleanup recovery",
        "type": "bugfix",
        "priority": "P1",
        "project": "app",
        "request": "recover cleanup",
        "goal": "finish cleanup after a controller restart",
        "acceptance_criteria": ["merged work is marked done after cleanup recovery"],
        "allowed_scope": ["lib/**"],
        "forbidden_scope": ["server/**"],
        "tests": ["flutter_test"],
        "test_targets": ["test/example_test.dart"],
        "dependencies": [],
        "risk": "low",
        "max_repair_cycles": 2,
        "write_permission": True,
        "specification_source": None,
        "specification_checked_at": None,
        "current_state": {},
    }


class RecoveryTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.store = Store(self.root / "control" / "tickets.sqlite3")
        self.config = {
            "workspace": {
                "root": str(self.root),
                "state_dir": str(self.root / "control"),
                "logs_dir": str(self.root / "logs"),
                "worktrees_dir": str(self.root / "worktrees"),
            },
            "codex": {"binary": "/not-used"},
            "git": {},
            "projects": {"app": {"repository": str(self.root / "repo"), "base_ref": "origin/main"}},
        }
        self.orchestrator = Orchestrator(self.store, self.config)

    def tearDown(self):
        self.temp.cleanup()

    def test_recovery_finishes_a_merge_interrupted_before_cleanup(self):
        self.store.create_ticket(ticket("MERGED-CLEANUP"), "READY")
        self.store.transition("MERGED-CLEANUP", "RUNNING", "START")
        self.store.transition("MERGED-CLEANUP", "READY_FOR_REVIEW", "QC")
        self.store.transition("MERGED-CLEANUP", "REVIEWING", "REVIEW")
        self.store.transition("MERGED-CLEANUP", "READY_TO_MERGE", "PASS")
        self.store.transition("MERGED-CLEANUP", "MERGED", "MERGED")

        recovered = self.orchestrator.recover_orphaned_work()

        self.assertIn("MERGED-CLEANUP", recovered)
        self.assertEqual(self.store.get_ticket("MERGED-CLEANUP")["status"], "DONE")
        self.assertEqual(self.store.active_leases("MERGED-CLEANUP"), [])

    def test_recovery_keeps_repository_lease_if_process_identity_is_unverified(self):
        self.store.create_ticket(ticket("ORPHAN"), "RUNNING")
        self.store.lease("ORPHAN", "repository", "app")
        process_lease = self.store.lease("ORPHAN", "process_group", "12345", {"pid": 12345, "pid_start": "expected-start"})
        self.store.create_run({
            "id": "orphan-run", "ticket_id": "ORPHAN", "role": "developer", "model": "gpt-6-sol",
            "reasoning": "low", "phase": "development", "log_path": "run.log", "output_path": "run.json",
            "pid": 12345, "pid_start": "expected-start",
        })

        with patch("tools.autodev.engine.process_start_identity", return_value="different-process"), \
             patch("tools.autodev.runtime.CodexRunner._process_group_exists", return_value=True):
            self.orchestrator.recover_orphaned_work()

        self.assertEqual(self.store.get_ticket("ORPHAN")["status"], "BLOCKED")
        leases = self.store.active_leases("ORPHAN")
        self.assertTrue(any(item["kind"] == "repository" for item in leases))
        self.assertTrue(any(item["id"] == process_lease and item["kind"] == "process_group" for item in leases))
        self.assertEqual(len(self.store.running_agent_runs("ORPHAN")), 1)

    def test_android_build_without_offline_cache_is_blocked_before_worktree_or_agent_start(self):
        item = ticket("ANDROID-CACHE")
        item["tests"] = ["android_debug_build"]
        self.store.create_ticket(item, "READY")

        claimed = self.store.claim_next()
        self.assertEqual(claimed["id"], "ANDROID-CACHE")
        self.orchestrator._execute(ticket_from_row(claimed))

        stored = self.store.get_ticket("ANDROID-CACHE")
        self.assertEqual(stored["status"], "BLOCKED")
        self.assertIsNone(stored["worktree"])
        self.assertEqual(self.store.running_agent_runs("ANDROID-CACHE"), [])
        self.assertEqual(self.store.active_leases("ANDROID-CACHE"), [])

    def test_required_specification_gate_releases_claimed_repository_lease(self):
        item = ticket("NEEDS-DRIVE-SPEC")
        item["current_state"] = {"intake": {"specification_required": True}}
        self.store.create_ticket(item, "READY")
        claimed = self.store.claim_next()

        self.orchestrator._execute(ticket_from_row(claimed))

        self.assertEqual(self.store.get_ticket("NEEDS-DRIVE-SPEC")["status"], "NEEDS_SPECIFICATION")
        self.assertEqual(self.store.active_leases("NEEDS-DRIVE-SPEC"), [])


if __name__ == "__main__":
    unittest.main()
