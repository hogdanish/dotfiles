<!--
  Deliberately UNSCOPED. This governs work on ~/.config/** (outside the working directory) and on
  plain questions like "what should I use for X", neither of which a `paths:` glob would catch.
  Kept short on purpose — it is an always-on cost. The `brewfile` skill owns *maintaining* the file;
  this rule only says "read it, and don't trust it too far".
-->

# Know what is on this machine before configuring it

**`./Brewfile` is the inventory of this machine** — 89 entries across taps, formulae, casks and App
Store apps, grouped by category, each with a one-line comment saying *why* it is installed. It is
hand-maintained. The repo root is `~/.config`, so the file is `~/.config/Brewfile`. Reading it is
cheap and it is almost always the fastest way to understand what you are working with.

## Read it before you

- Configure or improve anything under `~/.config` — you cannot sensibly write a `conf.d/<tool>.fish`
  snippet, a git config, or a theme without knowing which tools exist and which do not.
- Recommend, choose between, or install a tool. If it is already declared, do not propose installing it.
- Write a script or example that shells out to anything.
- Diagnose a "command not found", a dead abbreviation, or a config referencing a missing binary.
- Answer "what am I working with?", "what do I have for X?", or any capability question.

## ⚠ Declared intent is not verified state

The Brewfile records what *should* be installed. It fails in **both** directions, and has done
recently in both:

- **Installed but undeclared** — `shellcheck` was installed and missing from the file until
  2026-07-28.
- **Referenced but never installed** — `tre` is used by an abbreviation in `abbrs.fish` and is absent
  from both the machine and the Brewfile. `shfmt` is listed as installed in the user-level CLAUDE.md
  and is installed nowhere.

⚠ **Pick the right liveness check for the artefact type.** `command -v` only finds things on `$PATH`,
so it reports "missing" for entries that never install a binary. `pam-reattach` was wrongly recorded
as not-installed for exactly this reason — it ships a **PAM module**
(`/opt/homebrew/lib/pam/pam_reattach.so`), not an executable. Likewise keg-only formulae (`curl`) and
prefixed ones (`make` → `gmake`) are installed but invisible to a bare `command -v`. Use
`brew list --versions <formula>` when the formula does not put its own name on `$PATH`.

So: **the Brewfile for the survey, a live check for the dependency you are about to rely on.**

```sh
type -q <cmd>                                    # in fish
command -v <cmd> >/dev/null                       # in bash/zsh — Bash tool calls run under zsh
brew list --versions <formula>                    # for formulae that ship no same-named binary
.claude/skills/brewfile/scripts/brewfile-audit.sh # the full both-directions diff
```

⚠ `brew bundle check` is **not** this check — it only proves the declared set is installed, so it
passes on an incomplete file.

## Two more things

- **Prefer what is present.** The declared CLI preferences (`bat`, `eza`, `fd`, `ripgrep`, `zoxide`,
  `git-delta`, `xh`, `doge`, `trash`, `uv`, `bun`, `gum`) are the house tools — use them in scripts and
  examples rather than the coreutils defaults they replace. The `<original>: <purpose>` comment on each
  entry tells you what it displaces.
- **Absence is not evidence for untracked types.** `vscode` extensions and `cargo`/`uv`/`npm`/`go`
  globals are deliberately out of scope, so the Brewfile says nothing about them either way.

If you install something while working, add it to the Brewfile in the same change — that is the
`brewfile` skill.
