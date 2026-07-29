# bun — relocate its state onto the xdg base dirs, and put `bun add -g` binaries on $PATH.
#
# bun's default is a single ~/.bun tree holding the install cache, globally installed packages
# and their bin symlinks all together. the three BUN_INSTALL_* variables are the only way to
# split that across cache and data: BUN_INSTALL on its own relocates the tree but keeps it
# monolithic, and BUN_INSTALL_BIN overrides it regardless. all verified on bun 1.3.14.
#
# ⚠ BUN_RUNTIME_TRANSPILER_CACHE_PATH is deliberately absent. bun checks $XDG_CACHE_HOME
# itself before falling back to ~/Library/Caches/bun, so the transpiler cache already lands
# in $XDG_CACHE_HOME/bun/@t@ and setting the variable would only restate that.
#
# behaviour (as opposed to location) is configured in $XDG_CONFIG_HOME/.bunfig.toml — see
# that file's header for why the path is that unusual shape.

type -q bun; or return

# each is `set -q`-guarded so an already-exported value wins, matching conf.d/xdg-apps.fish
set -q BUN_INSTALL_CACHE_DIR; or set -gx BUN_INSTALL_CACHE_DIR $XDG_CACHE_HOME/bun/install
set -q BUN_INSTALL_GLOBAL_DIR; or set -gx BUN_INSTALL_GLOBAL_DIR $XDG_DATA_HOME/bun/global
set -q BUN_INSTALL_BIN; or set -gx BUN_INSTALL_BIN $XDG_DATA_HOME/bun/bin
# local `bun create` templates; keeps bun from making a ~/.bun-create dotdir
set -q BUN_CREATE_DIR; or set -gx BUN_CREATE_DIR $XDG_DATA_HOME/bun/create

# bun creates all four on demand, but ⚠ fish_add_path silently skips a directory that does
# not exist yet — it returns 1 and emits no `set`. so this one has to be real beforehand,
# or the very first `bun add -g` lands somewhere that is not on $PATH.
test -d $BUN_INSTALL_BIN; or mkdir -p $BUN_INSTALL_BIN

# sorts after brew.fish, which is load-bearing: brew.fish resets `set -g fish_user_paths`,
# so an entry added before it would be discarded. `-g` is explicit so the call can never
# resolve to a universal.
#
# ⚠ `-a`, because fish_add_path *prepends* by default — without it a `bun add -g` package
# shadows the homebrew binary of the same name, and the Brewfile is the machine's inventory.
# appending still leaves it ahead of /usr/bin: $fish_user_paths is prepended to $PATH whole.
fish_add_path -g -a $BUN_INSTALL_BIN
