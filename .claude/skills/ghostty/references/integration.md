# Ghostty integration — CLI, shell integration, terminfo, SSH, themes, AppleScript, debugging

Verified against **Ghostty 1.3.2-main-+6e21f41c0** (channel `tip`) on macOS 27, installed at
`/Applications/Ghostty.app`.

---

## 1. The `ghostty` CLI

The binary is `/Applications/Ghostty.app/Contents/MacOS/ghostty`. Ghostty's `path` shell-integration
feature appends that directory to `$PATH`, so a plain `ghostty` works in any Ghostty-launched shell.

⚠ **On macOS you cannot launch the terminal from the CLI** — only actions run. To launch with
arguments: `open -na Ghostty.app` or `open -na Ghostty.app --args --font-size=14`.

Every config key is also a CLI flag: `ghostty --font-size=12 --font-family="Fira Code"`.
`-e <command> …` runs a command in the terminal (sets `initial-command`; see
[configuration.md](configuration.md)).

### Actions

| Action | Purpose |
| --- | --- |
| `+version` | Version, channel, Zig version, build mode, runtime, font engine, renderer, libxev backend. Also how you check the **libadwaita version** on Linux. |
| `+help` | General help. `+<action> --help` for one action. |
| `+show-config` | The fully resolved, merged config. `--default` for defaults, `--docs` to include doc comments. `+show-config --default --docs` is the canonical offline option reference. |
| `+explain-config <key>` | Docs for a single option or action. `--option=` / `--keybind=` to disambiguate, `--no-pager` for scripting. Prints `Unknown: 'x'.` for a bad name. |
| `+validate-config` | Validate. `--config-file=<path>` to check one file, `--config-default-files=false` to check it in isolation. Exit **1** with `file:line:key: message` per error. |
| `+edit-config` | Open the config in the default editor. |
| `+list-fonts` | All discoverable fonts via Ghostty's own discovery. `--family=` to filter. |
| `+list-themes` | All themes (592 built-in + your own). `--plain` for scripting. |
| `+list-colors` | Named X11 colours accepted by colour options. |
| `+list-keybinds` | Current binds; `--default` for the shipped set. |
| `+list-actions` | All keybind actions; `--docs` for descriptions. |
| `+show-face` | Which font face is chosen for given text/style — the tool for debugging fallback. |
| `+ssh` / `+ssh-cache` | SSH wrapper and its terminfo cache (§4). Both present on the installed 1.3.2-main build (verified 2026-07-28). |
| `+new-window` / `+toggle-quick-terminal` | Drive a running instance. |
| `+crash-report` | List/inspect crash reports. |
| `+boo` | 👻 |

### Bundled resources (macOS)

```
/Applications/Ghostty.app/Contents/Resources/
├── ghostty/
│   ├── doc/{ghostty.1.md,ghostty.1.html,ghostty.5.md,ghostty.5.html}
│   ├── shell-integration/{bash,elvish,fish,nushell,zsh}/
│   └── themes/                       # 592 built-in themes
├── man/man1/ghostty.1  man/man5/ghostty.5
├── terminfo/{67/ghostty,78/xterm-ghostty}
├── {bash-completion,zsh/site-functions,fish/vendor_completions.d}/
└── bat/syntaxes/ghostty.sublime-syntax     # bat highlighting for config.ghostty
```

`ghostty.5.md` is the complete config + keybind-action reference in markdown; `ghostty.1.md` is the CLI
reference. Both are version-matched to the installed build and are the fastest offline source.

### Environment variables Ghostty sets

| Variable | Value on this machine |
| --- | --- |
| `TERM` | `xterm-ghostty` (configurable via `term`) |
| `TERM_PROGRAM` | `ghostty` |
| `TERM_PROGRAM_VERSION` | `1.3.2-main-+6e21f41c0` |
| `COLORTERM` | `truecolor` |
| `TERMINFO` | `…/Contents/Resources/terminfo` |
| `GHOSTTY_RESOURCES_DIR` | `…/Contents/Resources/ghostty` |
| `GHOSTTY_BIN_DIR` | `…/Contents/MacOS` |
| `GHOSTTY_SURFACE_ID` | per-surface id, e.g. `0x0d0436a48ce1e39b` |
| `GHOSTTY_SHELL_FEATURES` | the resolved `shell-integration-features`, e.g. `cursor:blink,path,sudo,title` |
| `GHOSTTY_SHELL_INTEGRATION_XDG_DIR` | transient — see §3 |
| `XDG_DATA_DIRS` / `MANPATH` | Ghostty's resource dir appended |

Variables Ghostty **reads**: `XDG_CONFIG_HOME`, `LOCALAPPDATA` (Windows), `SHELL`, and `GHOSTTY_LOG`.

---

## 2. Logging and debugging

`GHOSTTY_LOG` selects destinations: `stderr` and `macos` (the unified log). Comma-combine, `no-`-prefix
to disable, `true`/`false` for all. Debug-optimized builds log debug to stderr; other builds don't.

```sh
sudo log stream --level debug --predicate 'subsystem=="com.mitchellh.ghostty"'   # macOS
journalctl --user --unit app-com.mitchellh.ghostty.service                        # Linux systemd
```

Config load messages appear in the first ~20 lines of debug output. Config errors are also shown in a
dedicated window on macOS and GTK, and are never fatal — the bad key falls back to its default.

---

## 3. Shell integration

### What it buys you

- New terminals/tabs/splits inherit the working directory (OSC 7).
- Prompt marking (OSC 133) → `jump_to_prompt`, prompt-aware resizing (the shell **redraws** rather than
  reflows a complex prompt), triple-click+ctrl/cmd to select a command's output, alt/option+click to
  move the cursor, and `cursor-click-to-move`.
- Closing a terminal sitting at a prompt skips the confirmation.
- Bar cursor at the prompt.
- Optional `sudo` wrapping to preserve terminfo, and `ssh` wrapping (both off by default).

### How injection works

Ghostty supports `bash`, `elvish`, `fish`, `nushell`, `zsh`, detected by the **basename** of the command
(`shell-integration = detect`). Force with `shell-integration = fish`; disable with `none`.

⚠ Ghostty injects the fish/zsh integration by **prepending its own directory to `XDG_DATA_DIRS`** and
exporting `GHOSTTY_SHELL_INTEGRATION_XDG_DIR`, so the shell autoloads it from `vendor_conf.d`. The
script's first act is `ghostty_restore_xdg_data_dir`, which **removes that entry again and erases the
variable** — so by the time you inspect the environment, the injected path is already gone. Its absence
is not evidence that injection didn't happen.

| Shell | Integration script (under `$GHOSTTY_RESOURCES_DIR`) |
| --- | --- |
| bash | `shell-integration/bash/ghostty.bash` |
| elvish | `shell-integration/elvish/lib/ghostty-integration.elv` |
| fish | `shell-integration/fish/vendor_conf.d/ghostty-shell-integration.fish` |
| nushell | `shell-integration/nushell/vendor/autoload/ghostty.nu` |
| zsh | `shell-integration/zsh/ghostty-integration` |

Notes: ⚠ **macOS's `/bin/bash` cannot be auto-integrated** — source the script manually or install a
modern bash. Nushell provides title/cursor handling itself, so its integration only covers
Ghostty-specific features. **Fish 4.0+ has built-in prompt marking**, so `jump_to_prompt`, prompt
resizing and prompt selection work even without the integration.

### Verifying

Look for these log lines:

```
info(io_exec): using Ghostty resources dir from env var: /Applications/Ghostty.app/Contents/Resources
info(io_exec): shell integration automatically injected shell=termio.shell_integration.Shell.fish
```

Bad signs: `ghostty terminfo not found, using xterm-256color` or
`shell could not be detected, no automatic shell integration will be injected` — almost always a
`GHOSTTY_RESOURCES_DIR` problem. Validate with:
`test -f "$GHOSTTY_RESOURCES_DIR/../terminfo/ghostty.terminfo"`.
⚠ Needing to set `GHOSTTY_RESOURCES_DIR` by hand is a red flag that something else is wrong.

### Manual sourcing

Automatic injection covers **only the initially launched shell**. Running `bash`, `nix-shell`, or any
nested shell inside Ghostty loses it (the original shell keeps it). Manual sourcing fixes that, and
should come **as early as possible** in the rc file (some configurations interfere with it):

```bash
# top of ~/.bashrc
if [ -n "${GHOSTTY_RESOURCES_DIR}" ]; then
    builtin source "${GHOSTTY_RESOURCES_DIR}/shell-integration/bash/ghostty.bash"
fi
```

⚠ **Guard on `$GHOSTTY_RESOURCES_DIR`.** Unguarded, the path collapses to `/shell-integration/…`
outside Ghostty and every shell start prints:

```
source: Error encountered while sourcing file '/shell-integration/fish/vendor_conf.d/ghostty-shell-integration.fish':
source: No such file or directory
```

### What the fish script actually does

`ghostty-shell-integration.fish` (fish flavour, verified against this build):

- Restores `XDG_DATA_DIRS` and erases `GHOSTTY_SHELL_INTEGRATION_XDG_DIR`; exits unless interactive.
- Defers all real setup to `__ghostty_setup --on-event fish_prompt`, deliberately so it runs **last**,
  after other prompt-modifying integrations.
- Reads features from `$GHOSTTY_SHELL_FEATURES`.
- Emits OSC 133 marks: `A` on `fish_prompt`/`fish_posterror` (with `;click_events=1` on **fish ≥ 4.1**),
  `C` on `fish_preexec`, `D;$status` on `fish_postexec`.
- Emits OSC 7 cwd on `--on-variable PWD` (fish has this built in, but only for an allowlist of terminals
  that excludes Ghostty).
- Sets `fish_handle_reflow 1` so fish redraws the prompt on resize (Ghostty clears it).
- `cursor` → `\e[5 q` (blinking bar) or `\e[6 q` with `cursor:steady`, skipped when
  `fish_vi_cursor_handle` exists; reset with `\e[0 q` on preexec.
- `path` → `fish_add_path --global --path --append $GHOSTTY_BIN_DIR`.
- `sudo` → a `sudo` function adding `--preserve-env=TERMINFO`, but **only** when `$TERMINFO` is set and
  `sudo` is not already a function/alias. It skips the flag for `sudoedit` invocations (`-e`/`--edit`).
- `ssh-env`/`ssh-terminfo` → an `ssh` function translating the feature flags into
  `"$GHOSTTY_BIN_DIR/ghostty" +ssh <flags> -- $argv`.

### ⚠ How this actually resolves on this machine (verified on fish 4.8.1)

Ordering is **directory-major, not name-merged**: every file in `$XDG_CONFIG_HOME/fish/conf.d` runs
(alphabetically) *before* any `$XDG_DATA_DIRS/*/fish/vendor_conf.d` file — a user `zzz.fish` still
beats a vendor `aaa.fish`.

But `$__fish_vendor_confdirs` is computed at fish-init time, **before** any `conf.d` file runs, so the
snippet stripping `XDG_DATA_DIRS` at step 5 does **not** stop fish sourcing the vendor copy at step 7.
Consequences, both verified with a scratch config:

- `~/.config/fish/conf.d/_shell.fish` sources the snippet by hand, so the **top-level shell loads it
  twice**. The snippet is re-entrant, so this is harmless.
- A **nested** fish (`fish` inside Ghostty, `nix-shell`, …) inherits the already-stripped
  `XDG_DATA_DIRS` and gets **no** integration. That is the real reason the manual source has to stay —
  it matches Ghostty's own "Switching Shells" guidance above.

```sh
GI=/Applications/Ghostty.app/Contents/Resources/ghostty/shell-integration
XDG_DATA_DIRS=$GI       fish -c 'for d in $__fish_vendor_confdirs; test -d $d; and echo $d; end'  # prints it
XDG_DATA_DIRS=$GI/../.. fish -c 'for d in $__fish_vendor_confdirs; test -d $d; and echo $d; end'  # silent
```

---

## 4. Terminfo and SSH

`TERM` is `xterm-ghostty`. ⚠ The `xterm` prefix is deliberate: a pure `ghostty` value broke too many
applications that string-search `TERM` for "xterm" to infer capabilities. Ghostty's entry is in
**ncurses 6.5-20241228+**, so distro coverage grows over time.

Inspect the shipped entry:

```sh
TERMINFO=/Applications/Ghostty.app/Contents/Resources/terminfo infocmp -x xterm-ghostty
```

Notable capabilities: `Tc` (truecolor) · `Su` (styled underlines) + `Smulx`/`Setulc` ·
`Sync=\E[?2026…` (synchronized output) · `Ms=\E]52;…` (OSC 52 clipboard) · `XM=\E[?1006;1000…` (SGR
mouse) · `BE`/`BD`, `PS`/`PE` (bracketed paste) · `Cmg`/`Clmg`/`Enmg`/`Dsmg` (left/right margins) ·
`E3` (clear scrollback) · `Ss`/`Se` (cursor style) · `fullkbd`.

### sudo

`sudo` may reset the environment, producing `missing or unsuitable terminal: xterm-ghostty` or
`'xterm-ghostty': unknown terminal type`. Either configure sudo to preserve `TERMINFO`, or set
`shell-integration-features = sudo` and let Ghostty's wrapper add `--preserve-env=TERMINFO`.

### SSH to hosts without the entry

Symptoms: `missing or unsuitable terminal: xterm-ghostty`, `Error opening terminal: xterm-ghostty.`,
`WARNING: terminal is not fully functional`.

**Option 1 — copy the entry:**

```sh
infocmp -x xterm-ghostty | ssh YOUR-SERVER -- tic -x -
```

⚠ The remote `tic` warning `older tic versions may treat the description field as an alias` is safe to
ignore.
⚠ `tic` writes to `/usr/share/terminfo`; override with `$TERMINFO`, else it falls back to
`$HOME/.terminfo` **if that already exists**.
⚠ **macOS before Sonoma cannot use the system `infocmp`** — its ncurses is too old and emits an entry
newer `tic` rejects with `Illegal character` errors. Use
`/opt/homebrew/opt/ncurses/bin/infocmp` (`brew install ncurses`).

**Option 2 — fall back** (needs **OpenSSH ≥ 8.7**):

```ssh-config
Host example.com
  SetEnv TERM=xterm-256color
  SendEnv COLORTERM TERM_PROGRAM TERM_PROGRAM_VERSION
```

⚠ The fallback loses Ghostty-only capabilities such as coloured/styled underlines.
⚠ Do **not** apply `SetEnv TERM=xterm-256color` to hosts that already have the entry — it needlessly
downgrades them.
⚠ `SendEnv` is only a *request*: the remote `sshd` drops anything not in its `AcceptEnv`
(`AcceptEnv COLORTERM TERM_PROGRAM TERM_PROGRAM_VERSION`). `TERM` itself is always forwarded and is
unaffected by `AcceptEnv`.

### `ghostty +ssh` *(present on this build)*

⚠ Corrected 2026-07-28: this was documented as "requires tip / 1.4.0 — not in 1.3.x". It **is**
available on the installed **1.3.2-main-+6e21f41c0** — `ghostty +ssh --help` prints usage. This is
the `tip` channel, so version numbers are not a reliable gate; check the binary
(`ghostty +ssh --help`) rather than the release number. `shell-integration-features =
ssh-env,ssh-terminfo` is enabled in this machine's config and depends on it.

A drop-in `ssh` wrapper that prepares the remote session, then `exec`s the real `ssh` with your
arguments verbatim.

```sh
ghostty +ssh -- user@example.com
alias ssh='ghostty +ssh --'
```

- `--forward-env` (default `true`) — request `SendEnv` for `COLORTERM`, `TERM_PROGRAM`,
  `TERM_PROGRAM_VERSION`.
- `--terminfo` (default `true`) — install the terminfo entry remotely via `tic` on first connect, then
  set `TERM=xterm-ghostty`. On failure it logs a warning and falls back to `TERM=xterm-256color`.
- `--cache=false` — bypass both cache read and write for one invocation (scripting, debugging).
- `--ssh=PATH` — use a specific `ssh` binary. ⚠ If the path isn't executable, `+ssh` **fails** rather
  than silently falling back to the `PATH` `ssh`.

`ghostty +ssh-cache` manages the install cache, keyed `user@hostname` (the **resolved** host — post
`HostName`, post `ProxyJump` — not a `~/.ssh/config` alias; user defaults to `$USER`):

```sh
ghostty +ssh-cache                              # list all
ghostty +ssh-cache user@example.com             # one entry
ghostty +ssh-cache example.com                  # every cached user on a host
ghostty +ssh-cache --add=user@example.com       # mark cached after a manual install
ghostty +ssh-cache --remove=user@example.com    # force reinstall next connect (preferred)
ghostty +ssh-cache --prune=30d                  # s, m, h, d, w, y
ghostty +ssh-cache --clear
```

A lookup matching nothing exits nonzero.

### ⚠ The shell wrapper is a *function*, so it is not inherited

`shell-integration-features = ssh-env,ssh-terminfo` defines a shell function named `ssh`. It is **not**
used by:

- Scripts run as `./script.sh` or `sh script.sh` — each gets a fresh non-interactive shell. Use
  `source script.sh` to stay in the current shell.
- Tools that spawn `ssh` themselves: `scp`, `sftp`, `rsync -e ssh`, `git` over ssh, `mosh`,
  `gcloud compute ssh`, `aws ec2-instance-connect ssh`.
- Non-interactive shells generally — Makefile recipes, cron, command substitution in other programs.

For those, call `ghostty +ssh` directly or configure `~/.ssh/config` as above.

---

## 5. Themes

592 themes ship with Ghostty, sourced from [iterm2-color-schemes](https://iterm2colorschemes.com/) and
refreshed weekly on `main`. New themes should be contributed upstream to iterm2-color-schemes; Ghostty
picks them up automatically.

```sh
ghostty +list-themes            # interactive picker
ghostty +list-themes --plain    # scriptable list
```

```ini
theme = Catppuccin Frappe
theme = dark:Catppuccin Frappe,light:Catppuccin Latte   # follows system appearance
```

### Authoring

A theme is an ordinary config file. Lookup by name searches
`$XDG_CONFIG_HOME/ghostty/themes/` then `$PREFIX/share/ghostty/themes/`; `theme` also accepts an
absolute path to anywhere.

Themes load **before** your config, so your config overrides them — the opposite of `config-file`.
⚠ A theme may set **any** option, not just colours. Never use one from an untrusted source; the
built-ins are audited. `theme` and `config-file` inside a theme file are silently ignored.

The options a theme normally sets: `palette` (0–15 suffice; see `palette-generate`), `background`,
`foreground`, `cursor-color`, `cursor-text`, `selection-background`, `selection-foreground`.

Don't forget to reload after changing the theme.

---

## 6. AppleScript (macOS, since 1.3.0)

Enabled by default; disable with `macos-applescript = false`. macOS TCC prompts before another app may
control Ghostty.

```sh
sdef /Applications/Ghostty.app | less                  # the dictionary
osascript -e 'tell application "Ghostty" to get version'
```

Object model: `application → windows → tabs → terminals`.

| Object | Key properties | Elements |
| --- | --- | --- |
| `application` | `name`, `frontmost`, `front window`, `version` | `windows`, `terminals` |
| `window` | `id`, `name`, `selected tab` | `tabs`, `terminals` |
| `tab` | `id`, `name`, `index`, `selected`, `focused terminal` | `terminals` |
| `terminal` | `id`, `name`, `working directory` | — |

**Creation/layout:** `new surface configuration` · `new window [with configuration cfg]` ·
`new tab [in win] [with configuration cfg]` · `split <term> direction right|left|down|up [with configuration cfg]`
(returns the new terminal).

**Focus/lifecycle:** `focus <term>` · `activate window <w>` · `select tab <t>` · `close <term>` ·
`close tab <t>` · `close window <w>`.

**Input:** `input text "…" to <term>` (paste-style) · `send key "enter" to <term>` ·
`send mouse button left button to <term>` · `send mouse position x 240 y 120 to <term>` ·
`send mouse scroll x 0 y -8 precision true to <term>` ·
`perform action "toggle_fullscreen" on <term>`.

For `send key` / `send mouse button`, `action` is `press` or `release` and `modifiers` is a
comma-separated string of `shift`, `control`, `option`, `command`. `perform action` takes any keybind
action name ([keybinds.md](keybinds.md)).

**Surface configuration record fields:** `font size`, `initial working directory`, `command`,
`initial input`, `wait after command`, `environment variables` (a list of `"KEY=VALUE"` strings).

```applescript
tell application "Ghostty"
    set cfg to new surface configuration
    set initial working directory of cfg to POSIX path of (path to home folder) & "Projects/dotfiles"
    set font size of cfg to 13
    set environment variables of cfg to {"EDITOR=micro"}

    set win to new window with configuration cfg
    set editor to terminal 1 of selected tab of win
    set logs to split editor direction down with configuration cfg

    input text "git status -sb" to editor
    send key "enter" to editor
    focus editor
end tell
```

Useful idioms: `focused terminal of selected tab of front window` for the active surface, and
`every terminal whose working directory contains "dotfiles"` to find one by cwd.

---

## 7. macOS specifics

**Login shells.** ⚠ macOS starts **every** terminal shell as a login shell, and Ghostty follows that
convention (as Terminal.app does). The macOS GUI login never runs `.zprofile`, so a terminal that
didn't run it would produce broken shells. Because the shell is both login *and* interactive, both
`.zprofile` and `.zshrc` run for every new terminal — but a shell launched *inside* a terminal is
interactive-only and loses everything set in `.zprofile`. **Put shell setup in `.zshrc`**, matching
Linux practice. (Bash is the exception: it reads `.bashrc` only when interactive **and** non-login,
which is why so much macOS bash setup historically ended up in `.profile`.)

**Tiling window managers.** ⚠ Ghostty's tabs may render as separate windows under Yabai or Aerospace.
macOS native tabs *are* separate windows in the window-manager API, so this cannot be fixed from
Ghostty's side. A custom tabbing implementation is a longer-term goal. Workarounds:

```toml
# Aerospace — try "layout floating" if tiling still splits tabs
[[on-window-detected]]
if.app-id = "com.mitchellh.ghostty"
run = ["layout tiling"]
```

```sh
# Yabai
yabai -m signal --add app='^Ghostty$' event=window_created   action='yabai -m space --layout bsp'
yabai -m signal --add app='^Ghostty$' event=window_destroyed action='yabai -m space --layout bsp'
```

**Secure keyboard entry.** Auto-enabled on detected password prompts (`macos-auto-secure-input`),
manually via `Ghostty > Secure Keyboard Entry` or `toggle_secure_input`. An animated lock appears
top-right while active. ⚠ Detection is heuristic and does **not** work over SSH. ⚠ `toggle_secure_input`
is application-wide and stays on until untoggled or Ghostty quits.

---

## 8. Screen tearing / flicker in TUI programs

Not usually a Ghostty bug. Ghostty renders **faster than some programs update their cells**, so a
program that erases and repaints large regions tears. Known-affected: Claude Code, Docker CLI, Ollama,
Grok.

The fix belongs upstream: implement the
[Synchronized Output](https://github.com/contour-terminal/vt-extensions/blob/main/synchronized-output.md)
protocol (DEC mode 2026 — Ghostty advertises it as terminfo `Sync`) to tell the terminal when a frame
is complete. Best practice alongside it: update only the cells that changed — reposition with CUP and
clear the remainder with EL, rather than erasing whole rows or the screen. See
[vt-sequences.md](vt-sequences.md).
