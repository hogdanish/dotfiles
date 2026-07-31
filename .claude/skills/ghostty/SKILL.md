---
name: ghostty
description: The Ghostty terminal emulator (1.3.2-main, channel tip) on this machine — the complete configuration option reference (206 keys), the keybind system (triggers, global/all/unconsumed/performable prefixes, sequences, chains, key tables, all 85 actions), the ghostty CLI (+show-config, +validate-config, +explain-config, +list-*, +ssh), shell integration and its fish specifics, xterm-ghostty terminfo and SSH terminfo propagation, the 592-theme system and theme authoring, AppleScript, custom shaders, and the VT/control-sequence API (OSC 133 prompt marking, OSC 7 cwd, OSC 52 clipboard, synchronized output). Covers the live config at ~/.config/ghostty/config.ghostty and the laramie theme.
when_to_use: Load before reading or editing anything under ~/.config/ghostty (config.ghostty, themes/), before answering any question about terminal appearance, fonts, ligatures, padding, transparency/blur, cursor, splits, tabs, the quick terminal, keybindings, clipboard/OSC 52, scrollback, or the ghostty CLI — and whenever "terminal", "Ghostty", "terminal config", "terminal colours/theme", "terminal keybind", or "terminal window" is in play. Also for terminfo/$TERM/xterm-ghostty problems, TUI flicker or tearing, prompt marking, cwd inheritance, and terminal-side causes of shell startup errors. Boundary — this owns Ghostty and the terminal itself; fish syntax and ~/.config/fish belong to the `fish` skill (the ghostty↔fish seam is documented here), git-delta colours to git, and credential handling to `auth`.
---

# Ghostty

The terminal emulator on this machine. **Ghostty 1.3.2-main-+6e21f41c0**, channel `tip` (pre-release,
auto-updating), installed at `/Applications/Ghostty.app`, renderer Metal, font engine CoreText.

⚠ **`tip` moves fast.** Options and actions appear between releases, and several documented features
(`ghostty +ssh`, `window-padding-balance = equal`, `command-palette-entry = clear`) are marked
"available since 1.4.0" — i.e. tip-only. Never assert an option exists from memory; confirm with
`ghostty +explain-config <key>`, and run `scripts/ghostty-audit.sh` after any upgrade.

## The live setup

| | |
| --- | --- |
| Config | `~/.config/ghostty/config.ghostty` — **edited in place**, this repo holds no mirror |
| Theme | `~/.config/ghostty/themes/laramie` — user-authored, not a built-in |
| Shell | `command = /opt/homebrew/bin/fish --login --interactive`, `shell-integration = fish` |
| Look | `theme = laramie`, `background-opacity = 0.92`, `background-blur = macos-glass-regular`, `alpha-blending = linear-corrected`, `window-colorspace = display-p3`, `minimum-contrast = 1.1`, `macos-titlebar-style = transparent` |
| Font | CommitMono Nerd Font Mono with `ss01`–`ss04` + `cv02` |
| Updates | `auto-update = download`, `auto-update-channel = tip` |

⚠ The file is `config.ghostty`, **not** `config` — the name changed in 1.2.3. Both are still read, and
so are two more paths under `~/Library/Application Support/com.mitchellh.ghostty/` which load **after**
the XDG ones and would silently win. One of those (`config.ghostty`) exists and is empty; leave it that
way.

⚠ Ghostty is why `/bin/zsh` is still the login shell — it launches fish explicitly. Changing `command`
changes which shell every new surface gets.

## Five things that are counter-intuitive

1. **`theme` and `config-file` load at opposite ends.** A theme loads *before* your config (your config
   wins); `config-file` is processed at the *end* of the enclosing file (the included file wins), no
   matter where the directive appears in it.
2. **A theme can set any option, not just colours** — treat an untrusted theme as untrusted code.
3. **Omitted list features keep their defaults.** `shell-integration-features = cursor,sudo,title`
   does *not* disable `path`; only `no-path` does. Same for `bell-features`, `font-shaping-break`,
   `scroll-to-bottom`, `app-notifications`, `freetype-load-flags`.
4. **Not everything reloads.** `background-opacity`, `quick-terminal-position` and
   `auto-update-channel` need a full restart on macOS; many options apply to new surfaces only.
   Per-option notes are in [configuration.md](references/configuration.md).
5. **Config errors are never fatal.** A bad key logs, shows an error window, and falls back to its
   default — so a typo looks like "the setting did nothing". Run `+validate-config`.

## The Ghostty ↔ fish seam

Ghostty auto-injects shell integration by prepending its own directory to `XDG_DATA_DIRS`; the script's
first act is to **remove that entry again**, so its absence from the environment is not evidence that
injection failed. `~/.config/fish/conf.d/_shell.fish` also sources the script manually, guarded by
`test -r` since 2026-07-28.

⚠ The manual source is **not** redundant, but not for the obvious reason. `$__fish_vendor_confdirs` is
computed before any `conf.d` file runs, so the strip does not prevent fish sourcing the vendor copy —
the top-level shell loads the script **twice** (harmless; it is re-entrant). What the manual source
actually buys is **nested** fish shells, which inherit the stripped `XDG_DATA_DIRS` and would otherwise
get nothing. Verified both ways. Mechanics, what the script does, and the OSC marks it emits:
[integration.md](references/integration.md).

Editing the fish side of this is the **`fish` skill's** job; this skill owns what Ghostty injects and why.

## Verifying a change

```sh
ghostty +validate-config                                  # live config; exit 1 + file:line:key on error
ghostty +validate-config --config-file=<path> --config-default-files=false   # one file, isolated
ghostty +show-config                                      # fully resolved, merged
ghostty +explain-config <key|action>                      # authoritative docs for one name
.claude/skills/ghostty/scripts/ghostty-audit.sh           # config + skill-vs-binary drift
```

⚠ `+validate-config` silently ignores a nonexistent `--config-file` path, so a typo'd path looks like
success. Reload with `cmd+r`; a few options need a full quit.

## Reference material

Read the row that matches the task, in full — these are floors, not menus.

| Task | Read |
| --- | --- |
| Any option, syntax, or file-loading question | `configuration.md` |
| A keybind, action, leader key, or modal input | `keybinds.md` |
| CLI, shell integration, terminfo, SSH, themes, AppleScript, macOS quirks | `integration.md` |
| Escape sequences, prompt marking, TUI rendering, capability detection | `vt-sequences.md` |

- [configuration.md](references/configuration.md) (856) — **the complete option reference.** File
  format, the four load paths, `config-file` vs `theme` precedence, validation, then all **206** keys
  grouped by domain with defaults, valid values, units, clamps, platform limits, reload behaviour and
  ⚠ warnings. Also the two keys absent from `+show-config --default` (`quick-terminal-size`, `link`).
- [keybinds.md](references/keybinds.md) (359) — trigger syntax (codepoint vs W3C physical code vs
  `catch_all`), the four prefixes, key sequences, chained actions, key tables, all **85** actions with
  their parameters, and the 93 default macOS binds.
- [integration.md](references/integration.md) (439) — the `ghostty` CLI and bundled resources, env
  vars Ghostty sets, logging, shell integration (including exactly what the fish script does),
  `xterm-ghostty` terminfo, sudo and SSH terminfo propagation, `+ssh`/`+ssh-cache`, themes and theme
  authoring, the AppleScript object model and commands, macOS login shells, tiling-WM tab behaviour,
  secure input, and the screen-tearing explanation.
- [vt-sequences.md](references/vt-sequences.md) (206) — control-sequence anatomy, the documented C0 /
  ESC / CSI / OSC catalogue, **OSC 133** prompt marking and **OSC 7** cwd (the contract behind
  `jump_to_prompt`, cwd inheritance and `cursor-click-to-move`), terminal modes, the Kitty
  graphics/keyboard/colour protocols, and synchronized output.

## Where the authoritative data lives

Everything here was generated from the installed build, not recalled. The same sources regenerate it:

```sh
ghostty +show-config --default --docs      # every option + full doc comments
ghostty +list-actions --docs               # every keybind action + docs
ghostty +list-keybinds --default           # the shipped keybinds
ghostty +list-themes --plain               # 592 built-in themes
/Applications/Ghostty.app/Contents/Resources/ghostty/doc/ghostty.5.md   # config + actions, markdown
/Applications/Ghostty.app/Contents/Resources/ghostty/doc/ghostty.1.md   # CLI reference, markdown
```

The bundled `doc/*.md` are version-matched to the installed build and are the fastest offline source —
prefer them over ghostty.org, which documents the latest tip and may be ahead of or behind this build.

## Maintenance

1. **After every Ghostty upgrade**, run `scripts/ghostty-audit.sh`. It validates the live config and
   diffs the binary's option and action lists against these references, failing on drift in either
   direction. New keys go into `configuration.md` in the same change.
2. **Changing `~/.config/ghostty/` updates this skill in the same change** — the live-setup table
   above, and the `laramie` palette wherever it is duplicated.
3. **Colour values are the `laramie` skill's, not this one's.** `~/.config/ghostty/themes/laramie` is
   the **ANSI-16 contract** (`laramie` skill → `references/spec.md` §4) and is the most leveraged file
   in the theme: every tool that takes ANSI colour *names* inherits it, including ones laramie never
   configures. Load that skill before changing a hex here, and never hex-code a tool that could use a
   name instead.
   ⚠ **`window-colorspace = display-p3` means Ghostty interprets the theme's sRGB hexes as P3**, so
   everything renders more saturated than the spec's figures state. The spec's contrast and ΔE numbers
   are therefore *nominal*. Deliberate — the palette was signed off as rendered this way.
4. **Verify before writing anything down.** A claim about a `tip` build is worth nothing unless
   `+explain-config`, `+show-config` or a real run produced it. Several ⚠ entries in these references
   exist because the obvious assumption was wrong.

---
*Source of truth for Ghostty in this repo — update it in the same change as `~/.config/ghostty`.
The fish side of the shell-integration seam belongs to the `fish` skill.*
