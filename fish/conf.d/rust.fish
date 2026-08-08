# rustup is keg-only because it conflicts with Homebrew's monolithic rust formula.
# Keep rustup's toolchains and Cargo's mixed state/cache tree out of $HOME while
# leaving project target directories local to each repository.
set -l rustup_bin $HOMEBREW_PREFIX/opt/rustup/bin
test -x $rustup_bin/rustup; or return

test -n "$RUSTUP_HOME"; or set -gx RUSTUP_HOME $XDG_DATA_HOME/rustup
test -n "$CARGO_HOME"; or set -gx CARGO_HOME $XDG_DATA_HOME/cargo
test -n "$SCCACHE_DIR"; or set -gx SCCACHE_DIR $XDG_CACHE_HOME/sccache

set -l rust_dirs $RUSTUP_HOME $CARGO_HOME $CARGO_HOME/bin $SCCACHE_DIR
set -l missing (path filter -vd $rust_dirs)
test -n "$missing"; and mkdir -p $missing

# Homebrew's rustup keg contains the rustc/cargo proxies; $CARGO_HOME/bin holds
# `cargo install` binaries. Append both so Homebrew and project tools keep precedence.
fish_add_path -g -a $CARGO_HOME/bin $rustup_bin
