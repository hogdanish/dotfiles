# fzf configuration. not interactive-guarded: these are read by fzf itself, including when
# a script invokes it, so they belong in every shell.
#
# ⚠ this file MUST sort before conf.d/tools.fish, which is where `fzf --fish` is sourced.
# FZF_DEFAULT_OPTS and FZF_DEFAULT_COMMAND are read lazily at call time and would not care,
# but FZF_CTRL_R_COMMAND, FZF_CTRL_T_COMMAND and FZF_ALT_C_COMMAND are read at *source*
# time by fzf_key_bindings. set them after tools.fish and they do nothing.

type -q fzf; or return

# atuin owns ctrl-r. an empty-but-set value is fzf's own opt-out — its guard reads
# `not set -q FZF_CTRL_R_COMMAND; or test -n "$FZF_CTRL_R_COMMAND"`, so empty skips the
# bind silently while a *non-empty* value would print "custom commands are not yet
# supported for CTRL-R" on every single startup.
# -g not -gx: only fzf's fish integration in this shell reads it.
set -g FZF_CTRL_R_COMMAND ''

# fd instead of find: respects .gitignore, skips .git, and is an order of magnitude faster
# on a large tree. `--hidden` because dotfiles are the point of this machine.
if type -q fd
    set -gx FZF_DEFAULT_COMMAND 'fd --type=file --hidden --follow --exclude=.git'
    set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
    set -gx FZF_ALT_C_COMMAND 'fd --type=directory --hidden --follow --exclude=.git'
end

# laramie, from the $theme_* palette that conf.d/colours.fish sources above its own
# interactive guard. `bg:-1` is the terminal's own background rather than an opaque colour,
# so ghostty's background-opacity/blur still show through the finder.
set -gx FZF_DEFAULT_OPTS "\
--height=40% --layout=reverse --border=rounded --info=inline --cycle \
--color=fg:$theme_foreground,bg:-1,hl:$theme_blue \
--color=fg+:$theme_white,bg+:$theme_dust,hl+:$theme_light_blue \
--color=info:$theme_purple,prompt:$theme_green,pointer:$theme_red \
--color=marker:$theme_light_green,spinner:$theme_yellow,header:$theme_gray \
--color=border:$theme_darker_gray"
