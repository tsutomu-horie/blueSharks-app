from __future__ import annotations

import unittest

from tools.autodev.redaction import redact_text, redact_value


class RedactionTests(unittest.TestCase):
    def test_common_credential_values_are_redacted(self):
        value = "password=hunter2 otp 123456 Authorization: Bearer abc.def.ghi member_id=member-123 会員ID C-00991"
        redacted = redact_text(value)
        self.assertNotIn("hunter2", redacted)
        self.assertNotIn("123456", redacted)
        self.assertNotIn("abc.def.ghi", redacted)
        self.assertNotIn("member-123", redacted)
        self.assertNotIn("C-00991", redacted)

    def test_sensitive_json_fields_are_redacted(self):
        redacted = redact_value({"access_token": "abc", "masked_member_id": "1234", "status": "ok"})
        self.assertEqual(redacted["access_token"], "[REDACTED]")
        self.assertEqual(redacted["masked_member_id"], "[REDACTED]")
        self.assertEqual(redacted["status"], "ok")


if __name__ == "__main__":
    unittest.main()
