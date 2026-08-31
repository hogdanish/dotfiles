#!/usr/bin/env bash
# PostToolUse hook — validate any .fish file after a Write/Edit touches it.
#
# enforces the parts of claude-code/CLAUDE.md that are mechanically checkable.
# prose is a request; a hook is a guarantee. silent on success.
#
# user-level: wired from claude-code/settings.json, so it fires on every .fish
# write anywhere on this machine, not only inside the dotfiles repo.
#
# PostToolUse cannot block — the write already happened — so this reports back
# to claude via stderr + exit 1 so it gets fixed in the same turn.

set -uo pipefail

FISH=/opt/homebrew/bin/fish
INDENT=/opt/homebrew/bin/fish_indent

input=$(cat)
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

[[ -x "$FISH" ]] || exit 0

validate_file() {
  local file_path=$1
  local errors=""

  case "$file_path" in
    /*) ;;
    *) file_path="${CLAUDE_PROJECT_DIR:-${PWD}}/$file_path" ;;
  esac
  case "$file_path" in
    *.fish) ;;
    *) return 0 ;;
  esac
  [[ -f "$file_path" ]] || return 0

# 1. does it parse? catches [[ ]], ${var}, unbalanced end, bad redirections.
if ! out=$("$FISH" -n "$file_path" 2>&1); then
  errors+="fails to parse (fish -n):\n${out}\n\n"
fi

# 2. canonical formatting. auto-fixable, so say so.
if [[ -z "$errors" && -x "$INDENT" ]]; then
  if ! "$INDENT" --check "$file_path" >/dev/null 2>&1; then
    errors+="not canonically formatted. fix with:  fish_indent -w '${file_path}'\n\n"
  fi
fi

# 3. plaintext credentials. the one check worth having even at the cost of a
#    false positive — see style-guide.md §9.
if secrets=$(grep -nE '(github_pat_[A-Za-z0-9_]{20,}|ghp_[A-Za-z0-9]{20,}|sk-[A-Za-z0-9]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----)' "$file_path" 2>/dev/null); then
  # report line numbers only — never echo the credential back into context.
  lines=$(cut -d: -f1 <<<"$secrets" | paste -sd, -)
  errors+="possible plaintext credential on line(s) ${lines}. use an op:// reference resolved via\n"
  errors+="\`op run --\` instead of exporting the secret. see style-guide.md §9.\n\n"
fi

# 4. house style violations that fish itself accepts. keep these
#    high-confidence: a noisy hook is an ignored hook.
if hits=$(grep -nE '^[[:space:]]*alias[[:space:]]+[^[:space:]]' "$file_path" 2>/dev/null); then
  errors+="\`alias\` is banned (claude-code/CLAUDE.md §7) — write a function or an abbr:\n${hits}\n\n"
fi

# `set -U` / `--universal`, but not an erase (`set -eU x` is the sanctioned fix).
if hits=$(grep -nE '^[[:space:]]*set[[:space:]]+(-[a-zA-Z]*U[a-zA-Z]*|--universal)([[:space:]]|$)' "$file_path" 2>/dev/null \
          | grep -vE '(-[a-zA-Z]*e[a-zA-Z]*[[:space:]]|--erase)'); then
  errors+="universal variable written from a config file (claude-code/CLAUDE.md §1). \`set -U\` persists to\n"
  errors+="fish_variables, which is machine state, not version-controlled config:\n${hits}\n\n"
fi

if hits=$(grep -nE '^[[:space:]]*export[[:space:]]+[A-Za-z_]' "$file_path" 2>/dev/null); then
  errors+="\`export\` is not a fish builtin — use \`set -gx\`:\n${hits}\n\n"
fi

# `[[ ]]` parses fine (fish reads `[[` as a command name) and only fails at
# runtime with "Unknown command", so fish -n cannot catch it. grep must.
if hits=$(grep -nE '(^|[[:space:]])\[\[[[:space:]]' "$file_path" 2>/dev/null); then
  errors+="\`[[ ]]\` is bash — fish has no such construct and this fails at *runtime*, not parse time.\n"
  errors+="use \`test\` or \`string match\`:\n${hits}\n\n"
fi

# every function needs a description (claude-code/CLAUDE.md §6).
if hits=$(grep -nE '^[[:space:]]*function[[:space:]]+' "$file_path" 2>/dev/null \
          | grep -vE '(-d[[:space:]]|--description)'); then
  errors+="function without a --description (claude-code/CLAUDE.md §6):\n${hits}\n\n"
fi

  if [[ -n "$errors" ]]; then
    printf 'Fish validation failed for %s\n\n' "$file_path" >&2
    printf '%b' "$errors" >&2
    printf 'Fix before continuing. Full law: claude-code/CLAUDE.md and the fish skill'"'"'s\n' >&2
    printf 'references/style-guide.md.\n' >&2
    return 1
  fi
}

status=0
while IFS= read -r file_path; do
  [[ -n "$file_path" ]] || continue
  validate_file "$file_path" || status=1
done <<<"$files"

exit "$status"
