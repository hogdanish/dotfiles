# Core CLI reference

## Command shape and discovery

```sh
linode-cli COMMAND ACTION [POSITIONAL ...] [--field value ...] [GLOBAL OPTIONS]
linode-cli commands
linode-cli COMMAND --help
linode-cli COMMAND ACTION --help
```

The executable aliases `lin` and `linode` exist, but use `linode-cli` in documentation and scripts.
Action help includes its current Akamai API reference URL, positional parameters, request fields,
required values, nullable values, nested objects, conflicts, and defaults.

## Request arguments

- Pass scalar request fields as `--field value`.
- Repeat a list flag for each value: `--tags one --tags two`.
- Use dotted paths for nested fields: `--rules.inbound_policy DROP`.
- For a list of nested objects, repeating an already-used child begins the next object.
- Pass literal `null` only to a field marked nullable.
- Pass literal `[]` to explicitly send an empty list.
- Use `--raw-body '{...}'` only for POST/PUT and never with action-specific request flags. Prefer
  normal flags because help validates and documents them.
- Defaults can supply image, authorized users, region, database engine, and Linode type. Add
  `--no-defaults` whenever an exact request must not inherit configured defaults.

## Output and pagination

| Need | Flags |
| --- | --- |
| Agent or script | `--json --all-columns` |
| Readable JSON | `--json --all-columns --pretty` |
| Stable selected fields | `--json --format id,label,status` |
| Delimited text | `--text --delimiter $'\t' --no-headers` |
| Markdown for a user | `--markdown` |
| Every field in a table | `--all-columns` |
| Avoid clipped values | `--no-truncation` |
| One complex response table | `--single-table` |
| Select nested table(s) | `--table NAME` |
| Page manually | `--page N --page-size 25..500` |
| Fetch all pages | `--all-rows` |

`--all` is deprecated; use `--all-columns`. Prefer JSON plus `jq` to parsing tables. Use
`--suppress-warnings` only in automation that handles warnings separately. The CLI retries selected
timeouts and malformed proxy responses; use `--no-retry` only when duplicate-attempt semantics or
diagnosis require it.

List actions accept generated filters as ordinary request flags. Confirm them with action help. For
complex local selection, fetch JSON once and filter with `jq`.

## Configuration and authentication

This machine does not store a PAT in the tracked CLI config. Interactive Fish uses the 1Password
shell plugin wrapper. Codex CLI 0.147.0 and Claude Code 2.1.232 both strip the launch wrapper's
resolved `LINODE_CLI_TOKEN` before their shell tools. Their launch wrappers compensate with the
session-scoped, in-memory broker in the parent skill's **Machine-specific authentication** section.
Inside a wrapped agent session, use bare `linode-cli`; the session-local shim calls the official
binary through that broker.

Supported environment variables:

| Variable | Purpose |
| --- | --- |
| `LINODE_CLI_TOKEN` | PAT; skips token setup |
| `LINODE_CLI_CONFIG` | alternate config path |
| `LINODE_CLI_CA` | custom CA file |
| `LINODE_CLI_API_HOST` | API host override |
| `LINODE_CLI_API_VERSION` | API version override, such as `v4beta` |
| `LINODE_CLI_API_SCHEME` | scheme override |
| `LINODE_CLI_SUPPRESS_VERSION_WARNING` | suppress API-version warning |
| `LINODE_CLI_OBJ_ACCESS_KEY` | bundled `obj` plugin access key |
| `LINODE_CLI_OBJ_SECRET_KEY` | bundled `obj` plugin secret key |

Do not change host, version, scheme, CA, or config path unless the task explicitly requires a test
endpoint. Never print any secret-bearing variable.

The CLI also supports `configure`, `show-users`, `set-user USERNAME`, `remove-user USERNAME`, and
one-shot `--as-user USERNAME`. Agents should not run configuration or user-management commands; ask
Ethan to manage authentication interactively.

## Aliases and completion

Use `--alias NAME --alias-command 'COMMAND ACTION ...'` to set or remove CLI aliases. Avoid creating
aliases from an agent unless requested; aliases change persistent user state. Generate fish
completion with `linode-cli completion fish`, but this machine's completion installation remains
owned by the fish configuration.

## Bundled plugins

`linode-cli plugins` lists: `monitor-api`, `obj`, `firewall-editor`, `get-kubeconfig`, `metadata`,
`image-upload`, `region-table`, and `ssh`.

- `obj`: bucket/object/website operations with S3-style access and secret keys.
- `ssh`: connect to a Linode; prefer ordinary `ssh` when host and user are already known.
- `get-kubeconfig`: obtain an LKE kubeconfig.
- `firewall-editor`: interactive firewall rule editing; avoid in non-interactive agent work.
- `image-upload`: upload a custom image.
- `metadata`: query the Instance Metadata service from a Linode.
- `monitor-api`, `region-table`: monitoring and region-oriented helper surfaces.

Run `linode-cli PLUGIN --help` before use. Third-party plugins can be registered with
`register-plugin MODULE` and removed with `remove-plugin NAME`; do not mutate plugin registration
unless requested.

## Sources

Distilled from the installed 5.68.0 help/OpenAPI bake, the official linode-cli repository and wiki,
and Akamai Cloud API reference links emitted by action help. Re-check live help after upgrades.
