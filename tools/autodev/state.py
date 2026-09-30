from __future__ import annotations

from contextlib import contextmanager
from datetime import datetime, timezone
import json
from pathlib import Path
import sqlite3
from typing import Any, Iterator
from urllib.parse import quote

from .redaction import redact_text, redact_value


STATUSES = {
    "NEW",
    "TRIAGE",
    "READY",
    "RUNNING",
    "READY_FOR_REVIEW",
    "REVIEWING",
    "REPAIR",
    "READY_TO_MERGE",
    "MERGED",
    "CLEANUP",
    "DONE",
    "NEEDS_SPECIFICATION",
    "BLOCKED",
    "NEEDS_DECISION",
    "REPLAN",
    "FAILED",
    "CANCELLED",
    "BACKLOG",
    "PAUSED",
}

TRANSITIONS = {
    "NEW": {"TRIAGE", "NEEDS_SPECIFICATION", "CANCELLED"},
    "TRIAGE": {"READY", "NEEDS_SPECIFICATION", "NEEDS_DECISION", "BACKLOG", "BLOCKED", "CANCELLED"},
    "READY": {"RUNNING", "CANCELLED", "BLOCKED", "NEEDS_DECISION"},
    "RUNNING": {"READY_FOR_REVIEW", "REPAIR", "BLOCKED", "NEEDS_DECISION", "NEEDS_SPECIFICATION", "FAILED", "CANCELLED", "PAUSED"},
    "READY_FOR_REVIEW": {"REVIEWING", "CANCELLED", "BLOCKED", "PAUSED"},
    "REVIEWING": {"READY_TO_MERGE", "REPAIR", "CLEANUP", "BLOCKED", "NEEDS_DECISION", "FAILED", "CANCELLED", "PAUSED"},
    "REPAIR": {"RUNNING", "REPLAN", "BLOCKED", "NEEDS_DECISION", "FAILED", "CANCELLED", "PAUSED"},
    "READY_TO_MERGE": {"MERGED", "BLOCKED", "FAILED", "CANCELLED", "NEEDS_DECISION"},
    "MERGED": {"CLEANUP"},
    "CLEANUP": {"DONE", "BLOCKED", "FAILED"},
    "REPLAN": {"TRIAGE", "READY", "NEEDS_SPECIFICATION", "NEEDS_DECISION", "FAILED", "BACKLOG", "CANCELLED"},
    "NEEDS_SPECIFICATION": {"TRIAGE", "BACKLOG", "CANCELLED"},
    "NEEDS_DECISION": {"TRIAGE", "READY", "REPAIR", "BLOCKED", "BACKLOG", "CANCELLED"},
    "BLOCKED": {"TRIAGE", "READY", "BACKLOG", "CANCELLED"},
    "FAILED": {"TRIAGE", "BACKLOG", "CANCELLED"},
    "BACKLOG": {"TRIAGE", "CANCELLED"},
    "PAUSED": {"READY", "CANCELLED"},
    "DONE": set(),
    "CANCELLED": set(),
}


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def dump(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False, sort_keys=True)


class Store:
    """SQLite-backed ticket state. Every state transition is audited."""

    def __init__(self, path: Path, *, initialize: bool = True, readonly: bool = False):
        self.path = path.expanduser().resolve()
        self.readonly = readonly
        if initialize and readonly:
            raise ValueError("read-only Store cannot initialize a database")
        if initialize:
            self.path.parent.mkdir(parents=True, exist_ok=True)
            self.initialize()

    def connect(self) -> sqlite3.Connection:
        if self.readonly:
            uri = f"file:{quote(self.path.as_posix(), safe='/')}?mode=ro"
            db = sqlite3.connect(uri, timeout=30, isolation_level=None, uri=True)
        else:
            db = sqlite3.connect(self.path, timeout=30, isolation_level=None)
        db.row_factory = sqlite3.Row
        db.execute("PRAGMA foreign_keys=ON")
        db.execute("PRAGMA busy_timeout=30000")
        return db

    @contextmanager
    def connection(self) -> Iterator[sqlite3.Connection]:
        db = self.connect()
        try:
            yield db
        finally:
            db.close()

    def initialize(self) -> None:
        if self.readonly:
            raise ValueError("read-only Store cannot initialize")
        with self.connection() as db:
            db.execute("PRAGMA journal_mode=WAL")
            db.executescript(
                """
                CREATE TABLE IF NOT EXISTS tickets (
                    id TEXT PRIMARY KEY,
                    title TEXT NOT NULL,
                    type TEXT NOT NULL,
                    priority TEXT NOT NULL CHECK(priority IN ('P0','P1','P2')),
                    project TEXT NOT NULL,
                    status TEXT NOT NULL,
                    request TEXT NOT NULL,
                    goal TEXT NOT NULL,
                    acceptance_json TEXT NOT NULL,
                    allowed_scope_json TEXT NOT NULL,
                    forbidden_scope_json TEXT NOT NULL,
                    test_ids_json TEXT NOT NULL,
                    test_targets_json TEXT NOT NULL,
                    dependencies_json TEXT NOT NULL,
                    risk TEXT NOT NULL,
                    max_repairs INTEGER NOT NULL CHECK(max_repairs BETWEEN 0 AND 2),
                    repair_count INTEGER NOT NULL DEFAULT 0,
                    write_permission INTEGER NOT NULL DEFAULT 1,
                    specification_source TEXT,
                    specification_checked_at TEXT,
                    current_state_json TEXT NOT NULL DEFAULT '{}',
                    worktree TEXT,
                    branch TEXT,
                    base_commit TEXT,
                    pr_url TEXT,
                    cancel_requested INTEGER NOT NULL DEFAULT 0,
                    created_at TEXT NOT NULL,
                    updated_at TEXT NOT NULL
                );
                CREATE INDEX IF NOT EXISTS tickets_queue_idx
                    ON tickets(status, priority, created_at);
                CREATE TABLE IF NOT EXISTS ticket_events (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    ticket_id TEXT NOT NULL REFERENCES tickets(id),
                    event_type TEXT NOT NULL,
                    from_status TEXT,
                    to_status TEXT,
                    payload_json TEXT NOT NULL,
                    created_at TEXT NOT NULL
                );
                CREATE INDEX IF NOT EXISTS ticket_events_ticket_idx
                    ON ticket_events(ticket_id, id);
                CREATE TABLE IF NOT EXISTS agent_runs (
                    id TEXT PRIMARY KEY,
                    ticket_id TEXT NOT NULL,
                    role TEXT NOT NULL,
                    model TEXT NOT NULL,
                    reasoning TEXT NOT NULL,
                    phase TEXT NOT NULL,
                    state TEXT NOT NULL,
                    pid INTEGER,
                    pid_start TEXT,
                    log_path TEXT NOT NULL,
                    output_path TEXT NOT NULL,
                    started_at TEXT NOT NULL,
                    finished_at TEXT,
                    exit_code INTEGER,
                    result_json TEXT NOT NULL DEFAULT '{}'
                );
                CREATE TABLE IF NOT EXISTS resource_leases (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    ticket_id TEXT NOT NULL REFERENCES tickets(id),
                    kind TEXT NOT NULL,
                    resource_key TEXT NOT NULL,
                    details_json TEXT NOT NULL,
                    acquired_at TEXT NOT NULL,
                    released_at TEXT
                );
                CREATE UNIQUE INDEX IF NOT EXISTS resource_lease_active_idx
                    ON resource_leases(kind, resource_key) WHERE released_at IS NULL;
                CREATE TABLE IF NOT EXISTS artifacts (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    ticket_id TEXT NOT NULL REFERENCES tickets(id),
                    kind TEXT NOT NULL,
                    path TEXT NOT NULL,
                    created_at TEXT NOT NULL
                );
                CREATE TABLE IF NOT EXISTS control_flags (
                    id INTEGER PRIMARY KEY CHECK(id=1),
                    pause_requested INTEGER NOT NULL DEFAULT 0,
                    reason TEXT NOT NULL DEFAULT '',
                    updated_at TEXT NOT NULL
                );
                INSERT OR IGNORE INTO control_flags(id,pause_requested,reason,updated_at)
                    VALUES(1,0,'',CURRENT_TIMESTAMP);
                """
            )
            columns = {row["name"] for row in db.execute("PRAGMA table_info(tickets)")}
            if "specification_checked_at" not in columns:
                db.execute("ALTER TABLE tickets ADD COLUMN specification_checked_at TEXT")
            if "base_commit" not in columns:
                db.execute("ALTER TABLE tickets ADD COLUMN base_commit TEXT")
            run_columns = {row["name"] for row in db.execute("PRAGMA table_info(agent_runs)")}
            if "pid_start" not in run_columns:
                db.execute("ALTER TABLE agent_runs ADD COLUMN pid_start TEXT")

    @contextmanager
    def transaction(self) -> Iterator[sqlite3.Connection]:
        if self.readonly:
            raise ValueError("read-only Store cannot open a transaction")
        db = self.connect()
        try:
            db.execute("BEGIN IMMEDIATE")
            yield db
            db.commit()
        except Exception:
            db.rollback()
            raise
        finally:
            db.close()

    def create_ticket(self, ticket: dict[str, Any], status: str) -> None:
        if status not in STATUSES:
            raise ValueError(f"unknown status: {status}")
        stamp = now()
        safe_ticket = redact_value(ticket)
        with self.transaction() as db:
            db.execute(
                """INSERT INTO tickets(
                    id,title,type,priority,project,status,request,goal,
                    acceptance_json,allowed_scope_json,forbidden_scope_json,
                    test_ids_json,test_targets_json,dependencies_json,risk,
                    max_repairs,write_permission,specification_source,specification_checked_at,
                    current_state_json,created_at,updated_at
                ) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)""",
                (
                    safe_ticket["id"], safe_ticket["title"], safe_ticket["type"], safe_ticket["priority"],
                    safe_ticket["project"], status, safe_ticket["request"], safe_ticket["goal"],
                    dump(safe_ticket["acceptance_criteria"]), dump(safe_ticket["allowed_scope"]),
                    dump(safe_ticket["forbidden_scope"]), dump(safe_ticket["tests"]),
                    dump(safe_ticket["test_targets"]), dump(safe_ticket["dependencies"]),
                    safe_ticket["risk"], safe_ticket["max_repair_cycles"],
                    int(safe_ticket["write_permission"]), safe_ticket.get("specification_source"), safe_ticket.get("specification_checked_at"),
                    dump(safe_ticket.get("current_state", {})), stamp, stamp,
                ),
            )
            self._event(db, ticket["id"], "TICKET_CREATED", None, status, {"id": ticket["id"], "title": safe_ticket["title"], "project": ticket["project"], "priority": ticket["priority"], "type": ticket["type"]})

    def _event(
        self,
        db: sqlite3.Connection,
        ticket_id: str,
        event_type: str,
        from_status: str | None,
        to_status: str | None,
        payload: dict[str, Any] | None = None,
    ) -> None:
        db.execute(
            "INSERT INTO ticket_events(ticket_id,event_type,from_status,to_status,payload_json,created_at) VALUES(?,?,?,?,?,?)",
            (ticket_id, event_type, from_status, to_status, dump(redact_value(payload or {})), now()),
        )

    def transition(self, ticket_id: str, new_status: str, event: str, payload: dict[str, Any] | None = None) -> None:
        if new_status not in STATUSES:
            raise ValueError(f"unknown status: {new_status}")
        with self.transaction() as db:
            row = db.execute("SELECT status FROM tickets WHERE id=?", (ticket_id,)).fetchone()
            if row is None:
                raise KeyError(ticket_id)
            old = row["status"]
            if new_status != old and new_status not in TRANSITIONS.get(old, set()):
                raise ValueError(f"illegal ticket transition {old} -> {new_status}")
            if new_status == "DONE":
                active_process = db.execute(
                    "SELECT 1 FROM resource_leases WHERE ticket_id=? AND released_at IS NULL AND kind IN ('process_group','temp_directory') LIMIT 1",
                    (ticket_id,),
                ).fetchone()
                active_run = db.execute(
                    "SELECT 1 FROM agent_runs WHERE ticket_id=? AND state='RUNNING' LIMIT 1",
                    (ticket_id,),
                ).fetchone()
                if active_process or active_run:
                    raise ValueError("cannot mark Ticket DONE while an Agent process or temporary resource remains active")
            db.execute("UPDATE tickets SET status=?,updated_at=? WHERE id=?", (new_status, now(), ticket_id))
            if new_status == "DONE":
                db.execute("UPDATE resource_leases SET released_at=? WHERE ticket_id=? AND released_at IS NULL", (now(), ticket_id))
            self._event(db, ticket_id, event, old, new_status, payload)

    def update_ticket(self, ticket_id: str, **values: Any) -> None:
        allowed = {
            "current_state_json", "worktree", "branch", "pr_url", "repair_count",
            "cancel_requested", "specification_source", "write_permission",
            "specification_checked_at", "allowed_scope_json", "priority", "base_commit",
            "goal", "acceptance_json", "test_ids_json", "test_targets_json",
        }
        if not values or not set(values).issubset(allowed):
            raise ValueError("unsupported ticket update fields")
        values = redact_value(values)
        values["updated_at"] = now()
        columns = ",".join(f"{key}=?" for key in values)
        with self.transaction() as db:
            cur = db.execute(
                f"UPDATE tickets SET {columns} WHERE id=?",
                (*values.values(), ticket_id),
            )
            if cur.rowcount != 1:
                raise KeyError(ticket_id)

    def add_event(self, ticket_id: str, event: str, payload: dict[str, Any] | None = None) -> None:
        with self.transaction() as db:
            row = db.execute("SELECT status FROM tickets WHERE id=?", (ticket_id,)).fetchone()
            if row is None:
                raise KeyError(ticket_id)
            self._event(db, ticket_id, event, row["status"], row["status"], payload)

    def append_request(self, ticket_id: str, addition: str) -> str:
        with self.transaction() as db:
            row = db.execute("SELECT status,request FROM tickets WHERE id=?", (ticket_id,)).fetchone()
            if row is None:
                raise KeyError(ticket_id)
            status = row["status"]
            safe_addition = redact_text(addition.strip())
            combined = row["request"].rstrip() + "\n\n--- 追加情報 ---\n" + safe_addition
            next_status = "NEEDS_DECISION" if status in {"READY", "RUNNING", "READY_FOR_REVIEW", "REVIEWING", "REPAIR", "READY_TO_MERGE"} else status
            db.execute("UPDATE tickets SET request=?,status=?,updated_at=? WHERE id=?", (combined, next_status, now(), ticket_id))
            self._event(db, ticket_id, "SCOPE_CHANGE_REQUESTED", status, next_status, {"addition_characters": len(addition)})
            return next_status

    def request_cancel(self, ticket_id: str, reason: str = "user requested cancellation") -> str:
        with self.transaction() as db:
            row = db.execute("SELECT status FROM tickets WHERE id=?", (ticket_id,)).fetchone()
            if row is None:
                raise KeyError(ticket_id)
            old = row["status"]
            if old in {"DONE", "CANCELLED"}:
                return old
            new = "CANCELLED" if old not in {"RUNNING", "READY_FOR_REVIEW", "REVIEWING", "REPAIR"} else old
            db.execute(
                "UPDATE tickets SET cancel_requested=1,status=?,updated_at=? WHERE id=?",
                (new, now(), ticket_id),
            )
            self._event(db, ticket_id, "CANCEL_REQUESTED", old, new, {"reason": reason})
            return new

    def claim_next(self) -> sqlite3.Row | None:
        with self.transaction() as db:
            pause = db.execute("SELECT pause_requested FROM control_flags WHERE id=1").fetchone()
            if pause and pause[0]:
                return None
            candidates = db.execute(
                """SELECT * FROM tickets WHERE status='READY' AND cancel_requested=0
                   AND priority IN ('P0','P1') ORDER BY CASE priority WHEN 'P0' THEN 0 ELSE 1 END,
                   created_at,id"""
            ).fetchall()
            row = None
            for candidate in candidates:
                repo_busy = db.execute(
                    "SELECT 1 FROM resource_leases WHERE kind='repository' AND resource_key=? AND released_at IS NULL LIMIT 1",
                    (candidate["project"],),
                ).fetchone()
                if repo_busy:
                    continue
                dependencies = json.loads(candidate["dependencies_json"])
                if not dependencies:
                    row = candidate
                    break
                placeholders = ",".join("?" for _ in dependencies)
                completed = db.execute(
                    f"SELECT id,status FROM tickets WHERE id IN ({placeholders})",
                    dependencies,
                ).fetchall()
                states = {item["id"]: item["status"] for item in completed}
                if all(states.get(dependency) == "DONE" for dependency in dependencies):
                    row = candidate
                    break
            if row is None:
                return None
            db.execute("UPDATE tickets SET status='RUNNING',updated_at=? WHERE id=?", (now(), row["id"]))
            db.execute(
                "INSERT INTO resource_leases(ticket_id,kind,resource_key,details_json,acquired_at) VALUES(?,?,?,?,?)",
                (row["id"], "repository", row["project"], dump({"project": row["project"]}), now()),
            )
            self._event(db, row["id"], "TASK_STARTED", "READY", "RUNNING", {})
            return db.execute("SELECT * FROM tickets WHERE id=?", (row["id"],)).fetchone()

    def request_pause(self, reason: str = "safe stop requested") -> None:
        with self.transaction() as db:
            db.execute("UPDATE control_flags SET pause_requested=1,reason=?,updated_at=? WHERE id=1", (reason,now()))

    def resume_queue(self) -> None:
        with self.transaction() as db:
            db.execute("UPDATE control_flags SET pause_requested=0,reason='',updated_at=? WHERE id=1", (now(),))
            rows = db.execute("SELECT id FROM tickets WHERE status='PAUSED'").fetchall()
            for row in rows:
                db.execute("UPDATE tickets SET status='READY',cancel_requested=0,updated_at=? WHERE id=?", (now(),row["id"]))
                self._event(db,row["id"],"TICKET_RESUMED","PAUSED","READY",{})

    def pause_requested(self) -> bool:
        with self.connection() as db:
            row = db.execute("SELECT pause_requested FROM control_flags WHERE id=1").fetchone()
        return bool(row[0]) if row else False

    def get_ticket(self, ticket_id: str) -> sqlite3.Row:
        with self.connection() as db:
            row = db.execute("SELECT * FROM tickets WHERE id=?", (ticket_id,)).fetchone()
        if row is None:
            raise KeyError(ticket_id)
        return row

    def ticket_exists(self, ticket_id: str) -> bool:
        with self.connection() as db:
            return db.execute("SELECT 1 FROM tickets WHERE id=?", (ticket_id,)).fetchone() is not None

    def list_tickets(self, status: str | None = None) -> list[sqlite3.Row]:
        with self.connection() as db:
            if status:
                return list(db.execute("SELECT * FROM tickets WHERE status=? ORDER BY created_at,id", (status,)))
            return list(db.execute("SELECT * FROM tickets ORDER BY created_at,id"))

    def cancelled(self, ticket_id: str) -> bool:
        with self.connection() as db:
            row = db.execute("SELECT cancel_requested FROM tickets WHERE id=?", (ticket_id,)).fetchone()
        return row is None or bool(row[0])

    def lease(self, ticket_id: str, kind: str, key: str, details: dict[str, Any] | None = None) -> int:
        with self.transaction() as db:
            cur = db.execute(
                "INSERT INTO resource_leases(ticket_id,kind,resource_key,details_json,acquired_at) VALUES(?,?,?,?,?)",
                (ticket_id, kind, redact_text(key), dump(redact_value(details or {})), now()),
            )
            return int(cur.lastrowid)

    def release_lease(self, lease_id: int) -> None:
        with self.transaction() as db:
            db.execute("UPDATE resource_leases SET released_at=? WHERE id=? AND released_at IS NULL", (now(), lease_id))

    def active_leases(self, ticket_id: str | None = None) -> list[sqlite3.Row]:
        with self.connection() as db:
            if ticket_id:
                return list(db.execute("SELECT * FROM resource_leases WHERE released_at IS NULL AND ticket_id=?", (ticket_id,)))
            return list(db.execute("SELECT * FROM resource_leases WHERE released_at IS NULL"))

    def events_for(self, ticket_id: str, limit: int = 100) -> list[sqlite3.Row]:
        with self.connection() as db:
            return list(db.execute(
                "SELECT * FROM ticket_events WHERE ticket_id=? ORDER BY id DESC LIMIT ?",
                (ticket_id, max(1, min(limit, 500))),
            ))

    def running_agent_runs(self, ticket_id: str | None = None) -> list[sqlite3.Row]:
        with self.connection() as db:
            if ticket_id:
                return list(db.execute("SELECT * FROM agent_runs WHERE state='RUNNING' AND ticket_id=?", (ticket_id,)))
            return list(db.execute("SELECT * FROM agent_runs WHERE state='RUNNING'"))

    def counts(self) -> dict[str, int]:
        with self.connection() as db:
            rows = db.execute("SELECT status,COUNT(*) AS count FROM tickets GROUP BY status").fetchall()
        return {row["status"]: int(row["count"]) for row in rows}

    def create_run(self, run: dict[str, Any]) -> None:
        with self.transaction() as db:
            db.execute(
                """INSERT INTO agent_runs(id,ticket_id,role,model,reasoning,phase,state,pid,pid_start,log_path,output_path,started_at)
                   VALUES(?,?,?,?,?,?,?,?,?,?,?,?)""",
                (run["id"],run["ticket_id"],run["role"],run["model"],run["reasoning"],run["phase"],"RUNNING",run.get("pid"),run.get("pid_start"),run["log_path"],run["output_path"],now()),
            )

    def finish_run(self, run_id: str, exit_code: int, result: dict[str, Any] | None = None) -> None:
        with self.transaction() as db:
            db.execute(
                "UPDATE agent_runs SET state=?,finished_at=?,exit_code=?,result_json=? WHERE id=?",
                ("SUCCEEDED" if exit_code == 0 else "FAILED",now(),exit_code,dump(redact_value(result or {})),run_id),
            )

    def set_run_pid(self, run_id: str, pid: int, pid_start: str | None = None) -> None:
        with self.transaction() as db:
            db.execute("UPDATE agent_runs SET pid=?,pid_start=? WHERE id=?", (pid, pid_start, run_id))

    def add_artifact(self, ticket_id: str, kind: str, path: Path) -> None:
        with self.transaction() as db:
            db.execute("INSERT INTO artifacts(ticket_id,kind,path,created_at) VALUES(?,?,?,?)", (ticket_id,kind,str(path),now()))
