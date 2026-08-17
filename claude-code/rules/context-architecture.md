# Context architecture

How to organize what Claude reads, in any repository. Doctrine, not procedure — authoring mechanics
belong to each project's authoring skill.

| Layer | Role | Loads |
| --- | --- | --- |
| `CLAUDE.md` | **Router** — overview, always-on conventions, one glossary line per scope pointing at its skill. Never subsystem detail. | every session, in full |
| `.claude/rules/*.md` | **Law** — short imperative behaviour | always if unscoped; a `paths:` frontmatter defers all cost until a matching file is touched |
| `.claude/skills/*/SKILL.md` | Source of truth for one scope; lean overview plus pointers | description every session; body on invocation |
| `references/*.md` | Depth — API tables, catalogues, specs, append-only logs | on demand |
| memory store | Workflow and feedback learnings only; project facts belong in a skill | index every session |

**Precedence: the owning skill wins.** Fix a contradiction by deleting the duplicate in the same
change, never by syncing copies. Never write "CLAUDE.md is the source of truth" anywhere.

## Where new guidance goes

1. Behavioural, short, needed in most sessions → an unscoped rule. Add `paths:` the moment it only
   concerns certain files — unscoped rules are a shared always-on tax; keep the set lean.
2. How a scope works (seams, gotchas, API) → its skill, lean, plus `references/`.
3. A repeatable procedure → an invocable skill.
4. Must happen every time, without judgement → a hook in `settings.json`. Prose is a request; a
   hook is a guarantee.
5. A correction about how *you* should work → the memory store.

⚠ CLAUDE.md is the tempting default and almost always the wrong one. Past ~200 lines a router
becomes a document nobody can afford to load.

## Skill frontmatter and bodies (the budget rules)

- One `description` field per skill, ≤500 chars — what it covers, when to load, the one boundary
  with a neighbour, key use case first. No `when_to_use` twin field (it drifts). The listing is
  budgeted (~1% of context); overflow silently drops descriptions — `/doctor` reports the cost.
- A loaded body persists all session — keep it a lean overview, push depth into `references/`. But
  a lone reference under ~250 lines that is not a living log or fork-injected index belongs inline.
- Rarely needed or rule-triggered skills → `disable-model-invocation: true`: the description leaves
  the listing entirely; load with `/name`, or have a rule or CLAUDE.md pointer say to **Read** the
  SKILL.md path. Background articles → `user-invocable: false` (⚠ description still loads).
  ⚠ `paths:` on a skill gates auto-invocation only, never the listing cost.

## Self-improvement is mandatory

- A change to a scope updates its owning doc in the same change — never a follow-up task.
- A surprise, wrong assumption, or debugging cycle a doc should have prevented is a **documentation
  defect**. Fix the doc in the same turn, and say that you did.
- Recurring friction with a skill, rule, hook, or MCP server → improve the artifact; do not work
  around it a second time.
- A new scope earns a skill plus one CLAUDE.md glossary line. Cut cruft on sight.
