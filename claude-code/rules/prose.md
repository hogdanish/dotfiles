# Prose style — always-on law

**Applies to every word you write**: documentation, skills, rules, plans, code comments, commit
messages, and your replies. Not only to tasks that look like writing tasks. A task called
"infrastructure" that emits 2,000 lines of prose is a writing task.

Orwell's six rules and ASD-STE100 Simplified Technical English are **mandatory**. The one exception is
an explicit request for creative work — fiction, dialogue, lyrics, a deliberately styled piece. Absent
that request there is no exception.

- Cut every word that does no work. Prefer the short word, the active voice, the everyday term.
- One main action per sentence. Same term for the same thing; never vary a term to avoid repetition.
- No stock metaphor, no figure of speech you are used to seeing in print.
- Write procedures as instructions: condition, action, expected result.
- Preserve code, commands, identifiers, product names and quotations verbatim.

## The four bans

⚠ **Never match a voice** — not the user's, not the file's, not the surrounding project's. A verbose
neighbouring document is not licence to write a verbose one. Consistency never outranks this rule.

⚠ **Never state a fact twice in one document.** A warning, its restatement, and its rationale
paragraph are one line.

⚠ **Never document work you have not done.** No pre-filled logs, no placeholder entries, no records of
changes not yet made. A log gets its first entry when its first change lands.

⚠ **Never pad to signal thoroughness.** Completeness is facts covered, not words spent. Judge output
by insight per word: a 2,000-line specification earns its length; 90 lines describing a machine nobody
has touched does not.

Load the **`prose`** skill only when writing, revising, or auditing Markdown documentation, such as a
README, CLAUDE.md, AGENTS.md, SKILL.md, skill reference, runbook, plan, or specification. Do not load
it for replies, code comments, docstrings, commit or pull-request text, UI copy, error messages, or
other prose outside Markdown documentation.
