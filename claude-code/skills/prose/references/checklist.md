# Documentation verification checklist

Run this pass on every draft before delivery. Ignore matches inside code blocks, inline code, quoted
errors, legal text, and required quotations.

## Mechanical checks

| Search for | Violation | Fix |
| --- | --- | --- |
| `'ll`, `'re`, `'ve`, `n't`, `it's` | Contraction (Rule 4.2) | Expand it. |
| `has been`, `have been`, `had been` | Perfect tense (Rule 3.4) | Use simple past or present. |
| `has` or `have` plus a past participle | Perfect tense (Rule 3.4) | Use simple past. |
| `should`, `would`, `may`, `might`, `could` | Unapproved modal (Rule 3.2) | Use the modal table in `asd-ste100.md`. |
| `is being`, `are being`, `was being` | Progressive passive (Rules 3.4 and 3.5) | Use active voice and a simple tense. |
| `, making`, `, allowing`, `, enabling`, `, ensuring` | `-ing` clause as a verb (Rule 3.5) | Start a new sentence with a subject. |
| `;` | Semicolon (Rule 8.1) | Use two sentences. |
| `e.g.`, `i.e.`, `etc.` | Latin abbreviation (GR-6) | Write the full phrase or name the items. |
| `simply`, `easily`, `seamlessly`, `robust` | Filler | Delete it or give a measurable fact. |
| ` if ` or ` when ` in a procedure | Trailing condition (Rule 5.4) | Move the condition before the command. |

## Countable checks

1. Count the words in each sentence. The procedural limit is 20. The descriptive limit is 25.
2. Use no more than six sentences in a descriptive paragraph (Rule 6.6).
3. Break noun chains longer than three words with prepositions (Rule 2.1).
4. Give one instruction per sentence unless the actions occur at the same time (Rule 5.2).

Backticked commands, numbers with units, identifiers, and quoted text count as one word each (Rule
8.6).

## Judgment checks

1. Classify each passage as procedural or descriptive.
2. Use an imperative only in procedural text.
3. Use passive voice only in descriptive text when the actor is unknown (Rule 3.6).
4. Put each condition before its command (Rule 5.4).
5. Use one term for each concept throughout the document (Rules 1.11 and 9.4).
6. Put a warning's command or condition before its risk (Rules 7.2 and 7.3).
7. Keep articles and `that`. Do not use telegraphic grammar (Rule 4.2).
8. Preserve every untouchable item.
9. Preserve every fact required by the `SKILL.md` preservation contract.
10. Remove repeated facts, stock phrases, self-justifying asides, and speculative records.

## Audit reports

For each violation, give the rule number, the source text, and a compliant rewrite. Cite only rule
numbers in `asd-ste100.md`.

If the user asks for STE compliance, end with this statement: "No tool can guarantee ASD-STE100
compliance. Final approval rests with the writer. The official standard is available from
asd-ste100.org."

This checklist adapts material from
[SimpleEnglish](https://github.com/AminBlg/SimpleEnglish/tree/main/skills/simple-english), copyright
2026 AminBlg, used under the MIT License. See `../LICENSE-SimpleEnglish.txt`.
