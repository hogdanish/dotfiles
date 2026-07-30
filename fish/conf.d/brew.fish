# homebrew: the prefix, everything on $PATH that comes from it, and the HOMEBREW_* settings.
# this is the only file that establishes the base path, so it must stay the first conf.d
# snippet to touch it.

# prefix, before anything expands it. ghostty launches fish directly (`command =
# /opt/homebrew/bin/fish --login --interactive`), so no `brew shellenv` is ever inherited
# and an unset prefix would make the path lines below expand to a bare /bin and /sbin.
# `test -n` rather than `set -q`: an exported-but-empty value must also be repaired.
test -n "$HOMEBREW_PREFIX"; or set -gx HOMEBREW_PREFIX /opt/homebrew

# path
# ⚠ fish_user_paths is declared global and empty first. without it, `fish_add_path -g` reads
# whatever a leftover *universal* holds and copies it into the new global, preserving exactly
# the junk it is meant to drop. this is also the first conf.d file to touch the path, so
# nothing legitimate is being discarded.
set -g fish_user_paths

# ⚠ collected into one list and added with a SINGLE fish_add_path call. fish's embedded init
# registers __fish_reconstruct_path as an `--on-variable fish_user_paths` handler, so every
# fish_add_path rebuilds the whole of $PATH — measured at ~0.55 ms per call. the list order
# is the resulting $PATH order, so it must stay as written.

# prefer homebrew's newer builds of two tools macos also ships. both formulae are keg-only
# or prefixed, so brew does not symlink them into bin/ and the system copy would win:
#   curl  8.21.0, openssl 3.6.3, http/3, krb5   vs  system 8.7.1, libressl 3.3.6
#   make  gnu make 4.4.1                        vs  system gnu make 3.81 (2006)
# HOMEBREW_FORCE_BREWED_CURL below makes brew itself use the same curl.
#
# ⚠ deliberately NOT coreutils. gnu ls/sed/date/stat/readlink change flag semantics for every
# *child process*, not just this shell, and the breakage surfaces silently months later. the
# g-prefixed binaries (gls, gdate, gstat) are already on $PATH for the rare case.
# fish_add_path silently skips directories that do not exist, so an uninstalled formula is
# a no-op and needs no guard.
set -l brewpath "$HOMEBREW_PREFIX/opt/curl/bin" "$HOMEBREW_PREFIX/opt/make/libexec/gnubin"

# homebrew's own bin, last in the list and therefore last of these on $PATH.
set -a brewpath "$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin"

# -m/--move so homebrew wins over /usr/bin: /etc/paths.d/homebrew already appends
# /opt/homebrew/bin, which without --move would leave it *last* on $PATH. the flag is
# harmless for the keg-only entries above — they are on no other path list.
fish_add_path -g -m $brewpath

# settings
# ⚠ every HOMEBREW_* below is a *presence* flag: homebrew declares them `boolean: :set`, so any
# value at all — including `0` — enables the behaviour. there is no way to spell "off" except by
# not setting the variable. `HOMEBREW_DEVELOPER 0` lived here and reported `set` in `brew config`,
# i.e. it turned warnings into errors and dropped the auto-update interval to an hour. it is gone;
# do not reintroduce it, or any other `<VAR> 0`. verify with `brew config`, not by reading this file.
#
# ⚠ HOMEBREW_AUTO_UPDATE_SECS gates the *git* `brew update` run before install/upgrade/tap, and
# the launchd job from domt4/autoupdate now does that on its own 12h schedule — so a week here
# only stops an interactive `brew install` from stalling to redo it. the json api metadata is a
# different variable (HOMEBREW_API_AUTO_UPDATE_SECS, 450 s) and is deliberately left at default,
# so nothing goes stale. ⚠ if `brew autoupdate` is ever stopped, lower this again.
set -gx HOMEBREW_AUTO_UPDATE_SECS 604800
set -gx HOMEBREW_NO_ANALYTICS 1
set -gx HOMEBREW_NO_ENV_HINTS 1
set -gx HOMEBREW_BUNDLE_NO_LOCK 1
set -gx HOMEBREW_DOWNLOAD_CONCURRENCY auto
set -gx HOMEBREW_FORCE_BREWED_CURL 1
set -gx HOMEBREW_FORCE_BREWED_GIT 1
set -gx HOMEBREW_FORCE_BREWED_CMAKE 1
set -gx HOMEBREW_CURL_RETRIES 3
set -gx HOMEBREW_BAT 1
set -gx HOMEBREW_CASK_OPTS --no-quarantine

# ⚠ never call `brew` from this file — it is a ruby process on every shell start, including
# non-interactive ones. that is why there is no cached `brew shellenv` here: the four path
# lines above are all of it that this machine actually needs.
#
# there is no longer a functions/brew.fish either. it wrapped every invocation in
# `op plugin run --` for HOMEBREW_GITHUB_API_TOKEN, which since homebrew 4 buys only a higher
# github api rate limit for `brew search --desc` and the developer commands — metadata comes
# from the json api and touches api.github.com not at all. it cost a 1password prompt per
# session on the most-used command here. ⚠ if it ever comes back, this file must call
# `command brew`: an autoloaded function is visible *during* conf.d sourcing.
#
# no completions wiring either: homebrew installs to share/fish/vendor_completions.d, which
# fish already puts on $fish_complete_path automatically. the share/fish/completions path
# this file used to append does not exist.
