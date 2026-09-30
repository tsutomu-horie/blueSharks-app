from __future__ import annotations

import re
from pathlib import Path
from typing import Any

from .state import Store


H1 = re.compile(r"^#\s+([A-Z0-9][A-Z0-9-]*)\s+(.+?)\s*$", re.M)
META = re.compile(r"^-\s*([^:]+):\s*`?([^`\n]+?)`?\s*$", re.M)


def _section(text: str, heading: str) -> str:
    match = re.search(rf"^##\s+{re.escape(heading)}\s*$\n(.*?)(?=^##\s+|\Z)", text, re.M | re.S | re.I)
    return match.group(1).strip() if match else ""


def _bullets(section: str) -> list[str]:
    items = []
    for line in section.splitlines():
        match = re.match(r"^\s*-\s+(?:\[[ xX]\]\s*)?(.+?)\s*$", line)
        if match:
            item = match.group(1).strip()
            if item and item not in {"なし", "N/A"}:
                items.append(item)
    return items


def parse_legacy_ticket(path: Path) -> tuple[dict[str, Any], str] | None:
    text = path.read_text(errors="replace")
    heading = H1.search(text)
    if not heading:
        return None
    ticket_id, title = heading.group(1), heading.group(2).strip()
    meta = {key.strip().lower(): value.strip() for key, value in META.findall(text)}
    legacy_status = meta.get("status", "UNKNOWN").upper()
    priority = meta.get("priority", "P1").upper()
    if priority not in {"P0", "P1", "P2"}:
        priority = "P1"
    repository = meta.get("repository", "UNKNOWN").upper()
    project = {"APP": "app", "SERVER": "server", "BOTH": "both"}.get(repository, "both")
    category = meta.get("category", "").upper()
    ticket_type = "investigation" if "INVESTIGATION" in category else ("bugfix" if "BUG" in category or "REMEDIATION" in category else "feature")
    goal_text = _section(text, "ゴール") or _section(text, "目的")
    goal = " ".join(goal_text.split()) or f"既存Ticketを実行前に再整理する: {title}"
    criteria = _bullets(_section(text, "Acceptance Criteria"))
    tests = _bullets(_section(text, "テスト方法"))
    worktree_match = re.search(r"^-\s*Worktree:\s*`([^`]+)`", text, re.M)
    branch_match = re.search(r"^-\s*Branch:\s*`([^`]+)`", text, re.M)
    source = meta.get("latest specification source")
    spec_time = meta.get("specification checked at")
    original_scope = _bullets(_section(text, "対象"))
    forbidden_scope = _bullets(_section(text, "対象外"))
    current_state = {
        "migration": "legacy_markdown_import",
        "source_file": str(path.resolve()),
        "legacy_status": legacy_status,
        "legacy_repository": repository,
        "legacy_scope_notes": original_scope,
        "legacy_test_notes": tests,
        "legacy_worktree": worktree_match.group(1) if worktree_match else None,
        "legacy_branch": branch_match.group(1) if branch_match else None,
        "specification_source": source,
        "specification_checked_at": spec_time,
    }
    # Legacy prose scopes are not safe executable path globs; require current Ticket Intake/review.
    needs_specification = not criteria or not source or not spec_time
    if legacy_status.startswith("BLOCKED"):
        status = "BLOCKED"
    elif "DONE" in legacy_status or "MERGED" in legacy_status:
        status = "DONE"
    elif needs_specification:
        status = "NEEDS_SPECIFICATION"
    elif project == "both" or "IN_PROGRESS" in legacy_status or "COMMIT" in legacy_status:
        status = "NEEDS_DECISION"
    else:
        status = "TRIAGE"
    ticket = {
        "id": ticket_id,
        "title": title,
        "type": ticket_type,
        "priority": priority,
        "project": project,
        "request": goal_text or text[:12000],
        "goal": goal,
        "acceptance_criteria": criteria,
        "allowed_scope": [],
        "forbidden_scope": [],
        "tests": [],
        "test_targets": [],
        "dependencies": [],
        "risk": "medium",
        "max_repair_cycles": 2,
        "write_permission": ticket_type != "investigation",
        "specification_source": source,
        "specification_checked_at": spec_time,
        "current_state": current_state,
    }
    return ticket, status


def import_markdown_directory(store: Store, directory: Path, include_done: bool = False) -> dict[str, Any]:
    directory = directory.expanduser().resolve(strict=True)
    imported: list[dict[str, str]] = []
    skipped: list[dict[str, str]] = []
    for path in sorted(directory.glob("*.md")):
        parsed = parse_legacy_ticket(path)
        if parsed is None:
            skipped.append({"file": str(path), "reason": "no Ticket ID heading"})
            continue
        ticket, status = parsed
        if status == "DONE" and not include_done:
            skipped.append({"ticket": ticket["id"], "reason": "already completed"})
            continue
        if store.ticket_exists(ticket["id"]):
            skipped.append({"ticket": ticket["id"], "reason": "already in DB"})
            continue
        store.create_ticket(ticket, status)
        store.add_event(ticket["id"], "LEGACY_TICKET_IMPORTED", {"source_file": str(path), "execution_held": True})
        imported.append({"ticket": ticket["id"], "status": status})
    return {"imported": imported, "skipped": skipped, "execution_started": False}
