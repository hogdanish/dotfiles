#!/usr/bin/env fish
#
# audit-config.fish — report drift between ~/.config on disk and what the repo tracks.
#
# the allowlist in .gitignore makes "ignored" the default, which is what fails safe. the
# cost of that default is that a newly installed tool can drop a file into ~/.config and
# nothing will ever mention it. this script is the other half of that bargain: it names
# every top-level entry that is neither tracked nor *known* to be junk, so the decision is
# made once, deliberately, instead of never.
#
# usage: scripts/audit-config.fish

set -g REPO (path resolve (status dirname)/..)
set -g ISSUES 0

# top-level entries that are ignored on purpose. an ignored entry NOT in this list is a
# new arrival. keep the justification with the entry — an unexplained name here is how a
# denylist rots into uselessness.
set -g KNOWN_IGNORED \
    .git \
    .DS_Store \
    raycast \
    op \
    homebrew \
    claude

function __say --description 'status line — gum when available, stderr otherwise'
    set -l level $argv[1]
    set -l msg (string join ' ' -- $argv[2..])
    if type -q gum
        gum log --level $level -- $msg
    else
        echo >&2 "$level: $msg"
    end
end

function __fail --description 'record a problem and report it'
    set -g ISSUES (math $ISSUES + 1)
    __say error $argv
end

function __check_new_arrivals --description 'entries neither tracked nor known-ignored'
    # -c: tracked, -o --exclude-standard: untracked but NOT ignored. together this is
    # "everything that would end up in the repo", which is the right question before the
    # first commit exists — a bare `ls-files` is empty then and flags the whole tree.
    set -l tracked (git -C $REPO ls-files -co --exclude-standard | string replace -r '/.*$' '' | sort -u)
    set -l found 0
    for entry in (path basename -- $REPO/* $REPO/.*)
        contains -- $entry $tracked; and continue
        contains -- $entry $KNOWN_IGNORED; and continue
        __fail "new arrival: $entry — track it (add a '!' rule) or add it to KNOWN_IGNORED"
        set found 1
    end
    test $found -eq 0; and __say info 'no unreviewed top-level entries'
end

function __check_secrets --description 'scan committed history for credentials'
    if not type -q betterleaks
        __fail 'betterleaks is not installed — the secret gate is not active'
        return
    end
    if not git -C $REPO rev-parse HEAD >/dev/null 2>&1
        __say warn 'no commits yet — skipping history scan'
        return
    end
    if betterleaks git $REPO --redact --no-banner --log-level error >/dev/null 2>&1
        __say info 'history is clean'
    else
        __fail 'betterleaks found credentials in history — run: betterleaks git ~/.config --redact'
    end
end

function __check_home_links --description 'home/ files are still symlinks into the repo'
    for link in ~/.zshrc ~/.zprofile ~/.ssh/config ~/.gnupg/gpg-agent.conf
        if not test -e $link
            __fail "missing: $link — run scripts/link-home.fish"
        else if not test -L $link
            __fail "$link is a real file, not a symlink — edits to it are NOT tracked"
        else if not string match -q -- "$REPO/home/*" (path resolve $link)
            __fail "$link points outside the repo: "(path resolve $link)
        end
    end
    __say info 'home/ symlinks intact'
end

function __check_claude_links --description 'authored claude config is still symlinked, not detached'
    set -l state $XDG_STATE_HOME/claude
    if not test -d $state
        __fail "\$CLAUDE_CONFIG_DIR is missing: $state"
        return
    end
    # claude code rewrites settings.json when you use /config. if it replaces the symlink
    # with a regular file, edits silently stop being tracked — this is the check for that.
    for f in CLAUDE.md settings.json rules
        if not test -L $state/$f
            __fail "$state/$f is not a symlink — edits to it are NOT tracked"
        else if not test -e $state/$f
            __fail "$state/$f is a broken symlink"
        end
    end
    __say info 'claude-code symlinks intact'
end

function __check_permissions --description 'sensitive untracked files are not world-readable'
    set -l cookies $REPO/yt-dlp/cookies.txt
    test -e $cookies; or return
    set -l mode (stat -f '%Lp' $cookies)
    test "$mode" = 600; or __fail "yt-dlp/cookies.txt is mode $mode — should be 600 (chmod 600)"
end

function __check_universals --description 'fish universal variables must stay at zero'
    set -l names (set -U --names)
    test -z "$names"; and return
    __fail "fish universals present: $names — machine state escaping version control"
end

function main
    __say info "auditing $REPO"
    __check_new_arrivals
    __check_secrets
    __check_home_links
    __check_claude_links
    __check_permissions
    __check_universals

    if test $ISSUES -eq 0
        __say info 'audit clean'
        return 0
    end
    __say error "$ISSUES issue(s) found"
    return 1
end

main $argv
