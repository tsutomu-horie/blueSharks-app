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
    if legacy_status.startswith("CANCELLED"):
        status = "CANCELLED"
    elif legacy_status.startswith("BLOCKED"):
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


def retriage_legacy(store, config, ticket_id, *, projects=None, source_evidence=None):
    """Rebuild an imported request through current Intake; keep its audit history."""
    import json
    from .intake import add_request
    from .workspace import WorkspaceIntegration
    row = store.get_ticket(ticket_id)
    current = json.loads(row["current_state_json"])
    if current.get("migration") != "legacy_markdown_import":
        raise ValueError("retriage-legacy requires an imported Ticket")
    if row["status"] in {"DONE", "CANCELLED"}:
        return current.get("replacement_ticket_ids", [])
    if current.get("legacy_status", "").startswith("CANCELLED"):
        store.request_cancel(ticket_id, "旧Ticketの人間による中止を維持する")
        return []
    if current.get("replacement_ticket_ids"):
        return current["replacement_ticket_ids"]
    targets = projects or (["app", "server"] if row["project"] == "both" else [row["project"]])
    if not targets or any(value not in config["projects"] for value in targets):
        raise ValueError("select configured App/Server child projects")
    request = row["request"] + "\n完了条件: " + row["acceptance_json"] + "\n旧確認情報（再検証が必要）: " + json.dumps(current, ensure_ascii=False)
    evidence = source_evidence or WorkspaceIntegration(store, config).verify_specification(request)
    if not evidence:
        raise ValueError("latest specification could not be verified; imported Ticket remains held")
    children = []
    for project in targets:
        # Recover a completed Intake after an interruption without another child.
        with store.connection() as db:
            previous = db.execute("SELECT id FROM tickets WHERE json_extract(current_state_json,'$.legacy_parent')=? AND project=?", (ticket_id, project)).fetchone()
        if previous:
            children.append(previous["id"])
            continue
        child = add_request(store, config, request + f"\n今回の子Ticketは{project} Repositoryだけを担当し、対向側は別子Ticketが担当します。仕様に沿って未完了の不具合修正・必要テストを行い、既存merge済み変更は再実装しない。", project=project, priority=row["priority"], source_evidence=evidence, context_metadata={"legacy_parent": ticket_id}, prerequisite_dependencies=json.loads(row['dependencies_json']), hold_for_migration=True)
        children.append(child["id"])
    store.supersede_legacy(ticket_id, children)
    return children
