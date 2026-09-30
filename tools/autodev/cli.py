from __future__ import annotations

import argparse
from contextlib import contextmanager
import fcntl
import json
import os
from pathlib import Path
import re
import shutil
import signal
import subprocess
import sys
import time
from typing import Iterator

from .config import DEFAULT_CONFIG, load_config
from .engine import Orchestrator, ticket_from_row
from .intake import add_request
from .runtime import MIN_CODEX_VERSION_FOR_GPT_6_1
from .state import Store


SERVICE_LABEL = "com.bluesharks.autodev.orchestrator"
EXAMPLE_CONFIG = Path(__file__).with_name("config.example.toml")
def install_config(destination: Path = DEFAULT_CONFIG) -> Path:
    destination = destination.expanduser()
    if destination.exists():
        raise FileExistsError(f"configuration already exists; preserve it: {destination}")
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(EXAMPLE_CONFIG, destination)
    destination.chmod(0o600)
    return destination


def make_store(config: dict) -> Store:
    workspace = config["workspace"]
    for name in ("root", "state_dir", "worktrees_dir", "snapshots_dir", "logs_dir", "artifacts_dir"):
        Path(workspace[name]).mkdir(parents=True, exist_ok=True)
    return Store(Path(workspace["state_dir"]) / "tickets.sqlite3")


def read_store(config: dict) -> Store | None:
    path = Path(config["workspace"]["state_dir"]) / "tickets.sqlite3"
    return Store(path, initialize=False, readonly=True) if path.is_file() else None


@contextmanager
def orchestrator_lock(state_dir: Path) -> Iterator[None]:
    path = state_dir / "orchestrator.lock"
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a+") as stream:
        try:
            fcntl.flock(stream, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as exc:
            raise RuntimeError("Orchestrator is already running") from exc
        stream.seek(0)
        stream.truncate()
        stream.write(f"{os.getpid()}\n")
        stream.flush()
        try:
            yield
        finally:
            stream.seek(0)
            stream.truncate()
            stream.flush()
            fcntl.flock(stream, fcntl.LOCK_UN)


def kickstart_if_loaded() -> None:
    uid = os.getuid()
    target = f"gui/{uid}/{SERVICE_LABEL}"
    check = subprocess.run(["launchctl", "print", target], capture_output=True, text=True)
    if check.returncode == 0:
        subprocess.run(["launchctl", "kickstart", target], check=False, capture_output=True, text=True)


def _ticket_summary(ticket: dict) -> str:
    status = ticket.get("initial_status", ticket.get("status", ""))
    return f"{ticket['id']}  [{status}]  {ticket['priority']}  {ticket['project']}  {ticket['title']}"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="BlueSharks deterministic autonomous development Orchestrator")
    parser.add_argument("--config", type=Path, default=None, help="TOML config; defaults to ~/.config/bluesharks-autodev/config.toml")
    commands = parser.add_subparsers(dest="command", required=True)

    commands.add_parser("install-config", help="copy the reviewed example config without overwriting existing settings")
    commands.add_parser("init", help="create the runtime workspace and SQLite Ticket DB")
    commands.add_parser("doctor", help="read-only configuration and repository checks")
    commands.add_parser("status", help="show Ticket state counts and active leases")
    list_parser = commands.add_parser("list", help="list Tickets")
    list_parser.add_argument("--status")
    show_parser = commands.add_parser("show", help="show a Ticket and recent audit events")
    show_parser.add_argument("ticket_id")
    legacy = commands.add_parser("import-legacy", help="import Markdown Tickets as paused records for review; never auto-runs them")
    legacy.add_argument("directory", type=Path)
    legacy.add_argument("--include-done", action="store_true")

    for name, alias, priority, investigation in (
        ("task-add", "タスク追加", None, False),
        ("urgent-add", "緊急タスク追加", "P0", False),
        ("investigation-add", "調査タスク追加", None, True),
    ):
        add = commands.add_parser(name, aliases=[alias], help=f"Ticket Intake ({name})")
        add.set_defaults(priority_override=priority, investigation=investigation)
        add.add_argument("--request", required=True, help="human natural-language task request")
        add.add_argument("--project", choices=["app", "server", "both"])
        if name == "task-add":
            add.add_argument("--priority", choices=["P0", "P1", "P2"])
        else:
            add.set_defaults(priority_override=priority)

    append = commands.add_parser("append", aliases=["チケットに追記"])
    append.add_argument("ticket_id")
    append.add_argument("--text", required=True)
    cancel = commands.add_parser("cancel", aliases=["中止"])
    cancel.add_argument("ticket_id")
    cancel.add_argument("--reason", default="user requested cancellation")
    resolve = commands.add_parser("resolve", aliases=["判断を決定"], help="resolve a specification/decision/blocker with explicit human input")
    resolve.add_argument("ticket_id")
    resolve.add_argument("--action", choices=["approve", "retry", "cancel"], required=True)
    resolve.add_argument("--note", default="")
    resolve.add_argument("--goal")
    resolve.add_argument("--criterion", action="append", default=[])
    resolve.add_argument("--scope", action="append", default=[])
    resolve.add_argument("--test", action="append", default=[])
    resolve.add_argument("--target", action="append", default=[])
    resolve.add_argument("--spec-source")
    resolve.add_argument("--spec-checked-at")

    run = commands.add_parser("run", help="run the queue; AI starts only for Ticket events")
    run_mode = run.add_mutually_exclusive_group(required=True)
    run_mode.add_argument("--once", action="store_true", help="process one Ticket or one merge check")
    run_mode.add_argument("--continuous", action="store_true", help="process queued Tickets and wait without AI polling")
    run.add_argument("--idle-seconds", type=float, default=3.0)
    commands.add_parser("pause", aliases=["stop"], help="finish the active Ticket safely, then stop claiming new Tickets")
    commands.add_parser("resume", help="resume queue processing after a safe pause")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    if args.command == "install-config":
        print(f"config_created={install_config()}")
        return 0
    config = load_config(args.config)
    if args.command == "doctor":
        return doctor(config)
    if args.command in {"status", "list", "show"}:
        store = read_store(config)
        if store is None:
            print("Ticket DB is not initialized")
            return 0
        if args.command == "status":
            print(json.dumps({"paused": store.pause_requested(), "tickets": store.counts(), "active_leases": len(store.active_leases())}, ensure_ascii=False, indent=2))
            return 0
        if args.command == "list":
            for row in store.list_tickets(args.status):
                print(f"{row['id']}\t{row['status']}\t{row['priority']}\t{row['project']}\t{row['title']}")
            return 0
        row = store.get_ticket(args.ticket_id)
        ticket = ticket_from_row(row)
        events = [dict(item) for item in store.events_for(args.ticket_id)]
        print(json.dumps({"ticket": ticket, "events": events}, ensure_ascii=False, indent=2))
        return 0
    store = make_store(config)

    if args.command == "init":
        print(f"database={store.path}")
        print(f"workspace={config['workspace']['root']}")
        return 0
    if args.command == "import-legacy":
        from .legacy import import_markdown_directory
        result = import_markdown_directory(store, args.directory, include_done=args.include_done)
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return 0
    if args.command in {"task-add", "タスク追加", "urgent-add", "緊急タスク追加", "investigation-add", "調査タスク追加"}:
        priority = getattr(args, "priority", None) or getattr(args, "priority_override", None)
        ticket = add_request(store, config, args.request, project=args.project, priority=priority, investigation=args.investigation)
        print(_ticket_summary(ticket))
        if ticket["initial_status"] == "NEEDS_SPECIFICATION":
            for question in ticket["current_state"]["clarifying_questions"]:
                print(f"確認が必要: {question}")
        kickstart_if_loaded()
        return 0
    if args.command in {"append", "チケットに追記"}:
        status = store.append_request(args.ticket_id, args.text)
        print(f"{args.ticket_id}: {status} (append recorded)")
        kickstart_if_loaded()
        return 0
    if args.command in {"cancel", "中止"}:
        status = store.request_cancel(args.ticket_id, args.reason)
        print(f"{args.ticket_id}: {status} (cancel requested; running work stops at a safe phase boundary)")
        return 0
    if args.command in {"resolve", "判断を決定"}:
        from .decisions import resolve_ticket
        status = resolve_ticket(
            store, config, args.ticket_id, action=args.action, note=args.note,
            goal=args.goal, criteria=args.criterion, scopes=args.scope,
            tests=args.test, targets=args.target,
            specification_source=args.spec_source,
            specification_checked_at=args.spec_checked_at,
        )
        print(f"{args.ticket_id}: {status}")
        kickstart_if_loaded()
        return 0
    if args.command in {"pause", "stop"}:
        store.request_pause()
        print("pause_requested=true (active Ticket will finish its safe pipeline boundary; no new Ticket will start)")
        return 0
    if args.command == "resume":
        store.resume_queue()
        print("queue_resumed=true")
        kickstart_if_loaded()
        return 0
    if args.command == "run":
        engine = Orchestrator(store, config)
        try:
            with orchestrator_lock(Path(config["workspace"]["state_dir"])):
                recovered = engine.recover_orphaned_work()
                if recovered:
                    print("recovered_tickets=" + ",".join(recovered))
                engine.codex.sanitize_orphaned_logs()
                if args.once:
                    print(f"did_work={engine.run_once()}")
                else:
                    engine.run_forever(args.idle_seconds)
        except RuntimeError as exc:
            print(str(exc), file=sys.stderr)
            return 2
        return 0
    return 2


def doctor(config: dict) -> int:
    failures = []
    codex = Path(config["codex"]["binary"])
    print(f"codex_cli={'available' if codex.is_file() else 'missing'} path={codex}")
    if not codex.is_file():
        failures.append("Codex CLI missing")
    else:
        version_result = subprocess.run([str(codex), "--version"], capture_output=True, text=True, timeout=10)
        version_match = re.search(r"(\d+)\.(\d+)\.(\d+)", version_result.stdout)
        if version_result.returncode or not version_match:
            failures.append("Codex CLI version could not be verified")
        else:
            version = tuple(map(int, version_match.groups()))
            print("codex_version=" + ".".join(map(str, version)))
            if version < MIN_CODEX_VERSION_FOR_GPT_6_1:
                failures.append("Codex CLI 0.159.2 or newer is required (validated baseline for GPT-6.1 Sol)")
    sandbox_binary = Path(str(config.get("sandbox", {}).get("exec_binary", "")))
    sandbox_available = sandbox_binary.is_file()
    print(f"test_sandbox={'available' if sandbox_available else 'missing'} path={sandbox_binary}")
    if sys.platform == "darwin" and not sandbox_available:
        failures.append("macOS test sandbox missing; refusing unsandboxed project test execution")
    gradle_seed = config.get("sandbox", {}).get("gradle_cache_seed")
    gradle_ready = bool(
        gradle_seed
        and (Path(str(gradle_seed)).expanduser() / "caches" / "modules-2" / "files-2.1").is_dir()
        and (Path(str(gradle_seed)).expanduser() / "wrapper" / "dists").is_dir()
    )
    print(f"android_debug_build_cache={'ready' if gradle_ready else 'not configured (Android-build Tickets will be held)'}")
    for project_id, project in config["projects"].items():
        repo = Path(project["repository"])
        valid = repo.is_dir() and (repo / ".git").exists()
        print(f"repository.{project_id}={'available' if valid else 'missing'} path={repo}")
        if not valid:
            failures.append(f"repository missing: {project_id}")
        else:
            source = repo / str(project.get("source_directory", ""))
            if not source.is_dir():
                failures.append(f"source directory missing: {project_id}:{source}")
            if subprocess.run(["git", "-C", str(repo), "rev-parse", "--verify", project["base_ref"]], capture_output=True).returncode:
                failures.append(f"base ref missing: {project_id}:{project['base_ref']}")
    db_path = Path(config["workspace"]["state_dir"]) / "tickets.sqlite3"
    print(f"database={'initialized' if db_path.is_file() else 'not initialized'} path={db_path}")
    for warning in failures:
        print(f"ERROR: {warning}")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
