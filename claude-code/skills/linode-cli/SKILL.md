---
name: linode-cli
description: "Operate Akamai Cloud through the official linode-cli: the full command surface, safety workflow, and paid-resource guardrails. Load before any Linode/Akamai Cloud CLI task."
disable-model-invocation: true
---

# Operate Linode safely

Use `linode-cli` for the complete Akamai Cloud control plane. It is the only Linode control-plane
client exposed to agents on this machine. Use SSH for work inside an instance.

## Non-negotiable safety rules

1. Run read-only list, view, status, type, region, event, metric, and availability operations freely.
2. Never create, clone, resize, rebuild, restore, migrate, or enable a Linode or any other billable
   service unless Ethan explicitly requests that operation in the current request. This includes
   Backups, Managed, LKE, Managed Databases, NodeBalancers, Object Storage, and paid Volumes.
3. Treat delete, cancel, revoke, reset, detach, unassign, transfer, shutdown, reboot, restore,
   firewall/routing changes, credential changes, and account/billing changes as consequential.
   Resolve exact IDs with a read-only command first and act only when the request authorizes it.
4. Never run `linode-cli --debug`; HTTP debug output can expose authorization headers in the
   transcript. Never print, pass, or persist a PAT. Never read the CLI config to inspect credentials.
5. Never put a password, private key, Object Storage secret, or PAT on the command line. Use the
   inherited `LINODE_CLI_TOKEN`, 1Password, SSH agent, or another non-printing consumer.
6. Prefer JSON for agent processing and tables for humans. Do not scrape Unicode tables.

## Workflow

1. Confirm the binary and discover the live surface with `linode-cli --version`,
   `linode-cli commands`, or `linode-cli COMMAND --help`.
2. Read the matching reference below. For any write, also read
   [safety-and-workflow.md](references/safety-and-workflow.md).
3. Resolve names to IDs with `list --json --all-columns`; use `jq` locally when useful.
4. Inspect action-specific arguments with `linode-cli COMMAND ACTION --help`. The CLI is generated
   from the current OpenAPI specification, so live help outranks remembered flags and these notes.
5. Execute the narrowest command. Verify the result with a separate read-only `view` or `list`.

## Reference routing

- [core.md](references/core.md): syntax, arguments, defaults, output, pagination, filters,
  configuration, users, environment variables, aliases, completion, and plugins.
- [safety-and-workflow.md](references/safety-and-workflow.md): mutation classes, consent boundary,
  dry inspection patterns, verification, errors, and scripting practices. Read for every write.
- [compute-network.md](references/compute-network.md): Linodes, disks/configs/backups, images,
  volumes, IPs, VPCs, VLANs, firewalls, placement, NodeBalancers, regions, and transfer.
- [platform-services.md](references/platform-services.md): LKE, databases, Object Storage, DNS,
  Longview, Managed, Monitor, alerts, streams, and Marketplace referrals.
- [account-security.md](references/account-security.md): account and billing, profile, users, SSH
  keys, OAuth/PATs, events, tickets, tags, locks, transfers, betas, and child accounts.
- [command-index.md](references/command-index.md): every generated command group and action in
  linode-cli 5.68.0. Use it to find a capability; confirm exact flags with live `--help`.

## Machine-specific authentication

⚠ **Agent authentication path, verified with Codex CLI 0.147.0 and Claude Code 2.1.232 on
2026-08-14.** The Fish launch wrappers start a session-scoped credential broker: one launch-time
`op run` resolves the PAT, the broker keeps it only in memory, and a session-local `linode-cli` shim
forwards arguments to `/opt/homebrew/bin/linode-cli` over a mode-0600 Unix socket. The wrapper removes
the resolved credential from the agent environment before it starts.

```sh
linode-cli linodes view 102470771 --json
```

Use bare `linode-cli` inside a normally wrapped Claude Code or Codex session. It does not call `op`
again, so 1Password's CLI-session expiry cannot interrupt the agent. If the shim reports that its
session socket is unavailable, restart the agent through its Fish wrapper; do not bypass the broker
or run `configure`. The third-party Linode MCP was removed.

Interactive Fish users call the normal `linode-cli` wrapper, which uses the same 1Password shell
plugin. Never run `configure`, request a PAT, or use `--debug` to work around an authentication
failure.

SSH to `cg-test-ord-01` uses a host-scoped OpenSSH control connection that persists for 12 hours.
The first connection can require 1Password SSH approval; later commands reuse the existing transport.
