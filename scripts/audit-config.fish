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
    caddy \
    configstore

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
    set -l structure_errors (python3 $REPO/scripts/internal/codex-parity-audit.py $REPO $project 2>&1)
    if test $status -ne 0
        for message in $structure_errors
            __fail "Codex structure: $message"
        end
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

    string match -q '*## Project-wide law*' <$project_prompt
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

    if string match -q '*## Project-wide law*' <$unrelated_prompt
        __fail 'COMMONGROUNDS instructions leaked into an unrelated Codex context'
    end
    string match -q '*firecrawl:firecrawl:*' <$unrelated_prompt
    or __fail 'Firecrawl plugin skills are not model-visible to Codex'
    string match -q '*cloudflare:cloudflare:*' <$unrelated_prompt
    or __fail 'Cloudflare plugin skills are not model-visible to Codex'

    rm $project_prompt $dotfiles_prompt $unrelated_prompt
    rmdir $unrelated
    __say info 'Codex instruction and skill visibility is scoped'
end

function __check_codex_runtime --description 'Codex MCP and plugin gates match policy'
    set -l project $HOME/Projects/commongrounds
    set -l unrelated (mktemp -d)
    set -l hogdot $HOME/Projects/hogdot
    set -l project_mcp (mktemp)
    set -l unrelated_mcp (mktemp)
    set -l hogdot_mcp (mktemp)
    set -l hogdot_status 1
    set -l plugins (mktemp)

    pushd $project >/dev/null
    command codex mcp list --json >$project_mcp 2>/dev/null
    set -l project_status $status
    popd >/dev/null
    pushd $unrelated >/dev/null
    command codex mcp list --json >$unrelated_mcp 2>/dev/null
    set -l unrelated_status $status
    popd >/dev/null
    # the website spec server is the one gate that lives outside this repo's projects, so probe
    # hogdot too. skipped rather than failed when the checkout is absent — this repo must audit
    # clean on a machine that has not cloned it.
    if test -d $hogdot
        pushd $hogdot >/dev/null
        command codex mcp list --json >$hogdot_mcp 2>/dev/null
        set hogdot_status $status
        popd >/dev/null
    end
    command codex plugin list >$plugins 2>/dev/null
    set -l plugin_status $status

    test $project_status -eq 0; or __fail 'could not list project Codex MCPs'
    test $unrelated_status -eq 0; or __fail 'could not list unrelated-directory Codex MCPs'
    test $plugin_status -eq 0; or __fail 'could not list Codex plugins'
    for godot_mcp in godot-lsp godot-mcp
        jq -e --arg n $godot_mcp '.[] | select(.name == $n and .enabled == true)' $project_mcp >/dev/null
        or __fail "project-scoped $godot_mcp is not enabled in COMMONGROUNDS"
        if jq -e --arg n $godot_mcp '.[] | select(.name == $n)' $unrelated_mcp >/dev/null
            __fail "$godot_mcp leaked outside COMMONGROUNDS"
        end
    end
    for mcp_file in $project_mcp $unrelated_mcp
        jq -e '.[] | select(.name == "cloudflare-api" and .enabled == true)' $mcp_file >/dev/null
        or __fail 'Cloudflare MCP is not enabled globally'
        jq -e '.[] | select(.name == "context7" and .enabled == true)' $mcp_file >/dev/null
        or __fail 'Context7 MCP is not enabled globally'
    end
    python3 -c 'import sys, tomllib; c = tomllib.load(open(sys.argv[1], "rb")); t = c["mcp_servers"]["cloudflare-api"]["tools"]; assert all(t[n]["approval_mode"] == "approve" for n in ("search", "execute"))' $REPO/codex/config.toml
    or __fail 'Cloudflare MCP cannot run under the global never-approve policy'
    jq -e '.[] | select(.name == "website-spec" and .enabled == false)' $unrelated_mcp >/dev/null
    or __fail 'Website Spec MCP is not disabled by default'
    for browser_mcp in firefox-devtools safari
        jq -e --arg n $browser_mcp '.[] | select(.name == $n and .enabled == false)' $unrelated_mcp >/dev/null
        or __fail "browser MCP $browser_mcp is not disabled by default"
        jq -e --arg n $browser_mcp '.[] | select(.name == $n and .enabled == false)' $project_mcp >/dev/null
        or __fail "browser MCP $browser_mcp is enabled inside COMMONGROUNDS — it is --firefox/--safari only"
    end
    jq -e '.[] | select(.name == "website-spec" and .enabled == true)' $project_mcp >/dev/null
    or __fail 'Website Spec MCP is not enabled in COMMONGROUNDS'
    if test -d $hogdot
        test $hogdot_status -eq 0; or __fail 'could not list hogdot Codex MCPs'
        jq -e '.[] | select(.name == "website-spec" and .enabled == true)' $hogdot_mcp >/dev/null
        or __fail 'Website Spec MCP is not enabled in hogdot'
    end
    string match -q '*firecrawl@firecrawl*installed, enabled*' <$plugins
    or __fail 'Firecrawl Codex plugin is not installed and enabled'
    string match -q '*cloudflare@openai-curated-remote*installed, enabled*' <$plugins
    or __fail 'Cloudflare Codex plugin is not installed and enabled'

    rm $project_mcp $unrelated_mcp $hogdot_mcp $plugins
    rmdir $unrelated
    __say info 'Codex MCP scope and plugin state are correct'
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

function __check_claude_install --description 'claude code is the self-updating native build, not a cask'
    # ⚠ the cask was dropped 2026-09-01 — the Brewfile says why. it pins version+sha and trails the
    # release channel by days, and `brew upgrade` cannot close that gap. the native installer keeps
    # itself current instead, so what is worth asserting is that nothing has put a second, staler
    # claude ahead of it: conf.d/localbin.fish *appends* ~/.local/bin, so any brew claude wins.
    set -l launcher $HOME/.local/bin/claude
    if not test -x $launcher
        __fail "claude code is not natively installed — expected $launcher"
        __say warn 'reinstall: curl -fsSL https://claude.ai/install.sh | bash -s latest'
        return
    end
    # ⚠ never `brew uninstall --zap` this cask: its zap list includes ~/.local/state/claude, i.e.
    # $CLAUDE_CONFIG_DIR — transcripts, memory, plugins — plus ~/.config/claude and ~/.claude.json.
    if test -e /opt/homebrew/bin/claude
        __fail 'the claude-code cask is back and shadows the native build — brew uninstall --cask claude-code@latest (WITHOUT --zap)'
    end
    set -l resolved (command -s claude)
    if test -n "$resolved"; and test (path resolve $resolved) != (path resolve $launcher)
        __fail "claude on PATH is $resolved, not the native $launcher"
    end
    __say info 'claude code is the native self-updating build'
end

function __check_browser_mcp --description 'browser control stays opt-in, never always-on'
    # ⚠ the whole point of these two is that they cost an ordinary session NOTHING. firefox-devtools
    # is 45 tool descriptions in the `developer` preset and safari is 17, so the moment either lands
    # in enabledMcpjsonServers or a project .mcp.json, every session pays for a capability almost
    # none of them use. the only enable path is `claude --firefox` / `claude --safari`, which pass
    # --mcp-config for that launch alone.
    for decl in firefox-devtools safari
        set -l f $REPO/claude-code/mcp/$decl.json
        if not test -r $f
            __fail "missing browser MCP declaration $f"
            continue
        end
        jq -e . $f >/dev/null 2>&1; or __fail "$decl.json is not valid JSON"
    end

    set -l settings $REPO/claude-code/settings.json
    for name in firefox-devtools safari
        if jq -e --arg n $name '.enabledMcpjsonServers // [] | index($n)' $settings >/dev/null 2>&1
            __fail "$name is pre-approved in enabledMcpjsonServers — it must stay --mcp-config only"
        end
    end

    # a project .mcp.json naming either one would switch it on for every session in that repo.
    for project in $HOME/Projects/commongrounds $HOME/Projects/hogdot
        set -l mcp $project/.mcp.json
        test -r $mcp; or continue
        for name in firefox-devtools safari
            if jq -e --arg n $name '.mcpServers | has($n)' $mcp >/dev/null 2>&1
                __fail "$name leaked into "(path basename $project)"/.mcp.json — it is per-session only"
            end
        end
    end

    # headed, not headless: headless firefox resolves requestAdapter() to NULL on this machine, so a
    # --headless arg here would silently remove the ability to see WebGPU at all.
    if jq -e '.mcpServers["firefox-devtools"].args | index("--headless")' \
            $REPO/claude-code/mcp/firefox-devtools.json >/dev/null 2>&1
        __fail 'firefox-devtools is configured --headless, which resolves requestAdapter() to NULL'
    end

    type -q geckodriver
    or __fail 'geckodriver is missing — Selenium would download an untracked one into ~/.cache'
    test -d /Applications/Firefox.app
    or __fail 'Firefox.app is missing — the firefox-devtools MCP drives the branded browser'
    type -q safaridriver; and safaridriver --help 2>&1 | string match -q '*--mcp*'
    or __fail 'safaridriver does not support --mcp on this Safari'

    __say info 'browser MCPs are declared, opt-in, and headed'
end

function main --description 'audit tracked config, links and Codex parity'
    __say info "auditing $REPO"
    __check_new_arrivals
    __check_secrets
    __check_home_links
    __check_claude_links
    __check_claude_install
    __check_browser_mcp
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
