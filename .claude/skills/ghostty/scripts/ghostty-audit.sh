#!/usr/bin/env bash
# audit the ghostty skill against the installed ghostty binary
#
# 1. validates the live config
# 2. diffs the binary's option keys against references/configuration.md
# 3. diffs the binary's keybind actions against references/keybinds.md
#
# exit 0 = skill matches the installed build; 1 = drift or invalid config.
# run after every ghostty upgrade — the tip channel moves fast.

set -uo pipefail

GHOSTTY="${GHOSTTY_BIN:-/Applications/Ghostty.app/Contents/MacOS/ghostty}"
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_REF="$SKILL_DIR/references/configuration.md"
KEYBIND_REF="$SKILL_DIR/references/keybinds.md"

# options intentionally absent from `+show-config --default` (documented as such)
UNDOCUMENTED_BY_BINARY=(link quick-terminal-size)

rc=0
note() { printf '\n\033[1m%s\033[0m\n' "$*"; }
fail() { printf '  \033[31m✗\033[0m %s\n' "$*"; rc=1; }
ok() { printf '  \033[32m✓\033[0m %s\n' "$*"; }

if [ ! -x "$GHOSTTY" ]; then
    printf 'ghostty not found at %s (override with the GHOSTTY_BIN env var)\n' "$GHOSTTY" >&2
    exit 1
fi

version=$("$GHOSTTY" +version 2>/dev/null | head -1)
printf '\033[1mghostty-audit\033[0m — %s\n' "$version"

# ---------------------------------------------------------------- live config
note 'config validation'
if out=$("$GHOSTTY" +validate-config 2>&1) && [ -z "$out" ]; then
    ok 'live config is valid'
else
    fail 'live config has errors:'
    printf '%s\n' "$out" | sed 's/^/      /'
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# ------------------------------------------------------------------- options
note 'configuration options'
"$GHOSTTY" +show-config --default 2>/dev/null |
    grep -oE '^[a-z0-9][a-z0-9-]* =' | tr -d ' =' | sort -u >"$tmp/binary.txt"
printf '%s\n' "${UNDOCUMENTED_BY_BINARY[@]}" >>"$tmp/binary.txt"
sort -u -o "$tmp/binary.txt" "$tmp/binary.txt"

# option headings look like: **`font-size`** — 13
# shellcheck disable=SC2016  # backticks here are markdown, not command substitution
grep -oE '\*\*`[a-z0-9][a-z0-9-]*`\*\*' "$CONFIG_REF" |
    tr -d '*`' | sort -u >"$tmp/doc.txt"

missing=$(comm -23 "$tmp/binary.txt" "$tmp/doc.txt")
extra=$(comm -13 "$tmp/binary.txt" "$tmp/doc.txt")

if [ -z "$missing" ]; then
    ok "all $(wc -l <"$tmp/binary.txt" | tr -d ' ') options documented"
else
    fail 'in ghostty but NOT in configuration.md:'
    printf '%s\n' "$missing" | sed 's/^/      /'
fi
if [ -n "$extra" ]; then
    fail 'in configuration.md but NOT in ghostty (removed or typo):'
    printf '%s\n' "$extra" | sed 's/^/      /'
fi

# ------------------------------------------------------------------- actions
note 'keybind actions'
"$GHOSTTY" +list-actions 2>/dev/null |
    grep -oE '^[a-z_]+$' | sort -u >"$tmp/binact.txt"

# shellcheck disable=SC2016  # backticks here are markdown, not command substitution
grep -oE '`[a-z_]+`' "$KEYBIND_REF" | tr -d '`' | sort -u >"$tmp/docact.txt"

missing=$(comm -23 "$tmp/binact.txt" "$tmp/docact.txt")
if [ -z "$missing" ]; then
    ok "all $(wc -l <"$tmp/binact.txt" | tr -d ' ') actions documented"
else
    fail 'in ghostty but NOT in keybinds.md:'
    printf '%s\n' "$missing" | sed 's/^/      /'
fi

# ------------------------------------------------------------------- summary
note 'summary'
if [ "$rc" -eq 0 ]; then
    ok 'skill is in sync with the installed build'
else
    fail 'drift detected — update the references in the same change'
fi
exit "$rc"
