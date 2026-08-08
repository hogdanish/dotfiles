---
name: laramie
description: "The laramie color theme: its OKLCH token palette, per-tool bindings, ANSI-16 contract, and three-color syntax doctrine across Ghostty, bat, micro, delta/git, glamour/gum, fish, fzf, atuin, btop, and Claude Code. Load before editing any color value, answering about theme colors, contrast, syntax highlighting, or ANSI palettes, adding themed tools, or diagnosing a wrong color. Owns color values and semantics; each tool skill owns its config syntax."
---

# laramie

A Tokyo Night Storm derivative, rebuilt 2026-07-30 as a derived token system. Two facts govern
everything else:

1. **There is no build step.** Fourteen files carry the hexes by hand. This skill is the reference
   they all derive from; keeping them in sync is a human/agent job, not a script's.
2. **The spec is the source of truth, not any config file.** If a config disagrees with
   `references/spec.md`, the config is wrong — fix it, don't copy from it.

## The four doctrines

**1 — Three layers.** Primitives (OKLCH) → semantics (`surface.*`, `text.*`, `accent.*`) → per-tool
bindings. Never write a raw hex into a config without a token name behind it in `bindings.md`.

**2 — Lightness carries the hierarchy.** Six hues × three tiers: `deep` (L 0.60, non-text only),
`base` (L 0.755, ANSI normal), `loud` (L ~0.85, ANSI bright). ⚠ The old palette put every accent in
one flat ring (L 0.72–0.82) which is why nothing could recede or advance. Lightness spread is now
0.26. Chroma is deliberately **not** uniform — it tracks each hue's sRGB headroom.

**3 — ANSI is the shared abstraction.** ⚠ **If a tool accepts ANSI colour names and needs nothing
outside the 16, use the name — do not add a fifteenth hex copy.** `starship.toml`, `LS_COLORS`,
`EZA_COLORS`, `LESS_TERMCAP_*` and `git`'s log formats all do this on purpose, and they inherit
correct laramie colours for free once `ghostty/themes/laramie` is right. This is why fixing ANSI 8
(was 1.74:1, near-invisible) improved tools nothing here configures.

**4 — Syntax uses three colours, not ten.** Adapted from
<https://tonsky.me/blog/syntax-highlighting/> — read it before touching a syntax theme.

| role                 | token               | covers                                                         |
| -------------------- | ------------------- | -------------------------------------------------------------- |
| `syntax.literal`     | `accent.green.base` | strings, numbers, chars, booleans, null, constants             |
| `syntax.definition`  | `accent.cyan.loud`  | any name being **introduced** — def, class, type, declaration  |
| `syntax.comment`     | `accent.amber.loud` | explanatory comments — **bright, the loudest thing on screen** |
| `syntax.dead`        | `text.faint`        | commented-out code                                             |
| `syntax.punctuation` | `text.muted`        | brackets, separators, operators                                |
| _everything else_    | `text.base`         | ⚠ keywords, function calls and variable **usage** are plain    |

⚠ **Red, blue and violet do no syntax work at all.** Red is reserved for errors. Blue and violet are
structurally foreclosed — they sit at the same lightness as a blue-violet `text.base`, and ΔE is
dominated by lightness, so they read as barely-coloured inline. `rationale.md` has the measurements.
They do full duty in ANSI and UI chrome, where they sit against the _background_ instead.

## Invariants

- Every hex in the repo must appear in `spec.md` (32 values). Any other value is drift, by definition.
- Contrast floors vs `surface.base`: text ramp 10.5/7.4/5.5/4.5/3.1, accents 3.0 `deep` / 4.5 `base`
  / 7.0 `loud`. ⚠ `text.faint` is deliberately sub-AA — only for content meant to be skipped.
- Separation floors (ΔE2000): ≥20 between syntax roles and `text.base`, ≥20 between ANSI hues within
  a tier. These are what forced the three-colour syntax layer.
- `surface.base` `#1f2335` and `text.base` `#a9b1d6` are **pinned** — the two most-viewed values.

## References

- `references/spec.md` — every token with OKLCH, hex, contrast and ΔE; the derivation rules; the
  ANSI-16 contract; the CSS/light-variant derivation. **Read before quoting any value.**
- `references/bindings.md` — one table per tool: config key → token, plus that file's colour format,
  its traps, and its reload command. **Read before editing any theme file.**
- `references/rationale.md` — why each decision, what was retired and why it must not come back, and
  the measurements behind the three-colour syntax layer.

## Verifying

```sh
rg -o '#[0-9a-fA-F]{6}' --no-filename <theme files> | tr 'A-F' 'a-f' | sort -u   # ⊆ spec.md
ghostty +validate-config && .claude/skills/ghostty/scripts/ghostty-audit.sh
bat cache --build                     # ⚠ mandatory after editing the tmTheme, or bat silently falls back
fish -c 'set -U --names'              # must print nothing
```

⚠ Colour cannot be verified by parsers. Look at it in Ghostty: `bat` a long source file, `git diff` a
real change, `gum format` a README, `btop`, `atuin` (ctrl-r), the fish pager. The article's own test
is the one that matters — _can you find the definitions at a glance?_
