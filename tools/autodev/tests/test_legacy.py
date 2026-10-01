from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from tools.autodev.legacy import import_markdown_directory, parse_legacy_ticket
from tools.autodev.state import Store


class LegacyImportTests(unittest.TestCase):
    def test_cancelled_legacy_ticket_is_not_reactivated(self):
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "BS-CANCEL.md"
            path.write_text("# BS-CANCEL 中止した依存更新\n- Status: `CANCELLED_NO_APP_MERGE`\n- Repository: `APP`\n")
            ticket, status = parse_legacy_ticket(path)
            self.assertEqual(status, "CANCELLED")

    def test_legacy_ticket_is_held_for_retriage(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / "BS-HIGH-1.md"
            source.write_text(
                "# BS-HIGH-1 認証不具合\n\n"
                "- Status: `BLOCKED_VERIFICATION`\n- Priority: `P1`\n- Repository: `APP`\n"
                "- Latest Specification Source: Drive 仕様書\n- Specification Checked At: `2026-09-01 JST`\n\n"
                "## ゴール\n認証状態を正しく復元する。\n\n"
                "## Acceptance Criteria\n- [ ] tokenなしでは認証しない\n"
            )
            parsed = parse_legacy_ticket(source)
            self.assertIsNotNone(parsed)
            ticket, status = parsed
            self.assertEqual(ticket["id"], "BS-HIGH-1")
            self.assertEqual(ticket["project"], "app")
            self.assertEqual(status, "BLOCKED")
            self.assertEqual(ticket["allowed_scope"], [])

            store = Store(root / "state.sqlite3")
            result = import_markdown_directory(store, root)
            self.assertEqual(result["imported"][0]["status"], "BLOCKED")
            self.assertFalse(result["execution_started"])
            self.assertEqual(store.get_ticket("BS-HIGH-1")["status"], "BLOCKED")


if __name__ == "__main__":
    unittest.main()
