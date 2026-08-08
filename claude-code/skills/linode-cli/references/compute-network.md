# Compute and networking

## Linodes

`linodes` owns instance lifecycle, type discovery, configuration profiles, disks, interfaces, IPs,
firewall attachment, backups, rescue, transfer, and attached resources.

- Inspect: `list`, `view`, `types`, `type-view`, `configs-list`, `config-view`, `disks-list`,
  `disk-view`, `interfaces-list`, `interface-view`, `ips-list`, `backups-list`, `backup-view`,
  `firewalls-list`, `volumes`, `nodebalancers`, `transfer-view`.
- State changes: `boot`, `reboot`, `shutdown`, `rescue`.
- Billable/high-impact: `create`, `clone`, `resize`, `upgrade`, `migrate`, `rebuild`,
  `backups-enable`, `backup-restore`, `snapshot`.
- Destructive: `delete`, `disk-delete`, `config-delete`, interface/IP deletion, backup cancellation,
  password resets.

Creating from an image normally requires `region`, `type`, `image`, and a credential path. Never pass
a root password in an agent command. Prefer authorized users/keys already managed by the account and
inspect live help because interface schemas change frequently.

## Images, volumes, kernels, placement

- `images`: list/view, create from disk, upload, update, replicate, delete, and image share groups.
- `volumes`: list/view/types, create/clone/resize, attach/detach, update/delete. Volumes are billable.
- `kernels`: list/view available kernels.
- `placement`: list/view/create/update/delete groups and assign/unassign Linodes.
- `image-sharegroups`: share-group, member, token, and shared-image lifecycle. Tokens and membership
  changes are security-sensitive.

## IPs, VPCs, VLANs

- `networking`: account IP list/view, allocate, assign, share, update RDNS, IPv6 pools/ranges.
- `vpcs`: VPC list/view/create/update/delete; subnet list/view/create/update/delete; VPC IP views.
- `vlans`: list and delete VLANs. VLAN membership is configured through Linode interfaces.

IP assignment, sharing, RDNS, NAT, default routes, subnet ranges, and interface changes can sever
connectivity. Read the current Linode/interface plus target VPC/subnet before writing.

## Firewalls

`firewalls` owns firewall lifecycle, rules, device attachments, default firewall settings, templates,
and rule-version history. Use `rules-list` before `rules-update`; a rules update replaces policy/rule
sets, so preserve intended existing rules. Use templates only as input to an explicitly requested
change. Verify device attachments independently.

## NodeBalancers and transfer

`nodebalancers` covers balancer lifecycle, configs, backend nodes, VPC configs, firewalls, and types.
Creation is billable. Config rebuilds, node changes, protocol/health-check changes, and firewall
changes can shift production traffic.

`network-transfer prices` is read-only pricing data. Linode and Object Storage groups expose current
transfer usage. Do not infer future cost from one metric without checking the relevant type/region.

## Regions and maintenance

Use `regions list`, `regions view`, availability actions, `maintenance policies-list`, and account
maintenance listings before planning placement or migration. Availability does not authorize a
creation or migration.
