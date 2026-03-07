# dev_container_ada

[![Build](https://github.com/abitofhelp/dev_container_ada/actions/workflows/docker-build.yml/badge.svg)](https://github.com/abitofhelp/dev_container_ada/actions/workflows/docker-build.yml)
[![Publish](https://github.com/abitofhelp/dev_container_ada/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/abitofhelp/dev_container_ada/actions/workflows/docker-publish.yml)
[![License: BSD-3-Clause](https://img.shields.io/badge/License-BSD--3--Clause-blue.svg)](LICENSE)
[![Default GNAT](https://img.shields.io/badge/GNAT-15.2.1-6f42c1)](#override-toolchain-versions)
[![Container](https://img.shields.io/badge/container-ghcr.io%2Fabitofhelp%2Fdev--container--ada-0A66C2)](#image-name)

Professional Ada development container using **Alire**, **GNAT**, and **GPRBuild**.

## Image Name

```text
ghcr.io/abitofhelp/dev-container-ada
```

## Why This Container Is Useful

This container provides a reproducible Ada development environment that adapts
to the host user at runtime. Any developer can pull the pre-built image and
run it without rebuilding.

The included `.zshrc` detects when it is running inside a container and
visibly marks the prompt, which helps prevent common mistakes:

- editing files in the wrong terminal
- confusing host and container environments
- forgetting which compiler or toolchain path is active
- debugging UID, GID, or mount issues more slowly than necessary

Example prompt:

```text
parallels@container /workspace (main) [ctr:rootless]
❯
```

## Features

- Ubuntu 24.04
- Alire package manager
- GNAT Ada compiler
- GPRBuild
- Python 3 + venv
- Zsh interactive shell
- runtime-adaptive user identity (no rebuild needed per developer)
- container-aware shell prompt
- designed for nerdctl + containerd (rootless)
- also works with Docker (rootful), Podman (rootless), and Kubernetes
- GitHub Actions for build verification and container publishing
- Makefile for common build and run targets

## Quick Start

### Pull the pre-built image

```bash
nerdctl pull ghcr.io/abitofhelp/dev-container-ada:latest
```

### Build from source

```bash
make build
```

### Run

```bash
cd ~/projects/my_ada_app
make -f /path/to/dev_container_ada/Makefile run
```

The current directory is mounted into the container at `/workspace`. The
entrypoint adapts the container's home directory layout and toolchain access
to match your host user, so bind-mounted files are readable and writable.

### Inspect configured values

```bash
make inspect
```

## Manual Build

```bash
nerdctl build -t dev-container-ada .
```

## Manual Run

```bash
nerdctl run -it --rm \
  -e HOST_UID=$(id -u) \
  -e HOST_GID=$(id -g) \
  -e HOST_USER=$(whoami) \
  -v "$(pwd)":/workspace \
  -w /workspace \
  dev-container-ada
```

## Override Toolchain Versions

```bash
make build GNAT_VERSION=15.2.1 GPRBUILD_VERSION=25.0.1
```

You can also override them directly:

```bash
nerdctl build \
  --build-arg GNAT_VERSION=15.2.1 \
  --build-arg GPRBUILD_VERSION=25.0.1 \
  -t dev-container-ada .
```

## Use Docker or Podman Instead of nerdctl

All Makefile targets use `CONTAINER_CLI`, which defaults to `nerdctl`. Override
it to use Docker or Podman:

```bash
make build CONTAINER_CLI=docker
make run CONTAINER_CLI=docker
```

Or use the convenience aliases:

```bash
make docker-build
make docker-run

make podman-build
make podman-run
```

Podman rootless uses `--userns=keep-id` to map the host user directly into the
container without needing the `HOST_*` environment variables or entrypoint
adaptation. Podman support is implemented but not yet tested.

## Housekeeping

Remove build artifacts (saved images, source archives):

```bash
make clean
```

Create a compressed source archive from the current HEAD:

```bash
make compress
```

## Deployment Environments

This image supports three deployment environments with a single build.

### Local Development (nerdctl rootless)

This is the primary workflow. `make run` passes the host identity and mounts
the current directory:

```bash
cd ~/projects/my_ada_app
make run
```

The entrypoint sets up the home directory layout and toolchain access to match
your host identity. In rootless mode, the process stays as container UID 0
(which maps to the host user via the user namespace) for bind-mount
correctness. This is safe — no privilege escalation is possible.

### CI / Docker Rootful

The image runs as the fallback non-root user (`dev:1000:1000`) by default when
no `HOST_*` environment variables are passed. GitHub Actions workflows build
and publish the image using Docker.

### Kubernetes

The image is compatible with Kubernetes out of the box. Source code is
provisioned via PersistentVolumeClaims or init containers (e.g., git-sync),
not bind mounts.

Example pod spec:

```yaml
securityContext:
  runAsUser: 1000
  runAsGroup: 1000
  fsGroup: 1000
  runAsNonRoot: true
containers:
  - name: ada-dev
    image: ghcr.io/abitofhelp/dev-container-ada:latest
    workingDir: /workspace
    volumeMounts:
      - name: source
        mountPath: /workspace
volumes:
  - name: source
    persistentVolumeClaim:
      claimName: ada-source
```

`fsGroup: 1000` ensures the volume is writable by the container user.
Kubernetes manifests and Helm charts are not included in this repository.
Teams should create these per their cluster policies.

## Rootless Security

In rootless container runtimes (nerdctl/containerd rootless, Podman rootless),
the container runs inside a user namespace where container UID 0 maps to the
unprivileged host user. The process cannot escalate beyond the host user's
privileges. The entrypoint script detects this and avoids dropping privileges,
because doing so would map the process to a subordinate UID that cannot access
bind-mounted host files.

| Runtime          | Container UID 0 is...  | Bind mount access via...  | Security boundary      |
|------------------|------------------------|---------------------------|------------------------|
| Docker rootful   | Real root (dangerous)  | gosu drop to HOST_UID     | Container isolation    |
| nerdctl rootless | Host user (safe)       | Stay UID 0 (= host user)  | User namespace         |
| Podman rootless  | Host user (safe)       | --userns=keep-id          | User namespace         |
| Kubernetes       | Blocked by policy      | fsGroup in pod spec       | Pod security standards |

## Version Tags Based on GNAT Versions

Suggested container tags:

```text
ghcr.io/abitofhelp/dev-container-ada:latest
ghcr.io/abitofhelp/dev-container-ada:gnat-15.2.1
ghcr.io/abitofhelp/dev-container-ada:gnat-15.2.1-gprbuild-25.0.1
```

The included publish workflow automatically creates tags in this style.

## GitHub Actions

This repository includes:

- `docker-build.yml` to verify the Dockerfile on every push and pull request
- `docker-publish.yml` to publish images to GitHub Container Registry
- automatic tagging based on toolchain versions

## Repository Layout

```text
dev_container_ada/
├── .dockerignore
├── .github/
│   └── workflows/
│       ├── docker-build.yml
│       └── docker-publish.yml
├── .gitignore
├── .zshrc
├── CHANGELOG.md
├── Dockerfile
├── entrypoint.sh
├── LICENSE
├── Makefile
├── README.md
└── USER_GUIDE.md
```

## License

BSD-3-Clause — see `LICENSE`.

## AI Assistance and Authorship

This project was developed by Michael Gardner with AI assistance from Claude
(Anthropic) and GPT (OpenAI). AI tools were used for design review,
architecture decisions, and code generation. All code has been reviewed and
approved by the human author. The human maintainer holds responsibility for
all code in this repository.
