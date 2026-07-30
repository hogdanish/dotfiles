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

    __brewup_log info 'cleaning up'
    brew cleanup
    test $status -eq 0; or set -a failed 'brew cleanup'

    if test (count $failed) -gt 0
        __brewup_log error "failed: $failed"
        return 1
    end
    __brewup_log info 'everything is up to date'
end
