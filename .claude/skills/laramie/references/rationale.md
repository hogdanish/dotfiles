# laramie — why it is the way it is

Written 2026-07-30 during the rebuild, so the reasoning survives the values. Read this before
arguing with `spec.md`.

## 1. What was wrong with the old palette

laramie was assembled by eye from Tokyo Night Storm without a colour model. Measured in OKLCH:

- **One flat lightness ring.** All eight accents sat at L 0.719–0.822 — a spread of **0.10**. Nothing
  could recede or advance, so nothing could carry hierarchy.
- **Blue and violet were nearly the foreground.** ΔE2000 vs `text.base`: blue **12.7**, violet
  **11.8**. Six values sat within 12° of hue 274 — the neutral axis, the foreground, blue and violet
  all in one neighbourhood.
- **Contrast failures on the most-read surfaces.** Comments `#565f89` at **2.51:1**; autosuggestions
  and gutters `#737aa2` at **3.73:1**; ANSI 8 `#414868` at **1.74:1**.
- **Six wasted ANSI slots** — brights 9–14 were byte-identical to normals 1–6.
- **Lumpy hue distribution.** Four values crowded 182°–236° (all "some kind of cyan"), then a 52° gap
  to green.
- **15 off-palette hexes**, each appearing in exactly one file.

## 2. OKLCH as a tool, not a target

The article that prompted this rebuild — <https://tonsky.me/blog/syntax-highlighting/> — explicitly
attacks OKLCH-uniform palettes:

> If you make all colors the same lightness and chroma, they will look very similar to each other,
> and it'll be hard to tell them apart. … our eyes are way more sensitive to differences in lightness
> than in color, and we should use it, not try to negate it.

He is right, and laramie had arrived at that failure _by accident_ rather than by design. The
resolution: **OKLCH is the measurement and derivation space, never the output constraint.** It is
precisely what makes "this token is two lightness steps quieter than that one" a controllable,
verifiable claim instead of a guess. The output deliberately spreads lightness by 0.26 and varies
chroma per hue by nearly 2× (green 0.160, cyan 0.114).

## 3. Why the syntax layer has three colours, not four

The plan called for Alabaster's four (literal, constant, definition, comment). It shipped with three.
This was forced by measurement, and it is the single most important finding of the rebuild.

**A syntax token sits inline among body text**, so what matters is ΔE against `text.base` — not
contrast against the background. Four roles need four hues. Red is reserved for errors. That leaves
amber, green, cyan, blue, violet — and blue and violet fail:

| candidate            | ΔE vs `text.base` | verdict             |
| -------------------- | ----------------- | ------------------- |
| `accent.blue.base`   | 15.9              | fails the ≥20 floor |
| `accent.violet.base` | 15.4              | fails               |
| `accent.blue.loud`   | 13.6              | worse               |
| `accent.violet.loud` | 12.5              | worse               |

⚠ **This cannot be tuned away.** Both were swept against hue and chroma:

- Desaturating `text.base` from C 0.054 all the way to C 0.020 — a fully neutral grey foreground,
  which would cost the entire Tokyo Night cast — moves blue only from ΔE 11.9 to **17.0**. Still short.
- Widening the blue↔violet hue gap helps them separate _from each other_, and does nothing for
  either against the foreground.

The reason is the article's own point: **ΔE2000 is dominated by lightness difference**, and a
blue-violet foreground shares both the hue neighbourhood _and_ the lightness of any blue or violet
accent that is legible on a dark background. Three usable hues is the honest answer.

**Constants merged into literals** on principle, not just convenience — `true`, `null`, `42` and
`"x"` are all literal values, and one colour for "a literal appears here" is more memorable than two.
**Declarations merged into definitions** for the same reason after the two-tier split measured ΔE 8.8
(`cyan.loud` vs `cyan.base`), too subtle to function as a hierarchy cue.

The result is more restrained than Alabaster, which is the direction the article argues for.

## 4. Why blue moved 264° → 248°

The largest hue shift in the palette, and the direct fix for the "blue reads as barely coloured"
defect. At 264° blue sat 10° from the neutral axis. At 248° it is 26° away, ΔE against `text.base`
rises 12.7 → 15.9, and — with violet pushed to 308° — bright-blue vs bright-cyan clears its floor at
20.9 where it had been 16.2.

Blue is still not a syntax colour (§3). The move buys legibility in ANSI and UI use.

## 5. Comments are bright

The article's most contentious recommendation, adopted in full:

> Comments should be highlighted, not hidden away. … use bold colors, draw attention to them.

`syntax.comment` is `accent.amber.loud` at **9.92:1** — brighter than body text. Greying comments is
a habit from when people were paid by the line; a good comment explains something the code cannot.
⚠ **Commented-out code is the opposite case** and stays grey at `syntax.dead` (`text.faint`, 3.12:1).
A syntax theme that cannot distinguish the two should favour the bright treatment.

⚠ **If this proves annoying in daily use, it is a one-token change**: repoint `syntax.comment` at
`accent.amber.base` (7.00:1) or `text.muted`. That is why it is a named token and not a hex.

## 6. Why ANSI names are preferred over hex

`starship.toml`, `LS_COLORS`, `EZA_COLORS`, `LESS_TERMCAP_*` and `git`'s log/branch formats all use
ANSI colour _names_. That was already deliberate — the stated reason being that they then inherit
whatever terminal palette is live instead of becoming another place the theme is hand-duplicated.

The rebuild leans on it harder. Since ANSI-16 is now properly derived, every ANSI-name consumer gets
correct laramie colours for free — **including tools laramie does not configure at all**. Fixing
ANSI 8 from 1.74:1 to 4.53:1 improved `git log`, `grc` and every TUI without touching their configs.

⚠ **Do not "complete" the theme by hex-coding `starship.toml`.** It would be a fifteenth copy of the
problem, and it would break the inheritance that makes the other tools work.

## 7. Retired — do not reintroduce

| value                                                     | was                                 | why it is gone                                                                                                                            |
| --------------------------------------------------------- | ----------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| `#ff9e64`                                                 | orange: numbers, fish `redirection` | numbers unified with strings under `syntax.literal`; orange's only other job folded into the amber hue. A whole hue removed at zero cost. |
| `#73daca`                                                 | teal: object keys, markdown links   | crowded 182°–236° with three other "cyans"                                                                                                |
| `#b4f9f8`                                                 | light cyan: regex literals          | same crowding; also L 0.936, far outside every tier                                                                                       |
| `#cfc9c2`                                                 | "light yellow"                      | **C = 0.012** — a warm grey misfiled as a yellow                                                                                          |
| `#1a1b29`                                                 | ghostty `palette 0`                 | one-character typo for `#1a1b26`; never propagated anywhere else                                                                          |
| `#3d59a1 #89ddff #9d7cd8 #7982a9 #545c7e #3b4261 #5f6996` | micro only                          | off-palette one-offs                                                                                                                      |
| `#8089b3 #6881C0 #545c7e`                                 | atuin only                          | off-palette; `#6881C0` was the repo's only uppercase hex                                                                                  |
| `#4f4f5e #362c3d #373640`                                 | bat only                            | off-palette one-offs                                                                                                                      |
| `glamour/tui.json`                                        | —                                   | a full 213-line copy of the palette that **nothing reads**; zero references repo-wide                                                     |

## 8. Known trade-offs, accepted deliberately

1. ⚠ **`window-colorspace = display-p3`** in `config.ghostty` means Ghostty interprets these sRGB
   hexes as P3, rendering everything more saturated than authored. Every figure in `spec.md` is
   therefore _nominal_. Settle this with the `ghostty` skill before assuming a measured value is what
   reaches the eye.
2. ⚠ **`background-opacity = 0.92` + blur** means the real backdrop is not `#1f2335`. At 0.92 the
   contrast error is small, but the numbers are not lab-grade.
3. **`text.faint` at 3.12:1 is below AA on purpose.** It is only for content the reader is meant to
   skip — commented-out code, input placeholders. Never use it for information.
4. **ANSI 8 is now bright enough to change how box-drawing TUIs look.** Legibility of secondary
   _text_ was judged the more common case. See `spec.md` §4.
5. **`accent.red.loud` is pale pink** (`#fdadb6`, C 0.094). That is sRGB physics at L 0.83, not an
   oversight — red has almost no chroma headroom that high.
