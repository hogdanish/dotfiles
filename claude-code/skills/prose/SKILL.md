---
name: prose
description: Write, rewrite, or audit Markdown documentation under Orwell's six rules and ASD-STE100 Simplified Technical English. Use only for documentation in `.md` files, including README.md, CLAUDE.md, AGENTS.md, SKILL.md, skill references, runbooks, plans, and similar project docs. Do not invoke for chat replies, code comments or docstrings, commit messages, pull-request text, UI or error messages, source-code strings, marketing copy, fiction, or prose in non-Markdown files.
---

# prose — clear technical English, enforced

The always-on `prose` rule supplies a light style baseline. This skill supplies the documentation
workflow, the full writing rules, and the audit process.

## Scope

Use this skill only when the output is Markdown documentation. A Markdown document includes
repository instructions, skill files and references, READMEs, runbooks, plans, specifications,
architecture notes, and other project documentation.

Do not load this skill only because a task includes prose. Code comments, docstrings, commit messages,
pull-request descriptions, chat replies, interface copy, error messages, string literals, blogs,
marketing copy, and creative writing are outside its automatic scope. Apply the always-on prose rule
to those targets without loading this skill.

## Required reading (mandatory)

Read both references before drafting, rewriting, or auditing documentation:

- `references/asd-ste100.md` contains the two modes, text classification, all 53 distilled rules,
  vocabulary discipline, and untouchables.
- `references/checklist.md` contains the final mechanical and judgment checks.

## Invoking

| Ask | What runs |
| --- | --- |
| `/prose write path/to/doc.md` | Draft Markdown documentation. |
| `/prose rewrite ~/x/y.md` | Revise one Markdown document. |
| `/prose rewrite all skills starting with addon-` | Batch audit — resolve the glob, rewrite each file, report a table. |
| `/prose audit <glob>` | Report only. Find offenders, rank them, change nothing. |

## The rules

**Orwell.** (1) No metaphor or figure of speech you are used to seeing in print. (2) Never a long word
where a short one will do. (3) If a word can be cut, cut it. (4) Never the passive where the active
works. (5) No foreign, scientific or jargon term when an everyday English one exists. (6) Break any of
these sooner than write something barbarous.

**ASD-STE100.** Use pragmatic mode by default. Use strict mode only when the user names STE,
ASD-STE100, compliance, or strict mode. The complete rule catalog and mode definitions are in
`references/asd-ste100.md`.

⚠ STE has a controlled dictionary. Do not claim strict conformance without checking the current issue.

## Anti-patterns

Each of these was found in real output. The fix is always shorter and loses nothing.

**The triple statement.** A warning, a restatement, and a rationale paragraph carrying the same fact.
> ⚠ **UDP publishing is the other Docker trap.** `-p 4433:4433` publishes **TCP**, and yields a relay that starts cleanly, logs nothing, and is unreachable. It must be `-p 4433:4433/udp`.

→ `⚠ `-p 4433:4433` publishes TCP. QUIC needs `/udp`; the wrong one starts cleanly and never receives.`

**The self-justifying aside.** "worth naming rather than discovering", "worth understanding rather
than re-litigating", "recorded so it is not a surprise", "this is not paperwork". Delete. State the
fact; the reader decides whether it is worth anything.

**The heading that repeats itself.** A section titled *Why X matters*, whose first sentence is "X
matters because…". Cut the sentence.

**Speculative documentation.** A change log with entries for changes not made. A reference describing
an account model that does not exist. Write the record when the work lands, not before. If a document
must exist first, it is a plan, and it belongs with the plans.

**Padding that signals effort.** Restating a decision's rationale after already giving it. Listing
what you deliberately did not do, at length, when one line does it. Explaining a trade-off twice, once
as prose and once as a warning.

**Stock phrases.** "costs an hour if you meet it cold", "the layer that actually holds", "is not
negotiable", "security theatre", "the whole point is", "boring and reversible". These read as
authoritative and carry no information.

**Em-dash aside chains.** More than one parenthetical aside per sentence means the sentence is two
sentences.

**Hedged fact.** "This is arguably the right approach in most cases." Either it is, or say what it
depends on.

## Drafting

1. Name the audience, the purpose, and the one question the document answers.
2. Write the facts. No preamble, no framing paragraph, no summary of what follows.
3. Cut: stock phrases, dead metaphors, filler, pompous diction, avoidable jargon.
4. Check every sentence adds a fact the reader did not have.
5. Keep nuance. Short is not the goal — insight per word is. Do not make prose crude or false to
   shorten it.

## Revising one file

1. Read the whole file first. Never revise a fragment.
2. Extract the fact set (below). This is what must survive.
3. Rewrite. Prefer deleting a sentence to compressing it.
4. Verify the fact set is unchanged.
5. Report: lines before → after, and the fact-set check.

### The preservation contract

A rewrite must lose **nothing**. These survive verbatim:

- every command, code block, path, identifier, file name, URL, version and number
- every ⚠ warning, and the failure mode it names
- every date, decision, attribution and cross-reference
- every "verified" vs "reasoned" tag, and any status marker

**The test**: a reader of the new version can answer every question the old version answered. If a
fact cannot survive compression, keep it long.

**The check** — compare extracted facts, not prose:

```bash
extract() { rg -o '`[^`]+`|https?://\S+|\b\d[\d.,_]*\b' "$1" | sort -u; }
diff <(extract old.md) <(extract new.md)
```

Anything that disappears must be a duplicate. Investigate every other removal.

## Auditing many files

For `rewrite all skills starting with addon-` and similar:

1. **Resolve and report the target set before touching anything.**
   ```bash
   fd -e md . .claude/skills --glob 'addon-*/**' | xargs wc -l | sort -rn
   ```
   Show the user the file list and line counts. Confirm the set if it is larger than expected.
2. **Rank by likely waste**, not by size. A 2,000-line specification may be correct; a 90-line
   reference for a system with three moving parts is not.
3. **One subagent per file** when the set exceeds three files. Each rewrite needs the whole file in
   context, and the fact-set check is per file. Give each agent this skill's preservation contract and
   the single-file workflow.
4. **Never batch-edit with a regex.** Prose compression is judgement, not substitution.
5. **Report a table**: file, lines before, lines after, percent cut, facts lost (must be `0`).
6. Stop and ask if any file needs a structural change — a split, a merge, a deletion. That is a
   different decision and belongs to the user.

## Final check

Run every applicable check in `references/checklist.md`. If the user asks for strict STE compliance,
state that no tool can guarantee compliance and that the official ASD-STE100 dictionary controls the
final result.
