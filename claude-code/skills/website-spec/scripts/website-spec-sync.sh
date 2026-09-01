#!/usr/bin/env bash
# check the vendored specification.website copies against upstream, and optionally refresh them.
#
# a vendored copy of someone else's living document goes stale silently, which is the one real
# risk this skill carries. so: re-fetch, diff, and verify the digest upstream publishes.
#
#   website-spec-sync.sh            report drift; exit 1 if anything moved
#   website-spec-sync.sh --write    ...and update the vendored copies in place
#
# the provenance header at the top of each vendored file is regenerated, not diffed.

set -uo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REF_DIR="$SKILL_DIR/references"
SITE="https://specification.website"
SKILL_URL="$SITE/.well-known/agent-skills/specification-website/SKILL.md"

WRITE=0
[[ "${1:-}" == "--write" ]] && WRITE=1

rc=0
note() { printf '\n\033[1m%s\033[0m\n' "$*"; }
fail() { printf '  \033[31m✗\033[0m %s\n' "$*"; rc=1; }
ok() { printf '  \033[32m✓\033[0m %s\n' "$*"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$*"; }

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# strip our provenance header (the leading HTML comment block plus its blank line) so the
# comparison is upstream-against-upstream.
strip_header() { awk 'NR==1 && /^<!--/ {h=1} h {if (/-->/) {h=0; b=1} next} b {b=0; next} {print}' "$1"; }

check_one() {
  local label="$1" url="$2" dest="$3" header="$4"
  local fetched
  fetched="$tmp/$(basename "$dest" .md)"

  if ! curl -fsSL "$url" -o "$fetched"; then
    fail "$label: could not fetch $url"
    return
  fi

  if [[ ! -f "$dest" ]]; then
    fail "$label: no vendored copy at ${dest#"$SKILL_DIR/"}"
    [[ $WRITE -eq 1 ]] || return
  elif strip_header "$dest" | diff -q - "$fetched" >/dev/null 2>&1; then
    ok "$label: vendored copy matches upstream"
    return
  else
    fail "$label: upstream has changed"
    strip_header "$dest" | diff -u --label "vendored" - --label "upstream" "$fetched" | head -60
  fi

  if [[ $WRITE -eq 1 ]]; then
    { printf '%s\n\n' "$header"; cat "$fetched"; } > "$dest"
    warn "$label: rewrote ${dest#"$SKILL_DIR/"}"
  fi
}

today="$(date -u +%Y-%m-%d)"

note 'checklist'
check_one 'checklist.md' "$SITE/checklist.md" "$REF_DIR/checklist.md" \
"<!-- VENDORED VERBATIM from $SITE/checklist.md
     Fetched $today · Content licensed CC BY 4.0 · © Joost de Valk
     Do NOT hand-edit: scripts/website-spec-sync.sh re-fetches and diffs this file. -->"

note 'upstream agent skill'
check_one 'upstream-skill.md' "$SKILL_URL" "$REF_DIR/upstream-skill.md" \
"<!-- VENDORED VERBATIM from
     $SKILL_URL
     Fetched $today · Code MIT / content CC BY 4.0 · © Joost de Valk
     This is the SPEC AUTHOR'S own agent skill, kept whole as the upstream contract.
     Do NOT hand-edit: scripts/website-spec-sync.sh re-fetches and diffs this file. -->"

# upstream publishes a sha256 of its own SKILL.md in the discovery index — check ours against it.
note 'upstream digest'
if curl -fsSL "$SITE/.well-known/agent-skills/index.json" -o "$tmp/index.json"; then
  declared="$(python3 -c '
import json,sys
d=json.load(open(sys.argv[1]))
print(next((s.get("digest","") for s in d.get("skills",[]) if s.get("name")=="specification-website"), ""))
' "$tmp/index.json")"
  actual="sha256:$(shasum -a 256 "$tmp/upstream-skill" | cut -d" " -f1)"
  if [[ -z "$declared" ]]; then
    warn "discovery index declares no digest for specification-website"
  elif [[ "$declared" == "$actual" ]]; then
    ok "fetched SKILL.md matches the digest in the discovery index"
  else
    fail "digest mismatch — declared $declared, fetched $actual"
  fi
else
  warn "could not fetch the agent-skills discovery index"
fi

note 'item counts'
if [[ -f "$REF_DIR/checklist.md" ]]; then
  printf '  %s items:' "$(grep -c '^- \[ \]' "$REF_DIR/checklist.md")"
  for s in Required Recommended Optional Avoid; do
    printf ' %s %s' "$(grep -c -- "— $s\$" "$REF_DIR/checklist.md")" "$s"
  done
  printf '\n'
fi

if [[ $rc -eq 0 ]]; then
  note 'in sync with upstream'
elif [[ $WRITE -eq 1 ]]; then
  note 'refreshed — review the diff and commit the vendored copies on their own'
  rc=0
else
  note 'drift — re-run with --write to refresh'
fi
exit $rc
