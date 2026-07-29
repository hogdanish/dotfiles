# `brew bundle` and the `Brewfile` — distilled reference

Distilled from <https://docs.brew.sh/Brew-Bundle-and-Brewfile> (upstream `docs/Brew-Bundle-and-Brewfile.md`,
last upstream review 2026-07-18) and verified against **Homebrew 6.0.13** on this machine. Where the docs and
the local `--help` disagreed, the local binary won.

A `Brewfile` is a **declarative** manifest: you state the end state, not the commands. `brew bundle install`
converges the machine toward it. It is evaluated as **Ruby**, so anything Ruby can do, a Brewfile can do.

---

## 1. Entry types

Every entry is a Ruby method call: `keyword "name"[, option: value, ...]`.

| Keyword | Installs via | Example |
| --- | --- | --- |
| `tap` | `brew tap` | `tap "jorgelbg/tap"` |
| `brew` | `brew install` | `brew "ripgrep"` |
| `cask` | `brew install --cask` | `cask "ghostty"` |
| `mas` | `mas install` (needs the `mas` formula) | `mas "Yoink", id: 457622435` |
| `vscode` | VS Code + forks/variants | `vscode "editorconfig.editorconfig"` |
| `go` | `go install` | `go "github.com/charmbracelet/crush"` |
| `cargo` | `cargo install` | `cargo "ripgrep"` |
| `npm` | `npm install -g` | `npm "prettier"` |
| `uv` | `uv tool install` | `uv "ruff"` |
| `krew` | `kubectl krew install` | `krew "ctx"` |
| `flatpak` | `flatpak install` — **Linux only** | `flatpak "com.visualstudio.code"` |
| `winget` | `winget install` — **WSL only** | `winget "Steam", id: "Valve.Steam"` |

**This repo tracks `tap`/`brew`/`cask`/`mas` only** — see [style-guide.md](style-guide.md) §1. The rest are
documented here so the option is available, not because they are in use.

### Global directives

```ruby
# default args for EVERY `cask` entry in the file
cask_args appdir: "~/Applications", require_sha: true

# set an env var visible to `system` calls in this file and to `brew bundle exec`
ENV["SOME_ENV_VAR"] = "some_value"
```

---

## 2. Per-entry options

### `tap`

```ruby
tap "user/repo"                                              # standard
tap "user/repo", "https://user@bitbucket.org/user/repo.git"  # custom clone URL
tap "user/repo", trusted: true                               # trust the whole tap
tap "user/repo", trusted: {                                  # trust only named items
  formula:  "one-formula",
  formulae: ["another", "and-another"],
  cask:     "one-cask",
  casks:    ["another-cask"],
  command:  "one-command",
  commands: ["another-command"],
}
```

Singular and plural keys both work. Values are item names **inside that tap**, so `formula: "foo"` on
`tap "user/repo"` trusts `user/repo/foo`.

### `brew` (formulae)

| Option | Meaning |
| --- | --- |
| `args: ["with-rmtp"]` | Extra `brew install` args. Only valid for non-`homebrew/core` formulae. |
| `link: true` / `:overwrite` / `false` | Force `brew link`, `brew link --overwrite`, or skip linking. |
| `conflicts_with: ["mysql"]` | `brew unlink` these first, if installed. |
| `restart_service: true` | `brew services restart` after install. |
| `restart_service: :changed` | Restart **only** if it was installed or upgraded this run. |
| `restart_service: :always` | Restart unconditionally. |
| `start_service: true` | `brew services start`. |
| `postinstall: "cmd"` | Shell command, run only if installed/upgraded. `${HOMEBREW_PREFIX}` is available. |
| `version_file: ".ruby-version"` | Write the installed version to this file after processing. |
| `trusted: true` | Trust this formula from a non-official tap. |

```ruby
brew "denji/nginx/nginx-full", link: :overwrite, args: ["with-rmtp"], restart_service: :always
brew "mysql@5.6", restart_service: :changed, link: true, conflicts_with: ["mysql"]
brew "postgresql@16",
     postinstall: "${HOMEBREW_PREFIX}/opt/postgresql@16/bin/postgres -D ${HOMEBREW_PREFIX}/var/postgresql@16"
brew "ruby", version_file: ".ruby-version"
```

### `cask`

| Option | Meaning |
| --- | --- |
| `args: { appdir: "~/my-apps/Applications" }` | Per-cask install args (a **hash**, unlike `brew`'s array). |
| `greedy: true` | Run `brew upgrade` even on auto-updating/unversioned casks. Forces self-updating software to the newest cask version. |
| `postinstall: "cmd"` | Run if installed/upgraded. |
| `trusted: true` | Trust this cask from a non-official tap. |

```ruby
cask "firefox", args: { appdir: "~/my-apps/Applications" }
cask "opera", greedy: true
cask "google-cloud-sdk", postinstall: "${HOMEBREW_PREFIX}/bin/gcloud components update"
```

### `mas`

```ruby
mas "Yoink", id: 457622435
```

`id:` is **required and authoritative**; the name is a human label only. Requires `brew "mas"` in the file.

### `flatpak` / `winget`

```ruby
flatpak "org.godotengine.Godot", remote: "flathub-beta", url: "https://dl.flathub.org/beta-repo/"
winget "PowerToys", id: "XP89DCGQ3K6VLD", source: "msstore"
```

WinGet installs run non-interactively; if WinGet reports elevation is required, `brew bundle` retries
through Windows UAC.

---

## 3. Tap trust (`trusted:`)

Non-official taps require trust before Homebrew will load them. `trusted:` declares that trust **in the
Brewfile**, so `brew bundle install` works unattended on a fresh machine.

- Works on `tap`, `brew` and `cask` entries.
- Upstream advice: **prefer trusting the specific formula/cask/command over a whole tap.**
- `brew bundle dump` writes `trusted: true` on trusted `brew`/`cask`/whole-tap entries. It writes
  tap-level trust *hashes* for trusted items from a tap that are not otherwise present in the dump.
- `brew bundle cleanup --force` **resets Homebrew's tap trust file** to exactly what the Brewfile declares,
  removing any trust entry not declared there. Deleting a `trusted:` from the file therefore revokes trust.

⚠ `trusted: true` on a `brew` line is redundant when its `tap` line already carries `trusted: true`.
`brew bundle dump` emits tap-level trust only — match that.

---

## 4. Ruby semantics and conditionals

Brewfiles are `eval`'d Ruby. Useful, but it makes the file **non-declarative** and per-machine variable.

```ruby
brew "gnupg" if OS.mac?
brew "glibc" if OS.linux?

# runs `brew install --cask java` only if there is no Java already
cask "java" unless system "/usr/libexec/java_home", "--failfast"
```

⚠ Three real consequences:

1. **`brew bundle list` hides conditionally-excluded entries.** On Linux the `gnupg` line above simply does
   not appear in the list output — so a diff-based audit will report it as missing from the Brewfile.
2. **`system` calls run during `brew bundle check`**, not just `install`. A slow or side-effecting command
   in a conditional makes `check` slow or side-effecting.
3. **`brew bundle dump` never regenerates conditionals.** Any Ruby logic is destroyed by a `dump --force`.
   This is the single biggest reason not to maintain a Brewfile by dumping over it.

---

## 5. Subcommands

| Command | What it does |
| --- | --- |
| `brew bundle` / `install` | Install and (by default) upgrade everything in the file. |
| `brew bundle upgrade` | Shorthand for `install --upgrade`. |
| `brew bundle check` | Exit 0 if `install` would be a no-op. Add `--verbose` to list what is unmet. |
| `brew bundle list` | List entries. Filter with `--formula` / `--cask` / `--tap` / `--mas` / `--vscode` / … |
| `brew bundle dump` | Snapshot installed state to a Brewfile. |
| `brew bundle cleanup` | Uninstall supported packages **not** in the Brewfile. Dry-run unless `--force`. |
| `brew bundle add <name>` | Append an entry. Formula by default; `--cask`, `--tap`, `--vscode`, … for others. |
| `brew bundle remove <name>` | Remove matching entries. `--formula` also matches aliases and old names. |
| `brew bundle exec <cmd>` | Run a command with the Brewfile's packages on `PATH` (linked or not, keg-only or not). |
| `brew bundle sh` | Interactive shell in that same environment. |
| `brew bundle env` | Print the env vars as `export` lines; use with `eval`. |
| `brew bundle edit` | Open the Brewfile in `$EDITOR`. |

### Shared flags

| Flag | Applies to | Meaning |
| --- | --- | --- |
| `--file=PATH` | all | Which Brewfile. `--file=-` pipes via stdin/stdout. |
| `--global`, `-g` | all | Use `$HOMEBREW_BUNDLE_FILE_GLOBAL`, else `${XDG_CONFIG_HOME}/homebrew/Brewfile`, else `~/.homebrew/Brewfile`, else `~/.Brewfile`. |
| `--force`, `-f` | `dump`, `cleanup` | `dump`: overwrite an existing file. `cleanup`: actually uninstall. |

### `install` / `upgrade` flags

`--no-upgrade` (skip `brew upgrade`) · `--upgrade` (force, even if `HOMEBREW_BUNDLE_NO_UPGRADE` is set) ·
`--upgrade-formulae=a,b` (upgrade only these) · `--jobs=N|auto` (parallel installs; default 1, `auto` caps
at 4) · `--force` (`--force`/`--overwrite`) · `--force-cleanup` (cleanup afterwards without asking) ·
`--zap` (use `brew uninstall --zap` instead of plain uninstall when cleaning up casks).

### `dump` flags

Per-type opt-in: `--formula` `--cask` `--tap` `--mas` `--vscode` `--go` `--cargo` `--uv` `--flatpak`
`--winget` `--krew` `--npm`. Passing **any** type flag makes the dump only those types.

Per-type opt-out: `--no-<type>` (alias `--no-dump-<type>`), e.g. `--no-vscode`.

Also: `--describe` / `--no-describe` (description comments above each entry — **on by default**) ·
`--no-restart` (omit `restart_service:`) · `--install` (run `install` before dumping) · `--force`.

### `exec` / `sh` / `env` flags

`--check` (run `check` first) · `--install` (run `install` first) · `--services` (start the Brewfile's
services for the duration). Inside these environments `HOMEBREW_INSIDE_BUNDLE=1` is set.

---

## 6. Environment variables

| Variable | Effect |
| --- | --- |
| `HOMEBREW_BUNDLE_FILE` | Default Brewfile path. |
| `HOMEBREW_BUNDLE_FILE_GLOBAL` | Path used by `--global`. |
| `HOMEBREW_BUNDLE_NO_UPGRADE` | `install` behaves as `--no-upgrade`. |
| `HOMEBREW_BUNDLE_NO_DESCRIBE` | `dump` behaves as `--no-describe`. |
| `HOMEBREW_BUNDLE_DUMP_NO_<TYPE>` | `dump` skips that type. `<TYPE>` ∈ `BREW` `CASK` `TAP` `MAS` `VSCODE` `GO` `CARGO` `UV` `FLATPAK` `WINGET` `KREW` `NPM`. |
| `HOMEBREW_BUNDLE_<TYPE>_SKIP` | Space-separated names for `install` to skip. `<TYPE>` ∈ `BREW` `CASK` `MAS` `TAP`. |
| `HOMEBREW_BUNDLE_FORCE_INSTALL_CLEANUP` | With `--global`, implies `--force-cleanup`. |
| `HOMEBREW_INSIDE_BUNDLE` | Set to `1` inside `exec`/`sh`/`env`. Detect-only. |

---

## 7. Versions — there is no lock file

Homebrew is a rolling release. `brew bundle` **does not and will not** support pinning versions or a
`Brewfile.lock`. The only lever is `--no-upgrade` / `HOMEBREW_BUNDLE_NO_UPGRADE=1`, which stops upgrades
but pins nothing — `brew install` may still upgrade a package if a dependency requires it.

Version *selection* happens through versioned formula/cask tokens instead: `postgresql@16`, `temurin@25`,
`figma@beta`, `visual-studio-code@insiders`, `claude-code@latest`.

⚠ A versioned token and its unversioned sibling are **separate packages** and can both be installed
(this machine has both `figma` and `figma@beta`). Neither `dump` nor `check` will flag that as odd.

---

## 8. What `brew bundle dump` actually emits — verified

Confirmed by dumping this machine (Homebrew 6.0.13):

- **Order:** `tap` → `brew` → `cask` → `mas`. Alphabetical within each group; `mas` sorted by name.
- **Quoting:** always `"double"`. Never single.
- **Descriptions:** `--describe` is the default and covers **both formulae and casks**, as a full-line
  `# comment` *above* the entry.
- ⚠ **Font casks get no description at all** — `font-commit-mono`, `font-sf-pro` etc. dump bare.
- ⚠ **Long descriptions wrap onto a second comment line**, e.g. `pinentry-touchid` produces two `#` lines.
  Anything parsing "one comment = one package" breaks on this.
- **Tapped formulae are dumped fully qualified**: `brew "jorgelbg/tap/pinentry-touchid"`.
- **Trust is emitted at tap level**: `tap "jorgelbg/tap", trusted: true`, with no `trusted:` on the
  formula line.
- ⚠ **Dump includes every installed cask**, with no equivalent of `--installed-on-request`.
- ⚠ **Dump includes Apple's pre-bundled App Store apps** (GarageBand, iMovie, Keynote, Numbers, Pages).
- **`cask_args`, comments, section headers, blank lines and all Ruby logic are lost.** A dump is a
  flat generated file, which is why this repo treats it as an *input to a diff*, never as the output.
