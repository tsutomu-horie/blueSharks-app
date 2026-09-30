from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from tools.autodev.engine import ticket_from_row
from tools.autodev.state import Store


def sample_ticket(ticket_id: str, priority: str = "P1", dependencies=None):
    return {
        "id": ticket_id,
        "title": "テストTicketの状態遷移確認",
        "type": "bugfix",
        "priority": priority,
        "project": "app",
        "request": "テスト依頼",
        "goal": "Ticket DBの状態遷移が期待どおり動作することを確認する",
        "acceptance_criteria": ["READYからRUNNINGへ遷移できる"],
        "allowed_scope": ["lib/**"],
        "forbidden_scope": ["server/**"],
        "tests": ["flutter_test"],
        "test_targets": ["test/example_test.dart"],
        "dependencies": dependencies or [],
        "risk": "low",
        "max_repair_cycles": 2,
        "write_permission": True,
        "specification_source": None,
        "specification_checked_at": None,
        "current_state": {},
    }


class StoreTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.store = Store(Path(self.temp.name) / "control" / "tickets.sqlite3")

    def tearDown(self):
        self.temp.cleanup()

    def test_claim_is_deterministic_and_p0_first(self):
        self.store.create_ticket(sample_ticket("P1-ONE"), "READY")
        self.store.create_ticket(sample_ticket("P0-ONE", "P0"), "READY")
        claimed = self.store.claim_next()
        self.assertEqual(claimed["id"], "P0-ONE")
        self.assertEqual(claimed["status"], "RUNNING")

    def test_dependency_blocks_claim_until_done(self):
        self.store.create_ticket(sample_ticket("BASE"), "READY")
        self.store.create_ticket(sample_ticket("CHILD", dependencies=["BASE"]), "READY")
        self.assertEqual(self.store.claim_next()["id"], "BASE")
        self.assertIsNone(self.store.claim_next())
        self.store.transition("BASE", "READY_FOR_REVIEW", "QC_PASS")
        self.store.transition("BASE", "REVIEWING", "REVIEW_START")
        self.store.transition("BASE", "READY_TO_MERGE", "REVIEW_PASS")
        self.store.transition("BASE", "MERGED", "MERGED")
        self.store.transition("BASE", "CLEANUP", "CLEANUP")
        self.store.transition("BASE", "DONE", "DONE")
        self.assertEqual(self.store.claim_next()["id"], "CHILD")

    def test_illegal_transition_is_rejected(self):
        self.store.create_ticket(sample_ticket("ILLEGAL"), "READY")
        with self.assertRaises(ValueError):
            self.store.transition("ILLEGAL", "DONE", "skip-gates")

    def test_database_ticket_adapter_preserves_repair_limit_field(self):
        self.store.create_ticket(sample_ticket("REPAIR-LIMIT"), "READY")
        ticket = ticket_from_row(self.store.get_ticket("REPAIR-LIMIT"))
        self.assertEqual(ticket["max_repair_cycles"], 2)
        self.assertEqual(ticket["tests"], ["flutter_test"])
        self.assertNotIn("max_repairs", ticket)
        self.assertNotIn("test_ids", ticket)

    def test_done_transition_refuses_live_process_or_temporary_resource(self):
        self.store.create_ticket(sample_ticket("LIVE-AT-CLEANUP"), "CLEANUP")
        lease_id = self.store.lease("LIVE-AT-CLEANUP", "process_group", "12345")
        with self.assertRaises(ValueError):
            self.store.transition("LIVE-AT-CLEANUP", "DONE", "cleanup")
        self.assertEqual(self.store.get_ticket("LIVE-AT-CLEANUP")["status"], "CLEANUP")
        self.store.release_lease(lease_id)
        self.store.lease("LIVE-AT-CLEANUP", "temp_directory", "/workspace/tmp/LIVE-AT-CLEANUP/run")
        with self.assertRaises(ValueError):
            self.store.transition("LIVE-AT-CLEANUP", "DONE", "cleanup")

    def test_pause_flag_prevents_claim(self):
        self.store.create_ticket(sample_ticket("PAUSED"), "READY")
        self.store.request_pause()
        self.assertIsNone(self.store.claim_next())
        self.assertTrue(self.store.pause_requested())
        self.store.resume_queue()
        self.assertFalse(self.store.pause_requested())
        self.assertEqual(self.store.claim_next()["id"], "PAUSED")

    def test_active_lease_is_unique(self):
        self.store.create_ticket(sample_ticket("LEASE-1"), "READY")
        self.store.create_ticket(sample_ticket("LEASE-2"), "READY")
        lease_id = self.store.lease("LEASE-1", "repository", "/repo")
        with self.assertRaises(Exception):
            self.store.lease("LEASE-2", "repository", "/repo")
        self.store.release_lease(lease_id)
        self.assertGreater(self.store.lease("LEASE-2", "repository", "/repo"), 0)

    def test_sensitive_request_values_are_redacted_from_database_and_audit(self):
        item = sample_ticket("REDACTION")
        item["request"] = "password=hunter2 verification_code 123456"
        self.store.create_ticket(item, "READY")
        row = self.store.get_ticket("REDACTION")
        self.assertNotIn("hunter2", row["request"])
        self.assertNotIn("123456", row["request"])
        events = self.store.events_for("REDACTION")
        self.assertNotIn("hunter2", events[0]["payload_json"])


if __name__ == "__main__":
    unittest.main()
