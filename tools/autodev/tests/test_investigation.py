from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace

from tools.autodev.engine import Orchestrator
from tools.autodev.state import Store


def investigation_ticket(ticket_id: str) -> dict:
    return {
        "id": ticket_id,
        "title": "管理画面の仕様差分を調査する",
        "type": "investigation",
        "priority": "P0",
        "project": "server",
        "request": "仕様確認担当が最新仕様と現行実装を照合する",
        "goal": "仕様上の差分を根拠付きで特定しTicket案を作成する",
        "acceptance_criteria": ["調査結果とTicket案を独立レビューする"],
        "allowed_scope": ["docs/**"],
        "forbidden_scope": [],
        "tests": [],
        "test_targets": [],
        "dependencies": [],
        "risk": "low",
        "max_repair_cycles": 2,
        "write_permission": False,
        "specification_source": None,
        "specification_checked_at": None,
        "current_state": {},
        "worktree": None,
        "base_commit": "base-sha",
    }


def candidate(*, ticket_type="investigation", title="監査方針を確認する") -> dict:
    return {
        "title": title,
        "type": ticket_type,
        "project": "server",
        "priority": "P0",
        "goal": "最新仕様と現行実装の差分を調査し、根拠付きで報告する",
        "acceptance_criteria": ["確認した出典と未確定事項を明示する"],
        "allowed_scope": ["docs/**"],
        "forbidden_scope": [],
        "tests": [],
        "test_targets": [],
        "dependencies": [],
        "risk": "low",
        "max_repair_cycles": 2,
        "write_permission": False,
        "needs_specification": True,
        "specification_required": True,
        "clarifying_questions": ["仕様が資料で確定できない場合は質問として残す。"],
        "specification_source": "Driveの最新仕様を調査対象とする",
        "specification_checked_at": "2026-10-06T12:20:00+09:00",
    }


class InvestigationProposalTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.repo = self.root / "repo"
        self.repo.mkdir()
        self.store = Store(self.root / "control" / "tickets.sqlite3")
        self.config = {
            "workspace": {
                "root": str(self.root),
                "state_dir": str(self.root / "control"),
                "logs_dir": str(self.root / "logs"),
                "artifacts_dir": str(self.root / "artifacts"),
                "worktrees_dir": str(self.root / "worktrees"),
            },
            "codex": {"developer_model": "gpt-6.1-sol", "developer_reasoning": "low"},
            "git": {},
            "projects": {
                "server": {
                    "repository": str(self.repo),
                    "source_directory": "bluesharks-develop",
                    "base_ref": "origin/main",
                    "checks": {"php_lint": ["php", "-l", "{target}"]},
                    "test_target_roots": ["tests"],
                },
            },
        }
        self.engine = Orchestrator(self.store, self.config)
        self.ticket = investigation_ticket("INVESTIGATION-1")
        self.store.create_ticket(self.ticket, "RUNNING")

    def tearDown(self):
        self.temporary.cleanup()

    def run_investigation(self, proposed, *, needs_decision=False, scope_changes=None):
        report = {
            "summary": "仕様差分を確認し、候補を作成した。",
            "current_state": {"last_action": "Drive資料と実装を照合した。", "external_action_request": None},
            "scope_change_requests": scope_changes or [],
            "p2_candidates": [],
            "ticket_candidates": proposed,
            "needs_decision": needs_decision,
        }
        output = self.root / "agent-output.json"
        output.write_text(json.dumps(report, ensure_ascii=False))
        fake_result = SimpleNamespace(
            exit_code=0,
            output_path=output,
            log_path=self.root / "agent.jsonl",
            text=lambda: json.dumps(report, ensure_ascii=False),
        )
        self.engine._agent = lambda *args, **kwargs: fake_result
        self.engine.git.changed_files = lambda *args, **kwargs: []
        reviewed = {}

        def review(ticket, worktree, qc, developer):
            reviewed["summary"] = developer["summary"]
            return SimpleNamespace(
                exit_code=0,
                output_path=self.root / "review.json",
                text=lambda: json.dumps({"verdict": "PASS", "findings": [], "summary": "候補Ticketを確認した。"}, ensure_ascii=False),
            )

        self.engine._review = review
        return self.engine._investigate_only(self.ticket, self.repo), reviewed

    def test_intake_valid_candidates_are_preserved_for_independent_review(self):
        accepted, reviewed = self.run_investigation([candidate()])

        self.assertTrue(accepted)
        self.assertIn('"ticket_candidates"', reviewed["summary"])
        self.assertEqual(self.store.get_ticket("INVESTIGATION-1")["status"], "CLEANUP")
        events = self.store.events_for("INVESTIGATION-1")
        validated = [item for item in events if item["event_type"] == "INVESTIGATION_TICKET_CANDIDATES_VALIDATED"]
        self.assertEqual(len(validated), 1)
        payload = json.loads(validated[0]["payload_json"])
        self.assertEqual(payload["count"], 1)
        self.assertEqual(payload["candidates"][0]["initial_status"], "NEEDS_SPECIFICATION")

    def test_unsupported_question_type_keeps_investigation_held(self):
        accepted, _ = self.run_investigation([candidate(ticket_type="question")])

        self.assertFalse(accepted)
        self.assertEqual(self.store.get_ticket("INVESTIGATION-1")["status"], "NEEDS_DECISION")
        events = self.store.events_for("INVESTIGATION-1")
        invalid = [item for item in events if item["event_type"] == "INVESTIGATION_TICKET_PROPOSAL_INVALID"]
        self.assertEqual(len(invalid), 1)
        self.assertFalse(any(item["event_type"] == "INVESTIGATION_REPORT_READY" for item in events))

    def test_spec_required_candidate_cannot_claim_unverified_source_time(self):
        proposal = candidate()
        proposal["needs_specification"] = False

        accepted, _ = self.run_investigation([proposal])

        self.assertFalse(accepted)
        self.assertEqual(self.store.get_ticket("INVESTIGATION-1")["status"], "NEEDS_DECISION")
        invalid = [item for item in self.store.events_for("INVESTIGATION-1")
                   if item["event_type"] == "INVESTIGATION_TICKET_PROPOSAL_INVALID"]
        self.assertEqual(len(invalid), 1)
        finding = json.loads(invalid[0]["payload_json"])["findings"][0]
        self.assertIn("separate specification-gate verification", finding["reason"])

    def test_candidate_cannot_disable_both_specification_flags(self):
        proposal = candidate()
        proposal["specification_required"] = False
        proposal["needs_specification"] = False

        accepted, _ = self.run_investigation([proposal])

        self.assertFalse(accepted)
        self.assertEqual(self.store.get_ticket("INVESTIGATION-1")["status"], "NEEDS_DECISION")

    def test_unresolved_human_decision_prevents_investigation_acceptance(self):
        accepted, _ = self.run_investigation([candidate()], needs_decision=True)

        self.assertFalse(accepted)
        self.assertEqual(self.store.get_ticket("INVESTIGATION-1")["status"], "NEEDS_DECISION")
        self.assertFalse(any(item["event_type"] == "INVESTIGATION_REVIEW_STARTED"
                             for item in self.store.events_for("INVESTIGATION-1")))

    def test_scope_change_request_prevents_investigation_acceptance(self):
        accepted, _ = self.run_investigation([candidate()], scope_changes=["resources/views/**"])

        self.assertFalse(accepted)
        self.assertEqual(self.store.get_ticket("INVESTIGATION-1")["status"], "NEEDS_DECISION")
        self.assertFalse(any(item["event_type"] == "INVESTIGATION_REVIEW_STARTED"
                             for item in self.store.events_for("INVESTIGATION-1")))


if __name__ == "__main__":
    unittest.main()
