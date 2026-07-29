# key bindings. every binding here was checked free on fish 4.8.1 — verified with
# `bind <key>`, which reports preset bindings as well as user ones.
#
# ⚠ COLLISION HAZARD. a key sequence holds exactly ONE command list: the last `bind` for a
# key silently replaces the previous one, with no warning. this file sorts on `k`, so
# conf.d/tools.fish (`t`) runs LATER and its tool inits win any contested key — atuin takes
# ctrl-r and up, fzf takes ctrl-t, alt-c and shift-tab. nothing below touches those.
# if a binding here ever does need to beat a tool, do not reorder this file — register it on
# the deferred hook instead, and add the matching `emit fish_postinit` to config.fish:
#
#     function __keybindings_late --on-event fish_postinit --description '...'
#         bind ctrl-t my-widget
#     end
#
# (handlers only register when a file is *sourced*, which is why that must stay in conf.d/.)

status is-interactive; or return

# alt-e: edit the current command line in $VISUAL, then run what you saved.
# ⚠ not bound by default on 4.8.1 despite what the docs imply, and $VISUAL's `--wait` in
# conf.d/_init.fish is what makes it work at all — without it the editor returns instantly
# and the buffer is never updated.
bind alt-e edit_command_buffer

# ctrl-o: copy the command line to the clipboard without running it.
bind ctrl-o 'commandline | fish_clipboard_copy' repaint

# alt-p: page the job under the cursor. `--current-job` stops at `;` and `&`, so it does the
# right thing on a multi-command line.
bind alt-p 'commandline --current-job --append " &| $PAGER"' repaint

# ctrl-z: at an empty prompt, resume the most recently backgrounded job — the other half of
# the ctrl-z you already press to suspend one. only reachable when no job is in the
# foreground, so it cannot shadow the terminal's own SIGTSTP.
bind ctrl-z 'fg 2>/dev/null; commandline -f repaint'
