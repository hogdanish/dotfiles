# Reaching Ethan outside the terminal (`cc-notify`)

Ethan multitasks while you work, so the terminal is often not on screen. `cc-notify` is the one
channel that reaches him anyway: a banner **plus** an `afplay` chime that no Focus mode can suppress.

```bash
cc-notify hold      "Running a benchmark sweep" "~4 min"   # before: don't touch the machine
cc-notify clear     "Benchmark done"                        # after: free to multitask again
cc-notify attention "Godot editor needs a manual restart"   # I'm stuck and only you can unstick me
```

`hold` and `clear` are a **pair** — every `hold` gets a `clear`, including on the failure path, or he
stays frozen waiting for an all-clear that never comes. Keep messages to one short line; put duration
or the specific ask in the optional third argument.

## When it fires

- **`hold` / `clear`** — you are about to start something whose result is corrupted by ordinary use of
  the machine: benchmarks and frame-timing runs, anything needing a window focused or input injected,
  screen/audio capture, a long uninterruptible build. Announce *before*, all-clear *after*.
- **`attention`** — the session is blocked on a physical act only he can perform (restart an app, fix a
  dead MCP server, plug something in, approve out-of-band). Fire it, then keep going if you can; do
  **not** treat the notification as a substitute for saying the same thing in the terminal.

## When it does NOT fire

⚠ **The default is silence.** This is an interrupt, and an interrupt that arrives when nothing was at
stake trains him to ignore the one that mattered. Never send one for: finishing a normal task, asking a
question you could equally ask in the terminal, progress updates, a summary, a "heads up" about
something that will still be true in ten minutes, or anything he'd learn by simply scrolling up.

The test is not *"is this important?"* — it's **"does he lose something real if he reads this five
minutes late?"** If no, it belongs in the terminal like everything else.

Do not stack notifications: one `hold` covers a whole batch of runs, not one per run.
