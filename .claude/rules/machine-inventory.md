<!--
  Deliberately UNSCOPED. This governs work on ~/.config/** (outside the working directory) and on
  plain questions like "what should I use for X", neither of which a `paths:` glob would catch.
  Kept short on purpose — it is an always-on cost. It says only "read the Brewfile; it is complete,
  but prove a dependency before building on it". The `brewfile` skill owns maintaining it.
-->

# Know what is on this machine before configuring it

**`./Brewfile` is the inventory** — every tap, formula, cask, App Store app and uv tool, grouped by
category, each with a one-line comment saying *why* it is installed. Hand-maintained. The repo root
is `~/.config`, so the file is `~/.config/Brewfile`.

**Read the Brewfile before** configuring anything under `~/.config`, writing a `conf.d/<tool>.fish`
snippet or an abbreviation wrapping a command, or recommending or choosing between tools. Three
abbreviations in `abbrs.fish` were dead for months because this was skipped.

**The file is complete and current** — every install or removal updates it in the same change, and
`brewfile-audit.sh` diffs it against the machine in both directions. Treat it as authoritative for
*what is on this machine*; do not go surveying `brew list` to second-guess it.

⚠ That is a different question from *is this working right now*. Before building on a specific
dependency, prove it: a package can be declared and installed yet not give you the binary you
expect. `command -v` misses keg-only, prefixed and binary-less formulae, so use `brew list
--versions <formula>` for those. Drift is rare but not impossible — it has happened in both
directions (`shellcheck` installed but undeclared until 2026-07-28; `tre` referenced by an
abbreviation but installed nowhere), which is why the audit exists.

⚠ `brew bundle check` is **not** that check: it only proves the declared set is installed, so it
passes on an incomplete file. `.claude/skills/brewfile/scripts/brewfile-audit.sh` is the full
both-directions diff. ⚠ Absence from the Brewfile is not evidence for deliberately untracked classes
— VS Code extensions and `bun`/`npm` globals are recorded nowhere.

If you install something while working, add it to the `Brewfile` in the same change.
