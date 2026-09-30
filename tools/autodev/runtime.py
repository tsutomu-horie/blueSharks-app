from __future__ import annotations

from dataclasses import dataclass
import json
import os
from pathlib import Path
import signal
import subprocess
import time
import uuid
from typing import Callable

from .redaction import redact_text, redact_value
from .state import Store


ALLOWED_MODELS = {"gpt-6-luna", "gpt-6-sol", "gpt-6-astra"}
ALLOWED_REASONING = {"low", "medium", "high", "xhigh", "max"}


@dataclass
class RunResult:
    run_id: str
    exit_code: int
    output_path: Path
    log_path: Path
    cancelled: bool = False

    def text(self) -> str:
        return self.output_path.read_text(errors="replace") if self.output_path.exists() else ""


class CodexRunner:
    def __init__(self, store: Store, config: dict, logs_dir: Path):
        self.store = store
        self.config = config
        self.logs_dir = logs_dir

    def run(
        self,
        *,
        ticket_id: str,
        role: str,
        phase: str,
        model: str,
        reasoning: str,
        prompt: str,
        schema: Path,
        workdir: Path,
        write: bool,
        timeout: int | None = None,
    ) -> RunResult:
        self._validate_model(model, reasoning)
        codex_bin = str(self.config["codex"]["binary"])
        if not Path(codex_bin).exists():
            raise FileNotFoundError(f"Codex CLI not found: {codex_bin}")
        if not schema.is_file():
            raise FileNotFoundError(f"output schema not found: {schema}")
        workdir = workdir.resolve(strict=True)
        workspace_config = self.config.get("workspace", {})
        state_home = Path(workspace_config.get("codex_state_dir", self.logs_dir.parent / "codex-state")).expanduser()
        state_home.mkdir(mode=0o700, parents=True, exist_ok=True)
        try:
            state_home.chmod(0o700)
        except OSError:
            pass
        run_id = uuid.uuid4().hex
        output_dir = self.logs_dir / ticket_id
        output_dir.mkdir(mode=0o700, parents=True, exist_ok=True)
        try:
            output_dir.chmod(0o700)
        except OSError:
            pass
        log_path = output_dir / f"{run_id}-{phase}.jsonl"
        raw_log_path = output_dir / f".{run_id}-{phase}.raw"
        stderr_path = output_dir / f"{run_id}-{phase}.stderr.log"
        output_path = output_dir / f"{run_id}-{phase}.last.txt"
        command = [
            codex_bin, "exec", "--ephemeral", "--ignore-user-config", "--json", "--color", "never",
            "--model", model, "-c", f"model_reasoning_effort={reasoning}",
            "-c", f"sqlite_home={json.dumps(str(state_home.resolve()))}",
            "--sandbox", "workspace-write" if write else "read-only",
            "--cd", str(workdir), "--output-schema", str(schema),
            "--output-last-message", str(output_path), "-",
        ]
        run_record = {
            "id": run_id, "ticket_id": ticket_id, "role": role,
            "model": model, "reasoning": reasoning, "phase": phase,
            "log_path": str(log_path), "output_path": str(output_path),
        }
        duration = int(timeout or self.config["codex"].get("timeout_seconds", 1800))
        process: subprocess.Popen | None = None
        lease_id: int | None = None
        exit_code = 125
        cancelled = False
        group_stopped = True
        with self._open_private(raw_log_path) as stdout, self._open_private(stderr_path) as stderr:
            try:
                old_umask = os.umask(0o077)
                try:
                    process = subprocess.Popen(
                        command, cwd=workdir, stdin=subprocess.PIPE,
                        stdout=stdout, stderr=stderr, start_new_session=True,
                        env=self.safe_environment(),
                    )
                finally:
                    os.umask(old_umask)
                group_stopped = False
                pid_start = self._process_start_identity(process.pid)
                self.store.create_run({**run_record, "pid": process.pid, "pid_start": pid_start})
                self.store.set_run_pid(run_id, process.pid, pid_start)
                # Intake executes before its Ticket row exists. Track it in agent_runs
                # without taking a ticket-bound lease; startup recovery uses pid_start.
                if self.store.ticket_exists(ticket_id):
                    lease_id = self.store.lease(
                        ticket_id, "process_group", str(process.pid),
                        {"pid": process.pid, "pid_start": pid_start, "role": role, "phase": phase, "run_id": run_id},
                    )
                assert process.stdin is not None
                process.stdin.write(prompt.encode())
                process.stdin.close()
                deadline = time.monotonic() + duration
                while process.poll() is None:
                    if self.store.ticket_exists(ticket_id) and self.store.cancelled(ticket_id):
                        cancelled = True
                        group_stopped = self._terminate_group(process)
                        break
                    if time.monotonic() >= deadline:
                        group_stopped = self._terminate_group(process)
                        exit_code = 124
                        break
                    time.sleep(0.5)
                code = process.wait(timeout=10)
                if exit_code != 124:
                    exit_code = 130 if cancelled else code
                group_stopped = self._terminate_process_group(process.pid)
                if not group_stopped:
                    raise RuntimeError("Codex process group could not be confirmed stopped; lease retained for recovery")
                self.store.finish_run(run_id, exit_code, {"cancelled": cancelled})
            except Exception as exc:
                if process is not None and not group_stopped:
                    group_stopped = self._terminate_group(process)
                if process is not None and process.poll() is None:
                    try:
                        process.wait(timeout=10)
                    except subprocess.TimeoutExpired:
                        group_stopped = False
                if run_id and group_stopped:
                    try:
                        self.store.finish_run(run_id, exit_code, {"error_type": type(exc).__name__})
                    except Exception:
                        pass
                raise
            finally:
                if lease_id is not None and group_stopped:
                    self.store.release_lease(lease_id)
                self._sanitize_cli_log(raw_log_path, log_path)
                raw_log_path.unlink(missing_ok=True)
                self._sanitize_output(output_path)
                self._sanitize_text_file(stderr_path)
        return RunResult(run_id, exit_code, output_path, log_path, cancelled)

    @staticmethod
    def _open_private(path: Path):
        descriptor = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        return os.fdopen(descriptor, "wb")

    @staticmethod
    def safe_environment() -> dict[str, str]:
        allowed = {
            "HOME", "CODEX_HOME", "PATH", "TMPDIR", "TMP", "TEMP", "LANG", "LC_ALL",
            "LC_CTYPE", "USER", "LOGNAME", "SHELL", "TERM", "CI",
        }
        return {
            key: value for key, value in os.environ.items()
            if key in allowed or key.startswith("LC_")
        }

    def sanitize_orphaned_logs(self) -> None:
        """Redact private leftovers from an abruptly stopped Codex process."""
        if not self.logs_dir.is_dir():
            return
        for raw_path in self.logs_dir.rglob(".*.raw"):
            destination = raw_path.with_name(raw_path.name[1:-4] + ".jsonl")
            self._sanitize_cli_log(raw_path, destination)
            raw_path.unlink(missing_ok=True)
        for path in self.logs_dir.rglob("*.stderr.log"):
            self._sanitize_text_file(path)
        for path in self.logs_dir.rglob("*.last.txt"):
            self._sanitize_output(path)

    @classmethod
    def _sanitize_cli_log(cls, source: Path, destination: Path) -> None:
        with destination.open("w", encoding="utf-8") as sanitized:
            if not source.exists():
                return
            for line in source.read_text(errors="replace").splitlines():
                try:
                    event = json.loads(line)
                except json.JSONDecodeError:
                    sanitized.write('{"event":"unparsed_cli_event"}\n')
                    continue
                item = event.get("item", {}) if isinstance(event, dict) else {}
                safe = {
                    "type": event.get("type") if isinstance(event, dict) else "unknown",
                    "item_id": item.get("id") if isinstance(item, dict) else None,
                    "item_type": item.get("type") if isinstance(item, dict) else None,
                    "status": item.get("status") if isinstance(item, dict) else None,
                    "exit_code": item.get("exit_code") if isinstance(item, dict) else None,
                }
                sanitized.write(json.dumps(safe, ensure_ascii=False) + "\n")

    @classmethod
    def _sanitize_output(cls, path: Path) -> None:
        if not path.exists():
            return
        try:
            value = json.loads(path.read_text(errors="replace"))
        except json.JSONDecodeError:
            path.write_text(cls._redact_text(path.read_text(errors="replace")))
            return
        path.write_text(json.dumps(cls._redact_value(value), ensure_ascii=False, indent=2) + "\n")

    @classmethod
    def _redact_value(cls, value):
        return redact_value(value)

    @staticmethod
    def _redact_text(text: str) -> str:
        return redact_text(text)

    @classmethod
    def _sanitize_text_file(cls, path: Path) -> None:
        if path.exists():
            content = path.read_text(errors="replace")
            path.write_text(cls._redact_text(content[-16000:]))

    @staticmethod
    def _validate_model(model: str, reasoning: str) -> None:
        if model not in ALLOWED_MODELS:
            raise ValueError(f"model is not allowed by autonomous development policy: {model}")
        if model == "gpt-6-luna" and reasoning != "low":
            raise ValueError("GPT-6 Luna routing must use low reasoning")
        if reasoning not in ALLOWED_REASONING:
            raise ValueError(f"unsupported reasoning effort: {reasoning}")

    @staticmethod
    def _terminate_group(process: subprocess.Popen) -> bool:
        try:
            os.killpg(process.pid, signal.SIGTERM)
        except ProcessLookupError:
            return True
        try:
            process.wait(timeout=8)
        except subprocess.TimeoutExpired:
            try:
                os.killpg(process.pid, signal.SIGKILL)
            except ProcessLookupError:
                return True
            try:
                process.wait(timeout=3)
            except subprocess.TimeoutExpired:
                return False
        return CodexRunner._terminate_process_group(process.pid)

    @staticmethod
    def _terminate_process_group(process_group_id: int, grace_seconds: float = 8.0) -> bool:
        try:
            os.killpg(process_group_id, signal.SIGTERM)
        except ProcessLookupError:
            return True
        deadline = time.monotonic() + grace_seconds
        while time.monotonic() < deadline:
            try:
                os.killpg(process_group_id, 0)
            except ProcessLookupError:
                return True
            time.sleep(0.2)
        try:
            os.killpg(process_group_id, signal.SIGKILL)
        except ProcessLookupError:
            return True
        deadline = time.monotonic() + 2.0
        while time.monotonic() < deadline:
            try:
                os.killpg(process_group_id, 0)
            except ProcessLookupError:
                return True
            time.sleep(0.1)
        return False

    @staticmethod
    def _process_group_exists(process_group_id: int) -> bool:
        try:
            os.killpg(process_group_id, 0)
            return True
        except ProcessLookupError:
            return False
        except PermissionError:
            return True

    @staticmethod
    def _process_start_identity(pid: int) -> str | None:
        try:
            result = subprocess.run(["ps", "-o", "lstart=", "-p", str(pid)], capture_output=True, text=True, timeout=3)
            return result.stdout.strip() if result.returncode == 0 and result.stdout.strip() else None
        except (OSError, subprocess.SubprocessError):
            return None
