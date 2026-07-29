---
name: claude-framework
description: How this repo organizes context for Claude Code — the encyclopedia model (CLAUDE.md = router, .claude/rules = always-on law, .claude/skills = source-of-truth articles, references/ = on-demand depth), the skill map, invocation-control and line budgets, and the self-improvement mandate.
when_to_use: Read before creating or restructuring a skill/rule/hook, when a subsystem outgrows its skill, when CLAUDE.md and a skill disagree, or when deciding whether a new piece of guidance is a rule, a skill, a reference file, a hook, or a memory. For the step-by-step of writing one, use make-skill.
---

# Claude framework — how context is organized here

This repo treats Claude's context like an encyclopedia: a thin router that's always loaded, and deep
articles that load only when relevant. Follow this whenever you touch `.claude/` or `CLAUDE.md`.

## The encyclopedia model

| Layer                              | Role                                                                                                                                           | Loads                                             |
| ---------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------- |
| `CLAUDE.md`                        | **Router/glossary** — project overview, always-on conventions, autoloads table, one glossary line per subsystem → its skill. ≤200 lines, hard. | Every session, in full                            |
| `.claude/rules/*.md`               | **Always-on law** — short imperative rules. Unscoped = every session; `paths:` frontmatter gates to matching file work.                        | Every session (unscoped) / on matching file touch |
| `.claude/skills/*/SKILL.md`        | **Articles** — the source of truth for one subsystem; a lean overview + pointers. Cookbooks are invocable.                                     | Description always; body on invocation            |
| `.claude/skills/*/references/*.md` | **Depth** — API tables, catalogues, specs. Linked from a SKILL.md with a one-line "what/when".                                                 | On demand, when the SKILL.md points Claude to it  |
| Memory store                       | Workflow/feedback learnings only. **Project facts belong in skills** (version-controlled).                                                     | Index every session                               |

**Precedence:** a skill is the source of truth for its subsystem. If a CLAUDE.md glossary line, a rule,
or another skill disagrees with the owning skill, the owning skill wins — fix every copy in the same
change. Never write "CLAUDE.md is the source of truth" or "defers to CLAUDE.md" anywhere.

## Where does a new piece of guidance go?

1. **Needed in ≥90% of sessions, behavioural, short** → an unscoped rule in `.claude/rules/`. CLAUDE.md
   itself only gets glossary lines, never paragraphs.
2. **How a subsystem works** (seams, gotchas, API) → the owning subsystem skill (lean) + its `references/`.
3. **A repeatable procedure** (add-a-X, author-a-skill) → an invocable cookbook skill.
4. **Sourcing one item from a big library** (an icon, a sound, an fx) → a `find-*` fork lookup (below).
5. **Must happen deterministically every time** (a check, a cleanup) → a hook + `.claude/settings.json`.
   Prose is a request; a hook is a guarantee.
6. **A correction about how _you_ should work** (user feedback, workflow) → the memory store.

Always look for opportunities to author a new skill and suggest them to the user when relevant.

## The skill map

**Meta:** `claude-framework` (this — doctrine) · `make-skill` (the `/command` to write/fill a skill) ·
`addon-godot-mcp` (MCP fork pitfalls + friction log).
**Lookups** (`context: fork` → Haiku Explore, return one pick): `find-class-icons` · `find-sound` · `find-fx`
· `find-texture`.
**Platform:** `app-platform` (shell/scene-flow/loading/window/settings/chat-transport/names/FSM base) ·
`app-input` (input/cursor) · `addon-newgrounds` (NG.io + identity + login).
**Gameplay:** `game-audio` · `game-surfaces` · `game-vfx` · `game-entities` (entity core, spawn, props,
vehicles, rope, health, interaction, physics layers) · `game-characters` (character/player/npc, puppet,
cosmetics, toys) · `addon-phantom-camera` (Phantom Camera + PlayerCameraRig + menu pcams) · `game-movement`
(movement/posture on statecharts) · `addon-statecharts` (the vendored godot-statecharts addon manual) ·
`game-environment` (day/night, sky, city, water) · `game-events`.
**UI & cross-cutting:** `ui` (theme, HUD, chat widgets, labels, popups) · `addon-theme-gen` (the ThemeGen
addon — GDScript-authored `.tres` theme generator) · `app-commands` (the command
system) · `app-multiplayer` (netcode contract + seams) · `addon-clog` (CLog) · `addon-debug-draw` (DebugDraw3D).

Boundaries that were historically muddy: surfaces owns the _material data model_, audio owns _playback_;
water lives in environment though its files are under `surfaces/water/`; physics layers live in entities;
chat transport is app-platform, chat widgets are `ui`, the command tree is `app-commands`.

## Invocation control (stop skills firing "left and right")

- **Background article** → `user-invocable: false`. Claude loads it when relevant; not a `/` command.
- **Manual command** → `disable-model-invocation: true`. Only the user triggers it (`/make-skill`);
  its description leaves Claude's context entirely (frees budget). Use for side-effectful workflows.
- **Both** (default) → leave the flags off (cookbooks like `app-commands`, lookups like `find-class-icons`).
- **`paths:`** gates _auto-invocation_ to relevant files — do not use
- **`description` vs `when_to_use`:** `description` = _what it covers_ (name the real classes/files);
  `when_to_use` = _when to load / trigger phrases + where the boundary with a neighbour is_. Both terse.

## The lookup-fork pattern (`find-*`)

A lookup skill picks one item from a large index without spending the main agent's context or model on it:
`context: fork` + `agent: Explore` (Haiku, read-only, skips CLAUDE.md), a free-text `$ARGUMENTS` description, and a
` ```! ` block that injects the index (`cat ${CLAUDE_SKILL_DIR}/references/<index>.md`) at fork time so it
reaches the subagent, never the main context. The fork returns only the chosen artifact. `find-class-icons` is
the reference implementation; mirror it.

## Budgets

- `SKILL.md` body: a lean overview; push API tables/catalogues to `references/*.md` **when there are
  several or one is large**. ⚠ **Don't split off a lone small reference** — if a skill would have exactly
  one `references/` file and it isn't large (≳250 lines), a *living/append log* (e.g. a friction log), or a
  *fork-injected index* (`find-*`), inline it into the `SKILL.md` instead. A thin body that defers
  everything to a single small ref is pointless indirection. (Docs cap: <500 lines.)
- `description` + `when_to_use`: ≤1,536 chars combined, key use case first (it's truncated there).
- `CLAUDE.md`: ≤200 lines, glossary lines not paragraphs.
- All unscoped rules together: keep under ~80 lines — they're a shared always-on cost.

## Self-improvement mandate

- A change to a subsystem updates its owning skill **in the same change**; a new subsystem gets a new
  skill (`make-skill`) + one CLAUDE.md glossary line.
- Recurring friction with a skill/rule/hook/MCP → improve the artifact, don't work around it silently.
  Log Godot-MCP friction in `addon-godot-mcp/references/friction-log.md` (mandate: `rules/mcp.md`).
- Cut cruft on sight. Keep `CLAUDE.md` a router.

## Hard don'ts

- Don't restate what the Godot MCP server auto-injects every session (editor-vs-runtime split,
  `_mcp_print`, generic pitfalls) — project files hold only project deltas (`addon-godot-mcp` skill).
- Don't duplicate the global `gdscript` rule/skill; layer project law on top (`rules/gdscript-project.md`).
- Don't store project facts in the memory store — put them in the owning skill.
- Don't grow `CLAUDE.md` past ~200 lines or add multi-paragraph subsystem detail to it.

---

_Source of truth for the framework itself — update it when the conventions evolve._