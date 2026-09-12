# functions/brewup.fish
#
# the interactive counterpart to the `brew autoupdate` launchd agent (repo CLAUDE.md). the agent
# runs the same brew phases every 12h but deliberately cannot `sudo`, so this is also where the
# two pkg-artifact casks — temurin@25 and font-sf-pro — actually get upgraded, and the only place
# app store apps are updated at all.
#
# ⚠ a function rather than the `abbr` it replaced: the mas phase needs a conditional, and an
# abbreviation cannot hold one. that costs the abbr property of expanding in the buffer, which is
# the trade the conditional is worth.

function __brewup_log --argument-names level --description 'gum log, degrading to printf'
    set -e argv[1]
    if type -q gum
        gum log --level $level -- $argv
    else
        printf '%s: %s\n' $level "$argv" >&2
    end
end

# ⚠ clauth is installed from git, not crates.io, and a git install NEVER self-updates — cargo only
# reinstalls when told to. it is here rather than in a timer because this is the command a human
# runs to bring the machine current, and the daemon restart below wants a human nearby.
# the no-op costs ~0.5s: cargo fetches the ref and prints "already installed" without building.
function __brewup_clauth --description 'refresh the git-installed clauth and restart its daemon'
    command -q cargo; or return 0

    set -l out (cargo install --git https://github.com/uwuclxdy/clauth --locked 2>&1 | string collect)
    set -l rc $status
    if test $rc -ne 0
        __brewup_log error 'clauth refresh failed'
        printf '%s\n' $out
        return 1
    end

    # ⚠ the running daemon keeps the OLD code in memory, and it performs macos keychain writes of
    # its own on every auto-switch — exactly where the v0.15.1 truncation bug did its damage. so a
    # new build is only actually live once the agent is kicked.
    if string match -q '*Replacing*' -- $out
        __brewup_log info 'clauth updated; restarting its daemon'
        launchctl kickstart -k gui/(id -u)/dev.uwuclxdy.clauth 2>/dev/null
        or __brewup_log warn 'clauth daemon restart failed — launchctl print gui/(id -u)/dev.uwuclxdy.clauth'
    else
        __brewup_log info 'clauth is up to date'
    end

    # ⚠ the ONLY reason clauth comes from git is that release v0.15.1 corrupts the keychain login
    # item (repo CLAUDE.md). when a newer release lands, re-read its notes and consider moving back
    # to crates.io, which is signed and self-updating. non-fatal and best-effort: no network, no
    # nag.
    command -q curl; or return 0
    set -l latest (curl -fsS --max-time 5 https://api.github.com/repos/uwuclxdy/clauth/releases/latest 2>/dev/null |
        string match -rg '"tag_name"\s*:\s*"([^"]+)"')
    test -n "$latest"; or return 0
    if test "$latest" != v0.15.1
        __brewup_log warn "clauth $latest is released — if it carries the keychain fix, move back to `cargo install clauth`"
    end
end

function brewup --description 'update homebrew and the mac app store, then clean up'
    # collected rather than `; and`-chained: a single failed cask must not skip the cleanup, and
    # the caller wants to know everything that broke, not just the first thing.
    set -l failed

    __brewup_log info 'refreshing homebrew metadata'
    brew update
    test $status -eq 0; or set -a failed 'brew update'

    __brewup_log info 'upgrading formulae and casks'
    brew upgrade
    test $status -eq 0; or set -a failed 'brew upgrade'

    # ⚠ `mas update` REQUIRES root — `mas help update` says so outright. that is exactly why the
    # background agent does not do this and this function does: here a human is present and
    # /etc/pam.d/sudo_local turns the prompt into a touch id tap.
    # ⚠ gated on `mas outdated` so an up-to-date machine raises no sudo prompt at all. that
    # command defaults to --inaccurate, whose false negatives can hide an update for a few hours
    # (app store api eventual consistency) — the next run catches it. --accurate is not an option:
    # it starts and cancels a real download per app and opens dialogs.
    if type -q mas
        set -l pending (mas outdated)
        if test (count $pending) -gt 0
            # ⚠ $(…), not (…): a bare command substitution does not expand inside double quotes.
            __brewup_log info "upgrading $(count $pending) app store app(s)"
            printf '  %s\n' $pending
            sudo mas upgrade
            test $status -eq 0; or set -a failed 'mas upgrade'
        else
            __brewup_log info 'app store is up to date'
        end
    end

    __brewup_clauth
    test $status -eq 0; or set -a failed clauth

    __brewup_log info 'cleaning up'
    brew cleanup
    test $status -eq 0; or set -a failed 'brew cleanup'

    if test (count $failed) -gt 0
        __brewup_log error "failed: $failed"
        return 1
    end
    __brewup_log info 'everything is up to date'
end
