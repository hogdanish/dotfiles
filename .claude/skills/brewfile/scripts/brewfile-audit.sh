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

# ------------------------------------------------------------ npm tools
# upstream-supported global node clis that must resolve in every shell and agent. package names come
# from npm's global dependency map; brew bundle owns the declared side through its npm entry type.
section "npm tools"
if command -v npm >/dev/null; then
  npm list --global --depth=0 --json 2>/dev/null \
    | jq -r '.dependencies // {} | keys[] | select(. != "npm")' | sort >"$TMP/have-npm"
  brew bundle list --npm --file="$BREWFILE" 2>/dev/null | sort >"$TMP/want-npm"
  comm -23 "$TMP/have-npm" "$TMP/want-npm" >"$TMP/miss-npm"
  comm -13 "$TMP/have-npm" "$TMP/want-npm" >"$TMP/stale-npm"
  report npm "$TMP/miss-npm" "$TMP/stale-npm"
else
  echo "  npm not installed — skipping"
  : >"$TMP/want-npm"
fi

# ------------------------------------------------------------ uv tools
# homebrew 6 installs these via `uv tool install`. they are real declared software, so they get the
# same both-directions diff as formulae. `uv tool list` prints "name vX.Y.Z" then an indented line
# per shim, so the version line is the only one to match.
# ⚠ the shims land in ~/.local/bin, which reaches $PATH only through fish/conf.d/uv.fish — a shell
# that did not inherit fish's environment sees none of them. that is why the digest check below
# probes that directory directly rather than trusting `command -v`.
section "uv tools"
if command -v uv >/dev/null; then
  uv tool list 2>/dev/null | awk '/^[^ ]+ v/{print $1}' | sort >"$TMP/have-uv"
  brew bundle list --uv --file="$BREWFILE" 2>/dev/null | sort >"$TMP/want-uv"
  comm -23 "$TMP/have-uv" "$TMP/want-uv" >"$TMP/miss-uv"
  comm -13 "$TMP/have-uv" "$TMP/want-uv" >"$TMP/stale-uv"
  report uv "$TMP/miss-uv" "$TMP/stale-uv"
else
  echo "  uv not installed — skipping"
  : >"$TMP/want-uv"
fi

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
section "unmanaged applications"
jq -r '.casks[]? | (.artifacts[]? | .app? // empty | .[]? | select(type=="string"))' \
  <"$TMP/info.json" | sort -u >"$TMP/cask-artifacts"
found=0; noted=0
# a glob, not `ls | grep`: `ls` output is unparseable for names containing a
# newline, and this needs no subshell. (spaces were already safe via `read -r`.)
# ~/Applications is scanned too: casks land in /Applications, but steam, itch and
# any per-user installer write there, and that is exactly where an unmanaged app
# hides. one level deep only — /Applications/Utilities is apple's.
for path in /Applications/*.app "$HOME"/Applications/*.app; do
  [[ -e "$path" ]] || continue                                 # no matches -> literal glob
  app="${path##*/}"
  grep -qxF "$app" "$TMP/cask-artifacts" && continue
  [[ -e "$path/Contents/_MASReceipt/receipt" ]] && continue
  [[ "$app" == "Safari.app" ]] && continue                     # bundled with macos
  # an iphone/ipad app on apple silicon is a WRAPPED bundle: no Contents/ at all,
  # so the _MASReceipt probe above cannot see it and it reads as unmanaged
  # forever. it IS app store software, but `mas` cannot list or install it and no
  # cask exists — so it is a note, never an action.
  if [[ -e "$path/Wrapper" && -e "$path/WrappedBundle" ]]; then
    printf '  \033[2m~ %s\033[0m  — ios app from the app store; not brew- or mas-manageable\n' "$app"
    noted=1; continue
  fi
  # a steam "add to dock" shortcut is a 4-line bundle wrapping `open steam://run/<id>`
  # — no payload, nothing to install, and it multiplies with every game. the real
  # software is steam's, and steam is already a cask.
  if grep -qs 'steam://run/' "$path/Contents/MacOS/"* 2>/dev/null; then
    printf '  \033[2m~ %s\033[0m  — steam shortcut, not an install\n' "$app"
    noted=1; continue
  fi
  # local development output and Claude Code's signed URL dispatcher are intentional
  # app bundles, but neither is independently installable through brew or mas.
  if [[ "$app" == "COMMONGROUNDS.app" ]]; then
    printf '  \033[2m~ %s\033[0m  — local project build, not a package-manager install\n' "$app"
    noted=1; continue
  fi
  if [[ "$app" == "Claude Code URL Handler.app" ]]; then
    printf '  \033[2m~ %s\033[0m  — helper installed and managed by Claude Code\n' "$app"
    noted=1; continue
  fi
  printf '  \033[33m? %s\033[0m  — installed outside brew/mas (%s)\n' "$app" "${path%/*}"; found=1
done
[[ $found -eq 0 && $noted -eq 0 ]] && printf '  none\n'
[[ $found -eq 0 && $noted -eq 1 ]] && printf '  no actionable unmanaged apps\n'

# ------------------------------------------------------------ validation
section "validation"
if brew bundle check --file="$BREWFILE" >/dev/null 2>&1; then
  printf '  brew bundle check: satisfied\n'
else
  # `check` says "needs to be installed OR UPDATED" for a merely outdated package,
  # so on its own it reads as drift on a perfectly correct file. the per-type diffs
  # above are the authority on what is actually missing — if none of them found a
  # stale entry, everything `check` flagged is just an available upgrade.
  n=$(brew bundle check --file="$BREWFILE" --verbose 2>&1 | grep -c 'needs to be')
  if [[ -s "$TMP/stale-brew" || -s "$TMP/stale-npm" || -s "$TMP/stale-cask" || -s "$TMP/stale-mas" ]]; then
    printf '  \033[31mbrew bundle check: unsatisfied\033[0m — %s entry(ies); see the diffs above\n' "$n"
  else
    printf '  brew bundle check: %s entry(ies) outdated, none missing — not drift\n' "$n"
  fi
fi
echo
