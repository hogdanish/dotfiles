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
found=0; ios=0
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
    ios=1; continue
  fi
  # a steam "add to dock" shortcut is a 4-line bundle wrapping `open steam://run/<id>`
  # — no payload, nothing to install, and it multiplies with every game. the real
  # software is steam's, and steam is already a cask.
  if grep -qs 'steam://run/' "$path/Contents/MacOS/"* 2>/dev/null; then
    printf '  \033[2m~ %s\033[0m  — steam shortcut, not an install\n' "$app"
    ios=1; continue
  fi
  printf '  \033[33m? %s\033[0m  — installed outside brew/mas (%s)\n' "$app" "${path%/*}"; found=1
done
[[ $found -eq 0 && $ios -eq 0 ]] && printf '  none\n'
[[ $found -eq 0 && $ios -eq 1 ]] && printf '  no actionable unmanaged apps\n'

# ------------------------------------------------- claude toolbox digest
# claude-code/rules/toolbox.md is the always-in-context summary of this file: a
# user-level claude rule, loaded into every session in every project. it is
# hand-written on purpose — the usage guidance is the whole point, and no
# generator produces it — so it is made *self-verifying* instead. an html comment
# at the top carries the two name lists checked here; block comments are stripped
# before the file reaches claude's context, so carrying them is free.
#
# the invariant this enforces, in both directions:
#   every name it claims is present resolves, every name it claims is absent does
#   not, and every declared formula is mentioned somewhere in it.
# that is what makes it a verified view of the Brewfile rather than the kind of
# hand-kept duplicate that drifted before.
section "claude toolbox digest"
TOOLBOX="$(dirname "$BREWFILE")/claude-code/rules/toolbox.md"
if [[ ! -f "$TOOLBOX" ]]; then
  printf '  \033[33m~ no toolbox.md at %s\033[0m — skipping\n' "$TOOLBOX"
else
  # a `verify-*:` key plus its two-space-indented continuation lines. awk, not
  # sed: BSD sed has no portable multi-line range with this shape.
  manifest() {
    awk -v k="$1:" '$1==k {f=1; $1=""; print; next} f && /^  / {print; next} f {exit}' "$TOOLBOX" \
      | tr -s '[:space:]' '\n' | grep -v '^$'
  }
  n=0
  # present: `command -v` first, then `brew list` for formulae that put no
  # same-named binary on $PATH (pam-reattach ships only a PAM module), then the
  # uv shim directory.
  # ⚠ the uv probe is not redundant with `command -v`: ~/.local/bin reaches $PATH
  # only via fish/conf.d/uv.fish, so gdformat/gdlint resolve from a fish-launched
  # shell and not from launchd, cron, or a Claude Code Bash call. without this the
  # audit's verdict would depend on how it was invoked — the same failure class as
  # the brew.env and npmrc fixes.
  UV_BIN="$(uv tool dir --bin 2>/dev/null || echo "$HOME/.local/bin")"
  while read -r c; do
    [[ -z "$c" ]] && continue
    command -v "$c" >/dev/null 2>&1 && continue
    brew list --versions "$c" >/dev/null 2>&1 && continue
    [[ -x "$UV_BIN/$c" ]] && continue
    printf '  \033[31m- %s\033[0m  (toolbox.md claims it is present; it does not resolve)\n' "$c"
    n=$((n + 1))
  done < <(manifest verify-present)
  # absent: the negative claims are load-bearing too — they stop an agent
  # proposing a tool that is now installed, or avoiding one that is.
  while read -r c; do
    [[ -z "$c" ]] && continue
    command -v "$c" >/dev/null 2>&1 || continue
    printf '  \033[32m+ %s\033[0m  (toolbox.md claims it is absent; it is installed)\n' "$c"
    n=$((n + 1))
  done < <(manifest verify-absent)
  # coverage: a declared package nobody documented is a tool claude will not reach
  # for. uv tools count — gdtoolkit is declared software like any formula.
  while read -r f; do
    [[ -z "$f" ]] && continue
    grep -qwF -- "${f##*/}" "$TOOLBOX" && continue
    printf '  \033[33m~ %s\033[0m — declared, but unmentioned in toolbox.md\n' "${f##*/}"
    n=$((n + 1))
  done < <(cat "$TMP/want-brew" "$TMP/want-uv")
  [[ $n -eq 0 ]] && printf '  in sync\n'
fi

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
  if [[ -s "$TMP/stale-brew" || -s "$TMP/stale-cask" || -s "$TMP/stale-mas" ]]; then
    printf '  \033[31mbrew bundle check: unsatisfied\033[0m — %s entry(ies); see the diffs above\n' "$n"
  else
    printf '  brew bundle check: %s entry(ies) outdated, none missing — not drift\n' "$n"
  fi
fi
echo
