# Platform services

## LKE

`lke` covers cluster lifecycle, Kubernetes versions/types, API endpoints, control-plane ACLs,
kubeconfigs, service tokens, node pools, and individual nodes. All create/regenerate/recycle/delete,
pool sizing, and ACL changes are high-impact; cluster and pool creation are billable. Kubeconfig and
service-token responses are credential-bearing—do not print or persist them outside their intended
consumer.

## Managed Databases

`databases` covers engines/types plus MySQL and PostgreSQL create/restore, list/view, update/patch,
suspend/resume, delete, credentials, SSL certificates, and PostgreSQL connection pools. Database
creation/restoration and size changes are billable. Credential reset/view and SSL certificate output
are sensitive. `suspend` is not deletion and may not eliminate all charges; never promise savings
without current product/pricing documentation.

## Object Storage

The generated `object-storage` group manages account service state, endpoints/clusters/types, access
keys, TLS certificates, transfer, and quotas. The bundled `obj` plugin manages buckets and objects.
Enabling/canceling service, creating keys, deleting keys, and certificate operations are consequential;
bucket/object deletion can be irreversible. Treat returned key secrets as write-only credentials.

## DNS Manager

`domains` covers domain create/import/clone/list/view/update/delete, zone files, and record lifecycle.
DNS writes can cause outages even when they are not billable. Read the zone and exact record first;
verify name, type, target, TTL, priority, and domain ID after changes.

## Monitoring and managed service

- `longview`: clients, plans, subscriptions, types. Plan changes may affect billing.
- `managed`: contacts, credentials, Linode settings, services/monitors, issues, and stats. Enabling
  Managed or creating services may be billable; credential operations are sensitive.
- `monitor`: service types, dashboards, metrics, and service tokens. Token output is sensitive.
- `alerts`: notification channels, definitions, entity assignments, and service definitions.
  Channel/definition changes alter incident routing.
- `streams`: stream and destination lifecycle plus delivery history. Destination changes can expose
  or stop telemetry.

## Marketplace and StackScripts

`marketplace contacts-create` creates a third-party referral; it is not a general app deployment
surface. Marketplace deployments usually flow through `linodes create` with a StackScript and are
billable. `stackscripts` supports create/list/view/update/delete. Inspect required StackScript data
before deployment and never place secrets in StackScript data on a command line.
