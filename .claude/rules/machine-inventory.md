<!--
  Deliberately UNSCOPED. This governs work on ~/.config/** (outside the working directory) and on
  plain questions like "what should I use for X", neither of which a `paths:` glob would catch.
  Kept short on purpose — it is an always-on cost, and the user-level `toolbox` rule is already in
  context beside it, so anything true of the *tools* belongs there, not here. This rule says only
  "read the Brewfile, and don't trust it too far". The `brewfile` skill owns maintaining it.
-->

# Know what is on this machine before configuring it

**`./Brewfile` is the inventory** — every tap, formula, cask, App Store app and uv tool, grouped by
category, each with a one-line comment saying *why* it is installed. Hand-maintained. The repo root
is `~/.config`, so the file is `~/.config/Brewfile`.

**Check the `toolbox` rule first** — it is user-level, so its digest of this machine's tooling is
already in your context in every session, and for a capability question that is the answer. Open the
Brewfile for GUI apps, for the *why* behind an entry, or for anything the digest does not name.

**Read the Brewfile before** configuring anything under `~/.config`, writing a `conf.d/<tool>.fish`
snippet or an abbreviation wrapping a command, or recommending or choosing between tools. Three
abbreviations in `abbrs.fish` were dead for months because this was skipped.

⚠ **Declared intent is not verified state** — it has failed in both directions here (`shellcheck`
installed but undeclared until 2026-07-28; `tre` referenced by an abbreviation but installed
nowhere). The Brewfile is the survey; run a live check on the dependency you are about to rely on.
`toolbox.md` carries the liveness-check rules — the short version is that `command -v` misses
keg-only, prefixed and binary-less formulae, so use `brew list --versions <formula>` for those.

⚠ `brew bundle check` is **not** that check: it only proves the declared set is installed, so it
passes on an incomplete file. `.claude/skills/brewfile/scripts/brewfile-audit.sh` is the full
both-directions diff. ⚠ Absence from the Brewfile is not evidence for deliberately untracked classes
— VS Code extensions and `bun`/`npm` globals are recorded nowhere.

If you install something while working, add it to the `Brewfile` **and** to
`claude-code/rules/toolbox.md` in the same change.
