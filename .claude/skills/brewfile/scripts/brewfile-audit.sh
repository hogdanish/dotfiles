#!/usr/bin/env bash
# brewfile-audit.sh — diff intentionally-installed software against a Brewfile.
#
# usage: brewfile-audit.sh [path/to/Brewfile]
#
# prints four sections per package type:
#   + MISSING  installed on this machine but absent from the Brewfile
#   - STALE    listed in the Brewfile but not installed
#   ~ NOTE     things a human has to decide about
# exit 0 always — this is a report, not a gate.

set -uo pipefail

BREWFILE="${1:-Brewfile}"
[[ -f "$BREWFILE" ]] || { echo "no such Brewfile: $BREWFILE" >&2; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# apple's pre-bundled app store apps — reinstalled by macos, never tracked.
# ids, not names: apple renames these (Keynote -> "Keynote Creator Studio").
# verified against this machine; add new ids here rather than in the Brewfile.
# GarageBand iMovie Keynote Numbers Pages
APPLE_MAS_IDS=(682658836 408981434 361285480 361304891 361309726)

# one json call feeds every formula/cask query below; `brew info` is slow.
brew info --json=v2 --installed >"$TMP/info.json" 2>/dev/null || {
  echo "brew info failed" >&2; exit 1; }

section() { printf '\n\033[1m== %s ==\033[0m\n' "$1"; }
report() { # <label> <file-of-missing> <file-of-stale>
  local n=0
  while read -r l; do [[ -n "$l" ]] && { printf '  \033[32m+ %s\033[0m  (installed, not in Brewfile)\n' "$l"; n=1; }; done <"$2"
  while read -r l; do [[ -n "$l" ]] && { printf '  \033[31m- %s\033[0m  (in Brewfile, not installed)\n' "$l"; n=1; }; done <"$3"
  [[ $n -eq 0 ]] && printf '  in sync\n'
  return 0
}

# ---------------------------------------------------------------- taps
section "taps"
brew tap | sort >"$TMP/have-tap"
brew bundle list --tap --file="$BREWFILE" 2>/dev/null | sort >"$TMP/want-tap"
comm -23 "$TMP/have-tap" "$TMP/want-tap" >"$TMP/miss-tap"
comm -13 "$TMP/have-tap" "$TMP/want-tap" >"$TMP/stale-tap"
report tap "$TMP/miss-tap" "$TMP/stale-tap"

# ------------------------------------------------------------ formulae
# `.full_name` (not `.name`) — tapped formulae must stay tap-qualified so the
# name matches what `brew leaves` and the Brewfile use.
# `installed_on_request` (not `brew leaves`) — leaves drops anything that later
# became another package's dependency, even if you asked for it by name.
section "formulae"
jq -r '.formulae[] | select(.installed[0].installed_on_request) | .full_name' \
  <"$TMP/info.json" | sort >"$TMP/have-brew"
brew bundle list --formula --file="$BREWFILE" 2>/dev/null | sort >"$TMP/want-brew"
comm -23 "$TMP/have-brew" "$TMP/want-brew" >"$TMP/miss-brew-raw"
comm -13 "$TMP/have-brew" "$TMP/want-brew" >"$TMP/stale-brew-raw"
# a tapped formula written unqualified ("pinentry-touchid" vs
# "jorgelbg/tap/pinentry-touchid") diffs as a missing+stale PAIR. brew accepts
# both, so flag the qualification rather than reporting a phantom change.
: >"$TMP/miss-brew"; : >"$TMP/stale-brew"; : >"$TMP/note-brew"
while read -r f; do
  [[ -z "$f" ]] && continue
  if grep -qx "${f##*/}" "$TMP/stale-brew-raw"; then
    printf '%s\n' "$f" >>"$TMP/note-brew"
  else printf '%s\n' "$f" >>"$TMP/miss-brew"; fi
done <"$TMP/miss-brew-raw"
while read -r f; do
  [[ -z "$f" ]] && continue
  grep -q "/$f\$" "$TMP/miss-brew-raw" || printf '%s\n' "$f" >>"$TMP/stale-brew"
done <"$TMP/stale-brew-raw"
report brew "$TMP/miss-brew" "$TMP/stale-brew"
while read -r f; do [[ -n "$f" ]] &&
  printf '  \033[33m~ %s\033[0m — listed unqualified as "%s"; use the full tap path\n' "$f" "${f##*/}"
done <"$TMP/note-brew"

# --------------------------------------------------------------- casks
# casks have no installed_on_request flag; exclude only those another
# installed cask declares via depends_on.cask.
section "casks"
jq -r '[.casks[]?|.depends_on.cask//empty]|flatten|.[]' <"$TMP/info.json" | sort -u >"$TMP/cask-deps"
brew list --casks | sort >"$TMP/all-casks"
comm -23 "$TMP/all-casks" "$TMP/cask-deps" >"$TMP/have-cask"
brew bundle list --cask --file="$BREWFILE" 2>/dev/null | sort >"$TMP/want-cask"
comm -23 "$TMP/have-cask" "$TMP/want-cask" >"$TMP/miss-cask"
comm -13 "$TMP/have-cask" "$TMP/want-cask" >"$TMP/stale-cask"
report cask "$TMP/miss-cask" "$TMP/stale-cask"

# ----------------------------------------------------------- app store
# diff on numeric id, never on name: `brew bundle list --mas` prints names, and
# apple renames apps between releases (Keynote -> "Keynote Creator Studio").
section "app store (mas)"
if command -v mas >/dev/null; then
  mas list | awk '{print $1}' | sort >"$TMP/have-mas-all"
  printf '%s\n' "${APPLE_MAS_IDS[@]}" | sort >"$TMP/apple-mas"
  comm -23 "$TMP/have-mas-all" "$TMP/apple-mas" >"$TMP/have-mas"
  grep -oE '^[^#]*\bid:[[:space:]]*[0-9]+' "$BREWFILE" \
    | grep -oE '[0-9]+$' | sort >"$TMP/want-mas"
  comm -23 "$TMP/have-mas" "$TMP/want-mas" >"$TMP/miss-mas-id"
  comm -13 "$TMP/have-mas" "$TMP/want-mas" >"$TMP/stale-mas-id"
  # re-attach names for readability
  : >"$TMP/miss-mas"; : >"$TMP/stale-mas"
  while read -r id; do [[ -n "$id" ]] &&
    mas list | awk -v i="$id" '$1==i{$1="";sub(/ \([0-9.]+\)$/,"");sub(/^ +/,"");print $0" (id: "i")"}' >>"$TMP/miss-mas"
  done <"$TMP/miss-mas-id"
  while read -r id; do [[ -n "$id" ]] &&
    grep -hoE "mas \"[^\"]+\", id: $id" "$BREWFILE" >>"$TMP/stale-mas"
  done <"$TMP/stale-mas-id"
  report mas "$TMP/miss-mas" "$TMP/stale-mas"
  skipped=$(comm -12 "$TMP/have-mas-all" "$TMP/apple-mas" | wc -l | tr -d ' ')
  [[ "$skipped" -gt 0 ]] && printf '  \033[2m~ %s apple-bundled app(s) skipped by denylist\033[0m\n' "$skipped"
else
  echo "  mas not installed — skipping"
fi

# ------------------------------------------------- unmanaged /Applications
# match on the cask's declared .app artifact, NOT a slugified app name:
# "AltTab.app" -> alt-tab and "Prism Launcher.app" -> prismlauncher both
# defeat naive slug matching.
# app store apps are detected by their _MASReceipt, not by name: macos renames
# them ("Keynote" is shipped as "Keynote Creator Studio.app").
# note the spaces in `.app? // empty` — jq lexes `?//` as one operator.
section "unmanaged /Applications"
jq -r '.casks[]? | (.artifacts[]? | .app? // empty | .[]? | select(type=="string"))' \
  <"$TMP/info.json" | sort -u >"$TMP/cask-artifacts"
found=0
# a glob, not `ls | grep`: `ls` output is unparseable for names containing a
# newline, and this needs no subshell. (spaces were already safe via `read -r`.)
# top level only, matching the previous behaviour.
for path in /Applications/*.app; do
  [[ -e "$path" ]] || continue                                 # no matches -> literal glob
  app="${path##*/}"
  grep -qxF "$app" "$TMP/cask-artifacts" && continue
  [[ -e "$path/Contents/_MASReceipt/receipt" ]] && continue
  [[ "$app" == "Safari.app" ]] && continue                     # bundled with macos
  printf '  \033[33m? %s\033[0m  — installed outside brew/mas\n' "$app"; found=1
done
[[ $found -eq 0 ]] && printf '  none\n'

# ------------------------------------------------------------ validation
section "validation"
if brew bundle check --file="$BREWFILE" >/dev/null 2>&1; then
  printf '  brew bundle check: satisfied\n'
else
  printf '  \033[31mbrew bundle check: unsatisfied\033[0m — run with --verbose for detail\n'
fi
echo
