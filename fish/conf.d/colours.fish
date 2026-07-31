# every colour this shell is responsible for: the tools it launches, and fish's own line
# editor and pager. this is the fish and CLI half of laramie; thirteen other files carry
# their own hand-kept copy. ⚠ the `laramie` skill owns the values and the per-tool bindings.
#
# ⚠ sorts before fzf.fish and tools.fish, which is load-bearing: it exports the $theme_*
# palette that conf.d/fzf.fish builds FZF_DEFAULT_OPTS from.

# everything down to the interactive guard is consumed by *child processes*, so it must be
# set non-interactively too.

# the laramie palette, as $theme_*. sourced ABOVE the interactive guard on purpose: it is a
# cross-file contract, and conf.d/fzf.fish exports FZF_DEFAULT_OPTS from it — a variable
# that fzf reads in scripts, not just at an interactive prompt.
# ⚠ never `source $somevar` unguarded: if the variable is empty the token vanishes entirely,
# `source` then reads stdin, and it succeeds silently under every redirected-stdin check
# while erroring in every real terminal. see references/caveats.md.
set -q THEME; or set -g THEME laramie
set -l palette "$FISH_THEMES_DIR/$THEME.fish"
if not test -r "$palette"
    echo >&2 "colours: no palette at $palette"
    return 1
end
source $palette

# less
# -R pass ANSI colour through (without this delta and bat output is unreadable)
# -F quit immediately if the content fits one screen
# -i case-insensitive search unless the pattern has uppercase
# -M verbose prompt with position
# -w highlight the first new line after a forward scroll
set -gx LESS '-R -F -i -M -w'

# man pages, via less's termcap hooks. these deliberately use the terminal's own 16 colours
# rather than laramie hex: ghostty already maps 0-15 to laramie, so this stays correct if
# the terminal theme ever changes, and it degrades gracefully everywhere else.
set -gx LESS_TERMCAP_mb (set_color -o blue) # blink -> headings
set -gx LESS_TERMCAP_md (set_color -o cyan) # bold  -> section titles
set -gx LESS_TERMCAP_me (set_color normal)
set -gx LESS_TERMCAP_so (set_color -b white black) # standout -> status line, search hits
set -gx LESS_TERMCAP_se (set_color normal)
set -gx LESS_TERMCAP_us (set_color -u magenta) # underline -> arguments
set -gx LESS_TERMCAP_ue (set_color normal)

# bat. the laramie theme is a hand-kept .tmTheme in ~/.config/bat/themes; it is only visible
# to bat after `bat cache --build`, which is also what makes git-delta's
# `syntax-theme = laramie` resolve instead of silently falling back.
set -gx BAT_THEME laramie
set -gx BAT_STYLE 'header,header-filename,rule,numbers,snip'
set -gx BAT_PAGER 'less -R'

# man pages through bat, for real syntax highlighting in the laramie palette.
# `col -bx` strips the backspace-overstrike sequences roff emits for bold/underline, which
# bat would otherwise render literally; MANROFFOPT=-c stops groff re-adding them.
if type -q bat
    set -gx MANROFFOPT -c
    set -gx MANPAGER 'sh -c \'col -bx | bat -l man -p\''
end

# ls/eza. 8-colour ANSI on purpose, not laramie hex — ghostty maps 0-15 to laramie already,
# so this inherits the palette automatically and stays readable under any other terminal
# theme. truecolour here would hard-code one theme into every child process.
#   di dir · ln symlink · ex executable · pi fifo · so socket · bd/cd device · or orphan
set -gx LS_COLORS 'di=34:ln=36:so=35:pi=33:ex=32:bd=1;33:cd=1;33:or=1;31:mi=31:su=30;41:sg=30;46:tw=30;42:ow=30;43'
# eza understands LS_COLORS and layers its own keys on top. metadata columns are dimmed (2)
# so the filename stays the thing your eye lands on.
#   da date · uu/un user · gu/gn group · ur/uw/ux perm bits · sn/sb size · xa xattrs · lp link target
set -gx EZA_COLORS "$LS_COLORS:da=2:uu=33:un=2:gu=35:gn=2:ur=33:uw=31:ux=32:ue=32:gr=33:gw=31:gx=32:tr=33:tw=31:tx=32:sn=32:sb=2:xa=2:lp=36"

# ⚠ gum's palette is NOT here, unlike every other tool's. gum needs ~24 GUM_<COMMAND>_<FLAG>
# variables and its own `type -q` guard, which is a whole concern rather than a stanza — it
# lives in conf.d/gum.fish, per the `gum` skill. this file still owns everything else.

# everything below styles the commandline editor and the completion pager, neither of
# which exists in a non-interactive shell.
status is-interactive; or return

# syntax highlighting. every value comes from the palette sourced above; if that ever failed
# these would each be set to an empty list, which fish silently treats as "unset" and falls
# back to its own defaults — a theme that reads as applied and is not. hence the hard
# `return 1` on a missing palette rather than a warning.
#
# ⚠ the commandline IS a syntax surface, so the laramie syntax doctrine applies (the `laramie`
# skill): only literals, definitions and comments get a colour; everything else is plain text.
# one adaptation — the *command* keeps a colour, because it is the thing you scan history for,
# which makes it the commandline's analogue of a definition.
# ⚠ keyword and param must be set EXPLICITLY. unset, they fall back to command and would
# inherit the definition colour, defeating the doctrine.
set -g fish_color_normal $theme_text_base # general text
set -g fish_color_command $theme_cyan_loud # syntax.definition — the command being run
set -g fish_color_keyword $theme_text_base # plain: `if`, `while`, `and` (⚠ see above)
set -g fish_color_param $theme_text_base # plain: ordinary parameters (⚠ see above)
set -g fish_color_quote $theme_green_base # syntax.literal — strings
set -g fish_color_escape $theme_green_loud # escapes, one tier louder inside a literal
set -g fish_color_comment $theme_amber_loud # syntax.comment — bright, per the doctrine
set -g fish_color_option $theme_text_muted # flags modify, they are not content
set -g fish_color_operator $theme_text_muted # syntax.punctuation — expansion operators (*, ~)
set -g fish_color_redirection $theme_text_muted # syntax.punctuation — (>, >>)
set -g fish_color_end $theme_text_muted # syntax.punctuation — separators (; and &)
set -g fish_color_error $theme_red_base # state.error
set -g fish_color_autosuggestion $theme_text_faint # meant to be ignorable
set -g fish_color_search_match $theme_text_loud --background=$theme_surface_overlay
set -g fish_color_selection $theme_text_loud --background=$theme_surface_overlay

# default prompt. starship owns the prompt here, so these only surface if it is ever absent.
set -g fish_color_cwd $theme_blue_base # current working directory
set -g fish_color_cwd_root $theme_red_base # ...when root
set -g fish_color_user $theme_cyan_base # username
set -g fish_color_host $theme_cyan_base # hostname
set -g fish_color_host_remote $theme_amber_base # ...over ssh (state.warn)
set -g fish_color_status $theme_red_base # non-zero exit status

# completion pager
set -g fish_pager_color_progress $theme_text_muted
set -e fish_pager_color_background # inherit the terminal background
set -g fish_pager_color_prefix $theme_text_loud # the part already typed
set -g fish_pager_color_completion $theme_text_base
set -g fish_pager_color_description $theme_text_dim
set -g fish_pager_color_selected_background --background=$theme_surface_overlay
set -g fish_pager_color_selected_prefix $theme_cyan_loud
set -g fish_pager_color_selected_completion $theme_text_loud
set -g fish_pager_color_selected_description $theme_text_muted
set -g fish_pager_color_secondary_background --background=$theme_surface_raised # zebra striping
set -g fish_pager_color_secondary_prefix $theme_cyan_base
set -g fish_pager_color_secondary_completion $theme_text_base
set -g fish_pager_color_secondary_description $theme_text_dim
