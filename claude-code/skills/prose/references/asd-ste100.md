# ASD-STE100 rule catalog for software documentation

This reference distills the 53 writing rules in ASD-STE100 Issue 9 for Markdown documentation. It
adapts the SimpleEnglish skill for this `prose` skill. It does not reproduce the controlled
dictionary.

## Contents

- [Modes](#modes)
- [Classify the text](#classify-the-text)
- [Rule catalog](#rule-catalog)
- [Vocabulary discipline](#vocabulary-discipline)
- [Untouchables](#untouchables)
- [Limits](#limits)

## Modes

| Mode | Use | Rules |
| --- | --- | --- |
| Pragmatic (default) | Ordinary Markdown documentation | Apply all structural rules. Keep necessary domain terms such as `idempotent` and `webhook`. |
| Strict | The user names STE, ASD-STE100, compliance, or strict mode | Apply all structural rules and full vocabulary discipline. State that final compliance needs the official dictionary. |

Before drafting, choose one term for each concept and use it throughout the document. For example,
choose one of `config`, `configuration`, or `settings`. In strict mode, use `make sure that` for the
check, verify, confirm, or ensure concept.

## Classify the text

Classify each passage before writing it. Do not mix procedural and descriptive text in one passage.

| | Procedural | Descriptive |
| --- | --- | --- |
| Purpose | Tell the reader what to do | Explain what a thing is or does |
| Verb form | Imperative | Simple present, past, or future |
| Sentence limit | 20 words (Rule 5.1) | 25 words (Rule 6.3) |
| Unit | One instruction per sentence (Rule 5.2) | One topic per paragraph (Rule 6.5) |

A getting-started section is procedural. An architecture section is descriptive. A note inside a
procedure is descriptive and has the 25-word limit.

## Rule catalog

### 1. Words (Rules 1.1-1.14)

| Rule | Instruction |
| --- | --- |
| 1.1 | Use only approved words, technical nouns, or technical verbs. |
| 1.2 | Use an approved word only as its listed part of speech. |
| 1.3 | Use an approved word only with its approved meaning. |
| 1.4 | Use only the approved forms of verbs and adjectives. |
| 1.5 | Use domain words as technical nouns, for example `webhook`, `commit`, and `endpoint`. |
| 1.6 | Use an unapproved word only when it is a technical noun or part of one. |
| 1.7 | Do not use technical nouns as verbs. |
| 1.8 | Use the technical nouns of the project or industry. |
| 1.9 | Choose a short, clear technical noun. |
| 1.10 | Do not use regional, slang, or jargon words as technical nouns. |
| 1.11 | Use one name for one item. Do not alternate between `config` and `settings`. |
| 1.12 | Use domain verbs as technical verbs, for example `deploy`, `compile`, and `merge`. |
| 1.13 | Do not use technical verbs as nouns. |
| 1.14 | Use American English spelling unless the project requires another form. |

Rules 1.5, 1.8, and 1.12 permit necessary software terms in pragmatic mode. Rules 1.7, 1.11, and
1.13 prevent unclear term changes.

Before: You can webhook the event, then do a deploy.

After: Send the event to the webhook. Then deploy the service.

### 2. Multi-word nouns (Rules 2.1-2.2)

| Rule | Instruction |
| --- | --- |
| 2.1 | Write multi-word nouns of three words or fewer. |
| 2.2 | If a technical noun needs more than three words, write it in full once. Then give a short form or hyphenate its units. |

Break long noun chains with prepositions.

Before: the connection pool timeout configuration value

After: the timeout value for the connection pool

### 3. Verbs (Rules 3.1-3.7)

| Rule | Instruction |
| --- | --- |
| 3.1 | Use only the verb forms that the dictionary gives. |
| 3.2 | Use the infinitive, imperative, simple present, simple past, simple future, or a past participle as an adjective. |
| 3.3 | Use a past participle only as an adjective, for example `the cached response`. |
| 3.4 | Do not use auxiliary verbs for complex constructions. Do not use perfect tenses or forms such as `is to be installed`. |
| 3.5 | Use an `-ing` form only as a technical noun or inside one, for example `logging`. Do not use it as a verb. |
| 3.6 | Use active voice. In descriptive text, use passive voice only when the actor is unknown. |
| 3.7 | Describe an action with a verb, not a noun. Write `compress the file`, not `perform compression of the file`. |

STE permits `can`, `will`, and `must`. It rejects `should`, `would`, `may`, `might`, and `could`.
Write `must` for a requirement. Write `can` for possibility or permission. For a hypothetical, use
an `if` condition.

Before: The migration has completed and the table is being rebuilt.

After: The migration is complete. The database rebuilds the table.

### 4. Sentences (Rules 4.1-4.5)

| Rule | Instruction |
| --- | --- |
| 4.1 | Write short, clear sentences. |
| 4.2 | Do not omit words or use contractions. Keep articles and the conjunction `that`. |
| 4.3 | Use a vertical list for complex text. |
| 4.4 | Use connecting words between sentences on related topics, for example `Then` and `As a result`. |
| 4.5 | Put an article or a demonstrative adjective before a noun where applicable. |

Rule 4.2 prevents telegraphic text. Short sentences still need complete grammar.

Before: Ensure file exists before running.

After: Make sure that the file exists before you run the command.

### 5. Procedural writing (Rules 5.1-5.5)

| Rule | Instruction |
| --- | --- |
| 5.1 | Use no more than 20 words in a sentence, including warnings and cautions. |
| 5.2 | Give one instruction per sentence unless two actions occur at the same time. |
| 5.3 | Write instructions in the imperative. |
| 5.4 | Put a required condition before the command and separate it with a comma. |
| 5.5 | Use notes only for information. Apply the 25-word limit to notes. |

Before: Increase the timeout if the network is slow.

After: If the network is slow, increase the timeout.

### 6. Descriptive writing (Rules 6.1-6.6)

| Rule | Instruction |
| --- | --- |
| 6.1 | Give information gradually, with one new fact per sentence. |
| 6.2 | Use key words and phrases to give the text a logical structure. |
| 6.3 | Use no more than 25 words in a sentence. |
| 6.4 | Group related information in paragraphs. |
| 6.5 | Put one topic in each paragraph. |
| 6.6 | Use no more than six sentences in a paragraph. |

Do not use an imperative in descriptive text. Descriptions explain. Procedures instruct.

### 7. Safety instructions (Rules 7.1-7.3)

| Rule | Instruction |
| --- | --- |
| 7.1 | Use a word that shows the risk level. Use `WARNING` for injury and `CAUTION` for damage. |
| 7.2 | Start with a clear command or condition. |
| 7.3 | Then give the risk or possible result. |

Apply this pattern to destructive commands, irreversible migrations, and dangerous API options.

Before: Data loss may occur if you use the destructive flag against production.

After: CAUTION: Do not use `--force` against production. This flag deletes rows that are absent from
the source.

### 8. Punctuation and word count (Rules 8.1-8.7)

| Rule | Instruction |
| --- | --- |
| 8.1 | Use standard punctuation except the semicolon. Use two sentences instead. |
| 8.2 | Use hyphens to connect words that act as one unit. |
| 8.3 | Use parentheses only for references, item numbers, abbreviations, plurals, explanations, or alternatives. |
| 8.4 | In a vertical list, treat the lead-in colon as the end of a sentence for word count. |
| 8.5 | Count all text in parentheses as one word. |
| 8.6 | Count numbers, units, abbreviations, identifiers, quoted text, titles, labels, and proper nouns as one word each. |
| 8.7 | Count a hyphenated word as one word. |

A backticked command counts as quoted text. Long identifiers do not use the sentence budget.

### 9. Writing practices (Rules 9.1-9.4 and GR-1 to GR-8)

| Rule | Instruction |
| --- | --- |
| 9.1 | If a word-for-word replacement does not work, restructure the sentence. |
| 9.2 | Use each approved word with its approved meaning and part of speech. |
| 9.3 | Do not use phrasal verbs. Replace `go down` with `decrease`, and replace `set up` with `install` or `configure`. |
| 9.4 | Keep one style and one term for each concept throughout the document. |

The general recommendations are:

- Keep the conjunction `that`.
- Use `with` carefully.
- Give each pronoun a clear referent.
- Prefer `this` plus a noun to bare `this`.
- Avoid false friends.
- Replace Latin abbreviations. Write `for example` for `e.g.` and `that is` for `i.e.`.
- Use inclusive language.
- Use a possessive apostrophe only when its meaning is clear.

## Vocabulary discipline

The official dictionary contains approved and rejected words. It is copyrighted and is not included
here. Its central rule still applies: use one word with one meaning and one part of speech.

### Modal verbs

| Source | Replacement |
| --- | --- |
| `should` as a requirement | `must` |
| `should` as a recommendation | State why the option is better, or delete the sentence. |
| `may`, `might`, or `could` as possibility | `can` |
| `may` as permission | `can` |
| `would` as a hypothetical | Use `If X occurs, Y occurs.` |

### Common substitutions

Delete a word when it carries no fact. Do not replace filler with different filler.

| Avoid | Use |
| --- | --- |
| leverage, utilize | use |
| in order to | to |
| prior to | before |
| ensure | make sure that |
| it is worth noting that | delete |
| simply, just, easily, seamlessly, effortlessly | delete |
| robust, powerful, comprehensive, performant | give the measurable property or delete |
| functionality | function or feature |
| enables you to, allows you to | you can |
| is designed to, aims to | say what it does |
| facilitate | help or make possible |
| dive into, delve into | read or examine |
| when it comes to | for |
| in the event that | if |
| due to the fact that | because |
| as needed, as necessary | state the condition |
| and/or | choose one, or write `X, or Y, or both` |
| e.g., i.e., etc. | for example, that is, or name the items |
| gracefully handles | state the exact behavior |
| out of the box | by default |
| under the hood | internally |
| blazingly fast, state-of-the-art | give a measurement or delete |
| streamline | make simpler or make faster |
| plethora, myriad | many |

### Consistency pass

Collapse synonym rotations to one term. Choose one technical noun and keep it in both modes. In
strict mode, use the dictionary choice where known.

| Concept | Pragmatic mode | Strict mode |
| --- | --- | --- |
| configuration | Choose one of `config`, `configuration`, or `settings`. | Choose one and keep it. |
| inspection | Choose one of check, verify, confirm, or ensure. | Use `make sure that`. |
| validation | Use `validate` as a technical verb if necessary. | Use `make sure that`. |
| deletion | Choose one exact verb. | Use `erase` for data or `remove` for a physical item. |
| execution | Choose one of run, execute, invoke, or launch. | Use `operate` for run or `do` for execute. |
| display | Choose one of display, render, present, or show. | Use `show`. |

## Untouchables

Leave these exact, even when they break vocabulary or sentence rules:

- code blocks and inline code
- identifiers, commands, flags, and paths
- quoted errors and log lines
- product names, endpoint names, and configuration keys
- numbers with units
- legal text and required quotations

## Limits

This reference is an unofficial aid. It does not guarantee ASD-STE100 compliance. The official
standard and dictionary control the final result.

This adaptation includes material from
[SimpleEnglish](https://github.com/AminBlg/SimpleEnglish/tree/main/skills/simple-english), copyright
2026 AminBlg, used under the MIT License. See `../LICENSE-SimpleEnglish.txt`.
