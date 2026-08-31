#!/usr/bin/env fish
#
# link-claude.fish — symlink the authored Claude Code config into $CLAUDE_CONFIG_DIR.
#
# $CLAUDE_CONFIG_DIR is $XDG_STATE_HOME/claude, not ~/.config/claude: transcripts, prompt
# history and vendored plugins are state, and ~48 mb of them must not sit inside a public
# repo's working tree. so the authored half lives here as claude-code/… and is linked back
# in, one entry at a time — never the whole directory, or the state would follow it.
#
# ⚠ the per-skill loop is the point. claude code merges every directory under
# $CLAUDE_CONFIG_DIR/skills/, ours and any a tool installs, so the repo can only own the
# ones it authored. an installer that drops a skill in beside them is left alone.
#
# ⚠ symlinked skills DO load — verified 2026-07-30 against claude code 2.1.220 with a probe
# skill pointed at /tmp. when a symlinked skill does not appear, the link is broken, not
# unsupported: `firecrawl setup skills` wrote 31 of them with a `../../../` prefix correct
# only for ~/.claude/skills, and all 31 dangled silently.
#
# idempotent: an existing correct link is left alone, a wrong one is reported, and a real
# file is never overwritten without --force.
#
# usage: scripts/link-claude.fish [--force] [--dry-run]

set -g REPO (path resolve (status dirname)/..)
set -g SRC $REPO/claude-code
set -g DEST $XDG_STATE_HOME/claude
set -g FAILED 0

# ⚠ argparse writes $_flag_* into the *calling function's* scope and fish does not expose a
# function's locals to its callees, so main's flags have to be promoted to globals for
# __link_one to see them. same shape as link-home.fish; getting it wrong is silent.
set -g FORCE 0
set -g DRY_RUN 0

# the fixed entries. skills are discovered instead, below.
# ⚠ themes/ is linked as a whole directory, unlike skills/: it is a user-only namespace (plugin
# themes ship inside the plugin, not here), so nothing else writes into it.
set -g LINKS CLAUDE.md settings.json themes

function __say --description 'status line — gum when available, stderr otherwise'
    set -l level $argv[1]
    set -l msg (string join ' ' -- $argv[2..])
    if type -q gum
        gum log --level $level -- $msg
    else
        echo >&2 "$level: $msg"
    end
end

function __link_one --argument-names from to label --description 'link one path, idempotently'
    if not test -e $from
        set -g FAILED 1
        __say error "missing in repo: $label"
        return 1
    end

    # already correct? say nothing loud and move on. ⚠ `test -L` first: `path resolve` on a
    # dangling link still prints a path, so comparing resolved paths alone would call a
    # broken link correct.
    if test -L $to; and test -e $to; and test (path resolve $to) = (path resolve $from)
        __say info "ok: $label"
        return 0
    end

    if test -e $to; and not test -L $to
        if test $FORCE -eq 0
            set -g FAILED 1
            __say error "$to is a real file — refusing to clobber it (--force to replace)"
            return 1
        end
        test $DRY_RUN -eq 1; or mv $to $to.pre-dotfiles
        __say warn "$to backed up to $to.pre-dotfiles"
    end

    if test $DRY_RUN -eq 1
        __say info "would link $label -> $from"
        return 0
    end

    set -l parent (path dirname $to)
    test -d $parent; or mkdir -p $parent

    rm -f $to
    ln -s $from $to
    __say info "linked $label"
end

function __prune_broken_skills --description 'report dangling symlinks left by other installers'
    set -l broken
    for entry in $DEST/skills/*
        test -L $entry; and not test -e $entry; and set -a broken (path basename $entry)
    end
    test -n "$broken"; or return 0
    __say warn "dangling skill links in $DEST/skills: $broken"
    __say warn 'these load nothing. remove them, or fix whatever installed them.'
end

function main --description 'link authored Claude config and skills'
    argparse f/force n/dry-run h/help -- $argv; or return
    set -q _flag_force; and set -g FORCE 1
    set -q _flag_dry_run; and set -g DRY_RUN 1
    if set -q _flag_help
        echo 'usage: link-claude.fish [--force] [--dry-run]'
        return 0
    end

    if not test -d $SRC
        __say error "no claude-code/ in $REPO"
        return 1
    end

    for entry in $LINKS
        __link_one $SRC/$entry $DEST/$entry claude/$entry
    end

    # one link per authored skill. `path filter -d` on a glob that may match nothing is safe:
    # an unmatched glob expands to zero arguments for `path`, rather than erroring (status 124).
    set -l skills (path filter -d $SRC/skills/*)
    if test -z "$skills"
        __say warn 'no skills in claude-code/skills/ — nothing to link'
    else
        for skill in $skills
            set -l name (path basename $skill)
            __link_one $skill $DEST/skills/$name skills/$name
        end
    end

    __prune_broken_skills

    test $FAILED -eq 0; or return 1
    __say info 'claude-code links complete'
end

main $argv
