from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from tools.autodev.decisions import resolve_ticket
from tools.autodev.state import Store


def ticket(ticket_id, *, status="NEEDS_SPECIFICATION", priority="P1", project="app"):
    return {
        "id": ticket_id, "title": "仕様確認後のTicket", "type": "bugfix", "priority": priority,
        "project": project, "request": "依頼", "goal": "仕様確認後に受け入れ条件を満たす修正を実施する",
        "acceptance_criteria": [], "allowed_scope": [], "forbidden_scope": ["server/**"],
        "tests": [], "test_targets": [], "dependencies": [], "risk": "low",
        "max_repair_cycles": 2, "write_permission": True,
        "specification_source": None, "specification_checked_at": None,
        "current_state": {},
    }


class DecisionTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.store = Store(self.root / "state.sqlite3")
        self.config = {"projects": {"app": {"checks": {"flutter_test": ["flutter", "test", "{target}"]}, "test_target_roots": ["test"]}}}

    def tearDown(self):
        self.temp.cleanup()

    def test_human_resolution_requires_spec_scope_and_test(self):
        self.store.create_ticket(ticket("NEEDS"), "NEEDS_SPECIFICATION")
        with self.assertRaises(Exception):
            resolve_ticket(self.store, self.config, "NEEDS", action="approve", note="確認")
        status = resolve_ticket(
            self.store, self.config, "NEEDS", action="approve", note="Drive正本を確認",
            goal="仕様の復帰条件を満たす", criteria=["復帰時に値が保持される"],
            scopes=["lib/feature/**"], tests=["flutter_test"], targets=["test/feature/restore_test.dart"],
            specification_source="ICC開発案件/育成ゲーム仕様", specification_checked_at="2026-09-30 10:00 JST",
        )
        self.assertEqual(status, "READY")
        self.assertEqual(self.store.get_ticket("NEEDS")["status"], "READY")

    def test_multi_repository_ticket_cannot_be_auto_resolved_in_phase_one(self):
        self.store.create_ticket(ticket("BOTH", status="NEEDS_DECISION", project="both"), "NEEDS_DECISION")
        with self.assertRaises(ValueError):
            resolve_ticket(self.store, self.config, "BOTH", action="approve", note="approve")

    def test_p2_resolution_keeps_ticket_in_backlog(self):
        self.store.create_ticket(ticket("P2", status="NEEDS_DECISION", priority="P2"), "NEEDS_DECISION")
        status = resolve_ticket(self.store, self.config, "P2", action="approve", note="backlog")
        self.assertEqual(status, "BACKLOG")


if __name__ == "__main__":
    unittest.main()
