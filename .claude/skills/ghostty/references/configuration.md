# Ghostty configuration — format, loading, and the complete option reference

Verified against **Ghostty 1.3.2-main** (`+show-config --default --docs`, 205 unique keys). Regenerate
the raw source of this file with `ghostty +show-config --default --docs`; explain one key with
`ghostty +explain-config <key>`.

Entries are `**key** — default` followed by the condensed semantics. Enum values, units, clamps,
platform limits, reload behaviour and ⚠ warnings are preserved; only prose padding was cut.

---

## 1. File format

`key = value`. Whitespace around `=` is irrelevant. Comments are `#` **on their own line only** —
there are no trailing comments. Blank lines ignored.

```ini
background = 282c34
font-family = "JetBrains Mono"   # quoting optional, same as unquoted
keybind = ctrl+d=new_split:right
font-family =                    # empty value = reset to default
```

- **Keys are case-sensitive** and always lowercase.
- Values may be quoted or unquoted; quotes matter only for embedded spaces/specials.
- **Every key is also a CLI flag**: `ghostty --font-size=12 --font-family="Fira Code"`.
- Repeatable keys (`keybind`, `palette`, `font-feature`, `env`, `config-file`, `custom-shader`,
  `command-palette-entry`, `font-codepoint-map`, `clipboard-codepoint-map`, `key-remap`,
  `gtk-custom-css`, `input`) **append**. Set the key to `""` first to clear the list.
- Setting a repeatable key as a **CLI argument automatically clears** values from config files, so
  `--font-family=""` is unnecessary on the CLI.

## 2. Where the config is loaded from

The file is named **`config.ghostty`** (it was `config` before 1.2.3; both are still read). Load order
— later files override earlier ones:

1. `$XDG_CONFIG_HOME/ghostty/config.ghostty`
2. `$XDG_CONFIG_HOME/ghostty/config`
3. *(macOS)* `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty`
4. *(macOS)* `~/Library/Application Support/com.mitchellh.ghostty/config`

`$XDG_CONFIG_HOME` defaults to `~/.config`. On Windows, `$LOCALAPPDATA` is searched when
`XDG_CONFIG_HOME` is unset. ⚠ **All macOS-specific paths load *after* all XDG paths** — an empty
`~/Library/Application Support/com.mitchellh.ghostty/config.ghostty` is harmless, but a populated one
silently wins over `~/.config`.

Missing config is not an error; defaults are used. Config errors are **non-fatal**: the bad key falls
back to its default, the error is logged, and an error window is shown.

### `config-file` vs `theme`

Both pull in another file, but at opposite ends of the precedence chain:

| | Loaded | Result |
| --- | --- | --- |
| `theme = X` | **before** your config | your config **overrides** the theme |
| `config-file = X` | **after** the entire enclosing file | the included file **overrides** your config |

⚠ This is the single subtlest rule in Ghostty config. Given `config-file = foo` followed by `a = 1`,
if `foo` sets `a = 2` the final value is **2** — `config-file` directives are processed at the *end*
of the current file regardless of where they appear in it.

Relative `config-file` paths resolve against the file containing the directive (against `$PWD` for CLI
args). A `?` prefix makes the file optional: `config-file = ?optional/machine-local`. To load a path
that literally starts with `?`, quote the whole value. Cycles are detected, logged, and ignored.

## 3. Reloading

Default binds: `cmd+shift+,` (macOS) / `ctrl+shift+,` (Linux), or the `reload_config` action.
Not everything reloads — per-option notes below say "new terminals only", "requires restart", etc.

## 4. Validating

```sh
ghostty +validate-config --config-file=<path>          # exit 1 + "file:line:key: message" on error
ghostty +validate-config                               # validate the live config
ghostty +show-config                                   # the fully resolved, merged config
ghostty +explain-config <key|action>                   # docs for one key or keybind action
```

⚠ `+validate-config --config-file=X` also loads the default files; add `--config-default-files=false`
to validate a file in isolation. ⚠ `+validate-config` **only reports errors when given a file that has
them** — a nonexistent `--config-file` path is silently ignored, so a typo'd path looks like success.

---

# Option reference

## Font and text rendering

**`font-family`** — *(embedded JetBrains Mono)*
Repeat to add **fallback** fonts for codepoints the primary lacks. macOS always uses Apple Color Emoji
and Linux Noto Emoji unless a listed family provides emoji glyphs. List with `ghostty +list-fonts`.

**`font-family-bold`** / **`font-family-italic`** / **`font-family-bold-italic`** — *(unset)*
Explicit per-style families. Unset = search `font-family` for stylistic variants, falling back to the
regular style rather than to a different family. If the named family is missing, `font-family` is used.

**`font-style`** / **`font-style-bold`** / **`font-style-italic`** / **`font-style-bold-italic`** — `default`
Pick a style by the *font's advertised style string* (e.g. `Heavy` for "Iosevka Heavy"). Literal
`false` **disables** that style — the regular style is substituted when a program requests it. Only
meaningful if the corresponding `font-family` is set, except when disabling.

**`font-synthetic-style`** — `bold,italic,bold-italic`
Synthesize missing styles (bold = outline stroke, italic = slant). `true`/`false` for all;
`no-bold`, `no-italic`, `no-bold-italic` individually, comma-combinable.
⚠ Disabling `bold` and `italic` does **not** disable `bold-italic` — disable it explicitly. It cannot
be partially disabled.

**`font-feature`** — *(unset)*
OpenType features, repeatable or comma-separated. Enable: `feat`, `+feat`, `feat on`, `feat=1`.
Disable: `-feat`, `feat off`, `feat=0`. Value: `feat=2`. Names may be quoted (CSS
`font-feature-settings`-compatible). Invalid settings are silently ignored. Applies to *all* fonts —
per-face targeting is not yet possible. Disable programming ligatures with `-calt`; kill most
ligatures with `-calt,-liga,-dlig`.

**`font-size`** — `13`
Points, non-integer allowed (13.5pt @ 2px/pt = 27px; nearest integer pixel size is chosen). On reload,
terminals that have manually adjusted their size keep it. GTK additionally applies display-wide and
text scaling factors.

**`font-variation`** / **`font-variation-bold`** / **`font-variation-italic`** / **`font-variation-bold-italic`** — *(unset)*
Variable-font axes as `id=value`; `id` is a 4-char tag. Common: `wght`, `slnt`, `ital`, `opsz`,
`wdth`, `GRAD`. Out-of-range values are ignored, **not clamped**.

**`font-codepoint-map`** — *(unset)*
Force codepoints to a family: `U+ABCD=fontname`, ranges `U+ABCD-U+DEFG=fontname`, multiple ranges
comma-separated before the `=`. Repeatable. Runtime changes affect **new terminals only**.

**`clipboard-codepoint-map`** — *(unset)*
Rewrite codepoints **when copying** to the clipboard. `U+1234=U+ABCD`, `U+1234=replacement_text`, or a
range. Later entries win on overlap. Repeatable. Does not apply to URL copying. Useful for degrading
box-drawing to ASCII: `U+2500=U+002D`, `U+2502=U+007C`.

**`font-thicken`** — `false` · macOS only
Draw glyphs with a thicker stroke.

**`font-thicken-strength`** — `255` · macOS only
`0`–`255`. `0` is the *lightest* thickening, not none. No effect unless `font-thicken = true`.

**`font-shaping-break`** — `cursor`
Where to split shaping runs (a broken run cannot form a ligature across the break). Only value:
`cursor` — break under the cursor so editing shows individual characters. `no-`-prefixable.
*(1.2.0)*

**`grapheme-width-method`** — `unicode`
`unicode` (correct widths) or `legacy` (wcswidth-ish; maximizes compatibility with programs that
mis-measure skin-tone emoji, CJK, etc. and would otherwise desync the cursor). Terminal mode 2027
forces `unicode` while set. Runtime change affects **new terminals only**.

**`freetype-load-flags`** — `hinting,no-force-autohint,no-monochrome,autohint,light` · Linux/FreeType only
Flags: `hinting`, `force-autohint`, `monochrome` (1-bit, no AA), `autohint`, `light` (GTK-typical,
no effect with `monochrome`). `no-` prefix disables; `true`/`false` sets all. macOS uses CoreText and
ignores this.

**`alpha-blending`** — `native` (macOS) / `linear-corrected` (elsewhere)
Colour space for alpha blending; also the space custom shaders receive colours in.
`native` (Display P3 on macOS, sRGB on Linux) · `linear` (gamma-correct; removes dark fringing on
e.g. red-on-green but makes dark text thin and light text thick) · `linear-corrected` (linear plus a
correction that looks like `native` without the fringing). *(1.1.0)*

**`bold-color`** — *(unset)*
Colour for bold text. A colour value (as `background`), or `bright` to use the bright palette entry
matching the text colour. Replaces the deprecated `bold-is-bright`. *(1.2.0)*

**`faint-opacity`** — `0.5`
Opacity of faint (SGR 2) text, `0`–`1`, clamped. *(1.2.0)*

**`minimum-contrast`** — `1`
WCAG 2.0 contrast ratio floor, `1`–`21`. `1.1` prevents invisible same-colour text; `3`+ enforces
readability at the cost of pushing text toward black/white. Does not apply to emoji or images.

### Metric adjustments

All accept an integer (`1`, `-1`) or a percentage (`20%`, `-15%`), interpreted as a **delta**, not an
absolute — `1` means "increase by 1". ⚠ Nearly unvalidated: `-100%` can render the terminal unusable.
Many `*-thickness` values clamp at 1px, which can make an adjustment look ignored.

**`adjust-cell-width`**, **`adjust-cell-height`** — cell box. `adjust-cell-height` additionally centres
the font vertically, keeps the cursor at font size (tune with `adjust-cursor-height`), and scales
powerline glyphs so status lines stay aligned.
**`adjust-font-baseline`** — from the cell bottom; increase moves the baseline **up**.
**`adjust-underline-position`** / **`adjust-underline-thickness`** — position measured from the cell
top; increase moves **down**.
**`adjust-strikethrough-position`** / **`adjust-strikethrough-thickness`** — same convention.
**`adjust-overline-position`** / **`adjust-overline-thickness`** — same convention.
**`adjust-cursor-thickness`** — bar and outlined-rect cursors.
**`adjust-cursor-height`** — all cursor types (bar, rect, outlined rect).
**`adjust-box-thickness`** — box-drawing characters.
**`adjust-icon-height`** — max height for nerd-font icons. Effect varies per icon depending on whether
its default size is height-constrained. Powerline/box-drawing glyphs are unaffected. *(1.2.0)*

## Colours, theme and background

**`theme`** — *(unset)*
A built-in theme name, a custom theme name, or an **absolute path**. Split light/dark:
`theme = light:Rose Pine Dawn,dark:Rose Pine` — whitespace trimmed, order irrelevant, **both required**
in this form; selection follows the desktop appearance.
Name lookup searches, in order: `$XDG_CONFIG_HOME/ghostty/themes/` then
`$PREFIX/share/ghostty/themes/` (macOS: `Ghostty.app/Contents/Resources/ghostty/themes/`, 592 built-in
themes from iterm2-color-schemes). Case-sensitive on case-sensitive filesystems; path separators are an
error unless absolute. An absolute path that doesn't exist is an error and **no** directory search
follows.
A theme is just a config file, loaded **before** your config, so your config wins (opposite of
`config-file`). ⚠ A theme can set *any* option — never use one from an untrusted source. `theme` and
`config-file` inside a theme file are **silently ignored**.
Known bug: on macOS the titlebar-tabs style doesn't update on light/dark switch.

**`background`** — `#282c34` · **`foreground`** — `#ffffff`
`#RRGGBB`, `RRGGBB`, or a named X11 colour.

**`palette`** — *xterm 256-colour table*
`N=COLOR` where `N` is `0`–`255`. Index accepts `0b`/`0o`/`0x` prefixes (decimal otherwise). Repeatable.
For most themes only `0`–`15` matter.

**`palette-generate`** — `false` *(1.3.0)*
Derive indices 16–255 (the 6×6×6 cube and 24-step grey ramp) from the base 16 by interpolation.
Explicitly-set `palette` entries are never overwritten. Off by default because legacy programs hardcode
the xterm 256-colour values.

**`palette-harmonious`** — `false` *(1.3.0)*
Reverse the order of generated palette colours so palette-based apps read well in both light and dark.
No effect unless `palette-generate` is on. Off by default because programs assume 16–231 run
dark→light.

**`selection-foreground`** / **`selection-background`** — *(unset)*
Unset = inverted window fg/bg (not the cell's). Accepts a colour, or since 1.2.0 `cell-foreground` /
`cell-background`.

**`cursor-color`** — *(unset)* · **`cursor-text`** — *(unset)*
Colour, or `cell-foreground` / `cell-background` *(1.2.0)*.

**`cursor-opacity`** — `1`
`0`–`1`, clamped. ⚠ Values around `0.3` can make the cursor effectively invisible.

**`search-foreground`** — `#000000` · **`search-background`** — `#ffe082`
Non-focused (candidate) search matches. Also accepts `cell-foreground` / `cell-background`.

**`search-selected-foreground`** — `#000000` · **`search-selected-background`** — `#f2a57e`
The currently focused search match.

**`split-divider-color`** — *(unset)* *(1.1.0)*
**`unfocused-split-fill`** — *(unset, defaults to `background`)*
Colour of the translucent rectangle drawn over unfocused splits.
**`unfocused-split-opacity`** — `0.7`
Clamped to `0.15`–`1`. `1` disables split dimming.

**`window-titlebar-background`** / **`window-titlebar-foreground`** — *(unset)* · GTK only
Only applies when `window-theme = ghostty`.

**`background-opacity`** — `1`
`0`–`1`, clamped. ⚠ macOS: disabled in native fullscreen (the grey backdrop shows widgets through);
**changing it requires a full Ghostty restart**.

**`background-opacity-cells`** — `false` *(1.2.0)*
Apply `background-opacity` to cells with an explicit background colour too. Without this, apps like
Neovim and tmux that repaint the background appear fully opaque (by design).

**`background-blur`** — `false`
A nonnegative integer blur intensity, `false` (= 0), or `true` (= 20). Higher intensities can cause
rendering and performance problems. macOS 26+ also accepts `macos-glass-regular` and
`macos-glass-clear` for the native glass effects (these imply `true` on other platforms).
Linux ignores the intensity: Wayland uses `ext-background-effect-v1` (compositor-dependent), X11 works
only under KWin/KDE Plasma.

**`background-image`** — *(unset)* *(1.2.0)*
Path to a PNG or JPEG. Currently **per-terminal, not per-window** — heavy split users get it repeated.
⚠ Duplicated in VRAM per terminal; large images can balloon VRAM usage.
**`background-image-opacity`** — `1` — relative to `background-opacity` (`0.5` bg-opacity × `1.5` here = `0.75`).
**`background-image-position`** — `center` — `top-|center-|bottom-` × `left|center|right`.
**`background-image-fit`** — `contain` — `contain` · `cover` · `stretch` · `none`.
**`background-image-repeat`** — `false` — tile to fill leftover space.

**`osc-color-report-format`** — `16-bit`
Reply format for OSC 4/10/11 colour queries: `none` (no reply), `8-bit` (`rr/gg/bb`), `16-bit`
(`rrrr/gggg/bbbb`). Some legacy apps need `8-bit`.

## Cursor, mouse, selection and links

**`cursor-style`** — `block`
`block` · `bar` · `underline` · `block_hollow`. Only the *default* — programs override via `DECSCUSR`
(`CSI q`). ⚠ Shell integration forces a bar at the prompt regardless; suppress with
`shell-integration-features = no-cursor`.

**`cursor-style-blink`** — *(unset)*
` ` (blank) · `true` · `false`. Unset ≠ `true`: while unset, DEC mode 12 (AT&T blink) is honoured. Any
explicit value makes mode 12 ignored, but `DECSCUSR` is still respected.

**`cursor-click-to-move`** — `true`
Click in the prompt to move the cursor. Requires OSC 133 prompt marking — native in Fish 4 and
Nu 0.111+, otherwise via shell integration. Implemented as synthetic arrow keys or a direct click
event depending on the shell, so edge cases can surprise.

**`mouse-hide-while-typing`** — `false`
Reappears on mouse use; macOS also reveals it when a window/tab/split is created.

**`mouse-shift-capture`** — `false`
Whether programs see shift+click. `false` = shift extends the selection, program may override via
`XTSHIFTESCAPE`; `true` = shift is sent, program may still override; `never`/`always` = same but the
program **cannot** override. Use `never` to always keep shift for selection.

**`mouse-reporting`** — `true`
`false` blocks mouse events from reaching programs entirely. Toggle at runtime with
`toggle_mouse_reporting`.

**`mouse-scroll-multiplier`** — `precision:1,discrete:3`
Bare value applies to all devices; `precision:` / `discrete:` prefixes target one (comma-combinable;
prefixes added in 1.2.1). Clamped to `[0.01, 10000]`.

**`scroll-to-bottom`** — `keystroke,no-output`
When to snap to the bottom. `keystroke` = on any key that sends data to the pty; `output` = on new
output. `no-` prefixable.

**`focus-follows-mouse`** — `false`
Hovering a split focuses it — within the focused window only; it never raises an unfocused window.

**`copy-on-select`** — `true`
`true` prefers the selection clipboard; `clipboard` copies to both selection and system clipboards.
Middle-click paste stays enabled even at `false`, and reads from whichever clipboard this setting
implies.

**`right-click-action`** — `context-menu`
`context-menu` · `paste` · `copy` · `copy-or-paste` · `ignore`.

**`middle-click-action`** — `primary-paste`
`primary-paste` · `ignore`.

**`click-repeat-interval`** — `0`
Milliseconds for double/triple-click detection. `0` = platform default (macOS: system setting;
elsewhere 500 ms).

**`selection-clear-on-typing`** — `true` *(1.2.0)*
"Typing" = any non-modifier keypress that sends data to the program; also cleared when preedit/IME
composition starts. At `false`, clear manually with a single click or `escape`.

**`selection-clear-on-copy`** — `false`
Clear the selection after `copy_to_clipboard`. Never fires for `copy-on-select` copies.

**`selection-word-chars`** — ``\t '"│`|:;,()[]{}<>$``  *(1.3.0)*
Characters that **bound** words for double-click selection (the inverse of zsh's `WORDCHARS`). Each
character is a boundary; multi-byte UTF-8 is fine but only single codepoints (no emoji sequences).
`U+0000` is always a boundary.

**`link`** — ⚠ **not currently settable.** Regex→action link matching exists internally but has no
working config surface as of 1.3.2.

**`link-url`** — `true`
The built-in URL matcher (ctrl-hover on Linux, cmd-hover on macOS; opens with the system opener). It is
always the lowest-priority link.

**`link-previews`** — `true` *(1.2.0)*
`true` · `false` · `osc8` (preview only OSC 8 hyperlinks, where the text can differ from the target).

## Clipboard

**`clipboard-read`** — `ask` · **`clipboard-write`** — `allow`
Whether programs may use OSC 52. `ask` · `allow` · `deny`.

**`clipboard-trim-trailing-spaces`** — `true`
Trims trailing whitespace on copy (not on OSC 52 writes). Fully blank lines are always trimmed.

**`clipboard-paste-protection`** — `true`
Confirm before pasting text that looks unsafe (e.g. embedded newlines) — guards against copy/paste
attacks.

**`clipboard-paste-bracketed-safe`** — `true`
Treat pastes made while the program has bracketed-paste mode on as safe.

## Command, environment and process

**`command`** — *(unset)*
The shell/program for **all** surfaces. Non-absolute values are resolved on `PATH`. Default lookup:
`$SHELL`, then the `passwd` entry. With arguments, it is run through `/bin/sh -c` for expansion.
Prefix `direct:` to skip the `/bin/sh` roundtrip (no globs, `~`, or quoted args) or `shell:` to force
the wrapper *(both 1.2.0)*.

**`initial-command`** — *(unset)*
Same, but only for the very first surface. Cannot be re-triggered afterwards.
`ghostty -e <cmd> <args…>` sets this and additionally forces: no shell expansion,
`gtk-single-instance=false`, `quit-after-last-window-closed=true` (with the delay unset), and
`shell-integration=detect` (unless `none`) so integration isn't force-injected into a non-shell.

**`env`** — *(unset)* *(1.2.0)*
`env = KEY=VALUE`, repeatable. `env =` resets the whole map; `env = KEY=` removes one key; repeating a
key overwrites. These **override** Ghostty's own injections (including `GHOSTTY_RESOURCES_DIR`). Not
passed to helpers Ghostty runs itself (`open`, `xdg-open`).

**`input`** — *(unset)* *(1.2.0)*
Data written to the pty at startup, before any other input. `raw:<string>` (Zig string-literal escapes)
or `path:<file>` (finite files only — ⚠ never `/dev/stdin` or `/dev/urandom`, they block startup
forever; 10 MB cap). A bare value is treated as `raw:`. Repeatable, concatenated with no separator.
If any source is missing, **none** of the input is sent — and paths aren't checked until terminal
startup, so a bad path won't show up in config validation. ⚠ Sent verbatim: control characters here
can execute programs in a shell. New terminals only.

**`wait-after-command`** — `false`
Keep the window open after the command exits, until a keypress. For scripts and debugging.

**`abnormal-command-exit-runtime`** — `250`
Milliseconds below which an exit is considered abnormal and an error is shown. Linux additionally
requires a nonzero exit code; macOS accepts any because of how `login` launches shells.

**`working-directory`** — *(unset; effectively `inherit`)*
An absolute path, a `~/`-prefixed path, `home`, or `inherit` (launching process's cwd). Overridden by
`window-inherit-working-directory` when a previous terminal exists in the process, so this mostly
affects the first window. Defaults to `home` when macOS detects launch from launchd/`open`, or when
GTK detects a desktop launcher.

**`term`** — `xterm-ghostty`
Sets `$TERM`. ⚠ The `xterm` prefix is load-bearing: vim keys `modifyOtherKeys` and other features off
that substring, and many programs sniff for "xterm" to assume capabilities.

**`enquiry-response`** — *(empty)*
String sent when the program emits `ENQ` (`0x05`).

**`notify-on-command-finish`** — `never` *(1.3.0)*
`never` · `unfocused` · `always`. Requires shell integration or a shell that emits OSC 133 command
marks. GTK has a context-menu item to enable it for a single command, overriding `never`/`unfocused`.

**`notify-on-command-finish-action`** — `bell,no-notify` *(1.3.0)*
`bell` and/or `notify`, `no-`-prefixable.

**`notify-on-command-finish-after`** — `5s` *(1.3.0)*
Minimum runtime before notifying. Duration syntax below.

> **Duration syntax** (used by `notify-on-command-finish-after`, `resize-overlay-duration`,
> `quit-after-last-window-closed-delay`, `undo-timeout`): number+unit pairs, summed, whitespace
> allowed — `1h30m`, `45s`. Units: `y` (365 d) · `d` · `h` · `m` · `s` · `ms` · `us`/`µs` · `ns`.
> Repeated units add (`1h1h` = `2h`; confusing, may be disallowed later). Max
> `584y 49w 23h 34m 33s 709ms 551µs 615ns`, clamped.

## Scrollback, search and images

**`scrollback-limit-bytes`** — `50000000` (50 MB)
Per **surface**, including the active screen; enough for the visible screen is always reserved. Memory
is allocated lazily. `unlimited` removes the byte cap. The limit measures **uncompressed logical** size
— compression never buys extra history. New surfaces only.

**`scrollback-limit-lines`** — `unlimited`
Excludes the active screen; soft-wrapped lines count individually. An estimate — trimming happens at
page granularity (a handful to a couple hundred lines), so the real count runs slightly high. Whichever
of the two limits is hit first wins. New surfaces only.

**`scrollback-compression`** — `true`
Compress idle, non-visible historical pages. Text typically compresses to 10–30% of page memory.
Decompression is transparent. ⚠ Reduces **physical/resident** memory only — virtual mappings are
retained, so RSS drops but VSZ does not. Recommended on.

**`scrollbar`** — `system`
`system` (respect OS scrollbar behaviour) · `never` (scrolling still works, just no widget).

**`image-storage-limit`** — `320000000` (320 MB)
Bytes for image protocol data (e.g. Kitty graphics) **per screen**; primary and alternate screens each
get this, so the per-surface total is double. Max 4 GiB. `0` disables all image protocols.

## Window, tabs and splits

**`maximize`** — `false` *(1.1.0)* — start every new window maximized.

**`fullscreen`** — `false`
`false` · `true` (native) · `non-native` · `non-native-visible-menu` · `non-native-padded-notch`
(the last three macOS-only; elsewhere they behave as `true`).
⚠ **Tabs do not work with non-native fullscreen** — it removes the titlebar, which macOS native tabs
require. ⚠ macOS native fullscreen also fails when `window-decoration = false`.

**`title`** — *(unset)*
Forces the title permanently and makes Ghostty **ignore title escape sequences** from programs. A
blank title needs `title = " "` (an empty value resets to default). On reload: setting it updates all
windows; unsetting it only takes effect at the next title-change sequence, which may mean restarting
Neovim etc.

**`window-padding-x`** — `2` · **`window-padding-y`** — `2`
Points (DPI-scaled). One value = both sides; `2,4` = left/right (or top/bottom) separately.
⚠ Too large and the grid is squished to nothing and the screen renders empty; a warning is logged. New
terminals only.

**`window-padding-balance`** — `false`
Distribute the leftover sub-cell space. `false` = the top-left cell hugs the edge · `true` = balance
but cap top padding, pushing excess to the bottom · `equal` = balance all sides with no cap *(1.4.0)*.
Applied last, after the other padding options.

**`window-padding-color`** — `background`
`background` · `extend` (use the nearest cell's background) · `extend-always` (skip the heuristics).
`extend` self-disables on primary-screen apps when the nearest row has default-background cells, is a
prompt row (needs shell integration), or contains a perfect-fit powerline glyph.

**`window-vsync`** — `true` · macOS only
⚠ Defaults on because out-of-sync rendering caused **kernel panics on macOS 14.4+** and problems with
DisplayLink-class hardware. `false` minimizes input latency with that risk. New terminals only.

**`window-inherit-working-directory`** — `true` · **`tab-inherit-working-directory`** — `true` ·
**`split-inherit-working-directory`** — `true`
Inherit the previously focused surface's cwd; falls back to `working-directory`. Requires shell
integration (OSC 7) to know the cwd.

**`window-inherit-font-size`** — `true`
New windows/tabs inherit the previously focused window's (possibly adjusted) font size rather than
`font-size`.

**`window-decoration`** — `auto`
`none` (⚠ also disables tabs on macOS) · `auto` · `client` *(1.1.0)* · `server` *(1.1.0; Linux/GTK,
X11 or Wayland with `org_kde_kwin_server_decoration`; falls back to client)*. `true` = `auto`,
`false` = `none`. Toggle at runtime with `toggle_window_decorations`.
macOS: to hide only the titlebar while keeping borders and rounded corners, use
`macos-titlebar-style = hidden` instead.

**`window-title-font-family`** — *(system default)* *(macOS 1.0.0, GTK 1.1.0)*
Need not be fixed-width.

**`window-subtitle`** — `false` · GTK only *(1.1.0)* — `false` · `working-directory`.

**`window-theme`** — `auto`
`auto` (from the terminal background colour; behaves as `system` when `theme` has separate light/dark)
· `system` · `light` · `dark` · `ghostty` (Linux only; uses configured bg/fg).
macOS: with `macos-titlebar-style` of `tabs` or `transparent`, terminal windows derive the theme from
background luminosity regardless; this setting still governs non-terminal windows.

**`window-colorspace`** — `srgb` · macOS only — `srgb` · `display-p3`. Affects configured colours and
direct-colour SGR sequences.

**`window-height`** — `0` · **`window-width`** — `0`
Initial size in **grid cells**; **both** must be set or both are ignored. Pixels are not supported.
Larger than the screen clamps to the screen (a way to get maximize-by-default). Minimum 10×4. Affects
only the initial size of new windows, never tabs/splits, and never resizes existing windows.
⚠ **BUG (GTK):** window decorations aren't accounted for, so the grid won't match exactly unless
decorations are disabled.

**`window-position-x`** / **`window-position-y`** — *(unset)* · macOS only
Pixels from the top-left of the primary monitor; **both** required. On macOS this is the visible screen
area, so a visible menu bar pushes the window down. Invalid positions clamp. GTK cannot set window
position (Wayland forbids it).

**`window-save-state`** — `default` · macOS only
`default` (system behaviour — macOS saves only on forced termination or when enabled system-wide) ·
`never` · `always`. Preserving working directories needs shell integration. ⚠ Changing this while
Ghostty isn't running has asymmetric effects: switching to `never` prevents the next restore;
switching to `default` still restores previously-saved state (macOS doesn't report whether the last
exit was forced); enabling it doesn't retroactively create state.

**`window-step-resize`** — `false` · macOS only — resize in whole cells rather than pixels.

**`window-new-tab-position`** — `current` — `current` (after the focused tab) · `end`.

**`window-show-tab-bar`** — `auto` · Linux/GTK only
`always` *(1.2.0)* · `auto` (shown at ≥2 tabs) · `never` (tabs reachable only via the overview or
keybinds).

**`split-preserve-zoom`** — `no-navigation` *(1.3.0)*
Normally any focus/layout change unzooms a zoomed split. `navigation` instead moves the zoom to the
newly focused split. `no-` prefixable.

**`resize-overlay`** — `after-first` — `always` · `never` · `after-first` (not on creation, but on
later resizes).
**`resize-overlay-position`** — `center` — `center` or `top-|bottom-` × `left|center|right`.
**`resize-overlay-duration`** — `750ms` — duration syntax above.

**`class`** — `com.mitchellh.ghostty` · GTK only
X11 `WM_CLASS` class, Wayland app ID, and the DBus bus name. Must satisfy GTK's application-ID rules.
⚠ Changing it creates separate instances under `gtk-single-instance=true`, and can break `.desktop`
launching, DBus activation, and systemd user services, which all expect the default.

**`x11-instance-name`** — `ghostty` · X11 only — the instance field of `WM_CLASS`.

## Application lifecycle and UI

**`config-file`** — *(unset)* — see §2. Repeatable; `?` prefix = optional; relative to the including
file (to `$PWD` for CLI args); cycles logged and ignored. ⚠ Processed at the **end** of the enclosing
file, so it overrides that file.

**`config-default-files`** — `true` · **CLI-only**
`false` skips the default config paths. Setting it in a config file is silently a no-op (not an error).

**`confirm-close-surface`** — `true`
`true` · `false` · `always` (confirm even when shell integration reports no running process).

**`quit-after-last-window-closed`** — `false` on macOS, `true` on Linux
**`quit-after-last-window-closed-delay`** — *(unset)* · Linux only
Minimum `1s`, clamped. Only meaningful when the above is `true`.

**`initial-window`** — `true` · macOS + Linux
`false` opens no window at startup. ⚠ Combined with `quit-after-last-window-closed=true` and a delay,
Ghostty will quit after the delay if no window is ever created.

**`undo-timeout`** — `5s` · macOS only *(1.2.0)*
How long `undo`/`redo` stay available, **per operation** (new operations don't reset older ones). `0`
disables undo. ⚠ A huge timeout grows the undo stack unbounded, keeps closed surfaces alive, and stops
sessions from ever quitting.

**`command-palette-entry`** — *(≈90 built-in entries)* *(1.2.0)*
`title:…, action:…, description:…` — fields prefixed by name and a colon, whitespace between fields
ignored. Action syntax is identical to keybind actions. Quote a value to use a Zig string literal
(needed for embedded commas or leading/trailing whitespace); multiline literals are unsupported. Field
*names* cannot be quoted. `command-palette-entry = clear` removes **all** entries including defaults
*(1.4.0)*; an empty value restores the defaults.

```ini
command-palette-entry = title:Reset Font Style, action:csi:0m
command-palette-entry = title:Focus Split: Right,description:"Focus the split to the right, if it exists.",action:goto_split:right
```

**`app-notifications`** — `clipboard-copy,config-reload` · GTK only *(1.1.0)*
In-app toasts. `no-` prefixable; `true`/`false` for all.

**`desktop-notifications`** — `true`
Allow programs to raise desktop notifications via OSC 9 / OSC 777.

**`progress-style`** — `true`
Allow graphical progress bars via the ConEmu `OSC 9;4` sequence; `false` silently ignores them.

**`title-report`** — `false` *(1.0.1)*
Allow programs to query the title (`CSI 21 t`). ⚠ Off by default for good reason: it leaks information
at best and, with a maliciously crafted title plus slight user interaction, enables arbitrary code
execution.

**`vt-kam-allowed`** — `false`
Allow ANSI mode 2 (KAM), which lets an application disable keyboard input. If you don't know you need
it, you don't.

**`language`** — *(system default)* · GTK only *(1.3.0)*
Forces the GUI language (e.g. `de`). Does not affect programs running inside the terminal, nor
untranslated non-GUI strings. ⚠ **Cannot be reloaded** — requires a full restart.

**`async-backend`** — `auto` · Linux only *(1.2.0)*
`auto` · `epoll` · `io_uring`. Unavailable backends fall back automatically (e.g. `io_uring` on
hardened kernels). Benchmarks show no significant difference; the choice is about compatibility.
Requires a full restart.

**`auto-update`** — *(unset → Sparkle's stored preference)* · macOS only
`off` · `check` · `download` (download and notify, but don't install). No tracking beyond the network
metadata the protocols require. Takes effect at runtime after a short delay.

**`auto-update-channel`** — *(matches the running build)* · macOS only
`stable` · `tip` (per-commit pre-releases; generally stable but buggier). Requires a full restart.

## Bell

**`bell-features`** — `no-system,no-audio,attention,title,no-border`
`system` (OS alert sound / system bell) · `audio` (custom sound; macOS since 1.3.0) · `attention`
(bounce the dock icon on macOS; DE-dependent on Linux) · `title` (prefix 🔔 to the surface title until
refocused) · `border` (highlight the surface border; GTK 1.2.0, macOS 1.2.1). `no-` prefixable.
*(1.2.0)*

**`bell-audio-path`** — *(unset)* — relative paths resolve against the config file's directory (or
`$PWD` for CLI); `~/` expands. *(GTK 1.2.0, macOS 1.3.0)*
**`bell-audio-volume`** — `0.5` — `0.0`–`1.0`, relative to system volume.

## Quick terminal (Quake-style drop-down)

⚠ **There is no default keybind** — bind `toggle_quick_terminal`, ideally with `global:`.

**`quick-terminal-position`** — `top` — `top` · `bottom` · `left` · `right` · `center`.
⚠ macOS: changing this requires a **full Ghostty restart**.

**`quick-terminal-size`** — *(unset)* *(1.2.0)*
⚠ Absent from `+show-config --default` output (it has no simple default) but a valid key — verify with
`ghostty +explain-config quick-terminal-size`.
Percentages (`20%`) or pixels (`300px`); a bare number is a config error. One value sets the **primary
axis** (height for top/bottom, width for left/right; for `center` it follows monitor orientation).
The secondary axis is maximized unless a second comma-separated value is given; the two may mix units
(`50%,500px`).

**`quick-terminal-screen`** — `main`
`main` (OS-designated main screen; on macOS the one receiving keyboard input) · `mouse` · `macos-menu-bar`
(the screen holding the primary menu bar; treated as `main` on Wayland). On Linux there is no universal
"primary" monitor — the compositor-reported primary output is used, else GDK's first monitor.

**`quick-terminal-animation-duration`** — `0.2` seconds · macOS only — `0` disables. Runtime-changeable.

**`quick-terminal-autohide`** — `true` on macOS, `false` on Linux/BSD
Hide when focus moves elsewhere. The Linux default differs because global shortcuts there need system
configuration and are less reliable.

**`quick-terminal-space-behavior`** — `move` · macOS only *(1.1.0)*
`move` (follow the active macOS Space) · `remain`. Linux always behaves as `move`.

**`quick-terminal-keyboard-interactivity`** — `on-demand` · Linux/Wayland only *(1.2.0)*
`none` · `on-demand` · `exclusive` (receives input even when another window is focused). Behaviour
varies significantly between compositors. macOS is always `on-demand`.

**`gtk-quick-terminal-layer`** — `top` · GTK/Wayland *(1.2.0)*
`overlay` (above everything) · `top` (above normal windows, below lock screens) · `bottom` ·
`background`.
**`gtk-quick-terminal-namespace`** — `ghostty-quick-terminal` · GTK/Wayland *(1.2.0)* — Wayland layer
surface identifier, for compositor rules and scripts.

## Keybindings

**`keybind`** — *(≈93 defaults; see `ghostty +list-keybinds --default`)*
Full syntax, prefixes, sequences, chains, key tables and the action catalogue:
[keybinds.md](keybinds.md).

**`key-remap`** — *(unset)*
`from=to` for modifier keys. Generic names (`ctrl`, `alt`, `shift`, `super`/`cmd`) match both sides;
sided names (`left_ctrl`, `right_alt`) target one. Repeatable.
⚠ **One-way**: `ctrl=super` makes Ctrl act as Super, but Super stays Super.
⚠ **Not transitive**: `ctrl=super` + `alt=ctrl` means Alt produces Ctrl, not Super.
⚠ Affects keybind matching and terminal input encoding only — **not** keyboard layout. `option+a` may
still produce `å` on macOS even when Option is remapped.
⚠ macOS main-menu shortcuts fire **before** remapping (macOS handles them first); unbind and rebind the
menu items to work around it.

## Shell integration

**`shell-integration`** — `detect`
`none` · `detect` (by command basename) · `bash` · `elvish` · `fish` · `nushell` · `zsh`.

**`shell-integration-features`** — `cursor,no-sudo,title,no-ssh-env,no-ssh-terminfo,path`
`cursor` (bar cursor at the prompt) · `sudo` (wrap sudo to preserve `TERMINFO`) · `title` ·
`ssh-env` *(1.2.0)* · `ssh-terminfo` *(1.2.0)* · `path` (append Ghostty's bin dir to `PATH`, so
`ghostty` survives init scripts that reset `PATH` — particularly relevant on macOS).
`no-` prefixable; `true`/`false` set all. ⚠ **Omitted features keep their defaults** — listing
`cursor,sudo,title` does *not* disable `path`.
Details, mechanics and the fish specifics: [integration.md](integration.md).

## Custom shaders

**`custom-shader`** — *(unset)*
Path to a GLSL Shadertoy-style shader with a `mainImage` function, run after the default shaders.
Repeatable; shaders run in order, each receiving the previous one's output in `iChannel0`.
Runtime-changeable, affects all terminals.
⚠ **A bad shader can render Ghostty unusable (fully black window)** — unset the option to recover.
Compilation happens on the render thread *after* config load, so **compile errors never appear as
config errors** — only in the log.

Shadertoy uniforms: `sampler2D iChannel0` (current screen) · `vec3 iResolution` · `float iTime` ·
`float iTimeDelta` · `int iFrame` · `vec3 iChannelResolution[4]` (only `[0]`, = `iResolution`).
Unsupported/N-A: `iFrameRate`, `iChannelTime[4]`, `iMouse`, `iDate`, `iSampleRate`.

Ghostty extensions: `vec4 iCurrentCursor` (`.xy` = −X/+Y corner, `.zw` = width/height) ·
`vec4 iPreviousCursor` · `vec4 iCurrentCursorColor` · `vec4 iPreviousCursorColor` ·
`vec4 iCurrentCursorStyle` / `iPreviousCursorStyle` (macros `CURSORSTYLE_BLOCK` 0,
`CURSORSTYLE_BLOCK_HOLLOW` 1, `CURSORSTYLE_BAR` 2, `CURSORSTYLE_UNDERLINE` 3, `CURSORSTYLE_LOCK` 4) ·
`vec4 iCursorVisible` · `float iTimeCursorChange` · `float iTimeFocus` · `int iFocus` (1 focused;
check `iFocus > 0` to avoid animation artifacts from large deltas on unfocused surfaces) ·
`vec3 iPalette[256]` (normalized 0–1) · `iBackgroundColor` · `iForegroundColor` · `iCursorColor` ·
`iCursorText` · `iSelectionBackgroundColor` · `iSelectionForegroundColor`.

**`custom-shader-animation`** — `true`
`true` = animate while focused (<10% CPU typically) · `false` = render only on terminal updates (no
animation) · `always` = animate regardless of focus (⚠ costs CPU per surface). Only runs when custom
shaders exist.

## macOS

**`macos-non-native-fullscreen`** — `false`
`true` (hide the menu bar) · `false` (native) · `visible-menu` · `padded-notch` (avoid the notch; the
notch surround stays transparent for now).
⚠ **Tabs do not work in non-native fullscreen.** Fullscreening a tabbed window makes the focused tab
fullscreen and leaves the rest in a background window (reachable with cmd+`); exiting restores the
tabbed state. Runtime changes apply at the *next* fullscreen entry.

**`macos-window-buttons`** — `visible` *(1.2.0)* — `visible` · `hidden`. No effect when
`window-decoration = none` or `macos-titlebar-style = hidden` (buttons are always hidden there). New
windows only.

**`macos-titlebar-style`** — `transparent`
`native` (zero customization; follows `window-theme`) · `transparent` (native but lets the window
background through; updates live with OSC 11, but only for terminals bordering the window top, to
avoid a disjointed look) · `tabs` (tab bar merged into the titlebar; ⚠ on macOS ≤13 saved window state
doesn't restore tabs correctly) · `hidden` (hides the titlebar but keeps the frame and rounded corners
— unlike `window-decoration = none`; ⚠ toggling at runtime can affect existing windows in buggy ways,
and dragging then requires option+click on the frame). New windows only.

**`macos-titlebar-proxy-icon`** — `visible` — `visible` · `hidden`. Only shown with the `native`
titlebar style. ⚠ Runtime changes only take effect after the surface's working directory changes
again — `cd` somewhere to see it.

**`macos-dock-drop-behavior`** — `new-tab` — `new-tab` · `new-window`, for files/folders dropped on the
dock icon.

**`macos-option-as-alt`** — *(unset)*
Unset = `true` for U.S. Standard and U.S. International layouts, `false` otherwise. `true` makes Option
act as Alt (breaking macOS Unicode input like option-b → `∫`); `false` keeps Unicode input (breaking
Alt sequences); `left` / `right` enable it for one side. Option sequences that produce no printable
character are treated as Alt regardless.

**`macos-window-shadow`** — `true` — `false` can look better with transparency and some window managers.

**`macos-hidden`** — `never` *(1.2.0)*
`never` · `always` — exclude the app from the dock and app switcher, for quick-terminal-only use.
⚠ While hidden, **keyboard layout changes are no longer automatic** (a macOS limitation).

**`macos-auto-secure-input`** — `true`
Auto-enable macOS Secure Input when a password prompt is detected. ⚠ Heuristic — notably it does
**not** work over SSH. Disable if it interferes with accessibility software. Also available manually
via `Ghostty > Secure Keyboard Entry` and `toggle_secure_input`.

**`macos-secure-input-indication`** — `true` — the animated lock indicator. Worth disabling only if you
keep secure input permanently on.

**`macos-applescript`** — `true` — expose the AppleScript dictionary. `false` disables all AppleScript
commands and object lookup. See [integration.md](integration.md).

**`macos-icon`** — `official`
`official` · `blueprint` · `chalkboard` · `microchip` · `glass` · `holographic` · `paper` · `retro` ·
`xray` (hand-made variants, no AI) · `custom` (needs `macos-custom-icon`) · `custom-style` (needs
`macos-icon-ghost-color` **and** `macos-icon-screen-color`).
⚠ `custom-style` is **experimental**; the layer format may change. Affects the dock/switcher icon only
(`NSApplication.icon`) — the Finder icon is baked into the signed bundle. The update dialog always
shows the official icon.

**`macos-custom-icon`** — `~/.config/ghostty/Ghostty.icns` — absolute path; PNG, JPEG or ICNS.
**`macos-icon-frame`** — `aluminum` — `aluminum` · `beige` · `plastic` · `chrome`. Required for
`custom-style`.
**`macos-icon-ghost-color`** — *(unset)* — required for `custom-style`.
**`macos-icon-screen-color`** — *(unset)* — required for `custom-style`. A linear gradient: up to 64
comma-separated colours, first = bottom, last = top.

**`macos-shortcuts`** — `ask` *(1.2.0)*
Whether macOS Shortcuts may drive Ghostty (create terminals, send text, run commands, invoke any
keybind action). `ask` (remembered once, like camera/mic permissions) · `allow` · `deny`.
⚠ Powerful — a malicious installed shortcut gains full control.

## Linux / GTK

**`linux-cgroup`** — `never`
Put every surface in a transient systemd scope for per-surface resource management (OOM-kill or
throttle one shell instead of all of Ghostty). `never` · `always` · `single-instance`. Costs ~100 ms of
startup per surface, which is why `single-instance` (amortized once) is the intended sweet spot.
Requires systemd. New surfaces only.
**`linux-cgroup-memory-limit`** — *(unset)* — bytes; sets `MemoryHigh` (a **soft** limit — pair with
`systemd-oom`).
**`linux-cgroup-processes-limit`** — *(unset)* — sets `TasksMax` (a hard limit).
**`linux-cgroup-hard-fail`** — `false` — `true` makes surface creation fail when the scope can't be created.

**`gtk-single-instance`** — `detect`
`true` · `false` · `detect` — assume single-instance unless `TERM_PROGRAM` is non-empty (launched from
a graphical terminal → dedicated instance) or CLI arguments exist (custom config must be loaded, and
single-instance inherits the original config). The pre-1.2 value `desktop` is deprecated → `detect`.
Debug builds use a separate instance ID.

**`gtk-titlebar`** — `true` — use the full GTK titlebar instead of the WM's. No effect when
`window-decoration = none` or on macOS.
**`gtk-titlebar-style`** — `native` — `native` (separate tab bar below) · `tabs` (merged; ⚠ you can no
longer drag the window by the titles).
**`gtk-titlebar-hide-when-maximized`** — `false` *(1.1.0)*
**`gtk-tabs-location`** — `top` — `top` · `bottom` · `hidden` (a tab-count button appears in the title
bar, opening the tab overview; otherwise use `toggle_tab_overview` or tab keybinds).
**`gtk-toolbar-style`** — `raised` — `flat` · `raised` · `raised-border`.
**`gtk-wide-tabs`** — `true` — tabs fill available space (GNOME style); `false` = size to content.
**`gtk-horizontal-tab-scroll`** — `true` *(1.4.0)* — two-finger horizontal touchpad scroll switches tabs.
**`gtk-opengl-debug`** — `false` (`true` in debug builds) *(1.1.0)*
**`gtk-custom-css`** — *(unset)* *(1.1.0)*
GTK4 CSS files, repeatable, `?` prefix for optional, 5 MiB per stylesheet. Tweak live with
`env GTK_DEBUG=interactive ghostty`; CSS errors are reported on the launching terminal's stderr.
Reference: docs.gtk.org/gtk4/css-overview.html and css-properties.html.

---

## Options that are *not* in `+show-config --default`

- **`quick-terminal-size`** — documented but emits no default line. Real; use `+explain-config`.
- **`link`** — documented with an explicit "TODO: This can't currently be set!".

Both are worth re-checking on each Ghostty upgrade.
