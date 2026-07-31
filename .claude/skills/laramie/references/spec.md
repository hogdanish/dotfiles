# laramie — the token spec

Source of truth for every colour value on this machine. Derived 2026-07-30. All figures computed in
OKLCH; contrast is WCAG 2.1 against `surface.base`; ΔE is CIEDE2000 against `text.base`.

## 1. Derivation rules

Everything below is generated from eleven numbers, not chosen by eye.

| rule                    | value                                                                                          |
| ----------------------- | ---------------------------------------------------------------------------------------------- |
| neutral hue             | **274°** — the blue-violet cast that _is_ the laramie look. Carries surfaces and text.         |
| chromatic hues          | red **12°** · amber **78°** · green **133°** · cyan **198°** · blue **248°** · violet **308°** |
| tier lightness          | `deep` **0.600** · `base` **0.755** · `loud` **0.860**                                         |
| tier lightness override | `loud` for **red, blue, violet** drops to **0.828**                                            |
| accent chroma           | `min(0.160, max(0.090, 0.88 × maxChroma(L, H)))`, gamut-mapped `oklch-chroma` into sRGB        |
| pinned                  | `surface.base` `#1f2335`, `text.base` `#a9b1d6` — asserted, not derived                        |

⚠ **The `loud` override is load-bearing.** sRGB headroom is not uniform: red, blue and violet lose
chroma fast above L≈0.83, so a flat `loud` tier drives all three toward a common pale blue-white and
collapses bright-blue against bright-cyan (measured ΔE 16.2, floor 20). Seating those three at 0.828
restores it to 20.9. Do not "tidy" this into a single lightness.

⚠ **Chroma is intentionally non-uniform.** Green reaches 0.160, cyan only 0.114. Equalising it is the
failure mode Tonsky names — see `rationale.md` §2.

**Reproduce:** the derivation is ~60 lines of `coloraide`. Nothing is installed for it; run it
ephemerally with `uv run --no-project --with coloraide`. The script is not committed on purpose — the
table below _is_ the artifact, and a committed generator would imply a build step that does not exist.

## 2. Primitives

| token                | hex       | OKLCH                      | vs bg   | ΔE vs text.base |
| -------------------- | --------- | -------------------------- | ------- | --------------- |
| `surface.sunken`     | `#161925` | `oklch(21.6% 0.024 273.4)` | 1.13:1  | 57.2            |
| `surface.base`       | `#1f2335` | `oklch(26.1% 0.034 274.2)` | —       | 54.4            |
| `surface.raised`     | `#292e43` | `oklch(30.6% 0.039 273.6)` | 1.16:1  | 51.5            |
| `surface.overlay`    | `#343a55` | `oklch(35.5% 0.048 274.1)` | 1.39:1  | 47.6            |
| `surface.border`     | `#444b6b` | `oklch(42.0% 0.054 274.4)` | 1.83:1  | 39.4            |
| `text.faint`         | `#656e94` | `oklch(54.6% 0.060 273.9)` | 3.12:1  | 22.6            |
| `text.dim`           | `#8089af` | `oklch(63.7% 0.058 274.3)` | 4.53:1  | 12.4            |
| `text.muted`         | `#9099be` | `oklch(68.9% 0.055 274.2)` | 5.54:1  | 7.1             |
| `text.base`          | `#a9b1d6` | `oklch(76.7% 0.054 275.5)` | 7.37:1  | —               |
| `text.loud`          | `#c9d3f7` | `oklch(87.1% 0.051 273.1)` | 10.48:1 | 8.6             |
| `accent.red.deep`    | `#cd4f66` | `oklch(60.0% 0.160 12.3)`  | 3.63:1  | 35.3            |
| `accent.red.base`    | `#fc8697` | `oklch(75.5% 0.144 12.0)`  | 6.66:1  | 29.0            |
| `accent.red.loud`    | `#fdadb6` | `oklch(82.7% 0.094 11.9)`  | 8.76:1  | 25.2            |
| `accent.amber.deep`  | `#a57721` | `oklch(60.1% 0.113 78.3)`  | 3.90:1  | 42.4            |
| `accent.amber.base`  | `#e0a332` | `oklch(75.5% 0.141 78.2)`  | 7.00:1  | 41.6            |
| `accent.amber.loud`  | `#ffc55b` | `oklch(85.6% 0.138 80.1)`  | 9.92:1  | 41.8            |
| `accent.green.deep`  | `#59931f` | `oklch(60.1% 0.156 133.1)` | 4.16:1  | 46.3            |
| `accent.green.base`  | `#86c452` | `oklch(75.4% 0.160 132.9)` | 7.43:1  | 43.6            |
| `accent.green.loud`  | `#a7e775` | `oklch(86.0% 0.160 133.0)` | 10.61:1 | 44.1            |
| `accent.cyan.deep`   | `#299194` | `oklch(60.1% 0.091 197.9)` | 4.13:1  | 28.4            |
| `accent.cyan.base`   | `#3bc5ca` | `oklch(75.4% 0.114 198.6)` | 7.43:1  | 25.5            |
| `accent.cyan.loud`   | `#49ebf0` | `oklch(86.1% 0.130 198.1)` | 10.68:1 | 28.2            |
| `accent.blue.deep`   | `#0584da` | `oklch(59.9% 0.161 248.2)` | 3.94:1  | 23.4            |
| `accent.blue.base`   | `#6cb6fa` | `oklch(75.6% 0.123 247.8)` | 7.19:1  | 15.9            |
| `accent.blue.loud`   | `#98ccff` | `oklch(82.7% 0.090 248.5)` | 9.20:1  | 13.6            |
| `accent.violet.deep` | `#9b61c9` | `oklch(60.0% 0.161 308.0)` | 3.66:1  | 24.1            |
| `accent.violet.base` | `#cb92fc` | `oklch(75.5% 0.158 307.8)` | 6.71:1  | 15.4            |
| `accent.violet.loud` | `#dab4fe` | `oklch(82.9% 0.109 307.6)` | 8.84:1  | 12.5            |

**Diff surfaces** — the one place a *tinted* background is unavoidable, because added and removed
lines must differ from each other and from `surface.raised` without relying on the foreground. Derived
at the surface-ramp lightnesses with the green and red hues at low chroma.

| token | hex | OKLCH | `text.base` on it | ΔE vs `surface.raised` |
| --- | --- | --- | --- | --- |
| `surface.add` | `#29381d` | `oklch(31.9% 0.049 133.0)` | 5.93:1 | 26.3 |
| `surface.remove` | `#49282c` | `oklch(32.1% 0.050 12.0)` | 6.13:1 | 17.7 |
| `surface.add.emph` | `#3a5723` | `oklch(42.1% 0.086 133.0)` | 3.87:1 | — |
| `surface.remove.emph` | `#743841` | `oklch(42.1% 0.085 12.0)` | 4.17:1 | — |

`surface.add` ~ `surface.remove` is ΔE **33.2** — unmistakable. ⚠ The `.emph` pair is for word-level
highlights only; at ~4:1 they are below AA for body text and must always carry `text.loud`.

**32 values. That is the entire palette.** Anything else in any config is drift.

## 3. Semantic aliases

Aliases, not new colours. Use the alias name in `bindings.md` wherever the _meaning_ is what matters.

| alias              | → primitive          | used for                                                                      |
| ------------------ | -------------------- | ----------------------------------------------------------------------------- |
| `state.error`      | `accent.red.base`    | errors, deletions, failed status, invalid paths                               |
| `state.error.loud` | `accent.red.loud`    | error emphasis on a coloured ground                                           |
| `state.warn`       | `accent.amber.base`  | warnings, modified files, remote hosts                                        |
| `state.ok`         | `accent.green.base`  | success, additions, staged                                                    |
| `state.info`       | `accent.blue.base`   | informational, links, directories                                             |
| `ui.accent`        | `accent.violet.base` | the primary interactive accent — cursors, indicators, spinners, selected rows |
| `ui.label`         | `accent.blue.base`   | headers, prompts, field labels, key names                                     |
| `ui.select.bg`     | `surface.overlay`    | selection and search-match backgrounds                                        |
| `ui.highlight.bg`  | `surface.raised`     | current line, zebra rows, inline code ground                                  |

⚠ **Deliberate overload.** `state.warn` and `syntax.comment` are both amber; `state.ok` and
`syntax.literal` are both green. They never co-occur in one scope — syntax is inside a buffer, state
is chrome around it — and collapsing them is what keeps the palette memorable. Do not "fix" this.

## 4. The ANSI-16 contract

⚠ **The most leveraged table here.** Every tool that takes ANSI names inherits these, including ones
laramie never configures (`grc`, `gh`, any TUI). Set in `ghostty/themes/laramie`.

| #   | name    | token                | hex       | #   | name      | token                | hex       |
| --- | ------- | -------------------- | --------- | --- | --------- | -------------------- | --------- |
| 0   | black   | `surface.sunken`     | `#161925` | 8   | brblack   | `text.dim`           | `#8089af` |
| 1   | red     | `accent.red.base`    | `#fc8697` | 9   | brred     | `accent.red.loud`    | `#fdadb6` |
| 2   | green   | `accent.green.base`  | `#86c452` | 10  | brgreen   | `accent.green.loud`  | `#a7e775` |
| 3   | yellow  | `accent.amber.base`  | `#e0a332` | 11  | bryellow  | `accent.amber.loud`  | `#ffc55b` |
| 4   | blue    | `accent.blue.base`   | `#6cb6fa` | 12  | brblue    | `accent.blue.loud`   | `#98ccff` |
| 5   | magenta | `accent.violet.base` | `#cb92fc` | 13  | brmagenta | `accent.violet.loud` | `#dab4fe` |
| 6   | cyan    | `accent.cyan.base`   | `#3bc5ca` | 14  | brcyan    | `accent.cyan.loud`   | `#49ebf0` |
| 7   | white   | `text.base`          | `#a9b1d6` | 15  | brwhite   | `text.loud`          | `#c9d3f7` |

⚠ **Brights must differ from normals.** Until 2026-07-30, slots 9–14 were byte-identical to 1–6 —
six of sixteen slots doing no work. Any future edit that re-collapses them is a regression.

⚠ **ANSI 8 is `text.dim` (4.53:1), not a border colour.** It was a surface-ramp value at **1.74:1**, effectively
invisible, and it is what `git log`'s `%C(brightblack)`, `starship` and most TUIs use for _secondary
text_. Legibility wins over border subtlety here; a TUI that uses ANSI 8 for box-drawing will now
render brighter than before, which is the correct trade.

## 5. Syntax roles

See `SKILL.md` for the table and the doctrine. In token terms:

```
syntax.literal      = accent.green.base   #86c452
syntax.definition   = accent.cyan.loud    #49ebf0
syntax.comment      = accent.amber.loud   #ffc55b
syntax.dead         = text.faint          #656e94
syntax.punctuation  = text.muted          #9099be
syntax.plain        = text.base           #a9b1d6
```

Measured separation, all against a floor of ΔE2000 ≥ 20:

| pair                 | ΔE   | pair                 | ΔE   |
| -------------------- | ---- | -------------------- | ---- |
| literal ~ definition | 33.0 | definition ~ comment | 42.7 |
| literal ~ comment    | 29.7 | definition ~ plain   | 28.2 |
| literal ~ plain      | 43.6 | comment ~ plain      | 41.8 |

## 6. Porting the spec

**Scope-agnostic by construction** — tokens are named by role, values recorded in OKLCH first.

**CSS.** Emit primitives as custom properties in OKLCH (browsers gamut-map for you; the hex column is
the sRGB fallback), then layer the semantic aliases:

```css
:root {
    --surface-base: oklch(26.1% 0.034 274.2);
    --text-base: oklch(76.7% 0.054 275.5);
    --accent-green-base: oklch(75.4% 0.16 132.9);
    /* … */
    --state-ok: var(--accent-green-base);
}
```

**A light variant** is a mechanical derivation, not a redesign — the hues and the semantic layer are
unchanged:

1. Invert the two ramps: `surface.*` becomes L 0.98 → 0.86, `text.*` becomes L 0.38 → 0.15.
2. Reflect the accent tiers about L 0.5 — `deep` → L 0.40, `base` → L 0.245, `loud` → L 0.14 — so
   "loud" still means "furthest from the background".
3. Re-run the same chroma rule. ⚠ Headroom differs at low lightness, so the `loud` override will land
   on a **different** set of hues; re-measure, do not copy §1's override.
4. Re-check every floor in `SKILL.md`. ⚠ WCAG contrast is not symmetric under inversion.
