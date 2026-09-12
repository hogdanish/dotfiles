#!/usr/bin/env bash
# check the vendored SimpleEnglish copies against upstream, and optionally refresh them.
#
# this skill is a third party's living document, vendored rather than installed as a plugin:
# the upstream Claude Code plugin ships SessionStart, PostToolUse and Stop hooks that make the
# register always-on, which is exactly what this machine does not want. see the repo CLAUDE.md.
# a vendored copy goes stale silently, so: re-fetch the release, diff, and report.
#
#   simple-english-sync.sh            report drift; exit 1 if anything moved
#   simple-english-sync.sh --write    ...and update the vendored copies in place
#
# SE_REF pins the upstream ref (default: the repo's latest release tag).
#
# two things are local and are never diffed: the SKILL.md frontmatter (its description is
# rewritten so the skill loads only when asked for) and the block between the LOCAL OVERRIDE
# markers (which forces Plain mode). everything else must match upstream byte for byte.

set -uo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "$SKILL_DIR/../../.." && pwd)"
STYLE="$REPO_ROOT/claude-code/output-styles/simple-english.md"
API="https://api.github.com/repos/AminBlg/SimpleEnglish"
RAW="https://raw.githubusercontent.com/AminBlg/SimpleEnglish"

WRITE=0
[[ "${1:-}" == "--write" ]] && WRITE=1

rc=0
note() { printf '\n\033[1m%s\033[0m\n' "$*"; }
fail() { printf '  \033[31m✗\033[0m %s\n' "$*"; rc=1; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$*"; }

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# the local half: YAML frontmatter, the vendoring header comment, and the LOCAL OVERRIDE block.
# strip all three so the comparison is upstream-against-upstream.
strip_local() {
  awk '
    NR==1 && /^---[[:space:]]*$/ { fm=1; next }
    fm==1 && /^---[[:space:]]*$/ { fm=0; next }
    fm==1 { next }
    /LOCAL OVERRIDE START/ { ov=1; next }
    ov { if (/LOCAL OVERRIDE END/) ov=0; next }
    /^<!-- VENDORED VERBATIM/ { hd=1 }
    hd { if (/-->/) hd=0; next }
    { print }
  ' "$1" | sed -e '/./,$!d' | awk '{ lines[NR]=$0 } END { last=NR; while (last>0 && lines[last]=="") last--; for (i=1;i<=last;i++) print lines[i] }'
}

check_one() {
  local label="$1" path="$2" dest="$3"
  local fetched
  fetched="$tmp/$(echo "$path" | tr / _)"

  if ! curl -fsSL "$RAW/$REF/$path" -o "$fetched"; then
    fail "$label: could not fetch $RAW/$REF/$path"
    return
  fi
  # compare the upstream file through the same normaliser, so a frontmatter-only file
  # (the output style) and a header-only file (the references) both line up.
  strip_local "$fetched" > "$fetched.norm"

  if [[ ! -f "$dest" ]]; then
    fail "$label: no vendored copy at ${dest#"$REPO_ROOT/"}"
  elif strip_local "$dest" | diff -q - "$fetched.norm" >/dev/null 2>&1; then
    ok "$label"
    return
  else
    fail "$label: upstream has changed"
    strip_local "$dest" | diff -u --label vendored - --label upstream "$fetched.norm" | head -40
  fi

  if [[ $WRITE -eq 1 ]]; then
    # keep the local half of the file, replace the upstream body beneath it.
    python3 - "$dest" "$fetched" <<'PY'
import re, sys
dest, fetched = sys.argv[1], sys.argv[2]
local = open(dest).read()
new = open(fetched).read()
# upstream body = everything after upstream's own frontmatter and vendoring header
new = re.sub(r'\A---\n.*?\n---\n', '', new, flags=re.S)
new = re.sub(r'\A\s*<!-- VENDORED VERBATIM.*?-->\n', '', new, flags=re.S)
m = re.search(r'\A(.*?LOCAL OVERRIDE END -->\n|\A---\n.*?\n---\n|\A<!-- VENDORED VERBATIM.*?-->\n)', local, flags=re.S)
head = m.group(1) if m else ''
open(dest, 'w').write(head.rstrip('\n') + '\n\n' + new.lstrip('\n'))
PY
    warn "$label: rewrote ${dest#"$REPO_ROOT/"}"
  fi
}

REF="${SE_REF:-}"
if [[ -z "$REF" ]]; then
  REF="$(curl -fsSL "$API/releases/latest" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tag_name",""))' 2>/dev/null)"
fi
if [[ -z "$REF" ]]; then
  warn "could not resolve the latest release tag; falling back to main"
  REF=main
fi

note "upstream ref: $REF"
pinned="$(sed -n 's/.*SimpleEnglish \(v[0-9.]*\), verbatim.*/\1/p' "$SKILL_DIR/SKILL.md" | head -1)"
if [[ -n "$pinned" && "$pinned" != "$REF" ]]; then
  fail "vendored copies say $pinned, upstream latest release is $REF — read the changelog before you refresh"
  warn "https://github.com/AminBlg/SimpleEnglish/releases/tag/$REF"
else
  ok "vendored version marker matches ($pinned)"
fi

note 'skill'
check_one 'SKILL.md' 'skills/simple-english/SKILL.md' "$SKILL_DIR/SKILL.md"
for f in checklist strict-vocabulary use-cases word-swaps; do
  check_one "references/$f.md" "skills/simple-english/references/$f.md" "$SKILL_DIR/references/$f.md"
done

note 'output style'
check_one 'output-styles/simple-english.md' 'output-styles/simple-english.md' "$STYLE"

note 'opt-in guard'
if grep -q '"simple-english' "$REPO_ROOT/claude-code/settings.json"; then
  fail 'settings.json mentions simple-english — the upstream plugin ships always-on hooks; keep it out'
else
  ok 'no simple-english plugin or output style enabled in settings.json'
fi

exit $rc
