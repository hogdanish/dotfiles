# Skill templates — copy the matching one

## Subsystem article (background, paths-gated)

```markdown
---
name: game-<subsystem>
description: <What it covers — name the real classes/autoloads/files.> <Primary use case first.>
when_to_use: Load when touching <files/systems>. <Boundary with a neighbour: "sourcing X is find-X; this is Y.">
user-invocable: false
---

# <Subsystem>

<One-paragraph overview: what the system is and its entry points/autoloads.>

## <Topic> / <Seam>
- <Dense factual lines. Every ⚠ gotcha kept verbatim from the source.>

## Reference material
- [<topic>.md](references/<topic>.md) — <what's in it, when to read it>.

---
*Source of truth for <domain> — update in the same change as the code.*
```

## Reference file (placeholder to be filled by make-skill)

```markdown
# <Skill> — <topic>

FILL: <one line on what this reference must contain and its source (files to read / addon / Context7 lib).>

## <Section>
FILL: <the table/catalogue/spec that belongs here — kept out of SKILL.md because it loads on demand.>
```

## Lookup skill (`find-*`)

See [frontmatter.md](frontmatter.md) → "The `context: fork` lookup recipe". Mirror `find-class-icons` exactly:
`context: fork` + `agent: Explore`, inject `references/<index>.md` via a ` ```! ` block, return only the
artifact. The index reference file is the only real content; the SKILL.md is a thin shell.

## Cookbook (invocable procedure, no fork)

```markdown
---
name: <verb-noun>
description: <The procedure and when to run it.>
argument-hint: [<arg>]
---

# <Verb noun>

<Numbered steps. Point at the owning subsystem skill for "how the system works" instead of restating it.>
```

## Custom subagent (`.claude/agents/<name>.md`) — only if a fork needs tools Explore lacks

```markdown
---
name: <name>
description: When to delegate to this agent.
tools: Read, Grep, Glob
model: haiku
---

<System prompt: the agent's job, its output contract, its constraints.>
```