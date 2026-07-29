# abbreviations. an abbr expands in the buffer before the command runs, so history records
# the real command — that is why `abbr -a cd z` is right where `alias cd=z` is not.
# anything that must also work in scripts and pipelines is a function, not an abbr.
#
# ⚠ every target here must actually exist on this machine. three entries were dead for
# months because it was not checked; see .claude/rules/machine-inventory.md.
#
# an abbreviation is purely a line-editor feature — it expands on typed input and scripts
# never see one, so defining 30 of them in a non-interactive shell is 0.4 ms (~9% of its
# whole startup) spent on something nothing can read. `fish -c` sources all of conf.d/.
# ⚠ the every-target-resolves check in the fish skill must therefore run under `fish -i`.
status is-interactive; or return

# modern replacements for the coreutils defaults
abbr -a c cls # functions/cls.fish — clear the screen *and* the scrollback
abbr -a cd z # zoxide, initialised in conf.d/tools.fish
abbr -a ls 'eza --group-directories-first --icons=auto'
abbr -a ll 'eza --group-directories-first --icons=auto --long --git'
abbr -a la 'eza --group-directories-first --icons=auto --long --git --all'
abbr -a tree 'eza --tree --level=2 --icons=auto' # `tre` is not installed; eza does this natively
abbr -a find fd
abbr -a cat bat
abbr -a nano micro
abbr -a code code-insiders

# ⚠ `trash` (macos-shipped, /usr/bin/trash) moves to the Trash instead of unlinking, which
# is the documented preference on this machine. it does NOT take rm's flags — the expansion
# is visible in the buffer, so edit it there, and use `command rm` when you mean the real one.
abbr -a rm trash

abbr -a ping 'ping -c 5'
abbr -a refresh 'exec fish' # reload this shell in place

# git
abbr -a g git
abbr -a ga 'git add .'

# homebrew. `; and` rather than `&&`: both work in fish 4, but the word forms are the house
# spelling and fish_indent formats them consistently.
abbr -a brewup 'brew update; and brew upgrade; and brew cleanup'

# claude code
abbr -a cc claude
abbr -a ccc 'claude --continue'
abbr -a ccd 'claude --dangerously-skip-permissions'
abbr -a ccr 'claude --resume'

# projects and apps
abbr -a chat 'cd $PROJECTS/chat; and claude'
abbr -a aseprite 'open "$HOME/Library/Application Support/Steam/steamapps/common/Aseprite/Aseprite.app"'

# dirstack: `..3` -> `../../..`, and `--position anywhere` so it works as an argument too
# (`cp foo ..3`). string repeat leaves a trailing slash; string sub -e -1 drops it.
# ⚠ a literal list, not `(seq 2 9)` — seq is an external command and forking it here cost
# 1.7 ms on every interactive start, more than every cached tool init combined.
for i in 2 3 4 5 6 7 8 9
    abbr -a --position anywhere -- ..$i (string repeat -n $i ../ | string sub -e -1)
end

# bash-style !! — recall the previous command line. --function means the expansion is
# computed at expansion time by functions/__abbr_last_history_item.fish.
abbr -a '!!' --position anywhere --function __abbr_last_history_item
