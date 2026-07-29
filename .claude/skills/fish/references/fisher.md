# Fish — fisher (plugin manager)

fisher 4.4.8: what it actually does (read from `functions/fisher.fish`, not just the README), how to adopt
it in **this** config, and the failure modes worth knowing before you run it. It does not cover writing the
plugin's fish code itself — see [style-guide.md](style-guide.md).

⚠ **fisher is not installed on this machine.** Verified:

```sh
/opt/homebrew/bin/fish -c 'functions -q fisher; and echo installed; or echo absent'   # → absent
ls ~/.config/fish/functions/                                                          # → reload.fish only
ls ~/.config/fish/plugins/                                                            # → empty
```

Everything below §2 describes a **target state**. Nothing in `~/.config/fish` currently loads, calls, or
depends on fisher. The config does anticipate it: `~/.config/fish/plugins/` exists but is empty, and
`conf.d/_init.fish` ends its "fish dirs" section with

```fish
if set -q fisher_path
    mkdir -p "$fisher_path"
end
```

— a no-op today because `fisher_path` is unset. (style-guide §4 writes that guard as the one-liner
`set -q fisher_path; and mkdir -p $fisher_path`; the live file uses the block form.)

## 1. What fisher is and is not

**fisher is a single ~250-line fish function that copies files.** There is no daemon, no shim, no
`PATH` munging, no lockfile, and no dependency resolver. `fisher install` downloads a repository tarball,
then copies the contents of the plugin's `functions/`, `conf.d/`, `completions/` and `themes/`
directories into the same four directories under `$fisher_path`. From then on the plugin is loaded by
**fish's ordinary autoloading and conf.d sourcing** — fisher is not involved at shell startup at all.

Consequences that follow directly from that mental model:

| Because fisher only copies files… | …this is true |
| --- | --- |
| plugins are plain fish files in `$fisher_path` | you can read, `grep`, and delete them by hand |
| loading is fish's job | `$fisher_path/functions` must be on `$fish_function_path`, `completions` on `$fish_complete_path`, and `$fisher_path/conf.d/*.fish` must be sourced by *you* unless `$fisher_path` is `~/.config/fish` |
| nothing tracks provenance except universal variables | lose `fish_variables` and fisher no longer knows what it installed (§5, §8) |
| there is no version pinning beyond the `@ref` you type | `fisher update` fetches whatever that ref points at now |
| a plugin's own `fish_plugins` is ignored | **there is no dependency installation** (verified: a `fish_plugins` at a plugin's root is not copied and not read) |
| removal is `rm -rf` of a recorded path list | files you added to `$fisher_path` by hand are orphans; files you edited are destroyed |

## 2. Installation and adoption

### 2.1 Decide `$fisher_path` first

`fisher` reads it at call time: `set --query fisher_path || set --local fisher_path $__fish_config_dir`.
Unset means **plugin files are expanded straight into `~/.config/fish/{functions,conf.d,completions,themes}`**,
intermixed with hand-written config that `fisher remove` will later `rm -rf`. Set it before the first
`fisher` call, or you will be untangling the two by hand — the paths fisher recorded are frozen in
universal variables until that plugin is updated or removed.

For this config: **`$fisher_path` = `~/.config/fish/plugins`** (the empty directory that already exists),
set in `conf.d/_init.fish`'s "fish dirs" block, replacing the existing `set -q fisher_path` guard.
`_init.fish` sorts first in `conf.d/` (style-guide §2), so the value, the `mkdir -p` and the path wiring are
all in place before any later snippet can autoload a plugin function.

⚠ `fish_plugins` is **not** affected by `$fisher_path`. fisher hardcodes
`$__fish_config_dir/fish_plugins` → always `~/.config/fish/fish_plugins` (verified).

### 2.2 Lines to add to `conf.d/_init.fish`

Insert after the existing `set fish_complete_path …` line, replacing the bare `set -q fisher_path` guard:

```fish
# fisher owns everything under plugins/ — generated, never hand-edited
set -g fisher_path "$fish_config_dir/plugins"
mkdir -p "$fisher_path"/{functions,completions,conf.d,themes}

# append, so a hand-written function of the same name still wins
set fish_function_path $fish_function_path "$fisher_path/functions" (path resolve "$fisher_path/functions"/*/)
set fish_complete_path $fish_complete_path "$fisher_path/completions"

# fish only auto-sources conf.d under $__fish_config_dir; plugin snippets are ours to source.
# the glob is the guard — `for` expands an unmatched glob to nothing, so an empty plugins dir is a no-op
for f in "$fisher_path"/conf.d/*.fish
    source $f
end
```

Ordering consequence of putting the loop in `_init.fish`: **plugin snippets run before**
`abbrs.fish`, `brew.fish`, `git.fish`. That is the right default — it mirrors fish's own
conf.d-then-`config.fish` layering, so your files override a plugin's, not the reverse. The cost is that a
plugin snippet cannot see anything a later snippet sets (`$HOMEBREW_PREFIX`, the git overrides). If one
needs that, move **only the `for` loop** into a new `conf.d/zz-plugins.fish` (letters sort after `_`);
keep `fisher_path` and the two path lines in `_init.fish`.

### 2.3 Bootstrap

Reload first (`exec fish`) so `$fisher_path` is set, then run the README's one-liner — it defines `fisher`
for the current session only, and the first thing you install is fisher itself:

```sh
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
```

House-style spelling of the same thing (style-guide §5):

```fish
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
and fisher install jorgebucaran/fisher
```

That writes `$fisher_path/functions/fisher.fish` and `$fisher_path/completions/fisher.fish`, so the
command is autoloadable from the next session — which is exactly why §2.2 must land *before* this step.
Fetches are unauthenticated GitHub API calls, so the rate limit is per-IP and low (§8.2).

## 3. Commands

| Command | What it does | What it writes |
| --- | --- | --- |
| `fisher install <plugin>…` | fetches each plugin in parallel (one background job + `mktemp -d` each), refuses any whose target files already exist, copies, sources each top-level `.fish` file, emits `<name>_install` | `$fisher_path/{functions,conf.d,completions,themes}/`, `~/.config/fish/fish_plugins`, universal `_fisher_plugins` and `_fisher_<plugin>_files` |
| `fisher update <plugin>…` | re-fetch; `rm -rf` the previously recorded files, then copy the new set; emits `<name>_update` | same |
| `fisher update` | reconciles the installed set against `fish_plugins`: installs entries you added, removes entries you deleted, updates the rest (verified) | same |
| `fisher remove <plugin>…` \| `fisher uninstall …` | emits `<name>_uninstall`, `rm -rf`s the recorded paths, `functions --erase` / `complete --erase` for them | erases the plugin's universal vars; rewrites `fish_plugins`, or deletes it when nothing is left (verified) |
| `fisher list [REGEX]` | `string match --entire --regex -- REGEX $_fisher_plugins` | nothing |
| `fisher -v` / `fisher -h` | `fisher, version 4.4.8` / usage | nothing |

`install`, `update` and `remove` also read plugin names from **stdin** when stdin is not a TTY — that is how
`fisher list | fisher remove` nukes everything, and why a non-interactive call hangs (§8.1).

Accepted plugin-name forms — verified by watching the URL fisher builds:

| Form | Resolves to | Notes |
| --- | --- | --- |
| `owner/repo` | `https://api.github.com/repos/owner/repo/tarball/HEAD` | the normal case |
| `owner/repo@v6` / `@branch` / `@sha` | `…/tarball/v6` | any commit-ish |
| `gitlab.com/owner/repo[@ref]` | `https://gitlab.com/owner/repo/-/archive/<ref>/repo-<ref>.tar.gz` | `https://` prefix optional |
| `/abs/path` or `./relative` | `cp -Rf <path>/* <tmp>` — no network | recorded as the `realpath`; the way to develop a plugin in-tree |
| ⚠ `https://github.com/owner/repo` | **broken** — builds `https://api.github.com/repos/https://github.com/owner/repo/tarball/HEAD` | GitHub takes `owner/repo` only; the README's "bare URL" support is GitLab-only |

Remote names are lowercased before use and storage (`ilancosman/tide@v6`); local names become absolute paths.

## 4. `fish_plugins`

`~/.config/fish/fish_plugins` — one plugin per line, no comments (fisher reads it with
`string match --regex -- '^[^\s]+$'`, so blank/whitespace lines are dropped and anything with a space is
ignored). `$HOME` is written back as a literal `~`. fisher rewrites the whole file after every mutating
command; edit it and run `fisher update` to apply.

- **Bootstrap from the file.** `fisher install <anything>` when `$_fisher_plugins` is empty also installs
  everything listed in `fish_plugins` (verified). So on a new machine, `fisher install jorgebucaran/fisher`
  restores the whole set.
- ⚠ **It is the only artifact worth version-controlling** — but per CLAUDE.md `~/.config` is *not* mirrored
  into this repo, and no dotfiles manager has been adopted. Do not copy `fish_plugins` into the repo. It is
  the file that becomes tracked once one is.

A plausible starting set — only these two names are attested by a source available offline (fisher's own
README), and any other name **must be confirmed against GitHub before you write it into a file**:

```
jorgebucaran/fisher    # fisher manages itself
PatrickF1/fzf.fish     # fzf history/file/git widgets, replaces hand-written binds
```

`jorgebucaran/nvm.fish` and `IlanCosman/tide@v6` also exist per the README but are both redundant here
(brew's node; `starship`). `jorgebucaran/autopair.fish` is from memory — unverified.
⚠ Do **not** reach for a plugin for `zoxide`, `fzf`'s binary, `atuin`, `starship` or `grc`: those are
brew-installed and need a `conf.d/<tool>.fish` snippet (CLAUDE.md known-gap 5), not a plugin.

## 5. Internal state

All universal, all in `~/.config/fish/fish_variables`:

| Variable | Contents |
| --- | --- |
| `$_fisher_plugins` | installed plugin names, in install order (lowercased, or absolute paths) |
| `_fisher_<escaped-name>_files` | every path fisher copied for that plugin, with `$HOME` stored as a literal `~`. Name is `_fisher_` + `string escape --style=var -- $plugin` + `_files` |
| `_fisher_upgraded_to_4_4` | one-shot marker set when `fisher.fish` is sourced; guards the 3.x → 4.4 migration at the bottom of the file |

⚠ This is why style-guide §3's "never `set -U`" has an exception: fisher's own bookkeeping is universal by
design. Do not hand-edit `fish_variables` (CLAUDE.md), and do not commit it.

Debugging a broken install, in order:

```fish
# is there any state at all, and what does fisher think is installed?
set --names | string match '_fisher_*'
printf '%s\n' $_fisher_plugins

# what files does it claim to own, and what is actually on disk?
set -l v _fisher_(string escape --style=var -- jorgebucaran/fisher)_files
printf '%s\n' $$v
path filter -f -- $fisher_path/{functions,conf.d,completions,themes}/*
```

If the two disagree, resync by making disk match "nothing installed" and letting `fish_plugins` drive:

```fish
rm -rf $fisher_path/{functions,conf.d,completions,themes}
fisher update
```

Verified: that recovers a state where the universal variables were erased but the files were still present.

## 6. Events

fisher emits three events per plugin. ⚠ **The event prefix is the basename of each `conf.d/*.fish` file the
plugin ships — not the plugin's name.** `emit {$name}_$event` where `$name` comes from
`'.+conf\.d/([^/]+)\.fish$'`. A plugin `owner/flipper.fish` whose snippet is `conf.d/flipper.fish` emits
`flipper_install`; a plugin shipping two conf.d files emits two of each event.

| Event | When |
| --- | --- |
| `<name>_install` | after the files are copied and sourced, on first install only |
| `<name>_update` | same position, on `fisher update` |
| `<name>_uninstall` | **before** the files are deleted, on `fisher remove` |

The handler must be registered when the event fires, and autoloading does not register handlers
(style-guide §6) — so handlers live in `conf.d/`. Canonical example, fisher's own `tests/ponyo/conf.d/ponyo.fish`,
verbatim:

```fish
echo pyon pyon

function ponyo_install --on-event ponyo_install
    set --global ponyo pyon pyon
end

function ponyo_update --on-event ponyo_update
    set --global --append ponyo pyon
end

function ponyo_uninstall --on-event ponyo_uninstall
    set --erase ponyo
end
```

(House style would add `--description` to each and prefix them `__ponyo_*`; the upstream test does not.)

⚠ `_install` and `_update` work because fisher `source`s the plugin's top-level `.fish` files immediately
before emitting. `_uninstall` has no such help: the handler only exists if that `conf.d` file was sourced
earlier in **this** session. Verified — with `$fisher_path` outside `~/.config/fish` and no sourcing loop,
`fisher remove` silently ran no uninstall handler. §2.2's `for` loop is what makes uninstall work.

## 7. Authoring a plugin

```
myplugin/
├── completions/myplugin.fish     # complete -c …
├── conf.d/myplugin.fish          # wiring + --on-event handlers
├── functions/myplugin.fish       # one public function per file
└── themes/myplugin.theme         # optional
```

- Only those four directories are copied; a root-level `README.md`, `LICENSE` or `fish_plugins` is not.
- **Subdirectories are copied wholesale.** A plugin shipping `functions/git/foo.fish` gets the `git`
  directory copied and recorded as **one** path entry — it is not sourced at install time, and it is only
  autoloadable because §2.2 adds `(path resolve "$fisher_path/functions"/*/)`. `_init.fish`'s existing
  subdirectory glob covers `~/.config/fish/functions/*/` only. Verified both halves.
- **No dependencies.** A `fish_plugins` in your plugin is ignored (verified). Document prerequisites, or
  `type -q` them and degrade quietly.

Develop against the working tree with a path install — no network, no tag:

```fish
fisher install (path resolve .) # records the realpath
fisher update (path resolve .) # re-copy after an edit
fisher remove (path resolve .)
```

Checklist for a plugin that must also survive being installed by hand (`git clone` + `cp`):

- [ ] no essential setup lives only in an `--on-event` handler — make `conf.d` idempotent and
      self-sufficient, and treat the handler as a bonus
- [ ] `conf.d` snippet guards its tool (`type -q`) and bails early when non-interactive
- [ ] nothing reads `$fisher_path`, `$_fisher_plugins`, or assumes where it was copied to
- [ ] file basenames are distinctive enough not to collide with a user's own (§8.3)
- [ ] `functions/` file basename == function name, `--description` present, `fish_indent --check` clean

## 8. ⚠ Gotchas

1. **A non-interactive `fisher install` hangs.** `isatty || read --null --array stdin` — with no TTY it
   blocks reading stdin. Every Bash-tool invocation needs `</dev/null`:
   ```sh
   /opt/homebrew/bin/fish -c 'fisher install owner/repo' </dev/null
   ```
2. **Fetch failure is per-plugin and quiet-ish.** HTTP 403 → `fisher: GitHub API rate limit exceeded`;
   anything else → `fisher: Invalid plugin name or host unavailable: "…"`. The plugin is dropped from the
   batch and the previously installed copy is left untouched (no half-updated state). ⚠ But the exit status
   only reflects whether *anything* happened: one failure plus one success exits **0**; a batch where
   nothing installed/updated/removed exits 1. Verified. Never trust `fisher install`'s status alone —
   check `fisher list`.
3. **Install refuses to overwrite.** Any pre-existing target file aborts that plugin with
   `fisher: Cannot install "…": please remove or move conflicting files first:`. The realistic way to hit
   this is a `$fisher_path` whose files survived while the universal state did not (restored config, fresh
   `fish_variables`, or a changed `$fisher_path`): every plugin then looks new and every file conflicts.
   Fix with the resync in §5. Verified.
4. **`update` and `remove` `rm -rf` the recorded paths with no confirmation**, so a hand edit inside
   `$fisher_path` is lost on the next update — and conversely a file you dropped in there yourself is never
   recorded and never cleaned up (verified: it survives `fisher remove`). Treat `$fisher_path` as generated
   output; put your own code in `~/.config/fish/`.
5. **A new `conf.d` snippet only affects the installing shell.** fisher sources the plugin's top-level
   `.fish` files at install, so the current session is up to date; other running shells need `exec fish`
   (the `reload` function). Files in plugin *subdirectories* are never sourced.
6. **Path ordering decides who wins.** Earlier entries of `$fish_function_path` shadow later ones, so §2.2
   appends `$fisher_path/functions` — your `functions/foo.fish` beats a plugin's. Flip it only if you
   deliberately want plugins to override your own. Omit the lines entirely and the plugin's functions and
   completions simply never load, with no error.
7. **Themes are invisible from `fish_config`** unless they sit in `$__fish_config_dir/themes`. fisher's
   README suggests symlinking `~/.config/fish/themes → $fisher_path/themes`, which here would collide with
   `$FISH_THEMES_DIR` (set and `mkdir -p`'d by `_init.fish`) and with hand-maintained themes. Since
   `laramie` is hand-maintained across tools (CLAUDE.md), prefer copying a plugin theme in over symlinking
   the directory.
