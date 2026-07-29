# Ghostty terminal API (VT) — control sequences, modes and protocols

The programmer-facing side of Ghostty: what a program running *inside* the terminal can emit and query.
Sourced from `ghostty.org/docs/vt` and the shipped `xterm-ghostty` terminfo entry (Ghostty 1.3.2).

⚠ The upstream VT reference is explicitly **a work in progress** — Ghostty supports considerably more
than is listed there, and per-sequence documentation quality varies. Treat this file as the map, and
`ghostty.org/docs/vt/<type>/<name>` as the detail page for anything you need to be exact about.

Reach for this file when working on shell integration, a prompt, a TUI, terminal capability detection,
or when diagnosing rendering/cursor/clipboard misbehaviour. Configuration lives in
[configuration.md](configuration.md).

---

## 1. Anatomy of a sequence

| Class | Form | Notes |
| --- | --- | --- |
| **C0 control** | single byte `0x00`–`0x1F` | `BEL`, `BS`, `TAB`, `LF`, `CR` |
| **ESC** | `ESC <final>` | `ESC 7`, `ESC c` |
| **CSI** | `ESC [ <params> <intermediates> <final>` | the bulk of cursor/erase/style control |
| **OSC** | `ESC ] <num> ; <payload> ST` | terminated by `ST` (`ESC \`) or `BEL` (`0x07`) |
| **DCS** | `ESC P … ST` | device control strings |
| **SGR** | `CSI … m` | text styling |

`ST` is `ESC \` (`\x1b\x5c`); `BEL` (`\a`) is widely accepted as a terminator too and is what Ghostty's
own shell integration emits.

Ghostty's compatibility principles, in priority order: **xterm compatibility** first (some questionable
xterm behaviours are put behind a config flag), then **protocol-origin compatibility** (behave like the
terminal that defined a protocol, even where unspecified), then **de facto standard** behaviour.

---

## 2. Sequences Ghostty documents

### C0 controls

| Name | Byte | Effect |
| --- | --- | --- |
| `BEL` | `0x07` | Alert the user — see `bell-features` |
| `BS` | `0x08` | Cursor back one |
| `TAB` | `0x09` | Cursor right to next tab stop |
| `LF` | `0x0A` | Cursor down one line, scrolling if needed |
| `CR` | `0x0D` | Cursor to the left margin |

### ESC sequences

| Name | Sequence | Effect |
| --- | --- | --- |
| `DECSC` | `ESC 7` | Save cursor |
| `DECRC` | `ESC 8` | Restore cursor |
| `IND` | `ESC D` | Cursor down, scrolling if needed |
| `RI` | `ESC M` | Cursor up, scrolling if needed |
| `RIS` | `ESC c` | Full reset (what the `reset` keybind action does) |
| `DECKPAM` | `ESC =` | Keypad → application mode |
| `DECKPNM` | `ESC >` | Keypad → numeric mode |
| `DECALN` | `ESC # 8` | Screen alignment test |

### CSI — cursor movement

| Name | Sequence | Effect |
| --- | --- | --- |
| `CUU` / `CUD` / `CUF` / `CUB` | `CSI Pn A`/`B`/`C`/`D` | Up / down / right / left |
| `CNL` / `CPL` | `CSI Pn E` / `F` | Down / up `n` lines, to column 1 |
| `CUP` | `CSI Py ; Px H` | Absolute row and column |
| `HPA` | `CSI Px \`` | Absolute column |
| `VPA` | `CSI Py d` | Absolute row |
| `HPR` / `VPR` | `CSI Pn a` / `e` | Relative column / row |
| `CHT` / `CBT` | `CSI Pn I` / `Z` | Forward / backward `n` tab stops |

### CSI — editing and scrolling

| Name | Sequence | Effect |
| --- | --- | --- |
| `ED` | `CSI Pn J` | Erase display (`3` = scrollback, terminfo `E3`) |
| `EL` | `CSI Pn K` | Erase line |
| `ICH` / `DCH` | `CSI Pn @` / `P` | Insert / delete `n` characters |
| `IL` / `DL` | `CSI Pn L` / `M` | Insert / delete `n` lines |
| `ECH` | `CSI Pn X` | Erase `n` characters |
| `SU` / `SD` | `CSI Pn S` / `T` | Scroll up / down `n` lines |
| `REP` | `CSI Pn b` | Repeat the preceding character `n` times |
| `TBC` | `CSI Pn g` | Clear one or all tab stops |
| `DECSTBM` | `CSI Pt ; Pb r` | Top/bottom margins |
| `DECSLRM` | `CSI Pl ; Pr s` | Left/right margins (terminfo `Cmg`/`Clmg`, enabled via `Enmg`) |

### CSI — reporting and misc

| Name | Sequence | Effect |
| --- | --- | --- |
| `DSR` | `CSI Pn n` | Device status report (`CSI 6n` = cursor position) |
| `DECSCUSR` | `CSI Pn SP q` | Set cursor style — overrides `cursor-style` |
| `XTSHIFTESCAPE` | `CSI > Pn s` | Program's request for shift+click; governed by `mouse-shift-capture` |
| *(title report)* | `CSI 21 t` | ⚠ Disabled by default — see `title-report` |

### OSC

| Sequence | Purpose |
| --- | --- |
| `OSC 0 ; Pt ST` | Set window icon **and** title |
| `OSC 1 ; Pt ST` | Set window icon |
| `OSC 2 ; Pt ST` | Set window title (⚠ ignored entirely when `title` is configured) |
| `OSC 4 ; Pn ; Pc ST` | Query/set a palette colour |
| `OSC 5 ; Pn ; Pc ST` | Query/set a special colour |
| `OSC 7 ; Pu ST` | **Report the working directory** — powers cwd inheritance |
| `OSC 8 ; Pp ; Pu ST` | Begin/end a hyperlink (see `link-previews = osc8`) |
| `OSC 9 ; Pt ST` | Desktop notification (`desktop-notifications`) |
| `OSC 9 ; 4 ; Ps ; Pn ST` | ConEmu progress state (`progress-style`) |
| `OSC 10`–`OSC 19` | Query/set fg, bg, cursor, pointer fg/bg, Tektronix fg/bg/cursor, highlight fg/bg |
| `OSC 21 ; Pk = Pv ST` | Kitty colour-stack protocol |
| `OSC 22 ; Pt ST` | Set pointer shape |
| `OSC 52 ; Pc ; Pd ST` | **Clipboard read/write** — gated by `clipboard-read`/`clipboard-write` (terminfo `Ms`) |
| `OSC 104` / `OSC 105` | Reset palette / special colours |
| `OSC 110`–`OSC 119` | Reset the corresponding `OSC 10`–`19` colour |
| `OSC 133 ; …` | **Prompt/command marking** — see §3 |
| `OSC 777` | Desktop notification (rxvt-style; `desktop-notifications`) |

Colour **query** replies are formatted per `osc-color-report-format` (`16-bit` default, `8-bit`, or
`none` to refuse).

---

## 3. OSC 133 — prompt and command marking

The contract behind `jump_to_prompt`, prompt-aware resize, output selection, close-without-confirm,
`cursor-click-to-move`, and command-finished notifications. A shell emits:

| Mark | Meaning |
| --- | --- |
| `OSC 133 ; A ST` | Prompt start |
| `OSC 133 ; A ; click_events=1 ST` | Prompt start, and the shell accepts click-to-move events |
| `OSC 133 ; B ST` | Prompt end / command input start |
| `OSC 133 ; C ST` | Command output start (pre-exec) |
| `OSC 133 ; D ; <exit> ST` | Command finished, with exit status |

Ghostty's fish integration emits `A` on `fish_prompt`/`fish_posterror`, `C` on `fish_preexec` and
`D;$status` on `fish_postexec`, adding `click_events=1` on **fish ≥ 4.1**. Fish 4.0+ marks prompts
natively, so `jump_to_prompt` and prompt resizing work without Ghostty's integration.

`OSC 7` (cwd reporting) is the companion sequence that makes new windows/tabs/splits inherit the
directory. Fish has it built in but only enables it for an allowlist of terminals that excludes
Ghostty, so the integration emits it on `--on-variable PWD`.

---

## 4. Modes worth knowing

| Mode | Set / reset | Meaning |
| --- | --- | --- |
| `2` (KAM) | ANSI | Application disables keyboard input. ⚠ Refused unless `vt-kam-allowed = true` |
| `12` | DEC | AT&T cursor blink — honoured only while `cursor-style-blink` is unset |
| `1000` / `1006` | DEC | Mouse tracking / SGR mouse encoding (terminfo `XM`) |
| `1049` | DEC | Alternate screen with save/restore (terminfo `smcup`/`rmcup`) |
| `2004` | DEC | Bracketed paste (terminfo `BE`/`BD`; payload wrapped in `PS`/`PE`) |
| `2026` | DEC | **Synchronized output** (terminfo `Sync`) — see §6 |
| `2027` | DEC | Force Unicode grapheme widths, overriding `grapheme-width-method` while set |

---

## 5. Modern protocols Ghostty supports

- **Kitty graphics protocol** — inline images. Budget via `image-storage-limit` (320 MB per screen,
  primary and alternate counted separately; `0` disables all image protocols).
- **Kitty keyboard protocol** — unambiguous key reporting; terminfo `fullkbd`.
- **Kitty colour stack** — `OSC 21`.
- **Synchronized output** (DEC 2026) — terminfo `Sync`.
- **Truecolor** — terminfo `Tc`, `setrgbf`/`setrgbb`; colour space per `window-colorspace`.
- **Styled and coloured underlines** — terminfo `Su`, `Smulx` (`CSI 4:<n> m`), `Setulc`
  (`CSI 58:2::r:g:b m`). ⚠ Lost when falling back to `xterm-256color` over SSH.
- **OSC 8 hyperlinks**, **OSC 52 clipboard**, **bracketed paste**, **left/right margins**,
  **light/dark mode change notifications**, **ConEmu progress (`OSC 9;4`)**.

---

## 6. Synchronized output — the tearing fix

Programs that repaint large regions can flicker or tear in Ghostty while looking fine elsewhere,
because Ghostty renders faster than they finish updating cells. ⚠ **This is a bug in the program, not
in Ghostty**, and there is no terminal-side fix that doesn't cost performance.

Wrap each frame in DEC mode 2026 (`CSI ? 2026 h` … `CSI ? 2026 l`, or terminfo `Sync`) so the terminal
only composites complete frames.

Additionally — and independently useful — **update only the cells that changed**. Reposition with `CUP`
and clear the tail with `EL` instead of erasing whole rows or the entire screen. This reduces tearing
even on terminals without mode 2026 and cuts the volume of data sent to the terminal.

Known-affected programs (upstream issues filed): Claude Code, Docker CLI, Ollama, Grok.

---

## 7. Capability detection

Read the terminfo entry rather than sniffing `TERM`:

```sh
TERMINFO=/Applications/Ghostty.app/Contents/Resources/terminfo infocmp -x xterm-ghostty
```

`TERM_PROGRAM=ghostty` and `TERM_PROGRAM_VERSION` are the reliable identity check inside Ghostty; both
are forwarded over SSH only when `ssh-env` (or an explicit `SendEnv`) is used **and** the remote
`sshd` lists them in `AcceptEnv`. ⚠ `TERM` may legitimately be `xterm-256color` on a remote host even
though the terminal is Ghostty.

Full per-sequence documentation: <https://ghostty.org/docs/vt/reference>.
