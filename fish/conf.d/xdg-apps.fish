# point CLI tools at the XDG base dirs instead of littering $HOME. the base XDG_* variables
# themselves are set in conf.d/_init.fish; this file only maps per-app variables onto them.
#
# convention: config -> XDG_CONFIG_HOME · data -> XDG_DATA_HOME · history and other
# regenerable state -> XDG_STATE_HOME · caches -> XDG_CACHE_HOME.
#
# ⚠ NO early `return` anywhere in this file. it is one file holding many independent blocks,
# and a `return` in the middle silently skips every block below it — the exact failure that
# `type -q starship; or return 1` used to cause in _shell.fish.
#
# ⚠ this file sorts LAST in conf.d, so it must only hold variables that no *earlier* conf.d
# file reads. anything a tool's init consumes at source time belongs with that tool:
# BAT_* and LESS_* in colours.fish, FZF_* in fzf.fish.
#
# ⚠ GNUPGHOME is deliberately absent. only fish would export it, so launchd, GUI apps, cron
# and Claude Code's zsh would each create a second, empty ~/.gnupg. see the repo CLAUDE.md.
#
# each block is `set -q`-guarded so an already-exported value wins. adding a tool: check it
# is actually installed first (.claude/rules/machine-inventory.md), and see the fishconf
# crib sheet in the fish skill for the variable names of ~26 more.

if type -q less
    # ⚠ deliberately no LESSKEY. on less >= 582 (704 is installed here) LESSKEY names a
    # *compiled* lesskey binary, while less already searches $XDG_CONFIG_HOME/lesskey for the
    # modern source format by itself. pointing LESSKEY at that path was a no-op while no file
    # existed and would have made less parse a source file as a binary the moment one did.
    # the source-file override, if ever needed, is LESSKEYIN — not LESSKEY.
    #
    # state, not data: this is a regenerable position cache, not something to back up
    set -q LESSHISTFILE; or set -gx LESSHISTFILE $XDG_STATE_HOME/lesshst
end

if type -q node
    set -q NODE_REPL_HISTORY; or set -gx NODE_REPL_HISTORY $XDG_STATE_HOME/node_repl_history
end

if type -q npm
    set -q NPM_CONFIG_USERCONFIG; or set -gx NPM_CONFIG_USERCONFIG $XDG_CONFIG_HOME/npm/npmrc
    set -q NPM_CONFIG_CACHE; or set -gx NPM_CONFIG_CACHE $XDG_CACHE_HOME/npm
end

if type -q rg
    set -q RIPGREP_CONFIG_PATH; or set -gx RIPGREP_CONFIG_PATH $XDG_CONFIG_HOME/ripgrep/config
end

if type -q wget
    # wget reads no default rc outside $HOME; this also moves the HSTS db, via wgetrc itself
    set -q WGETRC; or set -gx WGETRC $XDG_CONFIG_HOME/wgetrc
end

if type -q sqlite3
    set -q SQLITE_HISTORY; or set -gx SQLITE_HISTORY $XDG_STATE_HOME/sqlite_history
end

if type -q python3
    set -q PYTHON_HISTORY; or set -gx PYTHON_HISTORY $XDG_STATE_HOME/python_history
end

if type -q zoxide
    # ⚠ zoxide is the one CLI here that is not XDG-aware on macos: it uses the `dirs` crate,
    # whose data dir is ~/Library/Application Support. without this the frecency database sits
    # outside the tree everything else in this file was written to consolidate.
    # safe despite this file sorting last — conf.d/tools.fish sources `zoxide init fish`
    # earlier, but that init never reads _ZO_DATA_DIR; only the binary does, at call time.
    set -q _ZO_DATA_DIR; or set -gx _ZO_DATA_DIR $XDG_DATA_HOME/zoxide
end

# glamour — the markdown renderer vendored into gh, which reads GLAMOUR_STYLE for issue and PR
# bodies, `gh repo view`, and release notes. this is what finally consumes
# ~/.config/glamour/laramie.json (known gap #2 in the repo CLAUDE.md).
# ⚠ verified end-to-end rather than inferred: under `script`, `gh repo view cli/cli` emits
# 38;2;187;154;247 (laramie purple) for headings with this set, and 256-colour 38;5;228 without.
# ⚠ gum is the *other* glamour surface and does NOT read this variable — it needs
# GUM_FORMAT_THEME, which conf.d/gum.fish sets from the same file.
# ⚠ a missing path renders unstyled rather than erroring, so it is checked, not assumed.
set -l glamour_style $XDG_CONFIG_HOME/glamour/laramie.json
if test -r "$glamour_style"
    set -q GLAMOUR_STYLE; or set -gx GLAMOUR_STYLE $glamour_style
end
