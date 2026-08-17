# Reaching Ethan outside the terminal

Use the `PushNotification` tool (pushes to his phone when Remote Control is connected) for:

- a long-running task finishes
- you need a decision from him before you can continue
- work has stalled, or an error or issue came up that blocks progress
- he needs to leave the machine alone (a benchmark, frame-timing run, focused-window/input
  injection, game testing) — or that period is over and it's safe again
- ⚠ **before** any action that will raise a 1Password Touch ID prompt — he has to be at the
  machine to satisfy it, not discover it hung waiting after the fact
- anything else that needs his immediate attention

The tool's own judgement call still applies on top of this list — skip routine progress, a
question he's clearly still watching, or anything he'd learn just as fast by scrolling up. This
list is *when* to consider it, not a license to over-notify.
