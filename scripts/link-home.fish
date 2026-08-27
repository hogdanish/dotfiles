#!/usr/bin/env fish
#
# link-home.fish — symlink home/* into $HOME.
#
# a few configs cannot live under ~/.config because their consumer hardcodes a $HOME path
# and has no XDG support: zsh reads ~/.zshenv and ~/.zshrc, openssh reads ~/.ssh/config,
# and gpg-agent reads ~/.gnupg/gpg-agent.conf. they are tracked here as home/… and linked into
# place, so the repo is a complete description of the machine rather than "everything except a few
# files".
#
# idempotent: an existing correct link is left alone, a wrong one is reported, and a real
# file is never overwritten without --force.
#
# usage: scripts/link-home.fish [--force] [--dry-run]

set -g REPO (path resolve (status dirname)/..)
set -g FAILED 0

# ⚠ argparse writes $_flag_* into the *calling function's* scope, and fish does NOT expose a
# function's locals to the functions it calls. __link_one therefore cannot see main's flags —
# they have to be promoted to globals. verified on 4.8.1; getting this wrong is silent, since
# `set -q $_flag_force` simply reads false in the callee.
set -g FORCE 0
set -g DRY_RUN 0

# source (relative to home/) → destination under $HOME
set -g LINKS \
    zshenv:.zshenv \
    zshrc:.zshrc \
    zprofile:.zprofile \
    ssh/config:.ssh/config \
    gnupg/gpg-agent.conf:.gnupg/gpg-agent.conf

function __say --description 'status line — gum when available, stderr otherwise'
    set -l level $argv[1]
    set -l msg (string join ' ' -- $argv[2..])
    if type -q gum
        gum log --level $level -- $msg
    else
        echo >&2 "$level: $msg"
    end
end

function __link_one --argument-names src dst --description 'link one file, idempotently'
    set -l from $REPO/home/$src
    set -l to $HOME/$dst

    if not test -e $from
        set -g FAILED 1
        __say error "missing in repo: home/$src"
        return 1
    end

    # already correct? say nothing loud and move on.
    if test -L $to; and test (path resolve $to) = (path resolve $from)
        __say info "ok: ~/$dst"
        return 0
    end

    if test -e $to; and not test -L $to
        if test $FORCE -eq 0
            set -g FAILED 1
            __say error "~/$dst is a real file — refusing to clobber it (--force to replace)"
            return 1
        end
        # keep a copy. this is someone's working config until proven otherwise.
        test $DRY_RUN -eq 1; or mv $to $to.pre-dotfiles
        __say warn "~/$dst backed up to ~/$dst.pre-dotfiles"
    end

    if test $DRY_RUN -eq 1
        __say info "would link ~/$dst -> $from"
        return 0
    end

    # ⚠ mkdir -p first: ~/.ssh and ~/.gnupg may not exist on a fresh machine, and both
    # must be 0700 or their tools refuse to read anything inside them.
    set -l parent (path dirname $to)
    test -d $parent; or mkdir -m 700 -p $parent

    rm -f $to
    ln -s $from $to
    __say info "linked ~/$dst"
end

function main
    argparse f/force n/dry-run h/help -- $argv; or return
    set -q _flag_force; and set -g FORCE 1
    set -q _flag_dry_run; and set -g DRY_RUN 1
    if set -q _flag_help
        echo 'usage: link-home.fish [--force] [--dry-run]'
        return 0
    end

    for pair in $LINKS
        set -l parts (string split -m1 ':' -- $pair)
        __link_one $parts[1] $parts[2]
    end

    # git tracks only the executable bit, so these come back 0755/0644 on a fresh clone.
    # ssh and gpg both refuse to run against a group- or world-writable directory.
    if test $DRY_RUN -eq 0
        for d in $HOME/.ssh $HOME/.gnupg
            test -d $d; and chmod 700 $d
        end
    end

    test $FAILED -eq 0; or return 1
    __say info 'home links complete'
end

main $argv
