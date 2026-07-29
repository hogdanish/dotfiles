# bun ships a fish completion for `bun` (homebrew links it into vendor_completions.d) but
# none for `bunx`, and nothing else provides one either — not embedded in fish, not scraped
# from a man page. so `bunx <TAB>` falls through to plain file completion, which is never
# what you want in package position.
#
# candidates come from bun's install cache: those are exactly the packages bunx can run
# without hitting the network. purely local `path` builtins, so no per-Tab fork or fetch.

function __bunx_cached_packages --description 'npm packages already in bun\'s install cache'
    set -q BUN_INSTALL_CACHE_DIR; or return

    # the cache mixes three things in one directory: `<name>` package dirs, `<name>@<ver>@@<n>`
    # extract dirs, and `<hash>.npm` manifest files. only the first is a package name.
    path basename -- (path filter -d -- $BUN_INSTALL_CACHE_DIR/*) | string match -rv '@@|^@'

    # scoped packages sit one level deeper; rebuild them as `@scope/name`
    string replace -- $BUN_INSTALL_CACHE_DIR/ '' \
        (path filter -d -- $BUN_INSTALL_CACHE_DIR/@*/*) | string match -rv '@@'
end

# ⚠ `-f` goes on each first-arg rule, never globally: it is scoped by the `-n` on its own
# line, so this suppresses filenames in package position while leaving them available to the
# package's own CLI afterwards (`bunx prettier foo.js`).
complete -c bunx -f -n __fish_is_first_arg -a '(__bunx_cached_packages)' -d 'cached package'

complete -c bunx -f -n __fish_is_first_arg -l bun -d 'force the command to run with Bun, not Node.js'
complete -c bunx -f -n __fish_is_first_arg -l no-install -d 'skip installation if not already installed'
complete -c bunx -f -n __fish_is_first_arg -l verbose -d 'verbose output during installation'
complete -c bunx -f -n __fish_is_first_arg -l silent -d 'suppress output during installation'

# ⚠ deliberately unconditional: `__fish_is_first_arg` is already false by the time the cursor
# is on -p's argument, so adding it here would silently fall back to file completion.
complete -c bunx -s p -l package -x -a '(__bunx_cached_packages)' \
    -d 'package to install when the binary name differs'
