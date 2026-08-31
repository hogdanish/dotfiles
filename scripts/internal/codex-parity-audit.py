#!/usr/bin/env python3
"""Compare structured Claude/Codex adapters and trusted hook inventory."""

from __future__ import annotations

import json
import re
import sys
import tomllib
from pathlib import Path
from typing import Any


def load_json(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)


def load_toml(path: Path) -> dict[str, Any]:
    with path.open("rb") as handle:
        return tomllib.load(handle)


def event_key(name: str) -> str:
    return re.sub(r"(?<!^)(?=[A-Z])", "_", name).lower()


def hook_keys(path: Path, data: dict[str, Any]) -> set[str]:
    keys: set[str] = set()
    for event, groups in data.get("hooks", {}).items():
        for group_index, group in enumerate(groups):
            for hook_index, _hook in enumerate(group.get("hooks", [])):
                keys.add(f"{path}:{event_key(event)}:{group_index}:{hook_index}")
    return keys


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: codex-parity-audit.py DOTFILES COMMONGROUNDS", file=sys.stderr)
        return 2

    dotfiles = Path(sys.argv[1]).resolve()
    project = Path(sys.argv[2]).resolve()
    errors: list[str] = []

    claude_mcp = load_json(project / ".mcp.json")["mcpServers"]
    codex_mcp = load_toml(project / ".codex/config.toml")["mcp_servers"]
    for name in ("godot-lsp", "godot-mcp"):
        expected = claude_mcp[name]
        actual = codex_mcp[name]
        if Path(actual["command"]).name != Path(expected["command"]).name:
            errors.append(f"{name} command differs from .mcp.json")
        if actual.get("args", []) != expected.get("args", []):
            errors.append(f"{name} args differ from .mcp.json")
        if actual.get("env", {}) != expected.get("env", {}):
            errors.append(f"{name} environment differs from .mcp.json")

    config = load_toml(dotfiles / "codex/config.toml")
    trusted = set(config.get("hooks", {}).get("state", {}))
    hook_sources = (
        (project / ".codex/hooks.json", project / ".codex/hooks.json"),
        (Path.home() / ".codex/hooks.json", dotfiles / "codex/hooks.json"),
    )
    for discovery_path, source_path in hook_sources:
        expected = hook_keys(discovery_path, load_json(source_path))
        prefix = f"{discovery_path}:"
        actual = {key for key in trusted if key.startswith(prefix)}
        for key in sorted(expected - actual):
            errors.append(f"untrusted hook: {key}")
        for key in sorted(actual - expected):
            errors.append(f"stale hook trust entry: {key}")

    for error in errors:
        print(error, file=sys.stderr)
    return bool(errors)


if __name__ == "__main__":
    raise SystemExit(main())
