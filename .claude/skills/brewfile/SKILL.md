---
name: brewfile
description: "Maintain the repo-root Brewfile, the software inventory: audit drift, write entries in the house layout, brew bundle options, validation, and how Homebrew itself is configured to run. Load when installing or removing software, auditing the Brewfile, or diagnosing brew's unattended updates, tap trust or environment."
allowed-tools: Read, Edit, Write, Grep, Glob, Bash(brew*), Bash(mas*), Bash(jq*), Bash(ruby*), Bash(.claude/skills/brewfile/scripts/*), Bash(ls*), Bash(comm*), Bash(sort*), Bash(grep*)
---

# Brewfile — auditing and maintenance

`Brewfile` at the repo root is the declarative manifest of software intentionally installed on this
machine. It is **hand-maintained in a categorised layout**, not generated. `brew bundle dump` is used only
as an *input to a diff*, never as output — it would destroy every comment, category and banner.

Unlike the rest of this repo (where `~/.config` is the live source of truth), the Brewfile genuinely lives
here and is the real artifact.

## Reference material

- [brew-bundle.md](references/brew-bundle.md) — the distilled `brew bundle` / Brewfile documentation: all
  twelve entry types, every per-entry option, tap trust, Ruby semantics, all subcommands and flags, env
  vars, and a verified account of exactly what `dump` emits. Read before using any option not already in
  the file.
- [style-guide.md](references/style-guide.md) — the house layout: scope, skeleton, ordering, the comment
  rules and the `<original>: <purpose>` replacement convention, taps, versioned tokens, `greedy:`, App
  Store entries. Read before writing any entry.
- [auditing.md](references/auditing.md) — how to derive the intentionally-installed set, the verified
  commands and their traps, drift classification, and validation. Read when the audit script's output
  needs interpreting or the script needs changing.
- [homebrew-runtime.md](references/homebrew-runtime.md) — how brew is configured to *run*, as opposed
  to what the file declares: the unattended-update launchd agent, why it has no `--sudo`, the App
  Store carve-out, `brew.env` / `npmrc` and the two "only fish exports it" failures, and the
  `HOMEBREW_*` boolean trap. Read before changing anything about brew's own behaviour.

## Scope

Track **`tap` / `brew` / `npm` / `uv` / `cask` / `mas`** only. `vscode`, `cargo`, `go`, `krew`,
`flatpak` and `winget` entries are deliberately out of scope — documented in the reference, absent
from the file. When dumping for comparison, suppress them: `--no-vscode --no-go --no-cargo`.

⚠ **`uv` was added to the tracked set on 2026-07-30**, reversing the earlier decision to exclude it. The
reasoning: a python CLI installed with `uv tool install` is declared software exactly like a formula, and
leaving it out meant `gdtoolkit` — the only headless GDScript formatter and linter on this machine — was
recorded nowhere and audited by nothing. `brew bundle` has supported the entry natively since Homebrew 6
(`uv "name"`, options `with:` and `source:`), so it costs one line and `check`/`cleanup` cover it.
⚠ The other excluded types stay excluded: they are not "not yet done", they are decisions.
⚠ **`npm` was added to the tracked set on 2026-08-08** for `cf`, whose upstream-supported global
installation is `npm install -g cf`. Reserve it for global CLIs that must resolve from every shell and
agent; project JavaScript tools remain project-local and bun remains the default package manager.
⚠ A uv tool's shims land in `~/.local/bin`, which reaches `$PATH` only via `fish/conf.d/uv.fish` — so
`brewfile-audit.sh` probes `uv tool dir --bin` directly rather than trusting `command -v`, and its verdict
does not depend on which shell launched it.

## Procedure — a maintenance pass

1. **Audit.** Run the bundled script; it does every diff in one pass:

   ```sh
   .claude/skills/brewfile/scripts/brewfile-audit.sh Brewfile
   ```

   It reports, per type, what is installed but undeclared (`+`), declared but uninstalled (`-`), and
   notes (`~`) for things needing a human decision. It also lists `/Applications` entries that came from
   neither brew nor the App Store, and finishes with `brew bundle check`.

2. **Classify** each result against [auditing.md](references/auditing.md) §7. The defaults:
   *untracked* → add it; *stale* → **ask before removing**; *unmanaged app* → report and ask.

3. **Write** the entries per [style-guide.md](references/style-guide.md): correct type section, a category
   subsection, and one terse trailing purpose comment. Preserve existing categories and ordering; insert
   into the right group rather than appending to the end.

4. **Validate.** `ruby -c Brewfile && brew bundle list --file=Brewfile >/dev/null && brew bundle check --file=Brewfile`.
   The `PostToolUse` hook runs the first two automatically on every write.

5. **Report** what changed, and surface anything you did not act on unilaterally.

## Writing an entry

The comment answers *why this is on the machine*, not what upstream calls it. `brew desc` is a starting
point, never the answer — see [style-guide.md](references/style-guide.md) §4.

⚠ **Two to five words; one sentence at the most; never wrapped onto a second line.** If the
rationale does not fit, it does not belong in the Brewfile — project-specific detail (build flags,
version skew, which repo needs it) goes in that project's docs, and cross-cutting policy goes in
this skill. Multi-line entry comments and paragraph-length section preambles were removed on
2026-08-27; do not let them grow back.

A tool that replaces, extends, or serves another is written `<original>: <purpose>` — the convention that
makes the file readable on a fresh machine:

```ruby
brew "ripgrep"      # grep: fast recursive search
brew "git-delta"    # less: git diff pager
cask "alt-tab"      # macos app switcher: windows-style alt-tab
```

Name the displaced thing by its **command or common name** (`cat`, `spotlight`), not its package or bundle.
For macOS built-ins with no command, describe the feature. When both tools stay installed and in use
(`xh` alongside `curl`), phrase it as an augmentation, not a swap.

## Gotchas that cost time

- ⚠ **`brew leaves --installed-on-request` is narrower than it looks** — it drops any formula that later
  became another package's dependency. Use the `installed_on_request` JSON query instead
  ([auditing.md](references/auditing.md) §2).
- ⚠ **Use `.full_name`, not `.name`**, in `brew info --json=v2` queries, or every tapped formula produces a
  phantom missing/stale pair.
- ⚠ **`brew bundle list --mas` prints names, not ids.** Diff App Store apps on the numeric id — Apple
  renames apps (`Keynote` ships as `Keynote Creator Studio.app`).
- ⚠ **jq: write `.app? // empty` with spaces.** `?//` lexes as the destructuring-alternative operator and
  fails to compile.
- ⚠ **Detect App Store apps by `Contents/_MASReceipt/receipt`**, never by slug-matching names against cask
  tokens — `AltTab.app`/`alt-tab` and `Prism Launcher.app`/`prismlauncher` both defeat that.
- ⚠ **`brew bundle check` passing does not mean the file is complete** — it only verifies that what is
  declared is installed. The 3-line stub this file replaced passed `check` while missing 90 packages.
- ⚠ **`check` failing does not mean something is missing.** It says "needs to be installed **or
  updated**" for a merely *outdated* package, which reads as drift and is not. Confirm with
  `brew list --versions <name>` / `brew list --cask --versions <token>` before touching the file;
  `.claude/hooks/brewfile-validate.sh` now makes that distinction itself.
- ⚠ **Never run `brew bundle dump --force` over `Brewfile`**, and never run `brew bundle cleanup --force`
  without showing the user the dry run first — it uninstalls everything undeclared *and* resets Homebrew's
  tap-trust file.

## Standing decisions

- Taps carry trust on the `tap` line only, never repeated on the entry — and at the **narrowest**
  scope that works (`trusted: {command: "autoupdate"}` over a blanket `trusted: true`).
- Tapped formulae are always **fully qualified**: `jorgelbg/tap/pinentry-touchid`.
- Apple's pre-bundled App Store apps (GarageBand, iMovie, Keynote, Numbers, Pages) are **excluded**; the
  id denylist lives in `scripts/brewfile-audit.sh`.
- `greedy:` is **omitted by default** — most casks here self-update, and `greedy` fights them.
- **No Ruby conditionals.** This machine is the only target.
- **npm globals are exceptional.** Track only upstream-supported global CLIs that must be on every
  shell and agent PATH; use project-local bun dependencies for ordinary JavaScript tooling.
- **`uv` tools are tracked** (since 2026-07-30); every other non-brew entry type is not. See §Scope.

---

*Source of truth for the Brewfile and `brew bundle` — update it when the format or the tooling changes.*
