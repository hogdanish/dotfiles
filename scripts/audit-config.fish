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
    .rumdl_cache \
    raycast \
    op \
    homebrew \
    claude \
    .wrangler \
    cagent \
    caddy

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
    for link in ~/.zshenv ~/.zshrc ~/.zprofile ~/.ssh/config ~/.gnupg/gpg-agent.conf
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
    for f in CLAUDE.md settings.json
        if not test -L $state/$f
            __fail "$state/$f is not a symlink — edits to it are NOT tracked"
        else if not test -e $state/$f
            __fail "$state/$f is a broken symlink"
        end
    end

    if test -L $state/rules
        __fail "$state/rules is an obsolete rules symlink — remove it"
    end

    # every authored skill must be linked in, or it is written but never loaded.
    for skill in (path filter -d $REPO/claude-code/skills/*)
        set -l name (path basename $skill)
        if not test -L $state/skills/$name
            __fail "skills/$name is authored but not linked — run scripts/link-claude.fish"
        else if not test -e $state/skills/$name
            __fail "$state/skills/$name is a broken symlink"
        end
    end

    # ...and the reverse: a dangling link loads nothing while looking installed. this is the
    # exact failure `firecrawl setup skills` produced 31 times, undetected for two days.
    for entry in $state/skills/*
        test -L $entry; and not test -e $entry
        and __fail "dangling skill link: "(path basename $entry)" — it loads nothing"
    end

    __say info 'claude-code symlinks intact'
end

function __check_codex_links --description 'Codex config, hooks and shared global skills are linked'
    set -l authored_config config.toml hooks.json
    for profile in (path filter -f $REPO/codex/*.config.toml)
        set -a authored_config (path basename $profile)
    end
    for f in $authored_config
        if not test -L $HOME/.codex/$f
            __fail "$HOME/.codex/$f is not a symlink — edits to it are NOT tracked"
        else if not test -e $HOME/.codex/$f
            __fail "$HOME/.codex/$f is a broken symlink"
        else if not string match -q -- "$REPO/codex/*" (path resolve $HOME/.codex/$f)
            __fail "$HOME/.codex/$f points outside the repo: "(path resolve $HOME/.codex/$f)
        end
    end

    if not test -L $HOME/.codex/AGENTS.md
        __fail "$HOME/.codex/AGENTS.md is not a symlink — edits to it are NOT tracked"
    else if not test -e $HOME/.codex/AGENTS.md
        __fail "$HOME/.codex/AGENTS.md is a broken symlink"
    else if not test (path resolve $HOME/.codex/AGENTS.md) = (path resolve $REPO/claude-code/CLAUDE.md)
        __fail "$HOME/.codex/AGENTS.md does not resolve to claude-code/CLAUDE.md"
    end

    for skill in (path filter -d $REPO/claude-code/skills/*)
        set -l name (path basename $skill)
        if not test -L $HOME/.agents/skills/$name
            __fail "shared global skill $name is not linked for Codex — run scripts/link-codex.fish"
        else if not test -e $HOME/.agents/skills/$name
            __fail "$HOME/.agents/skills/$name is a broken symlink"
        else if not test (path resolve $HOME/.agents/skills/$name) = (path resolve $skill)
            __fail "$HOME/.agents/skills/$name does not resolve to claude-code/skills/$name"
        end
    end

    for entry in $HOME/.agents/skills/*
        test -L $entry; and not test -e $entry
        and __fail "dangling Codex skill link: "(path basename $entry)" — it loads nothing"
    end
    __say info 'codex symlinks intact'
end

function __check_commongrounds_codex --description 'COMMONGROUNDS Codex adapters are reproducible'
    set -l project $HOME/Projects/commongrounds
    test -d $project/.git; or begin
        __say warn 'COMMONGROUNDS is absent — skipping its Codex parity checks'
        return
    end

    for path_name in AGENTS.md .agents/skills .codex/config.toml .codex/hooks.json .codex/README.md
        git -C $project ls-files --error-unmatch -- $path_name >/dev/null 2>&1
        or __fail "COMMONGROUNDS adapter is not tracked: $path_name"
    end
    test -L $project/AGENTS.md
    and test (readlink $project/AGENTS.md) = .claude/CLAUDE.md
    or __fail 'COMMONGROUNDS AGENTS.md must link to .claude/CLAUDE.md'
    test -L $project/.agents/skills
    and test (readlink $project/.agents/skills) = ../.claude/skills
    or __fail 'COMMONGROUNDS .agents/skills must link to ../.claude/skills'

    test -e $project/.agents/rules
    and __fail 'COMMONGROUNDS still has obsolete .agents/rules content'
    test -e $project/.claude/rules
    and __fail 'COMMONGROUNDS still has obsolete .claude/rules content'

    string match -qr '\[mcp_servers\.godot-lsp\]' <$project/.codex/config.toml
    or __fail 'COMMONGROUNDS project config lacks godot-lsp'
    string match -qr '@satelliteoflove/godot-mcp@4\.1\.11' <$project/.codex/config.toml
    or __fail 'COMMONGROUNDS project config lacks the pinned godot-mcp'
    if string match -qr '\[mcp_servers\.godot-(lsp|mcp)\]' <$REPO/codex/config.toml
        __fail 'project Godot MCPs leaked into the global Codex config'
    end

    for hook in check-gdscript.sh format-gdscript.sh format-markdown.sh
        string match -q "*$hook*" <$project/.codex/hooks.json
        or __fail "COMMONGROUNDS Codex hook adapter omits $hook"
    end
    __say info 'COMMONGROUNDS Codex adapters are tracked and scoped'
end

function __capture_codex_prompt --argument-names directory output --description 'render Codex context for one directory'
    pushd $directory >/dev/null
    command codex debug prompt-input parity-probe >$output 2>/dev/null
    set -l result $status
    popd >/dev/null
    return $result
end

function __check_codex_visibility --description 'Codex sees only the instructions and skills in scope'
    type -q codex; or begin
        __fail 'codex is not installed — cannot prove model-visible context'
        return
    end

    set -l project $HOME/Projects/commongrounds
    set -l unrelated (mktemp -d)
    set -l project_prompt (mktemp)
    set -l dotfiles_prompt (mktemp)
    set -l unrelated_prompt (mktemp)

    __capture_codex_prompt $project $project_prompt
    or __fail 'could not render COMMONGROUNDS Codex context'
    __capture_codex_prompt $REPO $dotfiles_prompt
    or __fail 'could not render dotfiles Codex context'
    __capture_codex_prompt $unrelated $unrelated_prompt
    or __fail 'could not render unrelated-directory Codex context'

    string match -q '*Project-wide law — always on*' <$project_prompt
    or __fail 'COMMONGROUNDS router is not model-visible to Codex'
    for skill in (path filter -d $project/.claude/skills/*)
        set -l name (path basename $skill)
        string match -q "*- $name:*" <$project_prompt
        or __fail "COMMONGROUNDS skill is not model-visible to Codex: $name"
    end

    string match -q '*Always-on dotfiles law*' <$dotfiles_prompt
    or __fail 'dotfiles router is not model-visible to Codex'
    for skill in (path filter -d $REPO/.claude/skills/*)
        set -l name (path basename $skill)
        string match -q "*- $name:*" <$dotfiles_prompt
        or __fail "dotfiles skill is not model-visible to Codex: $name"
    end

    if string match -q '*Project-wide law — always on*' <$unrelated_prompt
        __fail 'COMMONGROUNDS instructions leaked into an unrelated Codex context'
    end
    string match -q '*firecrawl:firecrawl:*' <$unrelated_prompt
    or __fail 'Firecrawl plugin skills are not model-visible to Codex'

    rm $project_prompt $dotfiles_prompt $unrelated_prompt
    rmdir $unrelated
    __say info 'Codex instruction and skill visibility is scoped'
end

function __check_codex_runtime --description 'Codex MCP and plugin gates match policy'
    set -l project $HOME/Projects/commongrounds
    set -l unrelated (mktemp -d)
    set -l project_mcp (mktemp)
    set -l unrelated_mcp (mktemp)
    set -l plugins (mktemp)

    pushd $project >/dev/null
    command codex mcp list --json >$project_mcp 2>/dev/null
    set -l project_status $status
    popd >/dev/null
    pushd $unrelated >/dev/null
    command codex mcp list --json >$unrelated_mcp 2>/dev/null
    set -l unrelated_status $status
    popd >/dev/null
    command codex plugin list >$plugins 2>/dev/null
    set -l plugin_status $status

    test $project_status -eq 0; or __fail 'could not list project Codex MCPs'
    test $unrelated_status -eq 0; or __fail 'could not list unrelated-directory Codex MCPs'
    test $plugin_status -eq 0; or __fail 'could not list Codex plugins'
    jq -e '.[] | select(.name == "godot-mcp" and .enabled == true)' $project_mcp >/dev/null
    or __fail 'project-scoped godot-mcp is not enabled in COMMONGROUNDS'
    if jq -e '.[] | select(.name == "godot-mcp")' $unrelated_mcp >/dev/null
        __fail 'godot-mcp leaked outside COMMONGROUNDS'
    end
    jq -e '.[] | select(.name == "cloudflare-api" and .enabled == false)' $project_mcp >/dev/null
    or __fail 'Cloudflare MCP is not disabled by default'
    string match -q '*firecrawl@firecrawl*installed, enabled*' <$plugins
    or __fail 'Firecrawl Codex plugin is not installed and enabled'
    string match -q '*cloudflare@openai-curated*installed, disabled*' <$plugins
    or __fail 'Cloudflare Codex plugin is not installed and disabled by default'

    rm $project_mcp $unrelated_mcp $plugins
    rmdir $unrelated
    __say info 'Codex MCP scope and plugin gates are correct'
end

function __check_project_agent_links --description 'claude project guidance is shared with codex'
    if not test -L $REPO/AGENTS.md
        __fail "$REPO/AGENTS.md is not a symlink to the canonical Claude instructions"
    else if not test -e $REPO/AGENTS.md
        __fail "$REPO/AGENTS.md is a broken symlink"
    else if not test (path resolve $REPO/AGENTS.md) = (path resolve $REPO/.claude/CLAUDE.md)
        __fail "$REPO/AGENTS.md does not resolve to .claude/CLAUDE.md"
    end

    for skill in (path filter -d $REPO/.claude/skills/*)
        set -l name (path basename $skill)
        set -l link $REPO/.agents/skills/$name
        if not test -L $link
            __fail "project Codex skill $name is not linked from .claude/skills"
        else if not test -e $link
            __fail "$link is a broken symlink"
        else if not test (path resolve $link) = (path resolve $skill)
            __fail "$link does not resolve to the canonical Claude skill"
        end
    end
    __say info 'project Claude/Codex symlinks intact'
end

function __check_rust_links --description 'cargo config is linked back into the repo'
    set -l cargo_home $XDG_DATA_HOME/cargo
    set -q CARGO_HOME; and set cargo_home $CARGO_HOME
    set -l link $cargo_home/config.toml
    if not test -L $link
        __fail "$link is not a symlink to the tracked Cargo config"
    else if not test -e $link
        __fail "$link is a broken symlink"
    else if not test (path resolve $link) = (path resolve $REPO/cargo/config.toml)
        __fail "$link does not resolve to $REPO/cargo/config.toml"
    end
    __say info 'Cargo config symlink intact'
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

function main --description 'audit tracked config, links and Codex parity'
    __say info "auditing $REPO"
    __check_new_arrivals
    __check_secrets
    __check_home_links
    __check_claude_links
    __check_codex_links
    __check_project_agent_links
    __check_commongrounds_codex
    __check_codex_visibility
    __check_codex_runtime
    __check_rust_links
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
