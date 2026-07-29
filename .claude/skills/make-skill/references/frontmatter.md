# SKILL.md frontmatter — the complete reference

Distilled from code.claude.com/docs/en/skills + /en/sub-agents. All fields optional; only `description`
is recommended. YAML between `---` markers at the top of `SKILL.md`.

## Fields

| Field | Purpose / notes |
| --- | --- |
| `name` | Display name in listings. Defaults to the directory name; the command you type (`/name`) comes from the **directory**, not this field. Keep it = dir name. |
| `description` | *What the skill does* + the primary use case first. Claude matches against this to auto-invoke. Combined with `when_to_use`, truncated at **1,536 chars** in the listing. |
| `when_to_use` | *When to load it* — trigger phrases, example requests, and the boundary with neighbour skills. Appended to `description`; counts toward the same 1,536-char cap. |
| `argument-hint` | Autocomplete hint, e.g. `[skill-name]` or `[filename] [format]`. |
| `arguments` | Named positional args for `$name` substitution. Space-separated string or YAML list; names map to positions in order. |
| `disable-model-invocation` | `true` = only the user can invoke it (`/name`); **its description leaves Claude's context** (frees listing budget) and it won't preload into subagents or fire from a scheduled task. Use for side-effectful commands. Default `false`. |
| `user-invocable` | `false` = hidden from the `/` menu; Claude-only background knowledge. **Description still stays in context.** Default `true`. |
| `allowed-tools` | Tools pre-approved (no permission prompt) while the skill is active. Space/comma string or YAML list. Doesn't restrict the pool. |
| `disallowed-tools` | Tools removed from the pool while active (clears on your next message). |
| `model` | Model override for the rest of the turn: `sonnet`/`opus`/`haiku`/`fable`/full-id/`inherit`. |
| `effort` | `low`/`medium`/`high`/`xhigh`/`max` — overrides session effort while active. |
| `context` | `fork` = run the skill in a forked subagent; the SKILL.md content becomes the subagent's prompt (no main-conversation history). |
| `agent` | Which subagent type when `context: fork` — `Explore`, `Plan`, `general-purpose`, or a custom `.claude/agents/` type. Defaults to `general-purpose`. |
| `hooks` | Hooks scoped to this skill's lifecycle. |
| `paths` | Globs that gate **auto-invocation** to matching file work (same format as path-specific rules). Comma string or YAML list. Does not hide the description. |
| `shell` | `bash` (default) or `powershell` for `` !`cmd` `` injection. |

## Invocation matrix

| Frontmatter | You invoke | Claude invokes | Description in context |
| --- | --- | --- | --- |
| (default) | yes | yes | yes |
| `disable-model-invocation: true` | yes | no | **no** |
| `user-invocable: false` | no | yes | yes |

Rule of thumb here: subsystem articles → `user-invocable: false`, do not use `paths:`. Cookbooks/lookups → default.
Side-effectful workflows → `disable-model-invocation: true`.

## String substitutions (in body and `allowed-tools`)

`$ARGUMENTS` (all args; auto-appended as `ARGUMENTS: …` if absent) · `$ARGUMENTS[N]` / `$N` (0-based) ·
`$name` (a declared `arguments:` entry) · `${CLAUDE_SESSION_ID}` · `${CLAUDE_EFFORT}` ·
`${CLAUDE_SKILL_DIR}` (this skill's dir — use it to reference bundled files/scripts) ·
`${CLAUDE_PROJECT_DIR}` (repo root). Escape a literal with `\$`.

## Dynamic context injection

`` !`command` `` (inline, at line start or after whitespace) or a ` ```! ` fenced block runs the shell
command **before** Claude sees the content and replaces the placeholder with its output. Runs once, not
re-scanned. For a forked skill this executes at fork time, so injected content reaches the subagent, not
the main context.

## The `context: fork` lookup recipe (used by `find-*`)

```yaml
---
name: find-thing
description: Pick a <thing> from the <library>. Returns the exact <artifact> to paste.
when_to_use: When adding/authoring something that needs a <thing>; Claude delegates the pick so the index never loads into the main context.
context: fork
agent: Explore            # Haiku, read-only, skips CLAUDE.md — cheapest possible
argument-hint: [what it's for]
allowed-tools: Read
---
## Index
```!
cat ${CLAUDE_SKILL_DIR}/references/thing-index.md
```
Pick the single best match for **$ARGUMENTS** and return ONLY `<the exact artifact string>`.
```

Why Explore: it's Haiku, read-only, and skips CLAUDE.md/git — strictly cheaper than any custom agent
(which loads CLAUDE.md). Only build a custom `.claude/agents/` type if the fork needs tools Explore lacks.

⚠ Use `$ARGUMENTS` (the full typed string), **not** a named `arguments: [description]` positional, for a
free-text argument. Named/indexed positionals are shell-tokenized, so `$description` captures only the
first word ("a breakable crate" → "a"). `$ARGUMENTS` always expands to the whole argument as typed.

## Budgets & lifecycle

- Keep `SKILL.md` a lean overview; docs cap it at <500 lines. Once invoked, the whole body stays in
  context for the session (re-attached after compaction within a 25k-token pool) — every line recurs.
- Put API tables/catalogues/specs in `references/*.md`, each linked with a one-line "what/when".
- `description`+`when_to_use` ≤1,536 chars, key use first (the listing budget scales at ~1% of the model
  context; overflow shortens least-used skills first — run `/doctor` to see shortening).

## Custom subagent frontmatter (`.claude/agents/*.md`), for reference

`name`, `description` (required) · `tools` / `disallowedTools` · `model` (default `inherit`) · `effort` ·
`skills` (preload full skill bodies) · `permissionMode` · `maxTurns` · `memory` (`user`/`project`/`local`
cross-session) · `mcpServers` · `hooks` · `color`. Only Explore and Plan skip CLAUDE.md; all other agents
(built-in and custom) load it.