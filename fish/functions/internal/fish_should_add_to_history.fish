function fish_should_add_to_history --description 'keep secret-shaped commands out of the history file'
    set -l cmd $argv[1]

    # ⚠ defining this function takes over ALL of fish's history filtering — including the
    # built-in "a leading space means do not record this" convention, which silently stops
    # working unless it is reimplemented here. this line is that reimplementation.
    string match -qr '^\s' -- $cmd; and return 1

    # 1password subcommands whose arguments are, or resolve to, credentials.
    # deliberately not every `op` command: `op signin`/`op whoami` are worth recalling.
    string match -qr '^\s*op\s+(read|run|inject|item|document)\b' -- $cmd; and return 1

    # an inline credential passed as a flag value, whatever the command
    string match -qr -- '--(token|password|passwd|secret|api[-_]?key)[= ]\S' $cmd; and return 1

    # a literal credential pasted on the command line
    string match -qr -- '(github_pat_|ghp_|gho_|ghs_|ghu_|ghr_|sk-[A-Za-z0-9]{16}|xox[baprs]-|AKIA[0-9A-Z]{16})' $cmd; and return 1

    return 0
end

# ⚠ this governs fish's own history file ONLY. atuin records separately, via its own
# `--on-event fish_preexec` hook into a sqlite database, and never consults this function.
# the matching filter lives in ~/.config/atuin/config.toml as `history_filter`; change both
# or the secret is still on disk.
