# git dirs
# -g, not -gx: only this file reads it, and the `__` prefix keeps it out of git's namespace.
set -g __git_config_dir $XDG_CONFIG_HOME/git
# ⚠ this is why the global config sits at the unusual path `git/.gitconfig` rather than
# git's own default `git/config`.
set -gx GIT_CONFIG_GLOBAL "$__git_config_dir/.gitconfig"
# guarded: an unconditional `mkdir -p` here cost 1.3 ms on every single shell start.
test -d $__git_config_dir; or mkdir -p $__git_config_dir
test -f $GIT_CONFIG_GLOBAL; or touch $GIT_CONFIG_GLOBAL
set -gx GIT_CONFIG_SYSTEM /dev/null # effectively disable git system config
set -gx GIT_PAGER delta
