# 1Password Environments (beta)

Distilled from www.1password.dev/environments (2026-07-28). Beta on Mac/Linux only; requires the
desktop app, and the CLI paths need `op` ≥ 2.33.0-beta.02 (this machine runs 2.38.1-beta.01).

Environments hold a project's environment variables *outside* the normal vault item model: a named
bag of `KEY=VALUE` pairs, versioned and shareable, that can be projected into a project without ever
writing plaintext to disk. This is the intended replacement for a `.env` file — and for
`~/.config/fish/conf.d/secrets.fish`.

## 1. Create and populate

1Password desktop app → **Developer** → **View Environments** → **New environment** (choose the
account if several).

Add variables either way:

- **Import .env file** — bulk-imports an existing `.env`.
- **New variable** — name (`DB_HOST`, `API_KEY`) + value, one at a time.

Values are **hidden by default**, which means masked in CLI and SDK output. Toggle per variable with
⋮ → *Show value by default*.

⚠ Values are returned **exactly as entered** — Environments do no quoting or escaping. Format them
as a `.env` file would: quote values containing spaces (`"bar baz"`), backslash-escape special
characters (`\$100`).

Manage: **Manage environment** → rename, delete (irreversible; breaks every destination), or
**Manage access** to share with team members (view / edit / manage).

Get the ID — needed by every programmatic path: **Manage environment** → **Copy environment ID**.

## 2. Destinations

Each Environment has a **Destinations** tab:

| Destination | What it does |
| --- | --- |
| **Local `.env` file** | mounts a `.env` at a chosen path on this device |
| **Agent hook** | validates mounted `.env` files before an AI agent runs shell commands |
| **Programmatic** | `op environment read` / `op run --environment` / SDKs |
| **AWS Secrets Manager** | syncs secrets outward |

## 3. Local mounted `.env`

Destinations → *Local `.env` file* → **Choose file path** → **Mount .env file**. Up to **ten enabled
mounts per device**; toggle *Enabled* to remove one.

The mounted file is a **FIFO (named pipe)**, not a regular file:

- Reading it (`cat .env`, a dotenv library) triggers a 1Password authorization prompt; approve once
  and it stays authorized **until 1Password locks**.
- The contents are delivered at read time and **never written to disk**.
- Each open reads once. Tools that stat, seek, or re-read the same handle may misbehave.

⚠ **Git interaction.** If a real `.env` is already tracked at that path, delete it *and commit the
deletion* before mounting. Otherwise Git operations complain about the generated file; it can never
actually be staged (so secrets stay safe), but `git status` stays dirty. Keep `.env` in
`.gitignore` regardless.

Verify:

```sh
cat .env        # authorize the prompt; contents print once
```

Standard dotenv libraries work with mounted files.

## 4. The Claude Code validation hook

`github.com/1Password/agent-hooks` ships a hook that verifies the mounted `.env` files a project
expects are enabled, present, and valid FIFOs **before** the agent executes a shell command; if not,
it blocks and tells the agent how to fix it. Supports Claude Code, Cursor, GitHub Copilot and
Windsurf. Requires `sqlite3` on `PATH` (it reads the 1Password app's local database).

Install for Claude Code: clone the repo and run its install script (Cursor has a marketplace
plugin instead).

**Default mode** — discovers every mount 1Password has configured inside the project directory.

**Configured mode** — a project-root `.1password/environments.toml` limits validation to named
mounts, relative to the project root or absolute:

```toml
mount_paths = [".env", "billing.env"]   # validate exactly these
mount_paths = []                        # validate nothing; allow all commands
```

The `mount_paths` field must exist; a TOML file without it logs a warning and falls back to default
mode. The hook **fails open** in default mode — if the 1Password database is unreachable it warns
and allows the command, so a machine without 1Password still works.

Debug log: `/tmp/1password-hooks.log` (queries, mount checks, permission decisions).

⚠ This is a *validation* hook, not a secret-delivery mechanism. It prevents an agent from running
against a silently missing `.env`; it does not inject anything.

## 5. Reading programmatically

```sh
op environment read <environmentID>              # prints KEY=VALUE lines
op environment read <envID> | grep DB_           # pipeable

op run --environment <environmentID> -- <command>
op run --environment <envID> -- printenv
```

`op run --environment` loads the variables into a subprocess only, with hidden values masked in
stdout/stderr unless `--no-masking`.

**Precedence** when the same name comes from several sources (highest first):

1. `--environment` (last one specified wins among several)
2. `--env-file` (last file wins)
3. inherited shell environment

Authentication is either the desktop app (Touch ID, human-in-the-loop) or a service account token
scoped to the Environment (`OP_SERVICE_ACCOUNT_TOKEN`) for headless use.

**SDKs** (Go / JavaScript / Python, beta builds) expose `environments.getVariables(environmentId)`
returning `{name, value, masked}` triples. Use when a service reads secrets natively; use the CLI for
shell, CI, IaC and task runners.

## 6. The MCP-server pattern

The clean way to give an MCP server a token without writing it into `mcp.json` — wrap the server
command in `op run --environment`, and drop the `env` block entirely:

```json
{
  "mcpServers": {
    "example": {
      "command": "op",
      "args": ["run", "--environment", "<environmentID>", "--",
               "npx", "-y", "@example/mcp@latest"]
    }
  }
}
```

`op` authenticates, resolves the Environment, injects the variables into the process, then execs the
real command. Non-secret configuration can still go in `env`.

⚠ GUI-launched MCP hosts (Claude Desktop on macOS) do not inherit the shell `PATH`. Use the absolute
path — `/opt/homebrew/bin/op` on this machine — as `command`.

The same shape works with `op://` references instead of an Environment
(`op run -- <cmd>` with references exported), which is preferable for a single token.

## 7. The 1Password MCP Server (beta)

A separate thing from the hook: an MCP server that lets Codex or Kiro *manage* Environments (create
them, list variable names, configure mounts) behind a 1Password authorization prompt for every
action. It never returns secret values to the model. Not currently used here.

## 8. Caveats

- ⚠ Beta on both sides — the feature and the CLI build. Reverting `1password-cli@beta` to the stable
  cask breaks `op environment` and `op run --environment`.
- ⚠ Mounted `.env` is macOS/Linux only; on Windows use `op run --environment`.
- ⚠ Sharing an Environment shares whatever is stored verbatim — review values before another person
  or a workflow consumes them.
- ⚠ Deleting an Environment is unrecoverable and silently breaks every destination that used it.
