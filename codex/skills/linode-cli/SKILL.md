---
name: linode-cli
description: Operate Akamai Cloud through the official linode-cli, including Linodes, networking, firewalls, VPCs, LKE, databases, Object Storage, DNS, NodeBalancers, volumes, account, billing, users, monitoring, and bundled plugins. Use for any Linode/Akamai Cloud inspection or CLI task when the Linode MCP is absent or unnecessary. Treat paid-resource operations as explicit-consent-only.
---

# Operate Linode safely

Use `linode-cli` for the complete Akamai Cloud control plane. Prefer it over the third-party Linode
MCP for quick inspection, unsupported MCP categories, scripts, and exact API coverage. Use SSH for
work inside an instance.

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

Normal Claude Code and Codex sessions inherit a resolved `LINODE_CLI_TOKEN` from their 1Password
launch wrappers, so `linode-cli` works without loading the Linode MCP. `--infra` additionally loads
the version-pinned MCP and exports its separate `LINODE_API_TOKEN` name. Interactive fish users call
the `linode-cli` wrapper, which uses the 1Password shell plugin.

If authentication fails inside an agent, report it. Do not run `configure`, request a PAT, or fall
back to `--debug`. A normal session may have started without 1Password; Ethan must relaunch it.
