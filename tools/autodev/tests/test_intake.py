from __future__ import annotations

import unittest

from tools.autodev.intake import IntakeError, validate_payload


def config():
    return {"projects": {"app": {"checks": {"flutter_test": ["flutter", "test", "{target}"]}, "test_target_roots": ["test"]}}}


def payload(**changes):
    result = {
        "title": "食事パラメータ復元を修正する",
        "type": "bugfix",
        "project": "app",
        "priority": "P1",
        "goal": "バックグラウンド復帰時に食事値が保持されること",
        "acceptance_criteria": ["復帰後の値が正しい", "既存の減少処理が維持される"],
        "allowed_scope": ["lib/presentation/training_game/**", "test/training_game/**"],
        "forbidden_scope": ["server/**", "lib/app/services/auth_token.dart"],
        "tests": ["flutter_test"],
        "test_targets": ["test/training_game/restore_test.dart"],
        "dependencies": [],
        "risk": "medium",
        "max_repair_cycles": 2,
        "write_permission": True,
        "needs_specification": False,
        "specification_required": False,
        "clarifying_questions": [],
        "specification_source": None,
        "specification_checked_at": None,
    }
    result.update(changes)
    return result


class IntakeTests(unittest.TestCase):
    def test_ready_p1_ticket_gets_required_fields(self):
        item = validate_payload(payload(), "依頼", config())
        self.assertEqual(item["initial_status"], "READY")
        self.assertTrue(item["id"].startswith("BS-"))

    def test_ambiguous_request_stays_needs_specification(self):
        item = validate_payload(payload(needs_specification=True, acceptance_criteria=[], allowed_scope=[]), "依頼", config())
        self.assertEqual(item["initial_status"], "NEEDS_SPECIFICATION")

    def test_scope_traversal_is_rejected(self):
        with self.assertRaises(IntakeError):
            validate_payload(payload(allowed_scope=["../../server/**"]), "依頼", config())

    def test_test_target_traversal_is_rejected(self):
        with self.assertRaises(IntakeError):
            validate_payload(payload(test_targets=["../secret.txt"]), "依頼", config())

    def test_investigation_is_read_only(self):
        item = validate_payload(payload(type="investigation", write_permission=True), "調査", config(), force_investigation=True)
        self.assertEqual(item["type"], "investigation")
        self.assertFalse(item["write_permission"])

    def test_both_repository_ticket_needs_supervisor(self):
        item = validate_payload(payload(project="both"), "依頼", config())
        self.assertEqual(item["initial_status"], "NEEDS_DECISION")

    def test_required_spec_without_verified_source_is_held(self):
        item = validate_payload(payload(specification_required=True), "依頼", config())
        self.assertEqual(item["initial_status"], "NEEDS_SPECIFICATION")
        self.assertIn("ICC開発案件", item["current_state"]["clarifying_questions"][0])

    def test_required_spec_with_source_and_check_time_can_be_triaged(self):
        item = validate_payload(payload(
            specification_required=True,
            specification_source="ICC開発案件/育成ゲーム仕様書",
            specification_checked_at="2026-09-30 10:00 JST",
        ), "依頼", config())
        self.assertEqual(item["initial_status"], "READY")


if __name__ == "__main__":
    unittest.main()
