# Context architecture

How to organize what Claude reads — in this repository and any other. It is doctrine, not procedure:
`skill-creator` (plugin) does the authoring, this decides what should exist and where content sits.

## The layers

| Layer | Role | Loads |
| --- | --- | --- |
| `CLAUDE.md` | **Router** — overview, always-on conventions, and one glossary *line* per scope pointing at its skill. Never paragraphs of subsystem detail. | every session, in full |
| `.claude/rules/*.md` | **Law** — short imperative behaviour. Unscoped loads always; `paths:` frontmatter gates it to matching files. | every session / on matching file touch |
| `.claude/skills/*/SKILL.md` | **Articles** — the source of truth for one scope; lean overview plus pointers. | description always, body on invocation |
| `.claude/skills/*/references/*.md` | **Depth** — API tables, catalogues, specs, append-only logs. | on demand, when its SKILL.md points at it |
| memory store | Workflow and feedback learnings only. Project facts belong in a skill, where they are version-controlled. | index every session |

**Precedence: the owning skill wins.** When CLAUDE.md, a rule, or a neighbouring skill contradicts it,
fix every copy in the same change. Never write "CLAUDE.md is the source of truth" anywhere.

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

## Writing a skill

- **Push depth into `references/`.** A SKILL.md body is a recurring cost once loaded; a reference file
  is free until pointed at. Keep the body an overview — the scope in a paragraph, each seam and gotcha in
  a line, a one-line what/when pointer per reference. ⚠ Don't split off a lone small reference: a single
  file under ~250 lines that isn't a living log or a fork-injected index belongs inline.
- **Name real artifacts** — classes, files, commands, constants. "The audio system" won't trigger;
  naming the actual types and paths will.
- **State the neighbour's boundary** ("sourcing clips is X, this is playback") so skills stop overlapping.
- **Preserve ⚠ gotchas verbatim** from whatever you distil — those are the expensive-to-rediscover bits.
- `description` = what it covers; `when_to_use` = when to load, trigger phrases, boundary. Combined
  ≤1,536 chars, key case first, because it truncates there.
- Picking one item out of a large index → `context: fork` + `agent: Explore`, with the index injected at
  fork time so it reaches the subagent and never the main context.

## Self-improvement is mandatory

- **A change to a scope updates its owning doc in the same change** — skill, rule, glossary line, README.
  Never a follow-up task.
- A surprise, a wrong assumption, or a debugging cycle that a doc should have prevented is a
  **documentation defect**. Fix the doc that was wrong in the same turn, and say that you did.
- Recurring friction with a skill, rule, hook or MCP server → improve the artifact. Don't quietly work
  around it a second time.
- A new scope earns a new skill plus one CLAUDE.md glossary line. Cut cruft on sight.
