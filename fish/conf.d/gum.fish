# gum — the laramie palette for its interactive widgets and its markdown renderer.
#
# one concern: gum styling only. gum has no config file, so theming is environment variables,
# one per style key — ~24 of them, which is why this is its own snippet rather than a stanza in
# conf.d/colours.fish. the block is the one from claude-code/skills/gum (references/recipes.md §6).
#
# ⚠ NOT interactive-guarded. a script calling `gum choose` is exactly the case that needs these,
# and functions/reload.fish is one such caller.
# ⚠ never export the *unprefixed* `gum style` variables ($FOREGROUND, $BORDER, $PADDING). they
# are not namespaced and would restyle every `gum style` call in every script on the machine.

type -q gum; or return

# ⚠ values come from the $theme_* palette, not literal hex — conf.d/colours.fish sources it
# above its own interactive guard and sorts earlier ('c' < 'g'), so it is always present here.
# bail rather than export empty strings, which gum renders as unstyled rather than erroring.
set -q theme_violet_base; or return

# markdown. ⚠ gum does NOT read GLAMOUR_STYLE (which conf.d/xdg-apps.fish sets for gh) — it has
# its own variable, pointed at the same file so both renderers agree.
set -gx GUM_FORMAT_THEME $XDG_CONFIG_HOME/glamour/laramie.json

# accents: ui.accent (violet) for anything that moves or is chosen, ui.label (blue) for
# headers and prompts, text.faint for placeholders the user is meant to type over.
set -gx GUM_CHOOSE_CURSOR_FOREGROUND $theme_violet_base
set -gx GUM_CHOOSE_SELECTED_FOREGROUND $theme_cyan_base
set -gx GUM_CHOOSE_HEADER_FOREGROUND $theme_blue_base
set -gx GUM_FILTER_INDICATOR_FOREGROUND $theme_violet_base
set -gx GUM_FILTER_MATCH_FOREGROUND $theme_amber_base
set -gx GUM_FILTER_HEADER_FOREGROUND $theme_blue_base
set -gx GUM_FILTER_PROMPT_FOREGROUND $theme_text_muted
set -gx GUM_FILTER_PLACEHOLDER_FOREGROUND $theme_text_faint
set -gx GUM_INPUT_CURSOR_FOREGROUND $theme_violet_base
set -gx GUM_INPUT_PROMPT_FOREGROUND $theme_blue_base
set -gx GUM_INPUT_PLACEHOLDER_FOREGROUND $theme_text_faint
set -gx GUM_WRITE_CURSOR_FOREGROUND $theme_violet_base
set -gx GUM_WRITE_HEADER_FOREGROUND $theme_blue_base
set -gx GUM_CONFIRM_PROMPT_FOREGROUND $theme_blue_base
set -gx GUM_CONFIRM_SELECTED_BACKGROUND $theme_violet_base
set -gx GUM_CONFIRM_SELECTED_FOREGROUND $theme_surface_base
set -gx GUM_CONFIRM_UNSELECTED_BACKGROUND $theme_surface_overlay
set -gx GUM_CONFIRM_UNSELECTED_FOREGROUND $theme_text_base
set -gx GUM_SPIN_SPINNER_FOREGROUND $theme_violet_base
set -gx GUM_FILE_DIRECTORY_FOREGROUND $theme_blue_base
set -gx GUM_FILE_SELECTED_FOREGROUND $theme_violet_base
set -gx GUM_FILE_SYMLINK_FOREGROUND $theme_cyan_base
set -gx GUM_TABLE_SELECTED_FOREGROUND $theme_violet_base
