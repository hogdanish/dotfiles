# Reaching Ethan outside the terminal (`cc-notify`)

Ethan multitasks while you work. `cc-notify` (self-authored, `~/.config/claude-code/bin/`, on
`$PATH`) reaches him anyway: a banner plus an `afplay` chime no Focus mode can suppress. Do not
hand-roll `osascript display notification`.

```bash
cc-notify hold      "Running a benchmark sweep" "~4 min"   # before: don't touch the machine
cc-notify clear     "Benchmark done"                        # after: free to multitask again
cc-notify attention "Godot editor needs a manual restart"   # blocked on a physical act only he can do
```

- `hold` fires before work that ordinary use of the machine would corrupt: benchmarks and
  frame-timing runs, focused-window or input injection, screen/audio capture, a long
  uninterruptible build. `hold`/`clear` are a **pair** — every `hold` gets a `clear`, on the
  failure path too, or he stays frozen waiting. One `hold` covers a whole batch, not one per run.
- `attention` fires when the session is blocked on a physical act only he can perform (restart an
  app, plug something in, approve out-of-band). Say the same thing in the terminal as well.
- Keep messages to one short line; duration or the specific ask goes in the third argument.

⚠ **The default is silence.** An interrupt that arrives when nothing was at stake trains him to
ignore the one that matters. Never notify for: a finished task, a question, progress, a summary, or
anything he can learn by scrolling up. The test is not "is this important?" — it is **"does he lose
something real if he reads this five minutes late?"** If no, it belongs in the terminal.
