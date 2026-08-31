#!/usr/bin/env python3
"""Deny protected paid-control-plane and destructive Brewfile commands."""

from __future__ import annotations

import json
import os
import shlex
import sys
from pathlib import Path
from typing import Any


SHELLS = {"bash", "fish", "sh", "zsh"}
LINODE_GENERIC = {"clone", "create", "migrate", "rebuild", "resize", "restore"}
LINODE_ACTIONS = {
    "account": {"enable-managed"},
    "databases": {"mysql-create", "postgresql-conn-pool-create", "postgresql-create"},
    "linodes": {"backup-restore", "backups-enable", "clone", "create", "migrate", "rebuild", "resize"},
    "lke": {"cluster-create", "pool-create"},
    "managed": {"enable", "service-create"},
    "nodebalancers": {"create"},
    "object-storage": {"cancel"},
    "volumes": {"clone", "create", "resize"},
}


def _basename(value: str) -> str:
    return Path(value).name


def _tokens(command: str) -> list[str]:
    try:
        return shlex.split(command)
    except ValueError:
        return []


def _nested_shell_commands(tokens: list[str]) -> list[str]:
    nested: list[str] = []
    for index, token in enumerate(tokens[:-1]):
        if _basename(token) not in SHELLS:
            continue
        flag = tokens[index + 1]
        if flag == "-c" or (flag.startswith("-") and "c" in flag[1:]):
            if index + 2 < len(tokens):
                nested.append(tokens[index + 2])
    return nested


def _linode_denial(tokens: list[str]) -> str | None:
    for index, token in enumerate(tokens):
        if _basename(token) != "linode-cli":
            continue
        args = [value for value in tokens[index + 1 :] if not value.startswith("-")]
        if not args:
            continue
        if args[0] in LINODE_GENERIC:
            return args[0]
        if len(args) >= 2 and args[1] in LINODE_ACTIONS.get(args[0], set()):
            return f"{args[0]} {args[1]}"
    return None


def _brew_denial(tokens: list[str]) -> str | None:
    for index, token in enumerate(tokens):
        if _basename(token) != "brew":
            continue
        args = tokens[index + 1 :]
        if len(args) >= 2 and args[0] == "bundle" and args[1] in {"cleanup", "dump"}:
            if "--force" in args or "-f" in args:
                return f"brew bundle {args[1]} --force"
    return None


def classify(command: str) -> str | None:
    pending = [command]
    seen: set[str] = set()
    while pending:
        current = pending.pop()
        if current in seen:
            continue
        seen.add(current)
        tokens = _tokens(current)
        if not tokens and current.strip():
            return "an unparseable command payload"
        if action := _linode_denial(tokens):
            return f"billable Akamai Cloud action `{action}`"
        if action := _brew_denial(tokens):
            return f"destructive software-inventory action `{action}`"
        pending.extend(_nested_shell_commands(tokens))
    return None


def _deny(reason: str) -> None:
    message = (
        f"Blocked {reason}. This hook cannot prove explicit authority from the current request; "
        "establish authority in a separately scoped user turn, then run the exact action outside "
        "Codex. This policy has no automatic bypass."
    )
    json.dump(
        {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": message,
            }
        },
        sys.stdout,
    )
    sys.stdout.write("\n")


def main() -> int:
    try:
        event: Any = json.load(sys.stdin)
    except (json.JSONDecodeError, UnicodeDecodeError):
        _deny("because the security hook received malformed JSON")
        return 0
    if not isinstance(event, dict):
        _deny("because the security hook received a non-object payload")
        return 0
    tool_input = event.get("tool_input")
    if not isinstance(tool_input, dict):
        _deny("because the security hook received no tool input")
        return 0
    command = tool_input.get("command")
    if not isinstance(command, str):
        _deny("because the security hook received no command string")
        return 0
    if reason := classify(os.path.expanduser(command)):
        _deny(reason)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
