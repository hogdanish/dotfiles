# Brewfile style guide

The house format for `Brewfile` at the repo root. Derived from the layout in `brewfile-example.md`, with
double quotes substituted so the file diffs cleanly against `brew bundle dump` output.

---

## 1. Scope — what belongs in the file

Track **`tap`, `brew`, `npm`, `uv`, `cask`, and `mas`**.

Deliberately excluded (all documented in [brew-bundle.md](brew-bundle.md) if this ever changes):

| Type | Why excluded |
| --- | --- |
| `vscode` | Extension lists churn on every install and sync through VS Code's own Settings Sync. |
| `cargo` / `go` | Language-toolchain globals, versioned by their own ecosystems. |
| `krew` / `flatpak` / `winget` | Not applicable on this machine (Linux/WSL/k8s). |

When dumping for comparison, suppress the excluded types explicitly:

```sh
brew bundle dump --file=- --force --no-vscode --no-go --no-cargo
```

## 2. File skeleton

```ruby
#
# ethan's global brewfile
#
# comments describe *why this is installed*, not what it is.
# tools that replace or extend something else are written '<original>: <purpose>'.
#

# ===============================
# 🚰 taps
# ===============================

# <what this tap is for>
tap "owner/tap", trusted: true
brew "owner/tap/formula"        # purpose

# ===============================
# 🧪 formulae
# ===============================

## <category>
brew "name"                     # purpose

# ===============================
# 📦 node
# ===============================

npm "name"                     # purpose

# ===============================
# 🐍 python
# ===============================

uv "name"                      # purpose

# ===============================
# 🛢️ casks
# ===============================

## <category>
cask "name"                     # purpose

# ===============================
# 🍎 app store
# ===============================

mas "Name", id: 123456789       # purpose
```

Rules:

- Banner comments (`# ====`) separate the six **types**. Never reorder them.
- `##` subsections group by **category** within a type. Add or rename categories freely as the file grows;
  do not create a category for fewer than two entries.
- One blank line between subsections, two around banners.
- Always `"double quotes"` — matches `brew bundle dump`, so a dump-vs-file diff shows only real changes.

## 3. Ordering

- **Types**: taps → formulae → npm → uv → casks → app store. Taps must precede anything that needs them.
- **Categories**: most-used first, not alphabetical. `shell & terminal` before `multimedia`.
- **Within a category**: group related tools adjacently (`git`, `git-lfs`, `git-delta`, `gh`), then order by
  importance. Alphabetical ordering inside a category is *not* required and usually hurts readability.

⚠ Do not sort the whole file alphabetically. That is what `dump` produces and what this format exists to
replace.

## 4. Comments — the important part

Every entry gets **one trailing comment**. Lowercase, no trailing period, terse.

⚠ **Never wrap a comment onto a second line.** A comment that will not fit on the entry's own line
is a comment that is saying too much — cut it, do not continue it with `#` on the following line.
The same ceiling applies to section preambles: a banner may carry one short line, never a
paragraph. There is no exception for a package with an interesting story.

The comment answers *"why is this on my machine"*, not *"what does upstream say it is"*. `brew desc` output
is a starting point, never a final answer — it is written for strangers browsing a package index.

| Bad (upstream desc) | Good (purpose) |
| --- | --- |
| `# Search tool like grep and The Silver Searcher` | `# grep: fast recursive search` |
| `# Cross-shell prompt for astronauts` | `# prompt` |
| `# Collaborative team software` | `# design tool` |
| `# JDK from the Eclipse Foundation (Adoptium)` | `# java runtime for prism launcher` |

Guidelines:

- **Aim for 2–5 words**, one sentence at the absolute most. Hard ceiling: the comment must not
  push the line past ~100 columns, and must not wrap.
- **No project-specific rationale.** The Brewfile is the *machine's* inventory, not a design doc.
  Version skew, build flags, which of `~/Projects/*` needs a package, and why an alternative was
  rejected all belong in that project's own docs or in this skill — never in an entry comment.
- **Don't restate the package name.** `brew "ffmpeg" # ffmpeg video tool` is noise; `# video processing` is not.
- **Name the consumer when a package exists only for another package**: `# yt-dlp: mp4 metadata`,
  `# gnupg: touch id pinentry`. This is what stops a future audit from deleting it as unrecognised.
- **Align trailing comments within a subsection**, not across the whole file. Realign the subsection when
  its longest entry changes.

### 4.0 Held entries — wanted, deliberately not installed

Software chosen but knowingly deferred is kept as a **commented-out entry** in its normal subsection,
aligned like a live one, with the comment saying *what it is waiting on*:

```ruby
# cask "thaw"              # ice: menu bar manager — held until stable on macos 27 golden gate
```

This survives every check — ruby ignores it, `brew bundle` never sees it, and the audit's mas-id regex
is anchored `^[^#]*` so a commented line cannot match. ⚠ **A commented entry is not drift; never
"clean it up"** — this skill is what stops the next audit deleting it. Drop the `#`
to install; delete the line only when the decision is reversed.

### 4.1 The replacement convention

> A tool that replaces, augments, or depends on another is written `<original>: <purpose>`.

This is the single most useful convention in the file — it records *what a package displaces*, which is
invisible from the package name and is exactly what you forget on a fresh machine.

```ruby
brew "bat"          # cat: syntax-highlighted viewer
brew "eza"          # ls: dir listing with icons
brew "fd"           # find: simpler file search
brew "ripgrep"      # grep: fast recursive search
brew "zoxide"       # cd: frecency-ranked jumping
brew "xh"           # curl: ergonomic http client
brew "doge"         # dig: dns client
brew "micro"        # nano: terminal editor
brew "btop"         # top: resource monitor
brew "git-delta"    # less: git diff pager
cask "alt-tab"      # macos app switcher: windows-style alt-tab
cask "raycast"      # spotlight: launcher
cask "keka"         # archive utility: file archiver
cask "iina"         # quicktime: media player
```

Three distinct relationships, all using the same `<original>:` slot:

1. **Replaces** — you use this *instead of* the original. `bat` → `cat`, `alt-tab` → the macOS switcher.
2. **Extends** — the original still does the work. `git-delta` → `less` (it *is* a pager for git).
3. **Depends on / serves** — this exists *for* the named tool. `atomicparsley` → `yt-dlp`.

⚠ Name the thing being replaced by its **command or common name**, not its package: `cat`, not `coreutils`;
`spotlight`, not `Spotlight.app`. For macOS built-ins, describe the feature (`macos app switcher`), because
several have no command name.

⚠ When a replacement is **partial** — both are installed and both get used — say so rather than implying a
swap. `xh` does not replace `curl` in scripts; `# curl: ergonomic http client` reads correctly, while
`# curl replacement` would be wrong given `curl` is also in the file.

## 5. Taps

Put each tap **immediately above the entries that need it**, with a comment saying what it provides:

```ruby
# touch id support for gpg
tap "jorgelbg/tap", trusted: true
brew "jorgelbg/tap/pinentry-touchid"   # gnupg: touch id pinentry
```

- **Always fully qualify tapped formulae** (`owner/tap/name`). Bare names work but break name-based
  auditing — see [auditing.md](auditing.md) §4.
- **Every tap carries trust on the `tap` line**, because a tap that is not trusted cannot install
  unattended. Prefer the **narrowest** form that works: `trusted: {command: "autoupdate"}` for a tap
  used for one command, `trusted: true` only when the whole tap is in play.
- **Do not repeat `trusted:` on the `brew`/`cask` line** when the tap already carries it. `brew bundle dump`
  emits tap-level trust only, so repeating it creates permanent diff noise.
- Never add a tap that nothing uses. If the last formula from a tap is removed, remove the tap.

## 6. Versioned and beta tokens

`figma@beta`, `visual-studio-code@insiders`, `claude-code@latest`, `temurin@25` are ordinary tokens. Two
rules:

- **Say which channel the comment refers to** when both the stable and the beta token are installed:
  `cask "figma"` → `# design tool (stable)`, `cask "figma@beta"` → `# design tool (beta channel)`.
- **Flag redundancy rather than silently removing it.** Both `figma` and `figma@beta` being installed is
  probably intentional (stable as a fallback), but it is worth a one-line note to the user during an audit.

## 7. `greedy:` — when to add it

`greedy: true` forces `brew upgrade` on casks that update themselves. Most GUI apps on this machine
auto-update (`auto_updates: true` in `brew info --json=v2`).

Default: **omit it.** Let self-updating apps update themselves; `greedy` fights them and re-downloads
large bundles on every `brew bundle install`.

Add it only when the app's self-updater is broken, disabled, or gated behind a paid tier — and always with
a comment saying why:

```ruby
cask "opera", greedy: true      # browser (self-updater disabled)
```

## 8. App Store entries

```ruby
mas "Wipr", id: 1662217862      # safari: content blocker
```

- `id:` is authoritative; the name is a label. Keep the name as `mas list` reports it so the two can be
  eyeballed side by side, but **never diff on the name** — Apple renames apps.
- **Apple's pre-bundled apps are excluded**: GarageBand (`682658836`), iMovie (`408981434`),
  Keynote (`361285480`), Numbers (`361304891`), Pages (`361309726`). macOS reinstalls them regardless, so
  listing them makes `brew bundle install` do pointless work. The denylist lives in
  `scripts/brewfile-audit.sh`; extend it there, not here.
- `brew "mas"` must be in the formulae section for any `mas` entry to install.

## 9. What never goes in this file

- **Ruby conditionals.** This machine is the only target. Conditionals break `brew bundle list`, make
  `check` slow, and are destroyed by any `dump`. If a conditional ever becomes necessary, note it in the
  file's header comment so the next audit does not regenerate it away.
- **Secrets or `op://` references.** Nothing in a Brewfile is secret. If something here feels like it
  should be, it belongs in the `Claude Code` 1Password Environment, fetched at point of use with
  `op run` — see the `auth` skill. ⚠ **Not** `~/.config/fish/conf.d/secrets.fish`: that file was retired
  on 2026-07-28 and must never be recreated (`.claude/rules/security.md`).
- **`cask_args appdir:`.** The default `/Applications` is correct here, and setting it globally changes
  where *every* cask lands.
