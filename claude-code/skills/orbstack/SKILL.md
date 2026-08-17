---
name: orbstack
description: "OrbStack, this Mac's Docker and Linux VM runtime: orb/orbctl, machine lifecycle, .orb.local networking, Docker troubleshooting, and container-versus-VM decisions. Load for OrbStack, local Docker problems, or Linux VMs."
disable-model-invocation: true
---

# OrbStack

OrbStack (cask `orbstack`, `Brewfile:130`) is the sole container/VM backend on this machine —
Docker Desktop was uninstalled 2026-08-06 in its favor. It replaces Docker Desktop's daemon *and*
adds something Docker Desktop never had: `orb create`, arbitrary full Linux VMs, not just
containers. `claude-code/rules/toolbox.md`'s Containers entry is the always-loaded one-paragraph
digest (why OrbStack over Docker Desktop / Apple's `container` CLI); this skill is the CLI depth.

## Container vs. machine — pick the right primitive

These solve different problems; neither is "preferred" over the other:

| | `docker run ubuntu:noble` | `orb create ubuntu:noble myvm` |
|---|---|---|
| What it is | A container: a namespaced process sharing the one shared Linux kernel inside OrbStack's VM | A full, separate Linux VM: its own kernel, disk, systemd, persists like a mini VPS |
| Lifetime | Ephemeral by convention, image-layered | Persistent until `orb delete` |
| Reach for it when | Running/building a containerized service, a Dockerfile, compose | You want a disposable full OS — apt packages, a real init system, SSH in and work interactively |

## Machine lifecycle

```bash
orbctl list                                          # list machines (alias: orb list)
orbctl create ubuntu:noble myvm                      # DISTRO[:VERSION] [NAME]; run `orbctl create --help` for the full supported-distro list
orbctl create -a amd64 ubuntu x86vm                  # x86 emulation via Rosetta (-a/--arch)
orbctl create --memory 4G --cpus 2 --disk 64G ubuntu dev
orbctl create -c cloud.yml ubuntu myvm               # -c/--user-data: cloud-init
orbctl create -u root -p ubuntu myvm                 # -u custom default user, -p set a password
orbctl create --isolated --mount ~/proj:/proj ubuntu sandboxvm   # blocks file sharing/integration except the explicit mount
orbctl start|stop|restart|delete myvm
orbctl default myvm                                  # get/set the default machine
orbctl clone myvm myvm2                              # orbctl rename / export / import also exist
```

⚠ `--isolated` (+ `--isolate-network`, `--mount`, `--forward-ssh-agent`) is the sandboxing story —
use it for anything untrusted rather than a bare `orbctl create`.

## Shell & exec

```bash
orb                        # shell into the default machine
orb -m myvm -u root        # specific machine + user
orb -m myvm ./script.sh    # run one command in a machine, then exit
```

## File transfer

```bash
orb push ~/local.txt              # macOS -> default machine's home
orb pull ~/remote.txt             # default machine -> macOS
orb push -m myvm ~/f.txt /tmp/    # specific machine + destination path
```
Equivalent, and often more convenient: the shared folder at `~/OrbStack/<machine>/` (see Key paths)
— `cp`/drag-and-drop works directly, no `orb` invocation needed.

## Docker engine & Kubernetes

```bash
orb restart docker      # restart the Docker engine
orb logs docker          # Docker engine logs
orbctl k8s               # instructions to enable/use the bundled Kubernetes cluster
```
Kubernetes is off by default (`orb config show` → `k8s.enable: false`); `orbctl k8s` prints the
exact command to turn it on. Once enabled, every service type is reachable from macOS with no
`kubectl port-forward`, and `cluster.local` DNS resolves directly.

## Config

```bash
orb config show                    # every current value
orb config set memory_mib 8192     # VM memory ceiling (MiB)
orb config set cpu 4               # VM CPU limit
orb config set rosetta true        # x86 emulation via Rosetta (default true)
orb config set network_proxy auto  # or a proxy URL; "auto" follows macOS system proxy
orb config get k8s.enable
orb config reset
```
Other keys worth knowing from `orb config show`: `docker.expose_ports_to_lan`,
`machines.expose_ports_to_lan`, `data_allow_backup`, `network.subnet4`.

## Key paths

| Location | Path |
|---|---|
| Linux files, from macOS | `~/OrbStack/<machine>/` |
| Docker volumes, from macOS | `~/OrbStack/docker/volumes/` |
| macOS files, from Linux | `/mnt/mac/Users/...` (also mounted at the same absolute path) |
| Other machines, from Linux | `/mnt/machines/<name>/` |
| OrbStack's own SSH key | `~/.orbstack/ssh/id_ed25519` |
| Docker daemon config | `~/.orbstack/config/docker.json` |
| `docker` CLI config (this machine) | `$XDG_CONFIG_HOME/docker` — redirected there by `conf.d/xdg-apps.fish`'s `DOCKER_CONFIG`, not the default `~/.docker` |

## Networking

Servers inside a Linux machine or container are **automatically reachable on `localhost`** from
macOS — no port mapping needed.

| Pattern | Resolves to |
|---|---|
| `<machine>.orb.local` | that Linux VM |
| `<container>.orb.local` | that Docker container |
| `<svc>.<project>.orb.local` | a compose service |
| `host.orb.internal` | the macOS host, from inside a Linux machine |
| `host.docker.internal` | the macOS host, from inside a container |

Every `.orb.local` domain gets zero-config HTTPS automatically. Custom container domain:
`docker run -l dev.orbstack.domains=myapp.local nginx`. Follows macOS system proxy settings and is
VPN-compatible.

## SSH

One multiplexed SSH server, no per-machine setup. On this machine, `home/ssh/config`'s very first
line is `Include ~/.orbstack/ssh/config` — OrbStack wrote that itself (through the `~/.ssh/config`
symlink into this repo), and it must stay ahead of every `Host` block for first-match-wins ssh_config
semantics. `~/.orbstack/ssh/config` is regenerated by OrbStack and marked do-not-edit.

```bash
ssh orb                # default machine
ssh myvm@orb           # specific machine
ssh user@myvm@orb      # specific user + machine
```
VS Code Remote-SSH: host `orb` or `myvm@orb`. JetBrains Gateway: host `localhost`, port `32222`,
key `~/.orbstack/ssh/id_ed25519`. SSH agent forwarding is automatic (or `--forward-ssh-agent` for
an `--isolated` machine).

## Docker differences from Docker Desktop

- Container domains resolve without port mapping (`web.orb.local` vs. `localhost:8080`).
- Prefer named volumes over bind mounts — data stays inside the Linux VM, no cross-filesystem hit.
- x86 images on Apple Silicon: `docker run --platform linux/amd64 ubuntu`, or
  `export DOCKER_DEFAULT_PLATFORM=linux/amd64`.
- SSH agent inside a container: mount
  `-v /run/host-services/ssh-auth.sock:/agent.sock -e SSH_AUTH_SOCK=/agent.sock`.

## macOS commands from inside Linux

```bash
mac open https://example.com                 # open in the macOS default browser
mac notify "Build done"                      # macOS notification banner
ORBENV=AWS_PROFILE:EDITOR orb ./deploy.sh    # forward specific env vars into the machine
```

## Troubleshooting

```bash
orbctl doctor                # check OrbStack is properly configured and in control
orbctl report                # generate a diagnostic bundle for a bug report
orb logs myvm                 # machine boot logs
orb restart docker            # fixes most "cannot connect to Docker daemon" cases
docker context use orbstack   # if `docker` picked a different context
orbctl reset                  # ⚠ destructive — deletes ALL Linux and Docker data
```
Rosetta x86 error inside a machine: `sudo dpkg --add-architecture amd64 && sudo apt install libc6:amd64`.
Cloud-init debug: `orb -m myvm cloud-init status --long`, or read
`/var/log/cloud-init-output.log` on that machine.
