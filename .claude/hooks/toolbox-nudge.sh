#!/usr/bin/env bash
# PreToolUse hook — nudge Bash commands toward this machine's tools.
#
# claude-code/rules/toolbox.md says which tool to reach for. prose is a request; a hook is a
# guarantee. this is the WARN-ONLY half of that guarantee: it never blocks, never denies, and
# never touches the permission flow. it attaches one line of context to the tool result, which
# is the `additionalContext` field (permissionDecision is NotRequired — verified against the
# PreToolUseHookSpecificOutput typed dict in the claude code hook docs).
#
# ⚠ a noisy hook is an ignored hook. every rule here is command-position only and
# high-confidence. if a match ever fires on something legitimate, delete the rule rather than
# adding an exception — the cost of a false positive is that the whole file gets ignored.
#
# ⚠ depends only on /usr/bin/jq and BSD sed, both macos system binaries. it must not need
# anything from $PATH, because the environment a hook runs in is not the environment fish sets up.

set -uo pipefail

input=$(cat)

[[ "$(jq -r '.tool_name // empty' <<<"$input" 2>/dev/null)" == "Bash" ]] || exit 0
cmd=$(jq -r '.tool_input.command // empty' <<<"$input" 2>/dev/null)
[[ -n "$cmd" ]] || exit 0

# strip quoted text before matching: `echo "pipe this to grep"` must not trip anything, and
# neither must a filename containing the word. this is the single biggest false-positive source.
stripped=$(sed -e "s/'[^']*'/''/g" -e 's/"[^"]*"/""/g' <<<"$cmd")

# every command position: start of line, and after ; | || && $( and newline.
# ⚠ `[$]` not a bare `$` — in a BRE `$` is only an anchor at the end, so `s/$(/…/` happens to work
# and would silently stop working under any other regex dialect.
segments=$(sed -e 's/&&/;/g' -e 's/||/;/g' -e 's/|/;/g' -e 's/[$](/;/g' <<<"$stripped" | tr ';' '\n')

# an in-place flag, or a substitution script at a word boundary (any of sed's usual delimiters).
SED_EDITS="(^|[[:space:]'\"])(-i|s[/|,#@])"

nudges=""
seen=""
add() { # <key> <message>
    case " $seen " in *" $1 "*) return ;; esac
    seen+=" $1"
    nudges+="  - $2"$'\n'
}

single_segment=$(grep -c . <<<"$segments")

while IFS= read -r seg; do
    # trim leading whitespace, then peel off prefixes that are not the real command
    seg="${seg#"${seg%%[![:space:]]*}"}"
    while [[ "$seg" =~ ^([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*|sudo|command|builtin|time|nohup|xargs)[[:space:]]+ ]]; do
        seg="${seg#"${BASH_REMATCH[0]}"}"
        seg="${seg#"${seg%%[![:space:]]*}"}"
    done
    read -r word args <<<"$seg" || true
    [[ -n "$word" ]] || continue

    # the backticks below are markdown for claude's benefit, not command substitution — which is
    # exactly why these strings are single-quoted.
    # shellcheck disable=SC2016
    case "$word" in
    grep | egrep | fgrep)
        add grep 'search contents with `rg` (ripgrep), not grep.'
        ;;
    find)
        # `find` with no path-ish first arg is usually something else entirely; still cheap to nudge.
        add find 'find files with `fd`, not find.'
        ;;
    sed)
        # only substitution and in-place editing have an `sd` equivalent. `sed -n '/a/,/b/p'` is
        # range extraction and has none. this rule has now false-positived twice, so it is anchored
        # tightly: slice out sed's OWN arguments from the original (unstripped) command — the script
        # is normally quoted, so $args above has had it eaten — and require the `s` of a
        # substitution to sit at a word boundary. ⚠ a loose `*"s/"*` matches every path with a
        # directory ending in s: `skills/`, `hooks/`, `rules/`, `scripts/`.
        # ⚠ known miss, deliberately kept: `sed 's|a|b|'` goes silent, because splitting the
        # pipeline on `|` eats the script. widening it to catch that also lets a trailing
        # `| grep -i x` back in, and a false positive costs far more than a miss here.
        sed_call="${cmd#*sed }"
        sed_call="${sed_call%%[|;&]*}"
        if [[ "$sed_call" =~ $SED_EDITS ]]; then
            add sed 'substitute with `sd` (literal by default, same syntax everywhere). ⚠ macOS sed is BSD: no `gsed`, and `-i` needs an explicit `-i ""`.'
        fi
        ;;
    ls)
        add ls 'list directories with `eza` (`--tree`, icons), not ls.'
        ;;
    rm)
        add rm 'delete with `trash` (recoverable), not rm.'
        ;;
    dig)
        add dig 'resolve DNS with `doge`, not dig.'
        ;;
    top)
        add top 'watch processes with `btop`, not top.'
        ;;
    curl)
        add curl 'prefer `xh` for HTTP. ⚠ curlrc sets `fail`, so a 404 exits 22, not 0.'
        ;;
    pip | pip3)
        add pip 'install Python packages with `uv` (`uv run`, `uv tool install`). pip is not used on this machine.'
        ;;
    npm | npx)
        case " $args " in
        *" -g "* | *" --global "*)
            add npm 'install JS globals with `bun`, not npm -g.'
            ;;
        esac
        ;;
    python | python3)
        case "$args" in
        *"-m venv"*) add venv 'create environments with `uv`, not python -m venv.' ;;
        esac
        ;;
    cat)
        # only when cat IS the command — `cat x | jq` is a legitimate pipeline, and a heredoc is not
        # a file read at all. one segment, one argument, no redirection.
        if [[ "$single_segment" -eq 1 && -n "$args" && "$args" != *" "* && "$args" != *"<"* && "$args" != *">"* ]]; then
            add cat 'to read a file into context use the Read tool, not `cat`. For a human-facing dump use `bat -pp`.'
        fi
        ;;
    esac
done <<<"$segments"

[[ -n "$nudges" ]] || exit 0

msg="This machine has dedicated tools for this (claude-code/rules/toolbox.md):"$'\n'"${nudges}"
msg+="Use them unless there is a specific reason not to. This is advisory — the command was not blocked."

jq -n --arg ctx "$msg" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", additionalContext: $ctx}}'

exit 0
