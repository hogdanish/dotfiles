# Context architecture

How to organize what Claude reads — in this repository and any other. It is doctrine, not procedure:
authoring mechanics belong to each project's authoring skill (e.g. `skill-creator`, a project's
`make-skill`); this decides what should exist and where content sits.

## The layers

| Layer | Role | Loads |
| --- | --- | --- |
| `CLAUDE.md` | **Router** — overview, always-on conventions, and one glossary *line* per scope pointing at its skill. Never paragraphs of subsystem detail. | every session, in full |
| `.claude/rules/*.md` | **Law** — short imperative behaviour. Unscoped loads always; `paths:` frontmatter gates it to matching files. | every session / on matching file touch |
| `.claude/skills/*/SKILL.md` | **Articles** — the source of truth for one scope; lean overview plus pointers. `paths:` works here too, gating auto-invocation. | description always, body on invocation |
| `.claude/skills/*/references/*.md` | **Depth** — API tables, catalogues, specs, append-only logs. | on demand, when its SKILL.md points at it |
| memory store | Workflow and feedback learnings only. Project facts belong in a skill, where they are version-controlled. | index every session |

**Precedence: the owning skill wins.** When CLAUDE.md, a rule, or a neighbouring skill contradicts it,
fix every copy in the same change — by deleting the duplicate, not syncing it. Never write "CLAUDE.md
is the source of truth" anywhere.

## Where new guidance goes

1. **Behavioural, short, needed in most sessions** → an unscoped rule. Add `paths:` the moment it only
   concerns certain files. All unscoped rules are a shared always-on tax — keep the set lean.
2. **How a scope works** (seams, gotchas, API) → its skill, lean, plus `references/`.
3. **A repeatable procedure** → an invocable skill.
4. **Must happen every time, without relying on judgement** → a hook in `settings.json`. Prose is a
   request; a hook is a guarantee.
5. **A correction about how _you_ should work** → the memory store.

⚠ CLAUDE.md is the tempting default and almost always the wrong one. Growing it past ~200 lines is how a
router becomes a document nobody can afford to load.

## Skill frontmatter and bodies (the budget rules)

- **One `description` field per skill, ≤500 chars** — what it covers (real classes, files, commands) +
  when to load + the one boundary with a neighbour, key use case first. Do not split into
  `when_to_use`; Claude Code appends it to `description` and the twin fields drift. The skill listing
  is budgeted (~1% of context); overflow silently drops least-invoked skills' descriptions — `/doctor`
  reports the cost.
- A loaded body persists all session — keep it a lean overview, push depth into `references/`. But
  don't split off a lone small reference: a single file under ~250 lines that isn't a living log or a
  fork-injected index belongs inline.
- Background articles → `user-invocable: false`; user-triggered workflows →
  `disable-model-invocation: true` (removes the description from the listing entirely).
- Per-skill authoring mechanics (templates, substitutions, fork lookups) → the project's authoring
  skill, not this rule.

## Self-improvement is mandatory

- **A change to a scope updates its owning doc in the same change** — skill, rule, glossary line, README.
  Never a follow-up task.
- A surprise, a wrong assumption, or a debugging cycle that a doc should have prevented is a
  **documentation defect**. Fix the doc that was wrong in the same turn, and say that you did.
- Recurring friction with a skill, rule, hook or MCP server → improve the artifact. Don't quietly work
  around it a second time.
- A new scope earns a new skill plus one CLAUDE.md glossary line. Cut cruft on sight.
