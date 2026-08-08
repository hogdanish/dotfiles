---
name: orbstack
description: Operate OrbStack as this Mac's Docker and Linux VM runtime, including orb/orbctl, machine lifecycle, Docker Compose, Kubernetes, .orb.local networking, the multiplexed orb SSH host, macOS-Linux interop, and troubleshooting. Use for OrbStack, local Docker daemon problems, Linux VMs, or container-versus-VM decisions. The Fish/XDG plumbing remains owned by the dotfiles Fish guidance.
---

# Operate OrbStack

OrbStack is the sole container and Linux VM backend on this machine. Docker Desktop is not installed.

## Choose the primitive

- Use `docker run` or Compose for image-based, usually ephemeral services that share OrbStack's Linux kernel.
- Use `orbctl create` for a persistent full Linux VM with its own kernel, disk, systemd, and package state.
- Use `--isolated`, explicit mounts, and explicit SSH-agent forwarding for untrusted workloads.

## Machine lifecycle

```bash
orbctl list
orbctl create ubuntu:noble myvm
orbctl create -a amd64 ubuntu x86vm
orbctl create --memory 4G --cpus 2 --disk 64G ubuntu dev
orbctl create --isolated --mount ~/proj:/proj ubuntu sandboxvm
orbctl start|stop|restart|delete myvm
orbctl clone myvm myvm2
orbctl default myvm
```

Run `orbctl create --help` before depending on a distro or version not already present.

## Shell, files, and services

```bash
orb                         # shell in the default machine
orb -m myvm -u root         # choose machine and user
orb -m myvm ./script.sh     # run one command
orb push -m myvm ~/f /tmp/  # macOS to Linux
orb pull -m myvm ~/f        # Linux to macOS
orb restart docker
orb logs docker
orbctl k8s
```

Shared paths:

- Linux files from macOS: `~/OrbStack/<machine>/`
- macOS files from Linux: `/mnt/mac/Users/...` and the same absolute macOS path
- Other machines from Linux: `/mnt/machines/<name>/`
- Docker volumes from macOS: `~/OrbStack/docker/volumes/`
- Docker CLI config: `$XDG_CONFIG_HOME/docker` through `DOCKER_CONFIG`

## Networking and SSH

- Services are reachable from macOS on `localhost` without manual forwarding.
- Use `<machine>.orb.local`, `<container>.orb.local`, or `<service>.<project>.orb.local`.
- Use `host.orb.internal` from a VM and `host.docker.internal` from a container.
- Use `ssh orb`, `ssh myvm@orb`, or `ssh user@myvm@orb`; OrbStack owns `~/.orbstack/ssh/config`.
- Do not edit generated files under `~/.orbstack/ssh/`.

## Configuration and diagnosis

```bash
orb config show
orb config get k8s.enable
orb config set memory_mib 8192
orb config set cpu 4
orb config set rosetta true
orbctl doctor
orbctl report
orb logs myvm
docker context use orbstack
```

Treat `orbctl reset` as destructive: it deletes all Linux machine and Docker data.
