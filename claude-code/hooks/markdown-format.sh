#!/usr/bin/env bash
# PostToolUse hook — format any .md file after a Write/Edit touches it.
#
# the counterpart to fish-validate.sh, and deliberately its opposite in temperament.
# fish-validate REPORTS a problem because a fish syntax error needs a human decision.
# markdown has exactly one correct shape and rumdl knows it, so this one FIXES and never
# asks. no violation is ever quoted at the agent: there is nothing for it to go and repair.
#
# the practical win: agent-authored tables arrive as ragged `|a|b|` pipes and leave aligned
# (MD060), and wall-of-text paragraphs leave wrapped at 100 columns (MD013 reflow).
#
# ⚠ but it does NOT stay silent when it changed something, and that part is load-bearing.
#   the file on disk no longer matches what the agent believes it wrote, so the next Edit's
#   old_string would miss and the turn would derail — the precise failure this hook would
#   otherwise cause. so: silent when the write was already clean (the common case), and one
#   line of `additionalContext` naming the reformatted files when it was not.
#
#   additionalContext, not stderr and not exit 2, is what makes that non-blocking. on exit 0
#   Claude Code parses stdout as JSON and passes additionalContext to the model as a system
#   message; the tool call still succeeds and nothing is interrupted. exit 2 would BLOCK the
#   write, and plain stdout would reach only the debug log, never the model.
#
# user-level: wired from claude-code/settings.json, so it fires on every markdown write
# anywhere on this machine. outside a repo with its own .rumdl.toml, rumdl falls back to
# ~/.config/rumdl/rumdl.toml — the same house style.
#
# always exits 0. this hook must never be the reason a turn fails.

set -uo pipefail

RUMDL=/opt/homebrew/bin/rumdl

[[ -x "$RUMDL" ]] || exit 0
command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)

# same extraction as fish-validate.sh: Claude Code puts the path in tool_input.file_path,
# Codex sends an apply_patch command whose body names the files.
files=$(jq -r '
  if (.tool_input.file_path? // "") != "" then
    .tool_input.file_path
  elif .tool_name == "apply_patch" then
    (.tool_input.command // "")
    | split("\n")[]
    | select(startswith("*** Update File: ") or startswith("*** Add File: "))
    | sub("^\\*\\*\\* (Update|Add) File: "; "")
  else
    empty
  end
' <<<"$input" 2>/dev/null)

changed=()

while IFS= read -r file_path; do
  [[ -n "$file_path" ]] || continue

  case "$file_path" in
    /*) ;;
    *) file_path="${CLAUDE_PROJECT_DIR:-${PWD}}/$file_path" ;;
  esac
  case "$file_path" in
    *.md | *.markdown) ;;
    *) continue ;;
  esac
  [[ -f "$file_path" ]] || continue

  # ⚠ never format through a symlink — rumdl would rewrite the file it points at, which is
  #   some other tool's or repo's. AGENTS.md -> .claude/CLAUDE.md is exactly this case.
  [[ -L "$file_path" ]] && continue

  before=$(shasum -a 256 -- "$file_path" 2>/dev/null | cut -d' ' -f1)

  # rumdl discovers its own config by walking up from the file, so this is correct in any
  # repo. `fmt` is the formatter-style entry point: it exits 0 even when something is left
  # unfixable, which is what keeps an unfixable violation from ever reaching the agent.
  # excludes still apply to explicitly-passed paths, so vendored markdown is passed over.
  "$RUMDL" fmt --silent -- "$file_path" >/dev/null 2>&1

  after=$(shasum -a 256 -- "$file_path" 2>/dev/null | cut -d' ' -f1)
  [[ "$before" != "$after" ]] && changed+=("$file_path")
done <<<"$files"

# nothing was rewritten: the agent's copy is still accurate, so say nothing at all.
[[ ${#changed[@]} -eq 0 ]] && exit 0

printf '%s\n' "${changed[@]}" | jq -Rs '
  rtrimstr("\n") | split("\n") |
  {
    hookSpecificOutput: {
      hookEventName: "PostToolUse",
      additionalContext: (
        "rumdl reformatted " + (length | tostring) +
        (if length == 1 then " file" else " files" end) + " on disk after this write: " +
        join(", ") +
        ". Nothing is wrong and there is nothing to fix — markdown is formatted automatically " +
        "here (tables aligned, paragraphs wrapped at 100 columns). But the file no longer " +
        "matches what you wrote, so re-read it before your next edit to it rather than " +
        "reusing an old_string from memory."
      )
    }
  }'

exit 0
