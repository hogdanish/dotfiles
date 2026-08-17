#!/usr/bin/env bash
# SessionStart/SessionEnd hook — keep the machine awake for as long as at least one Claude Code
# session is running, and let it sleep normally again once the last one exits.
#
# one marker file per active session, named by session_id: stable across a session's
# SessionStart/SessionEnd, unlike $PPID — each hook firing runs under its own transient `sh -c`
# spawned by claude, so the hook script's own parent pid differs between the start and end of the
# same session and cannot identify it.
set -uo pipefail

mode=${1:?usage: caffeinate.sh start|end}
input=$(cat)
session_id=$(jq -r '.session_id // empty' <<<"$input" 2>/dev/null)
[[ -n "$session_id" ]] || exit 0

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/claude-code/caffeinate"
sessions_dir="$state_dir/sessions"
pidfile="$state_dir/caffeinate.pid"
lockdir="$state_dir/lock"
mkdir -p "$sessions_dir"

# a session killed outright (no SessionEnd fired) leaves its marker behind forever; a session
# genuinely running this long is implausible, so age it out rather than tracking liveness another
# way — the harness gives no pid for a session, only its id.
find "$sessions_dir" -type f -mmin +1440 -delete 2>/dev/null || true

# mkdir is atomic — cheap spin-lock against two sessions starting/ending at the same instant.
for _ in $(seq 1 50); do
    mkdir "$lockdir" 2>/dev/null && break
    sleep 0.1
done
trap 'rmdir "$lockdir" 2>/dev/null || true' EXIT

case "$mode" in
start)
    touch "$sessions_dir/$session_id"
    if [[ ! -s "$pidfile" ]] || ! kill -0 "$(cat "$pidfile" 2>/dev/null)" 2>/dev/null; then
        /usr/bin/caffeinate -disu &
        disown
        echo $! >"$pidfile"
    fi
    ;;
end)
    rm -f "$sessions_dir/$session_id"
    if [[ -z "$(ls -A "$sessions_dir" 2>/dev/null)" && -s "$pidfile" ]]; then
        kill "$(cat "$pidfile")" 2>/dev/null || true
        rm -f "$pidfile"
    fi
    ;;
esac
exit 0
