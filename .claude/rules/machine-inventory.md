<!--
  Deliberately UNSCOPED. This governs work on ~/.config/** (outside the working directory) and on
  plain questions like "what should I use for X", neither of which a `paths:` glob would catch.
  Kept short on purpose — it is an always-on cost. It says only "read the Brewfile, and don't trust
  it too far". The `brewfile` skill owns maintaining it.
-->

# Know what is on this machine before configuring it

**`./Brewfile` is the inventory** — every tap, formula, cask, App Store app and uv tool, grouped by
category, each with a one-line comment saying *why* it is installed. Hand-maintained. The repo root
is `~/.config`, so the file is `~/.config/Brewfile`.

**Read the Brewfile before** configuring anything under `~/.config`, writing a `conf.d/<tool>.fish`
snippet or an abbreviation wrapping a command, or recommending or choosing between tools. Three
abbreviations in `abbrs.fish` were dead for months because this was skipped.

⚠ **Declared intent is not verified state** — it has failed in both directions here (`shellcheck`
installed but undeclared until 2026-07-28; `tre` referenced by an abbreviation but installed
nowhere). The Brewfile is the survey; run a live check on the dependency you are about to rely on.
`command -v` misses keg-only, prefixed and binary-less formulae, so use `brew list --versions
<formula>` for those.

⚠ `brew bundle check` is **not** that check: it only proves the declared set is installed, so it
passes on an incomplete file. `.claude/skills/brewfile/scripts/brewfile-audit.sh` is the full
both-directions diff. ⚠ Absence from the Brewfile is not evidence for deliberately untracked classes
— VS Code extensions and `bun`/`npm` globals are recorded nowhere.

If you install something while working, add it to the `Brewfile` in the same change.
