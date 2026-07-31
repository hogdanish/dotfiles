# the laramie palette — layer 0, the 28 primitives every fish colour derives from.
# sourced by conf.d/colours.fish (above its interactive guard, because conf.d/fzf.fish
# reads these too). global, not exported: nothing outside fish reads them.
#
# ⚠ the spec is the source of truth, not this file: .claude/skills/laramie/references/spec.md
# holds the OKLCH triplets, contrast figures and derivation rules. do not invent a value here.
# ⚠ hex keeps its leading '#' — set_color accepts it. the generated laramie.theme must NOT
# have it (a .theme file is tokenised, so '#' starts a comment).

# surfaces — neutral hue 274°, chroma rising with lightness
set -g theme_surface_sunken "#161925" # below the background: window chrome, code-block ground
set -g theme_surface_base "#1f2335" # THE background (pinned)
set -g theme_surface_raised "#292e43" # current line, zebra rows, inline code
set -g theme_surface_overlay "#343a55" # selection and search-match backgrounds
set -g theme_surface_border "#444b6b" # borders, dividers, rules

# text — same hue, chroma easing off as lightness rises so it reads neutral
set -g theme_text_faint "#656e94" # 3.12:1 — dead code, placeholders. deliberately sub-AA
set -g theme_text_dim "#8089af" # 4.53:1 — autosuggestions, gutters, ANSI 8
set -g theme_text_muted "#9099be" # 5.54:1 — punctuation, secondary chrome
set -g theme_text_base "#a9b1d6" # 7.37:1 — body text (pinned)
set -g theme_text_loud "#c9d3f7" # 10.48:1 — emphasis

# accents — six hues x three tiers. deep = non-text only, base = ANSI normal, loud = ANSI bright.
# ⚠ chroma is deliberately NOT uniform; it tracks each hue's sRGB headroom (spec.md §1).
set -g theme_red_deep "#cd4f66"
set -g theme_red_base "#fc8697"
set -g theme_red_loud "#fdadb6"
set -g theme_amber_deep "#a57721"
set -g theme_amber_base "#e0a332"
set -g theme_amber_loud "#ffc55b"
set -g theme_green_deep "#59931f"
set -g theme_green_base "#86c452"
set -g theme_green_loud "#a7e775"
set -g theme_cyan_deep "#299194"
set -g theme_cyan_base "#3bc5ca"
set -g theme_cyan_loud "#49ebf0"
set -g theme_blue_deep "#0584da"
set -g theme_blue_base "#6cb6fa"
set -g theme_blue_loud "#98ccff"
set -g theme_violet_deep "#9b61c9"
set -g theme_violet_base "#cb92fc"
set -g theme_violet_loud "#dab4fe"
