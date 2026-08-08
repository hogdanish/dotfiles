# Safety and workflow

## Classify before execution

| Class | Examples | Rule |
| --- | --- | --- |
| Read-only | `list`, `view`, `types`, `regions`, events, stats, availability | Run when relevant |
| Routine mutation | labels, tags, non-routing metadata, ticket replies | Require task authorization; verify after |
| Operational impact | boot, reboot, shutdown, firewall rules, IP assignment, pool recycle | Resolve target first; require clear authorization |
| Destructive/security | delete, cancel, restore, rebuild, reset, revoke, credential/TFA/user changes | Confirm exact target and requested outcome |
| Billable | create/clone/resize/migrate; enable Backups/Managed; LKE, DB, NodeBalancer, Object Storage, Volume | Ethan must explicitly request it now |
| Account/billing | payments, promo, account cancel, service transfer, payment method | Never infer; explicit current authorization only |

An instruction to “fix,” “deploy,” or “set up” does not automatically authorize a new paid resource
when an existing-resource or local alternative may work. State the cost-bearing step and stop for
permission if the request did not name it.

## Read-first pattern

```sh
linode-cli linodes list --json --all-columns
linode-cli linodes view INSTANCE_ID --json --all-columns
linode-cli linodes ACTION --help
```

For a write:

1. Resolve the unique resource ID and current state.
2. Inspect live action help.
3. Check that the user authorized this class of change.
4. Send only fields that need changing; avoid `--raw-body` unless necessary.
5. Re-read the resource and report the resulting state.

Never use a label alone when labels may be duplicated. Never guess an ID from an old transcript.

## Credentials and transcript safety

- Never use `--debug`; it enables HTTP debugging.
- Never echo or inspect `LINODE_CLI_TOKEN`, Object Storage keys, passwords, OAuth secrets, or the
  credential-bearing parts of CLI config.
- Do not pass `--root_pass`, `--token`, access keys, or secrets as literals. A command line is visible
  in process lists, shell history, and transcripts.
- Treat PAT creation/reset responses and Object Storage key creation responses as secret-bearing.
  Do not print them into the session.
- Use the 1Password SSH agent for SSH. Do not export private keys.

## Scripting

Use JSON, explicit fields, and an error-aware pipeline:

```sh
linode-cli linodes list --json --all-columns --suppress-warnings \
  | jq -e '.[] | select(.status != "running") | {id, label, status}'
```

Do not suppress retries by default. For mutation automation, consider whether a retry could duplicate
the request; prefer idempotent updates and verify server state after an ambiguous failure. Capture exit
status before subsequent commands. Do not treat an empty filtered result as an API failure.

## Verification by resource

| Change | Verify with |
| --- | --- |
| Linode state/config | `linodes view`, `configs-list`, `disks-list`, `interfaces-list` |
| Firewall | `firewalls view`, `rules-list`, `devices-list` |
| Network | `networking ips-list`, `vpcs view`, `subnets-list`, `vlans list` |
| LKE | `lke cluster-view`, `pools-list`, `api-endpoints-list` |
| Database | engine-specific `*-view` and `*-list` |
| DNS | `domains view`, `records-list`, `zone-file` |
| Account/security | matching `view` plus `events list` when available |

Some control-plane changes are asynchronous. Report the accepted operation and observed state; do not
claim completion until the readback says it completed.
