#!/usr/bin/env fish
#
# link-codex.fish — link authored codex config into its fixed discovery paths.
# usage: scripts/link-codex.fish [--force] [--dry-run]

set -g REPO (path resolve (status dirname)/..)
set -g SRC $REPO/codex
set -g CODEX_DEST $HOME/.codex
set -g SKILL_DEST $HOME/.agents/skills
set -g FAILED 0
set -g FORCE 0
set -g DRY_RUN 0

function __say --description 'status line — gum when available, stderr otherwise'
    set -l level $argv[1]
    set -l msg (string join ' ' -- $argv[2..])
    if type -q gum
        gum log --level $level -- $msg
    else
        echo >&2 "$level: $msg"
    end
end

function __link_one --argument-names from to label --description 'link one path idempotently'
    if not test -e $from
        set -g FAILED 1
        __say error "missing in repo: $label"
        return 1
    end
    if test -L $to; and test -e $to; and test (path resolve $to) = (path resolve $from)
        __say info "ok: $label"
        return 0
    end
    if test -e $to; and not test -L $to
        if test $FORCE -eq 0
            set -g FAILED 1
            __say error "$to is a real path — refusing to replace it (--force to back it up)"
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

function __check_dangling_skills --description 'report dangling user skill links'
    set -l broken
    for entry in $SKILL_DEST/*
        test -L $entry; and not test -e $entry; and set -a broken (path basename $entry)
    end
    test -n "$broken"; or return 0
    set -g FAILED 1
    __say error "dangling skill links in $SKILL_DEST: $broken"
end

function main --description 'link codex config and user-authored skills'
    argparse f/force n/dry-run h/help -- $argv; or return
    set -q _flag_force; and set -g FORCE 1
    set -q _flag_dry_run; and set -g DRY_RUN 1
    if set -q _flag_help
        echo 'usage: link-codex.fish [--force] [--dry-run]'
        return 0
    end
    test -d $SRC; or begin
        __say error "no codex/ in $REPO"
        return 1
    end

    __link_one $SRC/AGENTS.md $CODEX_DEST/AGENTS.md codex/AGENTS.md
    __link_one $SRC/config.toml $CODEX_DEST/config.toml codex/config.toml

    set -l skills (path filter -d $SRC/skills/*)
    if test -z "$skills"
        __say warn 'no skills in codex/skills — nothing to link'
    else
        for skill in $skills
            set -l name (path basename $skill)
            __link_one $skill $SKILL_DEST/$name skills/$name
        end
    end
    __check_dangling_skills

    test $FAILED -eq 0; or return 1
    __say info 'codex links complete'
end

main $argv
