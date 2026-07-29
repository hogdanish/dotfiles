# gum — the laramie palette for its interactive widgets and its markdown renderer.
#
# one concern: gum styling only. gum has no config file, so theming is environment variables,
# one per style key — ~24 of them, which is why this is its own snippet rather than a stanza in
# conf.d/colours.fish. the block is the one from .claude/skills/gum (references/recipes.md §6).
#
# ⚠ NOT interactive-guarded. a script calling `gum choose` is exactly the case that needs these,
# and functions/reload.fish is one such caller.
# ⚠ never export the *unprefixed* `gum style` variables ($FOREGROUND, $BORDER, $PADDING). they
# are not namespaced and would restyle every `gum style` call in every script on the machine.

type -q gum; or return

# markdown. ⚠ gum does NOT read GLAMOUR_STYLE (which conf.d/xdg-apps.fish sets for gh) — it has
# its own variable, pointed at the same file so both renderers agree.
set -gx GUM_FORMAT_THEME $XDG_CONFIG_HOME/glamour/laramie.json

# accents: magenta cursor, blue headers, dim placeholders
set -gx GUM_CHOOSE_CURSOR_FOREGROUND '#bb9af7'
set -gx GUM_CHOOSE_SELECTED_FOREGROUND '#7dcfff'
set -gx GUM_CHOOSE_HEADER_FOREGROUND '#7aa2f7'
set -gx GUM_FILTER_INDICATOR_FOREGROUND '#bb9af7'
set -gx GUM_FILTER_MATCH_FOREGROUND '#e0af68'
set -gx GUM_FILTER_HEADER_FOREGROUND '#7aa2f7'
set -gx GUM_FILTER_PROMPT_FOREGROUND '#414868'
set -gx GUM_FILTER_PLACEHOLDER_FOREGROUND '#414868'
set -gx GUM_INPUT_CURSOR_FOREGROUND '#bb9af7'
set -gx GUM_INPUT_PROMPT_FOREGROUND '#7aa2f7'
set -gx GUM_INPUT_PLACEHOLDER_FOREGROUND '#414868'
set -gx GUM_WRITE_CURSOR_FOREGROUND '#bb9af7'
set -gx GUM_WRITE_HEADER_FOREGROUND '#7aa2f7'
set -gx GUM_CONFIRM_PROMPT_FOREGROUND '#7aa2f7'
set -gx GUM_CONFIRM_SELECTED_BACKGROUND '#bb9af7'
set -gx GUM_CONFIRM_SELECTED_FOREGROUND '#1f2335'
set -gx GUM_CONFIRM_UNSELECTED_BACKGROUND '#414868'
set -gx GUM_CONFIRM_UNSELECTED_FOREGROUND '#a9b1d6'
set -gx GUM_SPIN_SPINNER_FOREGROUND '#bb9af7'
set -gx GUM_FILE_DIRECTORY_FOREGROUND '#7aa2f7'
set -gx GUM_FILE_SELECTED_FOREGROUND '#bb9af7'
set -gx GUM_FILE_SYMLINK_FOREGROUND '#7dcfff'
set -gx GUM_TABLE_SELECTED_FOREGROUND '#bb9af7'
