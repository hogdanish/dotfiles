---
name: make-skill
description: Create a new project skill or improve an existing one — fill placeholder reference files, distill a subsystem into a lean SKILL.md, and apply the correct frontmatter (description/when_to_use split, invocation control, paths, context:fork for lookups, supporting files). Run /make-skill <skill-name>.
disable-model-invocation: true
argument-hint: [skill-name]
arguments: [skill]
allowed-tools: Read, Grep, Glob, Edit, Write, Bash(ls*), Bash(wc*)
---

# make-skill — write and fill project skills

Author or improve the skill named **`$skill`**. This is the tool that turns a scaffolded skill (complete
SKILL.md + placeholder `references/*.md`) into a finished article. It knows every skill capability; the
architecture doctrine it obeys lives in `claude-framework` (read it if you're unsure where content
belongs — don't restate it here).

## Reference material

- [frontmatter.md](references/frontmatter.md) — the complete frontmatter field table, the invocation
  matrix, string substitutions, the `context: fork` lookup recipe, and line/char budgets. Read it before
  writing frontmatter.
- [templates.md](references/templates.md) — copy-paste templates: a subsystem SKILL.md, a reference file,
  a `find-*` lookup skill, and a custom subagent. Start from the matching one.

## Procedure

1. **Locate.** Read `.claude/skills/$skill/SKILL.md` and every file under `.claude/skills/$skill/references/`.
   Note which reference files are placeholders (contain `FILL:` markers) — those are the work.
2. **Map the subsystem.** `paths:` are not used in skills, Grep/Glob the real files: list the `class_name`s,
   what they extend, the autoloads, the seams, and the ⚠ gotchas. The codebase is ground truth, not the
   old `.claude/skills_old/` copy (use it only as a hint — it may be stale or wrong).
3. **Research when version-sensitive.** For a third-party addon or a Godot API whose behaviour matters,
   pull current docs via Context7 (`resolve-library-id` → `query-docs`) rather than trusting memory.
   ⚠ For local addon *forks* (CLog, godot_mcp), author from the **source**, not the bundled README — the
   README documents upstream and can be wrong (CLog's `o/e/w/v/c` API no longer exists here).
4. **Distill.** Keep `SKILL.md` a lean overview: the system in a paragraph, each seam/gotcha in a line,
   and a one-line "what/when" pointer to each reference file. Move API tables, catalogues, and long specs
   into `references/*.md`. Every line in a SKILL.md is a recurring token cost once loaded — cut ruthlessly.
5. **Frontmatter.** Apply [frontmatter.md](references/frontmatter.md): split `description` (what) from
   `when_to_use` (when/trigger phrases/boundary), set the invocation flag (`user-invocable:false` for a
   background article, `disable-model-invocation:true` for a side-effectful command, both off otherwise),
   set `paths:` for a subsystem skill, and `context: fork`+`agent: Explore` for a lookup.
6. **Verify.** `description`+`when_to_use` ≤1,536 chars; every `references/*.md` is linked from SKILL.md;
   no `FILL:` markers remain in a finished file; the footer names the domain. If you changed what the
   skill covers, update its CLAUDE.md glossary line in the same change.

## Writing standards

- Name real artifacts (classes, autoloads, files, constants) — a description of "the audio system" won't
  trigger; "PhysicsAudio, WorldAudio/UIAudio pools, ScrapeVoice" will.
- Say where a neighbour's boundary is ("sourcing clips is `find-sound`; this is playback") so skills stop
  overlapping.
- Preserve every ⚠ gotcha verbatim from the source you distil — those are the expensive-to-rediscover bits.
- Match the house voice: dense, lowercase-comment, imperative, no filler.

---
*Source of truth for skill authoring — update it (and [frontmatter.md](references/frontmatter.md)) when
Claude Code's skill features change.*