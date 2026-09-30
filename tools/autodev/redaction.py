from __future__ import annotations

import re
from typing import Any


_REDACTIONS = (
    (re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----[\s\S]*?-----END (?:RSA |EC |OPENSSH )?PRIVATE KEY-----"), "[REDACTED_PRIVATE_KEY]"),
    (re.compile(r"\bgh[pousr]_[A-Za-z0-9]{30,}\b"), "[REDACTED_TOKEN]"),
    (re.compile(r"\bAIza[0-9A-Za-z_-]{30,}\b"), "[REDACTED_API_KEY]"),
    (re.compile(r"\bsk-(?:proj-)?[A-Za-z0-9_-]{24,}\b"), "[REDACTED_API_KEY]"),
    (re.compile(r"(?i)(authorization\s*[:=]\s*bearer\s+)\S+"), r"\1[REDACTED]"),
    (re.compile(r"(?i)\b(password|passwd|access_token|refresh_token|client_secret|api_key|secret_key)\b(\s*[:=]\s*)([^\s,;]+)"), r"\1\2[REDACTED]"),
    (re.compile(r"(?i)\b(otp|verification[_ -]?code|one[_ -]?time[_ -]?password)\b(\s*[:=]?\s*)\d{4,8}\b"), r"\1\2[REDACTED]"),
    (re.compile(r"(?i)\b(account_id|member_id|customer_id|user_id)\b(\s*[:=]\s*)([^\s,;]+)"), r"\1\2[REDACTED]"),
    (re.compile(r"会員ID(\s*[:：=]?\s*)\S+"), r"会員ID\1[REDACTED]"),
)
_SENSITIVE_KEY = re.compile(r"(^|_)(access_?token|refresh_?token|password|passwd|otp|secret|api_?key|authorization|account_id|member_id)(_|$)", re.I)


def redact_text(text: str) -> str:
    for pattern, replacement in _REDACTIONS:
        text = pattern.sub(replacement, text)
    return text


def redact_value(value: Any) -> Any:
    if isinstance(value, dict):
        return {
            key: "[REDACTED]" if _SENSITIVE_KEY.search(str(key)) else redact_value(item)
            for key, item in value.items()
        }
    if isinstance(value, list):
        return [redact_value(item) for item in value]
    if isinstance(value, str):
        return redact_text(value)
    return value
