# shell integrations for external tools. one line per tool: guard, then source the cached
# init. the uncached form is kept as a comment above each — it documents what the cache
# holds and gives a one-character bisect when a tool's init changes shape.
#
# all of these define functions, key bindings or a prompt, none of which exist in a
# non-interactive shell. guarding here is what keeps `fish -c` at ~5 ms.

status is-interactive; or return

# fzf — ctrl-t files, alt-c cd, shift-tab completion. it would also take ctrl-r, but
# conf.d/fzf.fish opts out of that on atuin's behalf before this file runs.
# type -q fzf; and fzf --fish | source
type -q fzf; and cachecmd --source fzf --fish

# zoxide — provides `z`/`zi`, which conf.d/abbrs.fish points `cd` at.
# ⚠ zoxide's init runs `abbr --erase z` and defines `z` via `alias`. both violate house
# style, and the `abbr --erase` will silently delete any `abbr -a z ...` added in
# abbrs.fish (which sorts earlier). upstream's business, not ours — do not "fix" it.
# type -q zoxide; and zoxide init fish | source
type -q zoxide; and cachecmd --source zoxide init fish

# starship — owns fish_prompt entirely.
# ⚠ cache `--print-full-init`, NOT `starship init fish`. the latter emits only a one-line
# `source (starship init fish --print-full-init | psub)` bootstrap, so caching it caches
# nothing and still pays starship + mktemp + cat + rm on every start (13 ms, measured).
# the full init is deterministic; its only per-session value, $STARSHIP_SESSION_KEY, is
# evaluated when the cache is sourced, not when it is written.
# type -q starship; and starship init fish | source
if type -q starship
    cachecmd --source starship init fish --print-full-init
    # defined by the init above, so it cannot be assumed to exist.
    functions -q enable_transience; and enable_transience
end

# atuin — ctrl-r history search, and the up arrow.
#
# --disable-ai: without it atuin binds `?` to a hook that runs `atuin ai inline`, a network
# call to atuin's AI service, whenever you press `?` on an empty command line. verified on
# 18.18.1. opt in deliberately if ever wanted; do not get it by accident.
#
# --depends: the init text is generated from ~/.config/atuin/config.toml, so the config file
# has to invalidate the cache too — the atuin binary's mtime alone would miss a settings edit.
#
# ⚠ keep atuin last. a key sequence holds exactly one command list, so whichever tool binds
# a key last wins; conf.d/fzf.fish makes ctrl-r explicit rather than relying on this, but
# the ordering is still the belt to that braces.
if type -q atuin
    # preempt the one fork the cache cannot remove. the cached init opens with
    #     if not set -q ATUIN_SESSION; or test "$ATUIN_SHLVL" != "$SHLVL"
    #         set -gx ATUIN_SESSION (atuin uuid)
    # and `atuin uuid` costs 4.5-6.9 ms — around a third of this config's whole interactive
    # startup, paid by every new top-level shell. so satisfy that guard first, with builtins
    # only, and atuin's own branch is skipped.
    #
    # the session id is a grouping key, not a parsed value: atuin stores it verbatim in a
    # text column. verified against an isolated db (ATUIN_DB_PATH) that a plain 32-hex-char
    # string round-trips through `history start`/`end`, `search` and `stats`. this machine is
    # not logged in to a sync server, so no server-side validation is in play either.
    #
    # shape matches `atuin uuid` (32 lowercase hex). $fish_pid makes a collision between two
    # *concurrent* shells impossible however `random` is seeded; the three random words cover
    # reuse of a pid over time. 200 concurrent shells produced 200 distinct ids.
    #
    # ⚠ degrades safely: if atuin ever changes that condition, its own `atuin uuid` runs again
    # and the only cost is the time this saves. re-measure after an atuin upgrade.
    if not set -q ATUIN_SESSION; or test "$ATUIN_SHLVL" != "$SHLVL"
        set -gx ATUIN_SESSION (printf '%08x%08x%08x%08x' $fish_pid \
            (random 0 4294967295) (random 0 4294967295) (random 0 4294967295))
        set -gx ATUIN_SHLVL $SHLVL
    end

    # type -q atuin; and atuin init fish | source
    cachecmd --source --depends $XDG_CONFIG_HOME/atuin/config.toml \
        atuin init fish --disable-ai
end
