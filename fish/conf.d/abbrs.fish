# abbreviations. an abbr expands in the buffer before the command runs, so history records
# the real command — that is why `abbr -a cd z` is right where `alias cd=z` is not.
# anything that must also work in scripts and pipelines is a function, not an abbr.
#
# ⚠ every target here must actually exist on this machine. three entries were dead for
# months because it was not checked; see .claude/rules/machine-inventory.md.
#
# an abbreviation is purely a line-editor feature — it expands on typed input and scripts
# never see one, so defining them in a non-interactive shell is time spent on something
# nothing can read. `fish -c` sources all of conf.d/, hence the guard below.
# ⚠ the every-target-resolves check in the fish skill must therefore run under `fish -i`.
# measured 2026-07-30: all 68 abbrs cost 0.30 ms of a 9.93 ms interactive startup, and the
# 38 git ones added here moved the median by less than the run-to-run noise.
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

# git. these expand to *raw git*, not to the aliases in git/.gitconfig, even where
# an alias exists — the point of an abbr is that the buffer and the history end up
# holding a command that also works from zsh, from a script, and on another machine.
# the exceptions are `glg`/`gla`/`gll`/`gbr`, whose formats live in the gitconfig and
# have nowhere shorter to come from.
#
# ⚠ two obvious names are deliberately missing. `gs` is ghostscript and `gcp` is gnu
# coreutils' cp, both installed here (Brewfile), and an abbr at command position would
# shadow them in the buffer. `gss` and `gchp` stand in.
abbr -a g git
abbr -a ga 'git add .'
abbr -a gaa 'git add --all'
abbr -a gap 'git add --patch'
abbr -a gst 'git status'
abbr -a gss 'git status --short --branch'

# committing
abbr -a gc 'git commit'
abbr -a gcm 'git commit --message'
abbr -a gcam 'git commit --all --message'
abbr -a gam 'git commit --amend --no-edit'

# exchanging with a remote. no --set-upstream anywhere: push.autoSetupRemote is on,
# and fetch.prune is already true, so neither flag needs typing.
abbr -a gp 'git push'
abbr -a gpf 'git push --force-with-lease'
abbr -a gl 'git pull'
abbr -a gf 'git fetch --all'
abbr -a gcl 'git clone'

# branches
abbr -a gsw 'git switch'
abbr -a gswc 'git switch --create'
abbr -a gco 'git checkout'
abbr -a gb 'git branch'
abbr -a gbd 'git branch --delete'
abbr -a gbr 'git branches' # gitconfig alias: sorted, with upstream and subject

# reading history. delta is git's pager, so all of these are already themed.
abbr -a gd 'git diff'
abbr -a gds 'git diff --staged'
abbr -a gsh 'git show'
abbr -a gbl 'git blame'
abbr -a glg 'git lg' # gitconfig alias: --graph
abbr -a gla 'git lga' # ...the same, --all
abbr -a gll 'git ll' # ...flat, last 20

# undoing. `grh` is destructive, which is exactly why it is an abbr and not a
# function: the full `git reset --hard` sits in the buffer before you press enter.
abbr -a grs 'git restore'
abbr -a gun 'git restore --staged'
abbr -a grh 'git reset --hard'

# stashing and replaying
abbr -a gsta 'git stash push'
abbr -a gstp 'git stash pop'
abbr -a gstl 'git stash list'
abbr -a grb 'git rebase'
abbr -a grbi 'git rebase --interactive'
abbr -a grbc 'git rebase --continue'
abbr -a grba 'git rebase --abort'
abbr -a gchp 'git cherry-pick'
abbr -a gwt 'git worktree'

# homebrew. ⚠ `brewup` is deliberately NOT here any more — it is `functions/brewup.fish`, because
# it now gates the app store phase on `mas outdated` and an abbreviation cannot hold a conditional.

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
# computed at expansion time by functions/internal/__abbr_last_history_item.fish.
abbr -a '!!' --position anywhere --function __abbr_last_history_item
