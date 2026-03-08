# dev_container_ada

[![Build](https://github.com/abitofhelp/dev_container_ada/actions/workflows/docker-build.yml/badge.svg)](https://github.com/abitofhelp/dev_container_ada/actions/workflows/docker-build.yml)
[![Publish](https://github.com/abitofhelp/dev_container_ada/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/abitofhelp/dev_container_ada/actions/workflows/docker-publish.yml)
[![License: BSD-3-Clause](https://img.shields.io/badge/License-BSD--3--Clause-blue.svg)](LICENSE)
[![Default GNAT](https://img.shields.io/badge/GNAT-15.2.1-6f42c1)](#override-toolchain-versions)
[![Container](https://img.shields.io/badge/container-ghcr.io%2Fabitofhelp%2Fdev--container--ada-0A66C2)](#image-name)

Professional Ada development container using **Alire**, **GNAT**, and **GPRBuild**.

**Supported architectures**: `linux/amd64` (x86_64) and `linux/arm64` (Apple Silicon).
Docker automatically pulls the correct image for your platform.

## Image Names

```text
ghcr.io/abitofhelp/dev-container-ada          # Alire-managed toolchain (default)
ghcr.io/abitofhelp/dev-container-ada-system   # Ubuntu system toolchain (alternate)
```

## Choosing a Dockerfile

This repository ships two Dockerfiles representing two valid toolchain strategies:

| Dockerfile | Base | Compiler source | Image name |
|------------|------|-----------------|------------|
| `Dockerfile` (default) | Ubuntu 22.04 | Alire-managed GNAT + GPRBuild | `dev-container-ada` |
| `Dockerfile.system` | Ubuntu 24.04 | Ubuntu `gnat-13` + `gprbuild` packages | `dev-container-ada-system` |

**Which should I use?** Start with the default (`Dockerfile`). Alire's downloadable
Linux GNAT toolchains are built on Ubuntu 22.04, making it the most conservative
pairing. If you prefer Ubuntu's packaged compilers and only need native
compilation, use `Dockerfile.system`. See USER_GUIDE §0 for detailed rationale.

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

- Multi-architecture support: `linux/amd64` and `linux/arm64` (native Apple Silicon)
- Two Dockerfile variants: Alire-managed toolchain (Ubuntu 22.04) and system
  toolchain (Ubuntu 24.04)
- Alire package manager
- GNAT Ada compiler (Alire-managed or Ubuntu system package)
- GPRBuild (Alire-managed or Ubuntu system package)
- Python 3 + venv
- Zsh interactive shell
- runtime-adaptive user identity (no rebuild needed per developer)
- container-aware shell prompt
- designed for nerdctl + containerd (rootless)
- also works with Docker (rootful), Podman (rootless), and Kubernetes
- GitHub Actions for build verification and container publishing (both variants)
- Makefile for common build and run targets (both variants)

## Pre-installed Tools

Both images ship the same set of developer tools. The Ada toolchain source
differs (Alire-managed vs Ubuntu system packages), but all other tools are
identical.

| Category | Tools |
|----------|-------|
| **Ada toolchain** | alr, gnat, gprbuild, gnatmake, gnatbind, gnatlink, gnatls, gprof |
| **Debugger / profiling** | gdb, strace, gcov, gcov-tool |
| **Compiler infrastructure** | gcc, ld, as, ar, nm, objcopy, objdump, ranlib, readelf, size, strings, strip, addr2line |
| **Build** | make, pkg-config |
| **Version control** | git, patch, openssh-client (ssh, scp) |
| **Text processing** | awk, sed, grep, diff, find, xargs, sort, uniq, wc, head, tail, tr, cut, tee |
| **Network** | curl, wget, rsync |
| **Archives** | tar, zip, unzip, xz, gzip, bzip2 |
| **Editors** | vim, nano |
| **Pagers / utilities** | less, more, file, which, lsof, ps, jq |
| **Search** | ripgrep (rg), fd-find (fdfind), fzf |
| **Python** | python3, pip3, python3-venv |
| **Libraries** | libgmp-dev (required by GNATcoverage / libadalang) |
| **Shell** | zsh (default), bash, zsh-autosuggestions, zsh-syntax-highlighting |
| **Container** | gosu, sudo |

Tools like GNATcoverage (`gnatcov`) and code formatters (`gnatformat`) are
installed per-project via Alire crates, not baked into the base image.

## Read Me First: Choosing the Right Mount Point

The `-v` (bind mount) flag determines which host directories are visible inside
the container. The correct mount point depends on how your project resolves its
dependencies.

| Scenario | Mount point | Example |
|----------|-------------|---------|
| **Published crates only** | Project directory | `-v ~/projects/my_app:/workspace` |
| **Pinned deps (absolute paths)** | The pinned path itself | `-v /deps26:/deps26` |
| **Pinned deps (relative paths)** | Common ancestor of project and deps | `-v ~/ada/github.com/abitofhelp:/home/you/ada/github.com/abitofhelp` |

**Why this matters**: Alire resolves pin paths in `alire.toml` relative to the
project root. If your pins use relative paths (e.g., `../deps26/AdaSAT-26.0.0`),
the mount must be high enough in the directory tree for those `../` references
to resolve inside the container.

For example, given this host layout:

```text
~/ada/github.com/abitofhelp/
├── my_app/          ← project with pinned deps
├── functional/      ← ../functional pin
└── deps26/          ← ../deps26/* pins
```

Mount the common parent and set `-w` to the project:

```bash
nerdctl run -it --rm \
  -e HOST_UID=$(id -u) \
  -e HOST_GID=$(id -g) \
  -e HOST_USER=$(whoami) \
  -v "$HOME/ada/github.com/abitofhelp":/home/$(whoami)/ada/github.com/abitofhelp \
  -w /home/$(whoami)/ada/github.com/abitofhelp/my_app \
  dev-container-ada           # or dev-container-ada-system
```

If your project uses only published Alire crates (no pins), the simple
`-v "$(pwd)":/workspace` shown below is all you need.

---

## Quick Start

### Pull a pre-built image

```bash
# Default (Alire-managed toolchain)
nerdctl pull ghcr.io/abitofhelp/dev-container-ada:latest

# System toolchain alternative
nerdctl pull ghcr.io/abitofhelp/dev-container-ada-system:latest
```

### Build from source

```bash
# Default (Alire-managed toolchain)
make build

# System toolchain alternative
make build-system
```

### Run

```bash
# Default
cd ~/projects/my_ada_app
make -f /path/to/dev_container_ada/Makefile run

# System toolchain alternative
make -f /path/to/dev_container_ada/Makefile run-system
```

> **Note**: When using `make -f`, the Makefile mounts the caller's current
> directory (not the Makefile's directory) into the container. This is
> intentional — it bind-mounts your project, not the container repository.

The current directory is mounted into the container at `/workspace`. The
entrypoint adapts the container's home directory layout and toolchain access
to match your host user, so bind-mounted files are readable and writable.

### Inspect configured values

```bash
make inspect
```

## Manual Build

```bash
# Default (Alire-managed toolchain)
nerdctl build -t dev-container-ada .

# System toolchain alternative
nerdctl build -f Dockerfile.system -t dev-container-ada-system .
```

## Manual Run

```bash
# Default (Alire-managed toolchain)
nerdctl run -it --rm \
  -e HOST_UID=$(id -u) \
  -e HOST_GID=$(id -g) \
  -e HOST_USER=$(whoami) \
  -v "$(pwd)":/workspace \
  -w /workspace \
  dev-container-ada

# System toolchain alternative
nerdctl run -it --rm \
  -e HOST_UID=$(id -u) \
  -e HOST_GID=$(id -g) \
  -e HOST_USER=$(whoami) \
  -v "$(pwd)":/workspace \
  -w /workspace \
  dev-container-ada-system
```

## Override Toolchain Versions

> **Note**: Toolchain version overrides apply only to the default Alire-managed
> image (`Dockerfile`). The system toolchain image uses whichever GNAT and
> GPRBuild versions Ubuntu 24.04 provides.

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
adaptation. Podman requires `crun` and `fuse-overlayfs`. The `--userns=keep-id`
flag requires kernel support for unprivileged private mounts (see User Guide
for details and known VM limitations).

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

## Version Tags

### Default image (Alire-managed toolchain)

```text
ghcr.io/abitofhelp/dev-container-ada:latest
ghcr.io/abitofhelp/dev-container-ada:gnat-15.2.1
ghcr.io/abitofhelp/dev-container-ada:gnat-15.2.1-gprbuild-25.0.1
```

### System toolchain image

```text
ghcr.io/abitofhelp/dev-container-ada-system:latest
ghcr.io/abitofhelp/dev-container-ada-system:system-gnat-13
```

The included publish workflow automatically creates tags in these styles.

## GitHub Actions

This repository includes:

- `docker-build.yml` to verify both Dockerfiles on every push and pull request
  (matrix build: Alire + system variants)
- `docker-publish.yml` to publish both images to GitHub Container Registry
  (two jobs: `publish-alire` + `publish-system`)
- automatic tagging based on toolchain versions
- all actions pinned by SHA digest for supply-chain security

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
├── Dockerfile              ← Alire-managed toolchain (Ubuntu 22.04)
├── Dockerfile.system       ← system toolchain (Ubuntu 24.04)
├── entrypoint.sh
├── examples/
│   └── hello_ada/
├── exports/                ← temporary AI-assisted context files
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
