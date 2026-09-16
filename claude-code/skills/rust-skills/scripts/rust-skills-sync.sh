#!/usr/bin/env bash
# check the vendored leonardomso/rust-skills copy against upstream, and optionally refresh it.
#
# the whole skill is a third party's living document — 265 rule files plus the SKILL.md index —
# vendored byte-for-byte because upstream ships NO claude code plugin and no marketplace, so the
# repo-preferred `claude plugin install` path does not exist for it. see .claude/CLAUDE.md.
#
#   rust-skills-sync.sh            report drift; exit 1 if anything moved
#   rust-skills-sync.sh --write    ...and update the vendored copy in place, pin included
#
# ⚠ nothing here is hand-edited. every vendored file is compared line-for-line, which is also why
# the tree is excluded in .rumdl.toml — reformatting one would read as upstream drift.

set -uo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_URL="https://github.com/leonardomso/rust-skills.git"

# the upstream commit this copy was taken from. upstream publishes NO git tags and no releases,
# so the frontmatter `metadata.version` and this sha are the only provenance there is.
# ⚠ --write rewrites this line; do not hand-edit it.
PINNED_COMMIT="fd2a861ab0406a4ac536a55274d14ea6fd1ca9c9"
PINNED_VERSION="1.5.1"

# the vendored paths, relative to the skill root. anything upstream adds outside this list is
# reported but not vendored — `checks/` (a python + cargo validation harness), the duplicated
# AGENTS.md / CLAUDE.md copies of SKILL.md, and the repo's own README are all deliberately out.
PATHS=(SKILL.md LICENSE rules)

WRITE=0
[[ "${1:-}" == "--write" ]] && WRITE=1

rc=0
note() { printf '\n\033[1m%s\033[0m\n' "$*"; }
fail() { printf '  \033[31m✗\033[0m %s\n' "$*"; rc=1; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$*"; }

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

note 'upstream'
if ! git clone -q --depth 1 "$REPO_URL" "$tmp/up" 2>/dev/null; then
  fail "could not clone $REPO_URL"
  exit 1
fi
head_sha="$(git -C "$tmp/up" rev-parse HEAD)"
if [[ "$head_sha" == "$PINNED_COMMIT" ]]; then
  ok "at the pinned commit ${PINNED_COMMIT:0:12}"
else
  warn "upstream HEAD is ${head_sha:0:12}, pinned is ${PINNED_COMMIT:0:12}"
fi

# the frontmatter version is upstream's only release marker — a bump is a reason to read the
# changelog before refreshing, exactly as with simple-english.
up_version="$(sed -n 's/^[[:space:]]*version: "\(.*\)"$/\1/p' "$tmp/up/SKILL.md" | head -1)"
if [[ -z "$up_version" ]]; then
  warn 'upstream SKILL.md declares no metadata.version'
elif [[ "$up_version" == "$PINNED_VERSION" ]]; then
  ok "version $PINNED_VERSION"
else
  fail "version moved $PINNED_VERSION -> $up_version — read CHANGELOG.md before refreshing"
fi

note 'vendored files'
for p in "${PATHS[@]}"; do
  if [[ ! -e "$SKILL_DIR/$p" ]]; then
    fail "no vendored copy at $p"
    continue
  fi
  if diff -rq "$SKILL_DIR/$p" "$tmp/up/$p" >/dev/null 2>&1; then
    ok "$p matches upstream"
  else
    fail "$p has drifted"
    diff -ru --label "vendored/$p" "$SKILL_DIR/$p" --label "upstream/$p" "$tmp/up/$p" | head -60
  fi
done

note 'rule count'
vendored_rules="$(find "$SKILL_DIR/rules" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')"
upstream_rules="$(find "$tmp/up/rules" -name '*.md' | wc -l | tr -d ' ')"
if [[ "$vendored_rules" == "$upstream_rules" ]]; then
  ok "$vendored_rules rules"
else
  fail "$vendored_rules rules vendored, $upstream_rules upstream"
fi

if [[ $rc -ne 0 && $WRITE -eq 1 ]]; then
  note 'refreshing'
  for p in "${PATHS[@]}"; do
    rm -rf "${SKILL_DIR:?}/$p"
    cp -R "$tmp/up/$p" "$SKILL_DIR/$p"
    warn "rewrote $p"
  done
  self="${BASH_SOURCE[0]}"
  sed -i '' \
    -e "s/^PINNED_COMMIT=\".*\"$/PINNED_COMMIT=\"$head_sha\"/" \
    -e "s/^PINNED_VERSION=\".*\"$/PINNED_VERSION=\"${up_version:-$PINNED_VERSION}\"/" \
    "$self"
  warn "re-pinned to ${head_sha:0:12} (version ${up_version:-$PINNED_VERSION})"
  note 'refreshed — review the diff and commit the vendored copy on its own'
  exit 0
fi

if [[ $rc -eq 0 ]]; then
  note 'in sync with upstream'
else
  note 'drift — re-run with --write to refresh'
fi
exit $rc
