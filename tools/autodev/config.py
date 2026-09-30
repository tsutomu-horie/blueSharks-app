from __future__ import annotations

import os
from pathlib import Path
import shutil
import sys
import tomllib
from typing import Any

from .runtime import ALLOWED_MODELS


DEFAULT_CONFIG = Path.home() / ".config" / "bluesharks-autodev" / "config.toml"


def load_config(path: Path | None = None) -> dict[str, Any]:
    config_path = path or Path(os.environ.get("BLUE_SHARKS_AUTODEV_CONFIG", DEFAULT_CONFIG))
    if not config_path.is_file():
        raise FileNotFoundError(
            f"Autonomous development is not configured. Copy config.example.toml to {config_path} and review paths."
        )
    with config_path.open("rb") as stream:
        config = tomllib.load(stream)
    sandbox = config.setdefault("sandbox", {})
    sandbox.setdefault("exec_binary", "/usr/bin/sandbox-exec" if sys.platform == "darwin" else "")
    read_paths = {
        "/usr", "/System", "/Library",
        str(Path.home() / ".pub-cache"), str(Path.home() / "Library" / "Android" / "sdk"),
        *(str(item) for item in sandbox.get("read_paths", [])),
    }
    for project in config.get("projects", {}).values():
        for command in project.get("checks", {}).values():
            if not command:
                continue
            executable = str(command[0])
            resolved = shutil.which(executable)
            if not resolved:
                continue
            path = Path(resolved).resolve()
            read_paths.add(path.as_posix())
            if len(path.parents) > 1:
                read_paths.add(path.parents[1].as_posix())
    sandbox["read_paths"] = sorted(read_paths)
    sandbox.setdefault("gradle_cache_seed", None)
    validate_config(config)
    config["_config_path"] = str(config_path.resolve())
    for key in ("root", "state_dir", "worktrees_dir", "snapshots_dir", "logs_dir", "artifacts_dir"):
        config["workspace"][key] = str(Path(config["workspace"][key]).expanduser().resolve())
    for project in config["projects"].values():
        project["repository"] = str(Path(project["repository"]).expanduser().resolve())
    return config


def validate_config(config: dict[str, Any]) -> None:
    for section in ("workspace", "codex", "git", "projects"):
        if section not in config or not isinstance(config[section], dict):
            raise ValueError(f"missing configuration section: [{section}]")
    workspace = config["workspace"]
    for key in ("root", "state_dir", "worktrees_dir", "snapshots_dir", "logs_dir", "artifacts_dir"):
        if key not in workspace:
            raise ValueError(f"missing workspace.{key}")
    root = Path(workspace["root"]).expanduser().resolve()
    for key in ("state_dir", "worktrees_dir", "snapshots_dir", "logs_dir", "artifacts_dir"):
        target = Path(workspace[key]).expanduser().resolve()
        if target == root or root not in target.parents:
            raise ValueError(f"workspace.{key} must be inside workspace.root")
    sandbox = config.get("sandbox", {})
    sandbox_binary = str(sandbox.get("exec_binary", ""))
    if sys.platform == "darwin" and (not sandbox_binary or not Path(sandbox_binary).is_absolute()):
        raise ValueError("sandbox.exec_binary must be an absolute macOS sandbox-exec path")
    read_paths = sandbox.get("read_paths", [])
    if not isinstance(read_paths, list):
        raise ValueError("sandbox.read_paths must be an array of absolute paths")
    for value in read_paths:
        raw = Path(str(value)).expanduser()
        target = raw.resolve()
        if not raw.is_absolute() or ".." in raw.parts or target == Path("/"):
            raise ValueError("sandbox.read_paths must not grant filesystem-root access")
    gradle_seed = sandbox.get("gradle_cache_seed")
    if gradle_seed:
        raw_seed = Path(str(gradle_seed)).expanduser()
        if not raw_seed.is_absolute() or ".." in raw_seed.parts or raw_seed.resolve() == Path("/"):
            raise ValueError("sandbox.gradle_cache_seed must be a specific absolute directory")
    codex = config["codex"]
    for key in ("binary", "intake_model", "intake_reasoning", "developer_model", "developer_reasoning", "reviewer_model", "reviewer_reasoning", "supervisor_model", "supervisor_reasoning", "escalation_model", "escalation_reasoning"):
        if key not in codex:
            raise ValueError(f"missing codex.{key}")
    if int(codex.get("max_repair_cycles", 2)) not in (0, 1, 2):
        raise ValueError("codex.max_repair_cycles must be between 0 and 2")
    for key in ("intake_model", "developer_model", "reviewer_model", "supervisor_model"):
        if codex[key] not in ALLOWED_MODELS:
            raise ValueError(f"{key} must use an allowed GPT-6 model; GPT-5.6 fallback is prohibited")
    if codex.get("intake_model") != "gpt-6-luna":
        raise ValueError("Ticket Intake must use GPT-6 Luna")
    if any(codex[key] != "gpt-6.1-sol" for key in ("developer_model", "reviewer_model", "supervisor_model")):
        raise ValueError("Developer, Reviewer, and Supervisor must use GPT-6.1 Sol")
    if codex.get("escalation_model", "gpt-6-astra") != "gpt-6-astra":
        raise ValueError("final escalation must use GPT-6 Astra")
    if codex.get("escalation_reasoning", "high") != "high":
        raise ValueError("GPT-6 Astra escalation must use high reasoning")
    for project_id, project in config["projects"].items():
        for key in ("repository", "base_ref", "checks", "test_target_roots"):
            if key not in project:
                raise ValueError(f"missing projects.{project_id}.{key}")
        if not isinstance(project["checks"], dict):
            raise ValueError(f"projects.{project_id}.checks must be a table")
        if not isinstance(project["test_target_roots"], list) or not project["test_target_roots"]:
            raise ValueError(f"projects.{project_id}.test_target_roots must be a non-empty string array")
        source_directory = str(project.get("source_directory", ""))
        if source_directory.startswith("/") or ".." in Path(source_directory).parts:
            raise ValueError(f"projects.{project_id}.source_directory must stay within the Git worktree")
        for check_id, command in project["checks"].items():
            if not isinstance(command, list) or not command or not all(isinstance(item, str) for item in command):
                raise ValueError(f"check {project_id}.{check_id} must be an argv string array")
