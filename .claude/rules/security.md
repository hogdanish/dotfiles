# Security & secrets rules

Applies everywhere, including files outside this repo. The **`auth` skill is authoritative** for how
credentials are stored and retrieved on this machine; this is the always-on subset that must hold
even when the skill hasn't been loaded. Load the skill before writing anything that stores, reads, or
authenticates with a credential.

## Never

1. **Never write a credential literal** into any file — dotfile, script, config, test fixture,
   commit message, or example. Use an `op://` secret reference, `op run --`, or a 1Password
   Environment. "Temporary" and "it's only a test key" are not exceptions.
2. **Never read, print, or copy these files**, in whole or in part:
   `~/.config/yt-dlp/cookies.txt` (live session cookies) · anything under
   `~/.gnupg/private-keys-v1.d/` · any `id_*` private key. Their existence, path, and variable
   *names* are in scope; their values are not.
   ✅ `~/.config/fish/conf.d/secrets.fish` was **retired on 2026-07-28** — the four tokens now live in
   the `Claude Code` 1Password Environment. **Never recreate it.** A shell needing a credential gets
   it from `op run`/`op plugin run` at the moment of use; see the `auth` skill.
3. **Never run a command that prints a resolved secret** to the terminal — `op read`, `op run
   --no-masking`, `security find-generic-password -w`, `gpg --export-secret-keys`, `cat` on a
   mounted `.env`. Output lands in the transcript. Pipe into the consumer, or ask the user to run it.
4. **Never export a private key** out of 1Password to make a client work. Fix the client config.
5. **Never commit a `.env`, `*.pem`, `*.key`, or a `.tpl` render.** Templates with `op://`
   references are safe to commit; their output is not.

## Always

6. **Ask before changing an authentication path** that could lock the user out — `~/.ssh/config`,
   `/etc/pam.d/*`, `~/.gnupg/gpg-agent.conf`, `~/.config/1Password/ssh/agent.toml`. Show the diff,
   and keep a working session open while testing.
7. **Prefer the narrowest exposure** that works: mounted Environment → `op run` → `op read` in a
   subshell. Never a global `set -gx` of a real secret value.
8. **If a secret is ever exposed** — printed, committed, or pasted — say so immediately and tell the
   user to rotate it. Do not quietly continue.

Guard external tools before using them (`type -q op`), and check `./Brewfile` before assuming a
security tool is installed — `pam-reattach` is declared there but is **not** on this machine.
