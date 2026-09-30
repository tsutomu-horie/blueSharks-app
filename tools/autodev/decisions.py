from __future__ import annotations

import json
from typing import Any

from .intake import IntakeError, _scope_list, _string_list, _target_list
from .state import Store, dump


def resolve_ticket(
    store: Store,
    config: dict[str, Any],
    ticket_id: str,
    *,
    action: str,
    note: str,
    goal: str | None = None,
    criteria: list[str] | None = None,
    scopes: list[str] | None = None,
    tests: list[str] | None = None,
    targets: list[str] | None = None,
    specification_source: str | None = None,
    specification_checked_at: str | None = None,
) -> str:
    row = store.get_ticket(ticket_id)
    status = row["status"]
    if action == "cancel":
        return store.request_cancel(ticket_id, note or "human cancelled Ticket")
    if action not in {"approve", "retry"}:
        raise ValueError(f"unknown resolution action: {action}")
    if not note.strip():
        raise ValueError("a short decision note is required for audit")
    if status not in {"NEEDS_SPECIFICATION", "NEEDS_DECISION", "BLOCKED", "FAILED", "REPLAN", "TRIAGE"}:
        raise ValueError(f"Ticket in {status} cannot be manually resolved")
    if row["priority"] == "P2":
        if status != "BACKLOG":
            store.transition(ticket_id, "BACKLOG", "P2_DEFERRED", {"note": note})
        return "BACKLOG"
    if row["project"] == "both":
        raise ValueError("Phase 1 does not run multi-repository Tickets; split this request into App and Server Tickets")
    if row["pr_url"]:
        raise ValueError("Ticket already has a Pull Request; create a follow-up Ticket instead of reusing its committed branch")

    project = config["projects"][row["project"]]
    current_state = json.loads(row["current_state_json"])
    acceptance = json.loads(row["acceptance_json"])
    allowed = json.loads(row["allowed_scope_json"])
    test_ids = json.loads(row["test_ids_json"])
    test_targets = json.loads(row["test_targets_json"])
    acceptance = _string_list(acceptance + (criteria or []), "acceptance_criteria", 12)
    allowed = _scope_list(allowed + (scopes or []), "allowed_scope", allow_empty=row["type"] == "investigation")
    test_ids = _string_list(test_ids + (tests or []), "tests", 12)
    test_targets = _target_list(test_targets + (targets or []))
    if row["type"] != "investigation":
        if not str(goal or row["goal"]).strip() or not acceptance or not allowed or not test_ids:
            raise IntakeError("Ticket remains incomplete; provide a goal, acceptance criteria, allowed scope, and tests")
        unknown = sorted(set(test_ids) - set(project["checks"]))
        if unknown:
            raise IntakeError("test commands are not configured: " + ", ".join(unknown))
        roots = [str(item).strip("/") for item in project["test_target_roots"]]
        if any(not any(item == root or item.startswith(root + "/") for root in roots) for item in test_targets):
            raise IntakeError("one or more test targets are outside configured test directories")
    elif test_ids and any(item not in project["checks"] for item in test_ids):
        raise IntakeError("investigation check references an unconfigured mechanical check")

    new_source = specification_source or row["specification_source"]
    new_checked = specification_checked_at or row["specification_checked_at"]
    if (row["specification_source"] or status == "NEEDS_SPECIFICATION") and (not specification_source or not specification_checked_at):
        raise IntakeError("provide the current authoritative specification source and the time you checked it")

    store.update_ticket(
        ticket_id,
        goal=(goal or row["goal"]).strip(),
        acceptance_json=dump(acceptance),
        allowed_scope_json=dump(allowed),
        test_ids_json=dump(test_ids),
        test_targets_json=dump(test_targets),
        specification_source=new_source,
        specification_checked_at=new_checked,
        repair_count=0 if action == "retry" else int(row["repair_count"]),
        current_state_json=dump({
            **current_state,
            "intake": {**current_state.get("intake", {}), "specification_required": bool(current_state.get("intake", {}).get("specification_required") or status == "NEEDS_SPECIFICATION")},
            "human_resolution": {"action": action, "note": note.strip()},
        }),
    )
    store.add_event(ticket_id, "HUMAN_RESOLUTION_RECORDED", {"action": action, "note": note})

    if row["priority"] == "P0" or row["risk"] in {"high", "critical"}:
        target_status = "TRIAGE"
    else:
        target_status = "READY"
    if status == "NEEDS_SPECIFICATION":
        store.transition(ticket_id, "TRIAGE", "SPECIFICATION_COMPLETED", {"source": new_source, "checked_at": new_checked})
        if target_status != "TRIAGE":
            store.transition(ticket_id, "READY", "HUMAN_APPROVED_READY", {"note": note})
    elif status == "FAILED" and target_status == "READY":
        store.transition(ticket_id, "TRIAGE", "FAILED_TICKET_RETRIAGED", {"note": note})
        store.transition(ticket_id, "READY", "HUMAN_APPROVED_READY", {"note": note})
    elif status != target_status:
        store.transition(ticket_id, target_status, "HUMAN_APPROVED_READY", {"note": note})
    return target_status
