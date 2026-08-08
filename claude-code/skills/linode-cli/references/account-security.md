# Account, security, and support

## Account and billing

`account` covers account details/settings, invoices/items, payments, payment submission, login history,
notifications, maintenance, network transfer, regional service availability, promos, Managed enablement,
OAuth clients, and account cancellation. Read-only billing inspection is allowed. Payment, promo,
OAuth-secret reset, Managed enablement, settings updates, and cancellation require explicit current
authorization. Never expose invoice or payment details beyond what the task needs.

`payment-methods` can list/view, add, set default, and delete methods. `phone` manages verification and
deletion. `security-questions` is list-only. These are account-security surfaces, not routine setup.

## Profile and identity

`profile` covers current profile, authorized apps, trusted devices, logins, TFA, and PAT lifecycle.
Never create/view/reset a PAT or TFA secret in an agent transcript. Revoking apps/devices/tokens can
lock out users and integrations. `users` manages account users and grants; `sshkeys` manages public
keys. Resolve the exact identity and preserve least privilege.

## Events, tickets, tags, and locks

- `events`: list/view and mark seen. Use events to verify asynchronous operations.
- `tickets`: list/view replies, create, reply, close. Ticket content may contain private account or
  infrastructure details; disclose minimally.
- `tags`: create/list/delete account tags. Deleting a tag removes its association context.
- `resource-locks`: create/list/view/delete locks. Do not remove a lock merely because it blocks a
  requested mutation; the lock may be the intended guardrail.

## Transfers, betas, and child accounts

`service-transfers` can create/list/view, accept, and cancel transfers. Acceptance changes ownership
and may change billing; require explicit authorization from the account owner. `betas` can inspect and
enroll; enrollment may expose unstable services and is opt-in only. `child-account` can create proxy
tokens and exposes deprecated list/view actions; proxy-token output is sensitive.

`image-sharegroups` and service-transfer tokens are capability-bearing. Do not print or relay them
except directly to the authorized consumer.
