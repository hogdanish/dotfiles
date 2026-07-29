#!/usr/bin/env bash
# PostToolUse hook — validate the Brewfile after any Write/Edit touches it.
#
# catches what an editor can't:
#   1. ruby syntax errors        -> error (Brewfiles are eval'd ruby)
#   2. names brew can't resolve  -> error (a typo'd package is valid ruby)
#   3. valid but not installed   -> note  (legitimate: declared ahead of install)
#
# PostToolUse cannot block — the write already happened — so a real error is
# reported via stderr + exit 1 to get fixed in the same turn. notes go back as
# additionalContext so they inform without reading as a failure.
#
# silent when the file is clean.

set -uo pipefail

input=$(cat)
file_path=$(jq -r '.tool_input.file_path // empty' <<<"$input" 2>/dev/null)

# only Brewfiles. matches "Brewfile", "Brewfile.work"; never "brewfile-example.md".
case "${file_path##*/}" in
  Brewfile|Brewfile.*) ;;
  *) exit 0 ;;
esac
[[ -f "$file_path" ]] || exit 0
command -v brew >/dev/null 2>&1 || exit 0

fail() {
  printf 'Brewfile validation failed for %s\n\n%b\n' "$file_path" "$1" >&2
  printf 'Fix before continuing — see .claude/skills/brewfile/references/auditing.md §8.\n' >&2
  exit 1
}

# --- 1. ruby syntax ------------------------------------------------------
if command -v ruby >/dev/null 2>&1; then
  out=$(ruby -c "$file_path" 2>&1) || fail "ruby syntax error:\n${out}"
fi

# --- 2. brew can parse the file -----------------------------------------
out=$(brew bundle list --file="$file_path" 2>&1 >/dev/null) \
  || fail "brew could not parse the Brewfile:\n${out}"

# --- 3. resolve anything `check` flags as unsatisfied ---------------------
# `brew bundle check` reports a typo, a not-yet-installed package and a merely
# outdated one identically ("needs to be installed or updated"), so each flagged
# name is resolved against the index and then against the local installs to tell
# the three apart. an outdated entry is not drift — the file is already correct.
check_out=$(brew bundle check --verbose --file="$file_path" 2>&1) || true
[[ "$check_out" != *"needs to be"* ]] && exit 0

bad="" ; pending="" ; outdated=""
while read -r kind name; do
  [[ -z "$name" ]] && continue
  case "$kind" in
    Formula) brew info --formula "$name" >/dev/null 2>&1 || { bad+="  - brew \"$name\" — no such formula\n"; continue; }
             brew list --formula --versions "$name" >/dev/null 2>&1 \
               && { outdated+="  - brew \"$name\" — installed, upgrade available\n"; continue; } ;;
    Cask)    brew info --cask    "$name" >/dev/null 2>&1 || { bad+="  - cask \"$name\" — no such cask\n";    continue; }
             brew list --cask    --versions "$name" >/dev/null 2>&1 \
               && { outdated+="  - cask \"$name\" — installed, upgrade available\n"; continue; } ;;
    Tap)     pending+="  - tap \"$name\" — not tapped\n"; continue ;;
    App)     pending+="  - mas \"$name\" — not installed\n"; continue ;;
  esac
  # `tr`, not ${kind,,} — macos ships bash 3.2, which lacks case expansion.
  kw=$(printf '%s' "$kind" | tr '[:upper:]' '[:lower:]')
  [[ "$kw" == "formula" ]] && kw="brew"
  pending+="  - $kw \"$name\" — declared but not installed\n"
done < <(grep -oE '^→ (Formula|Cask|Tap|App) [^ ]+' <<<"$check_out" | sed 's/^→ //')

[[ -n "$bad" ]] && fail "unresolvable entries (likely typos):\n${bad}"

ctx=""
[[ -n "$pending" ]] && ctx+="Brewfile declares entries that are not installed on this machine:
$(printf '%b' "$pending")
This is fine if intentional (declared ahead of install); otherwise it is drift.
"
[[ -n "$outdated" ]] && ctx+="Brewfile entries that are installed but out of date — not drift, the file is correct:
$(printf '%b' "$outdated")
"

if [[ -n "$ctx" ]]; then
  jq -n --arg ctx "${ctx}Run \`brew bundle install --file=$file_path\` to converge." \
    '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$ctx}}'
fi

exit 0
