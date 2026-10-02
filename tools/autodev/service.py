"""LaunchAgent API; importing this module never registers or starts a service.

build_plist(config, repo_root) -> dict; install(plist, directory) -> Path;
read(path) -> dict; status(uid=None) -> CompletedProcess;
bootstrap(path, state_dir, uid=None) -> bool (False means Runner lock active);
unload(state_dir, uid=None, *, config_path=None) -> bool;
stop(config, repo_root, timeout=60) -> bool.
stop requests the existing CLI pause and waits for the Runner lock before unload.
No operation removes the Runner lock or resumes the queue.
"""
from __future__ import annotations

from contextlib import contextmanager
import fcntl
import os
from pathlib import Path
import plistlib
import json
import re
import shutil
import subprocess
import sys
import tempfile
import time

LABEL = "com.bluesharks.autodev.orchestrator"
CONFIG_ENV = "BLUE_SHARKS_AUTODEV_CONFIG"
STATE_ENV = "BLUE_SHARKS_AUTODEV_STATE_DIR"


class ServiceIdentityError(ValueError):
    """A registered job cannot be proven to belong to the requested Runner."""


def build_plist(config: dict, repo_root: Path) -> dict:
    """Use the actual loaded config path, interpreter and workspace log directory."""
    logs = Path(config["workspace"]["logs_dir"]).expanduser().resolve()
    config_path = str(Path(config["_config_path"]).expanduser().resolve())
    return {
        "Label": LABEL,
        "ProgramArguments": [sys.executable, "-m", "tools.autodev.cli", "--config",
                             config_path, "run", "--continuous"],
        "WorkingDirectory": str(Path(repo_root).resolve()),
        "EnvironmentVariables": {
            CONFIG_ENV: config_path,
            STATE_ENV: str(Path(config["workspace"]["state_dir"]).expanduser().resolve()),
            "PATH": os.environ.get("PATH", "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"),
        },
        "RunAtLoad": True,
        "KeepAlive": {"SuccessfulExit": False},
        "ThrottleInterval": 15,
        "ProcessType": "Background",
        "StandardOutPath": str(logs / "orchestrator.stdout.log"),
        "StandardErrorPath": str(logs / "orchestrator.stderr.log"),
    }


def read(path: Path) -> dict:
    with Path(path).open("rb") as stream:
        return plistlib.load(stream)


def install(plist: dict, directory: Path | None = None) -> Path:
    """Install without activation; preserve foreign files and back up own updates.

    launchd retains its loaded definition after a file update. Apply updates via
    stop/unload followed by bootstrap; kickstart alone does not reload a plist.
    """
    if plist.get("Label") != LABEL:
        raise ValueError("unexpected service label")
    directory = Path(directory) if directory is not None else Path.home() / "Library/LaunchAgents"
    directory.mkdir(parents=True, exist_ok=True)
    path = directory / f"{LABEL}.plist"
    payload = plistlib.dumps(plist)
    if path.is_symlink():
        raise FileExistsError(f"refusing symlink: {path}")
    if path.exists():
        if read(path).get("Label") != LABEL:
            raise FileExistsError(f"foreign LaunchAgent: {path}")
        if path.read_bytes() == payload:
            return path
        with tempfile.NamedTemporaryFile(prefix=path.name + ".backup-", dir=directory, delete=False) as backup:
            backup_path = Path(backup.name)
        shutil.copy2(path, backup_path)
    for key in ("StandardOutPath", "StandardErrorPath"):
        Path(plist[key]).parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(dir=directory, delete=False) as stream:
        temporary = Path(stream.name)
        try:
            stream.write(payload)
            stream.flush()
            os.fsync(stream.fileno())
            temporary.chmod(0o600)
            os.replace(temporary, path)
        finally:
            temporary.unlink(missing_ok=True)
    return path


def _target(uid: int | None) -> str:
    return f"gui/{os.getuid() if uid is None else uid}/{LABEL}"


def _launchctl(*args: str) -> subprocess.CompletedProcess:
    return subprocess.run(["launchctl", *args], capture_output=True, text=True, timeout=15)


def status(uid: int | None = None) -> subprocess.CompletedProcess:
    """Return raw launchctl print output and exit status without changing state."""
    return _launchctl("print", _target(uid))


def _loaded_identity(uid: int | None) -> tuple[str, str] | None:
    """Read only the registered job's explicit environment, never its disk plist.

    Default/inherited environments are not proof of job ownership. Unrecognized
    print formats and legacy jobs without both identity fields fail closed.
    """
    result = status(uid)
    if result.returncode == 0:
        blocks = re.findall(r"(?m)^([ \t]*)environment = \{[ \t]*$", result.stdout)
        if len(blocks) != 1:
            raise ServiceIdentityError("Loaded service identity is unknown; no service operation permitted")
        indent = blocks[0]
        match = re.search(r"(?m)^" + re.escape(indent) + r"environment = \{[ \t]*$", result.stdout)
        end = re.search(r"(?m)^" + re.escape(indent) + r"\}[ \t]*$", result.stdout[match.end():])
        if end is None:
            raise ServiceIdentityError("Loaded environment is malformed")
        environment = result.stdout[match.end():match.end() + end.start()]
        values = []
        for key in (CONFIG_ENV, STATE_ENV):
            entries = re.findall(r"(?m)^[ \t]+" + re.escape(key) + r" => (.*?)\s*$", environment)
            if len(entries) != 1:
                raise ServiceIdentityError("Loaded service lacks a unique config/state identity")
            value = entries[0]
            if value.startswith('"'):
                try:
                    value = json.loads(value)
                except ValueError as exc:
                    raise ServiceIdentityError("Loaded identity cannot be decoded") from exc
            if not isinstance(value, str) or not value or not Path(value).is_absolute() or "\x00" in value:
                raise ServiceIdentityError("Loaded service identity must contain absolute paths")
            values.append(str(Path(value).resolve()))
        return tuple(values)
    # launchctl reports a missing service as ESRCH (3) or its print error (113).
    if result.returncode not in (3, 113):
        raise subprocess.CalledProcessError(result.returncode, result.args, result.stdout, result.stderr)
    return None


def _identity(config_path, state_dir) -> tuple[str, str]:
    if config_path is None:
        raise ServiceIdentityError("config_path is required to verify the loaded service")
    return (str(Path(config_path).expanduser().resolve()),
            str(Path(state_dir).expanduser().resolve()))


def _verify_loaded(identity, uid):
    loaded = _loaded_identity(uid)
    if loaded is not None and loaded != identity:
        raise ServiceIdentityError("Loaded service config/state identity differs from the requested Runner")
    return loaded is not None


@contextmanager
def _idle_lock(state_dir: Path):
    path = Path(state_dir) / "orchestrator.lock"
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a+") as stream:
        try:
            fcntl.flock(stream, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as exc:
            raise RuntimeError("Runner still active; request pause and wait before service changes") from exc
        try:
            yield
        finally:
            fcntl.flock(stream, fcntl.LOCK_UN)


def bootstrap(path: Path, state_dir: Path, uid: int | None = None) -> bool:
    """Start an idle job without killing an existing process or changing pause.

    A loaded job is kickstarted without -k, using its registered definition.
    To apply a reinstalled plist, unload safely before calling this function.
    """
    plist = read(path)
    if plist.get("Label") != LABEL:
        raise ValueError("unexpected service label")
    environment = plist.get("EnvironmentVariables", {})
    identity = _identity(environment.get(CONFIG_ENV), state_dir)
    if environment.get(STATE_ENV) != identity[1]:
        raise ServiceIdentityError("Plist state identity differs from requested state directory")
    # Ensure the command actually uses the declared config identity.
    arguments = plist.get("ProgramArguments", [])
    if arguments.count("--config") != 1:
        raise ServiceIdentityError("Plist config argument is unknown")
    index = arguments.index("--config") + 1
    if index >= len(arguments) or arguments[index] != identity[0]:
        raise ServiceIdentityError("Plist config argument differs from declared identity")
    _verify_loaded(identity, uid)
    try:
        with _idle_lock(state_dir):
            loaded = _verify_loaded(identity, uid)
    except RuntimeError:
        return False
    # Release before launching: the CLI itself acquires the same nonblocking lock.
    if loaded:
        result = _launchctl("kickstart", _target(uid))
    else:
        result = _launchctl("bootstrap", _target(uid).rsplit("/", 1)[0], str(Path(path).resolve()))
    result.check_returncode()
    return True


def unload(state_dir: Path, uid: int | None = None, *, config_path: Path | None = None) -> bool:
    """Refuse to terminate an active pipeline; bootout only after lock release."""
    loaded = _loaded_identity(uid)
    if loaded is None:
        return False
    identity = _identity(config_path, state_dir)
    if loaded != identity:
        raise ServiceIdentityError("Loaded service config/state identity differs from the requested Runner")
    with _idle_lock(state_dir):
        if not _verify_loaded(identity, uid):
            return False
        result = _launchctl("bootout", _target(uid))
        result.check_returncode()
    return True


def stop(config: dict, repo_root: Path, timeout: float = 60, uid: int | None = None) -> bool:
    """Pause at the existing safe boundary, then unload; timeout never force-kills."""
    identity = _identity(config["_config_path"], config["workspace"]["state_dir"])
    if not _verify_loaded(identity, uid):
        return False
    args = build_plist(config, repo_root)["ProgramArguments"][:-2] + ["pause"]
    subprocess.run(args, cwd=str(Path(repo_root).resolve()), capture_output=True,
                   text=True, timeout=15, check=True)
    deadline = time.monotonic() + timeout
    while True:
        try:
            with _idle_lock(Path(config["workspace"]["state_dir"])):
                pass
            return unload(Path(config["workspace"]["state_dir"]), uid,
                          config_path=Path(config["_config_path"]))
        except RuntimeError:
            if time.monotonic() >= deadline:
                raise TimeoutError("pause requested; Runner still finishing; service remains loaded")
            time.sleep(min(0.2, max(0, deadline - time.monotonic())))
