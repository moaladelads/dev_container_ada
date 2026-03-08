<!-- ====================================================================== -->
<!-- USER_GUIDE.md                                                          -->
<!-- ====================================================================== -->
<!-- Copyright (c) 2025 Michael Gardner, A Bit of Help, Inc.               -->
<!-- SPDX-License-Identifier: BSD-3-Clause                                  -->
<!-- See LICENSE file in the project root.                                  -->
<!-- ====================================================================== -->

# User Guide: dev_container_ada

**Version**: 2.0.0 (dual-Dockerfile)
**Date**: 2026-03-07
**Authors**: Michael Gardner, Claude (Anthropic), GPT (OpenAI)

---

## 0. Choosing a Dockerfile

### 0.1 Why there are two Dockerfiles

Alire's downloadable Linux GNAT toolchains are built on Ubuntu 22.04. Using
them on Ubuntu 24.04 works in practice, but Ubuntu 22.04 is the more
conservative pairing — fewer surprises from glibc or runtime library
differences.

At the same time, Ubuntu 24.04 ships `gnat-13` and `gprbuild` as system
packages. Developers who prefer system-packaged compilers — or whose projects
only need native compilation — may find this simpler.

Rather than declare one approach wrong, this project ships both:

| Dockerfile | Base | Compiler source | Image name |
|------------|------|-----------------|------------|
| `Dockerfile` (default) | Ubuntu 22.04 | Alire-managed GNAT + GPRBuild | `dev-container-ada` |
| `Dockerfile.system` | Ubuntu 24.04 | Ubuntu `gnat-13` + `gprbuild` packages | `dev-container-ada-system` |

**Start with the default.** It gives you Alire's full toolchain management,
including the ability to install cross compilers for embedded targets. Switch
to `Dockerfile.system` if you prefer system packages and only need native
compilation.

### 0.2 What stays the same

Regardless of which Dockerfile you choose:

- The same `entrypoint.sh` handles runtime user adaptation.
- The same `.zshrc` provides the container-aware prompt.
- The same `examples/hello_ada/` smoke test works in both images.
- Alire is installed as a workspace and dependency tool in both images.
- All three deployment environments (rootless nerdctl, rootful Docker,
  Kubernetes) are supported.

### 0.3 Cross-target and embedded development

If you need Alire-managed cross compilers (e.g., `gnat_arm_elf` for
bare-metal ARM, `gnat_riscv64_elf` for RISC-V), use the default
`Dockerfile`. Alire distributes these as downloadable toolchains, and they
are built against Ubuntu 22.04. The system toolchain image does not support
cross-target compilation through Alire.

---

## 1. Prerequisites

### 1.1 Primary runtime: nerdctl + containerd (rootless)

This is the default development runtime. Install nerdctl and containerd
following the [nerdctl documentation](https://github.com/containerd/nerdctl).

### 1.2 Optional: Docker Engine (rootful testing)

Docker Engine is required for `make test-docker` and rootful testing.

```bash
# Ubuntu 24.04
sudo apt-get update
sudo apt-get install -y docker.io docker-buildx

# Add your user to the docker group.
sudo usermod -aG docker "$USER"

# Apply the group change — log out and back in.
# Verify after re-login.
docker --version
docker buildx version
```

> **Do not use `newgrp docker`** as a shortcut to apply the group change.
> It sets `docker` as the primary GID, which breaks Podman's `newuidmap`
> if Podman is also installed. A full logout/login picks up `docker` as a
> supplementary group and avoids this conflict.

Docker Engine coexists safely with rootless nerdctl/containerd. Docker runs
a system-level containerd at `/run/containerd/containerd.sock`, while rootless
nerdctl runs a user-space containerd at `~/.local/share/containerd/`. They use
separate storage and do not conflict.

### 1.3 Optional: Podman (rootless testing)

Podman is required for `make test-podman`.

```bash
# Ubuntu 24.04
sudo apt-get update
sudo apt-get install -y podman
```

Podman rootless requires `crun` and `fuse-overlayfs`:

```bash
sudo apt-get install -y crun
```

Configure Podman to use `crun` and `fuse-overlayfs`:

```ini
# ~/.config/containers/containers.conf
[engine]
runtime = "crun"
```

```ini
# ~/.config/containers/storage.conf
[storage]
driver = "overlay"

[storage.options.overlay]
mount_program = "/usr/local/bin/fuse-overlayfs"
```

> **Known limitation**: Podman's `--userns=keep-id` requires kernel support
> for unprivileged private mounts. This does not work in Parallels Desktop
> VMs due to kernel restrictions on mount propagation. Testing on bare-metal
> Ubuntu or non-Parallels VMs is pending. See §16 for testing status.

---

## 2. Design Goals

1. **One image, any developer** — a pre-built image from GHCR works for any
   developer without rebuilding. User identity is provided at run time, not
   baked in at build time.
2. **Bind-mounted source** — the developer's host project directory is
   mounted into the container. Edits inside the container are live on the host.
3. **Correct file permissions** — the container process runs with the host
   user's UID/GID so that bind-mounted files are readable and writable.
4. **Works in all three target environments** — local rootless nerdctl, local
   rootful Docker, and Kubernetes.
5. **Secure by default** — non-root inside the container in rootful runtimes.
   In rootless runtimes, container UID 0 is already unprivileged on the host.

---

## 3. Architecture: Runtime-Adaptive User

### Previous design (build-time user)

The Dockerfile created a user at build time via `ARG USERNAME=dev`. The
username, UID, GID, and home directory were frozen in the image. Any developer
whose identity differed from the baked-in values had to rebuild the image.

### New design (runtime-adaptive user)

The image ships with a **generic fallback user** (`dev:1000:1000`) for CI and
Kubernetes. At run time, the **entrypoint script** reads host identity from
environment variables and creates or adapts the in-container user to match.

```
Host                          Container
─────                         ─────────
$(whoami)  → HOST_USER  ───→  entrypoint.sh creates user
$(id -u)   → HOST_UID   ───→  with matching UID
$(id -g)   → HOST_GID   ───→  and matching GID
$(pwd)     → -v mount   ───→  /workspace (bind mount)
```

---

## 4. File Inventory

```
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
└── USER_GUIDE.md          ← this file
```

---

## 5. Dockerfile Changes

> **Note**: This section documents the design of `Dockerfile` (Alire-managed
> toolchain). `Dockerfile.system` follows the same structure but installs GNAT
> and GPRBuild from Ubuntu's apt repositories instead of Alire, omits the
> `alr toolchain --select` step, and uses `update-alternatives` to create
> unversioned `gnat` symlinks. See §0 for the rationale.

### 5.1 Fix the ENV PATH bug

The current single `ENV` block resolves `${HOME}` against its value _before_
the instruction runs (which is `/root` in the base image). Split into two
instructions:

```dockerfile
ENV HOME=/home/${USERNAME}
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    PATH=${HOME}/.local/bin:/usr/local/bin:${PATH} \
    SHELL=/usr/bin/zsh \
    TERM=xterm-256color \
    TZ=UTC
```

### 5.2 Install gosu

Add `gosu` to the base packages list. `gosu` is a lightweight
privilege-dropping tool designed for container entrypoints. It is preferred
over `sudo` or `su` because it execs directly (no intermediate shell, no TTY
issues).

```dockerfile
RUN apt-get update && apt-get install -y --no-install-recommends \
    ...
    gosu \
    ...
```

### 5.3 Remove the commented-out package

Remove the commented-out `zsh-history-substring-search` line entirely.

### 5.4 Add entrypoint.sh

Copy the entrypoint script into the image and set it as `ENTRYPOINT`. The
`CMD` remains `zsh -l` so that it can be overridden.

```dockerfile
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/bin/zsh", "-l"]
```

### 5.5 Keep build-time user creation

The build-time user (`dev:1000:1000`) is still created so that:
- Alire toolchain installation runs as non-root during the build.
- CI and Kubernetes have a working fallback user if no `HOST_*` env vars are
  passed.
- The `.zshrc` is placed in a known location during the build.

The `USER` directive remains so that the image's default user is non-root.

### 5.6 Change WORKDIR to /workspace

```dockerfile
WORKDIR /workspace
```

This is the fixed mount point. The entrypoint does not need to know the
username to determine the working directory.

---

## 6. Entrypoint Script (entrypoint.sh)

### 6.1 Responsibilities

1. Export container-detection environment variables (`IN_CONTAINER=1`,
   `CONTAINER_RUNTIME`) so that `.zshrc` can detect the container environment
   reliably without inspecting `/proc` or sentinel files.
2. Read `HOST_USER`, `HOST_UID`, `HOST_GID` from environment.
3. If they are set and the entrypoint is running as root:
   a. Create a group with the given GID (if it does not exist).
   b. Create or adapt a user with the given username, UID, GID, home
      directory, and shell.
   c. Copy the default `.zshrc` into the new home if it does not exist.
   d. Set ownership on the home directory.
   e. Detect whether the runtime is rootless or rootful.
   f. If rootful: drop privileges via `gosu` and exec the CMD.
   g. If rootless: stay as UID 0 (which is the host user), set
      `HOME=/home/$HOST_USER`, and exec the CMD.
4. If `HOST_*` vars are not set, fall through to the default user (`dev`)
   and exec the CMD directly.

**Important distinction**: In rootless mode, the user created in step 3b
exists for **home-directory shape, shell identity, `.zshrc` placement, and
prompt consistency** — not for the final process UID. The process stays as
container UID 0 (which maps to the host user). The created user is never
`gosu`'d into in rootless mode.

### 6.2 Rootless detection

The entrypoint detects rootless mode by checking whether UID 0 inside the
container maps to a non-root UID on the host:

```bash
is_rootless() {
    if [ -f /proc/self/uid_map ]; then
        # In rootless mode, UID 0 maps to a non-zero host UID.
        # The uid_map line looks like: "0  1000  1"
        local host_uid
        host_uid=$(awk '/^\s*0\s/ { print $2 }' /proc/self/uid_map)
        [ "$host_uid" != "0" ]
    else
        return 1
    fi
}
```

### 6.3 Privilege drop decision

```
if running as UID 0:
    if HOST_USER/HOST_UID/HOST_GID provided:
        create/adapt user
        if rootless:
            # Container UID 0 == host user. Dropping to HOST_UID would
            # map to an unmapped subordinate UID and break bind mounts.
            export HOME=/home/$HOST_USER
            exec "$@"                          # stay UID 0
        else (rootful):
            exec gosu "$HOST_USER" "$@"        # drop to real user
    else:
        # No host identity. Fall through to default user.
        exec gosu dev "$@"
else:
    # Already non-root (e.g., K8s securityContext). Just run.
    exec "$@"
fi
```

### 6.4 Error handling

- If `HOST_UID` is set but `HOST_USER` is not, default `HOST_USER` to `dev`.
- If `HOST_GID` is not set, default to the value of `HOST_UID`.
- The entrypoint must never prevent the container from starting.
- If user/group creation fails (e.g., UID conflict), the fallback is
  deterministic and depends on the runtime:
  - **Rootless**: log a warning, stay as UID 0 (which is the host user),
    set `HOME` to the fallback user's home (`/home/dev`), and exec the CMD.
  - **Rootful**: log a warning, drop to the fallback user via `gosu dev`,
    and exec the CMD.
  This ensures the failure mode is predictable — rootless always has bind
  mount access (UID 0 = host user), and rootful always runs non-root.

---

## 7. Makefile Changes

### 7.1 Remove hardcoded USERNAME default

```makefile
HOST_USER    ?= $(shell whoami)
HOST_UID     ?= $(shell id -u)
HOST_GID     ?= $(shell id -g)
```

`USERNAME` is kept for the build-time fallback user in the Dockerfile (still
defaults to `dev`).

### 7.2 Configurable container CLI

The container CLI defaults to `nerdctl` but is configurable so that the same
run targets work for Docker without duplicating recipes:

```makefile
CONTAINER_CLI ?= nerdctl
```

All run targets use `$(CONTAINER_CLI)` instead of hardcoding `nerdctl` or
`docker`. Dedicated `docker-build` and `docker-run` targets are kept as
convenience aliases that override the CLI:

```makefile
docker-run:
    $(MAKE) run CONTAINER_CLI=docker

docker-build:
    $(MAKE) build CONTAINER_CLI=docker
```

### 7.3 Revised targets

> **Important — Mount Point Selection**: Both `make run` and `make run-system`
> mount only the current directory. If your project uses Alire path pins with
> relative paths (e.g., `../deps26/AdaSAT-26.0.0`), you must mount high enough
> in the directory tree for those references to resolve inside the container.
> See the "Read Me First: Choosing the Right Mount Point" section in
> [README.md](README.md) for the three scenarios and examples.

```makefile
# Primary local workflow
run:
    $(CONTAINER_CLI) run -it --rm \
        -e HOST_UID=$(HOST_UID) \
        -e HOST_GID=$(HOST_GID) \
        -e HOST_USER=$(HOST_USER) \
        -v "$(PWD)":/workspace \
        -w /workspace \
        $(IMAGE_NAME)

# Diagnostic: run as root, no user adaptation
run-root:
    $(CONTAINER_CLI) run -it --rm \
        -u 0 \
        -v "$(PWD)":/workspace \
        -w /workspace \
        $(IMAGE_NAME)

# Shell in home directory instead of workspace
run-shell:
    $(CONTAINER_CLI) run -it --rm \
        -e HOST_UID=$(HOST_UID) \
        -e HOST_GID=$(HOST_GID) \
        -e HOST_USER=$(HOST_USER) \
        -v "$(PWD)":/workspace \
        $(IMAGE_NAME)

# Build
build:
    $(CONTAINER_CLI) build \
        --build-arg GNAT_VERSION=$(GNAT_VERSION) \
        --build-arg GPRBUILD_VERSION=$(GPRBUILD_VERSION) \
        -t $(IMAGE_NAME) .

# Docker convenience aliases
docker-run:
    $(MAKE) run CONTAINER_CLI=docker

docker-build:
    $(MAKE) build CONTAINER_CLI=docker

# Podman convenience aliases
# --userns=keep-id maps the host user directly; no HOST_* vars needed.
podman-build:
    $(MAKE) build CONTAINER_CLI=podman

podman-run:
    podman run -it --rm \
        --userns=keep-id \
        -v "$(CURDIR)":/workspace \
        -w /workspace \
        $(IMAGE_NAME)
```

Note: `USER_UID`, `USER_GID`, `USERNAME` build args are no longer needed in
the build targets because the image ships with a fixed fallback user. The
Alire toolchain is installed during the build under that fallback user.

### 7.4 Housekeeping targets

```makefile
# Remove build artifacts (dist/, source archives)
clean:
    rm -rf dist/
    rm -f $(PROJECT_NAME).tar.gz

# Create a compressed source archive from HEAD
compress:
    git archive --format=tar.gz --prefix=$(PROJECT_NAME)/ \
        -o $(PROJECT_NAME).tar.gz HEAD
```

`PROJECT_NAME` defaults to `dev_container_ada` and is used as the archive
filename and internal directory prefix.

### 7.5 Help target update

Update the help text to reflect the new targets and the `HOST_USER`,
`HOST_UID`, `HOST_GID` variables.

---

## 8. README Changes

### 8.1 Deployment Environments section

Add a section describing the three supported environments:

**Local development (nerdctl rootless)**
- Primary workflow.
- `make run` passes host identity and mounts the current directory.
- The entrypoint adapts the container user to match the host user.
- In rootless mode, container UID 0 maps to the host user via user namespace.
  This is safe — no privilege escalation is possible.

**CI / Docker rootful**
- Image runs as the fallback non-root user (`dev:1000:1000`) by default.
- `make docker-run` passes host identity for local Docker use.
- GitHub Actions workflows build and publish the image.

**Kubernetes**
- Image is compatible out of the box.
- Source code is provisioned via PersistentVolumeClaims or init containers
  (e.g., git-sync), not bind mounts.
- Pod spec should include:

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
```

- `fsGroup: 1000` ensures the volume is writable by the container user.
- Kubernetes manifests and Helm charts are not included. Teams should create
  these per their cluster policies.

### 8.2 Rootless security note

Add a short paragraph explaining why `-u 0` / staying as UID 0 in rootless
mode is safe:

> In rootless container runtimes (nerdctl/containerd rootless, Podman
> rootless), the container runs inside a user namespace where container UID 0
> maps to the unprivileged host user. The process cannot escalate beyond the
> host user's privileges. The entrypoint script detects this and avoids
> dropping privileges, because doing so would map the process to a subordinate
> UID that cannot access bind-mounted host files.

---

## 9. Container Detection (.zshrc)

### Previous approach (unreliable under nerdctl/containerd)

The current detection logic checks `/.dockerenv`, `/run/.containerenv`, and
`/proc/1/cgroup`. Under nerdctl/containerd, none of these may be present.
PID-based heuristics (`$$` = 1, process name checks) are fragile because
process names change if someone overrides `CMD`.

### New approach (entrypoint-exported marker)

The entrypoint script exports `IN_CONTAINER=1` and `CONTAINER_RUNTIME` as
environment variables before exec'ing the shell. The `.zshrc` then checks
these directly:

```bash
# Container detection — trust the entrypoint marker first
if [[ -n "$IN_CONTAINER" ]] && (( IN_CONTAINER )); then
    # Already set by entrypoint.sh — nothing to do.
    :
elif [[ -f /.dockerenv ]]; then
    ...existing fallback checks...
fi
```

This is simpler, more reliable, and works across all container runtimes. The
existing fallback checks (`/.dockerenv`, `/run/.containerenv`,
`/proc/1/cgroup`) are kept for cases where the `.zshrc` is used outside this
image (e.g., copied to another container that lacks the entrypoint).

The entrypoint sets these variables as follows:

```bash
export IN_CONTAINER=1
if is_rootless; then
    export CONTAINER_RUNTIME="rootless"
else
    export CONTAINER_RUNTIME="docker"
fi
```

---

## 10. CI Workflow Adjustments

### 10.1 docker-build.yml

- Remove `USER_UID` and `USER_GID` build args (no longer needed).
- Remove the duplicate matrix entry. The current matrix has two entries
  ("default" and "stable") with identical versions. Keep a single entry now
  and add a real second GNAT version when one is actually needed.

### 10.2 docker-publish.yml

- Remove `USER_UID` and `USER_GID` build args.
- No other changes needed.

### 10.3 Tag-triggered publish uses hardcoded defaults

When `docker-publish.yml` is triggered by a **tag push** (e.g., `gnat-16.0.0`),
`github.event.inputs` is not populated — that object is only set for
`workflow_dispatch` runs. The fallback values (`|| '15.2.1'` for GNAT,
`|| '25.0.1'` for GPRBuild) are used instead, so every tag push builds with the
hardcoded default versions regardless of the actual tag name.

This means a tag `gnat-16.0.0` would still build GNAT 15.2.1.

**Current workflow**: Update the default versions in the workflow file first,
commit, then create the tag. The tag serves as a release marker, not as the
version source.

**Future improvement**: Parse the tag name into `GNAT_VERSION` and
`GPRBUILD_VERSION` so that the tag drives the build. This is deferred until a
second GNAT version is actually needed.

---

## 11. Security Model Summary

| Runtime             | Container UID 0 is... | Bind mount access via... | Security boundary        |
|---------------------|-----------------------|--------------------------|--------------------------|
| Docker rootful      | Real root (dangerous) | gosu drop to HOST_UID    | Container isolation      |
| nerdctl rootless    | Host user (safe)      | Stay UID 0 (= host user) | User namespace           |
| Podman rootless     | Host user (safe)      | --userns=keep-id         | User namespace           |
| Kubernetes          | Blocked by policy     | fsGroup in pod spec      | Pod security standards   |

---

## 12. Resolved Questions

1. **gosu vs su-exec**: `gosu` — more common in Docker ecosystems, available
   in Ubuntu apt. **Decided.**

2. **Container detection**: Entrypoint exports `IN_CONTAINER=1` and
   `CONTAINER_RUNTIME` as environment variables. `.zshrc` checks those first,
   with existing sentinel/cgroup checks as fallback. **Decided.**

3. **Workspace path**: `/workspace` — fixed mount point, decoupled from
   username. **Decided.**

4. **docker-build.yml matrix**: Remove the duplicate entry. Add a real second
   GNAT version when one is actually needed. **Decided.**

5. **Configurable container CLI**: `CONTAINER_CLI ?= nerdctl` with
   `docker-run` / `docker-build` as convenience aliases. **Decided.**

6. **Podman support**: Added `podman-build` and `podman-run` targets.
   `podman-build` delegates to the standard `build` target via
   `CONTAINER_CLI=podman`. `podman-run` does **not** delegate to the
   standard `run` target because Podman rootless requires a different
   invocation: `--userns=keep-id` replaces the `HOST_*` environment
   variables used by nerdctl and Docker. With `--userns=keep-id`, Podman
   maps the host UID/GID directly into the container, so the entrypoint
   detects a non-root UID and execs the CMD without user adaptation.
   **Decided.**

7. **sudo + passwordless sudo**: Kept intentionally. Development containers
   need `sudo` for installing ad-hoc packages during interactive sessions
   (e.g., `sudo apt-get install strace`). The passwordless configuration
   avoids interrupting workflow. In rootful runtimes, the entrypoint drops
   to a non-root user via `gosu`, so `sudo` is the only path back to
   elevated privileges. In rootless runtimes, container UID 0 is already
   unprivileged on the host, so `sudo` inside the container does not grant
   any additional host-level access. **Decided.**

## 13. Remaining Open Questions

None at this time.

---

## 14. Implementation Order

1. Create `entrypoint.sh`
2. Modify `Dockerfile` (ENV fix, gosu, entrypoint, remove commented package)
3. Modify `Makefile` (runtime-adaptive targets, remove build-time UID args)
4. Update `.zshrc` (container detection for nerdctl)
5. Update `README.md` (deployment environments, security note, K8s snippet)
6. Update CI workflows (remove USER_UID/USER_GID build args)
7. Test locally on nerdctl rootless
8. Test with Docker rootful (if available)

---

## 15. Upgrading Component Versions

### 15.1 Ubuntu base image

Both Dockerfiles pin their base image by digest for reproducibility.

**Dockerfile (Ubuntu 22.04)**:

```bash
nerdctl pull ubuntu:22.04
nerdctl image inspect ubuntu:22.04 \
  | python3 -c "import json,sys; d=json.load(sys.stdin); print(d[0]['RepoDigests'][0])"
# Update the FROM line in Dockerfile with the new digest.
```

**Dockerfile.system (Ubuntu 24.04)**:

```bash
nerdctl pull ubuntu:24.04
nerdctl image inspect ubuntu:24.04 \
  | python3 -c "import json,sys; d=json.load(sys.stdin); print(d[0]['RepoDigests'][0])"
# Update the FROM line in Dockerfile.system with the new digest.
```

Rebuild and test the affected image after updating.

### 15.2 Alire

1. Check the latest release at
   `https://github.com/alire-project/alire/releases`.
2. Download the new `alr-<version>-bin-x86_64-linux.zip` and compute its
   checksum:

   ```bash
   curl -sL -o /tmp/alr.zip \
     https://github.com/alire-project/alire/releases/download/v<version>/alr-<version>-bin-x86_64-linux.zip
   sha256sum /tmp/alr.zip
   ```

3. Update `ALIRE_VERSION`, `ALIRE_ZIP`, and `ALIRE_SHA256` in the Dockerfile.
4. Rebuild and verify that `alr version` reports the expected release.

### 15.3 GNAT and GPRBuild

**Alire-managed toolchain (`Dockerfile`)**:

1. Check available versions: `alr search gnat_native` and
   `alr search gprbuild`.
2. Update `GNAT_VERSION` and `GPRBUILD_VERSION` in:
   - `Dockerfile` (build-arg defaults)
   - `Makefile` (variable defaults)
   - `.github/workflows/docker-build.yml` (matrix)
   - `.github/workflows/docker-publish.yml` (input defaults and fallbacks)
3. Rebuild and verify: `alr version`, `alr toolchain`.

> **Note**: The Alire crate version (e.g., `gnat_native=15.2.1`) may differ
> from the version reported by the binary itself (`gnat --version` →
> `GNAT 15.2.0`). The Alire crate version reflects the packaging; use
> `alr version` or `alr toolchain` to see the authoritative installed versions.

**System toolchain (`Dockerfile.system`)**:

The system toolchain version is determined by Ubuntu's `gnat-13` package.
To upgrade, wait for Ubuntu to ship a newer `gnat-*` package (e.g.,
`gnat-14`), then update the `apt-get install` and `update-alternatives`
lines in `Dockerfile.system`. Update the `system-gnat-13` tag in
`.github/workflows/docker-publish.yml` to match.

### 15.4 Checklist

- [ ] Update version numbers / digests in all files listed above.
- [ ] Rebuild the Alire image: `make build-no-cache`.
- [ ] Rebuild the system image: `make build-system-no-cache`.
- [ ] Run each image and verify toolchain versions.
- [ ] Commit, tag, and push.

---

## 16. Pre-Release Testing Status

This section tracks testing gaps that should be resolved before the next
release. Remove or update entries as they are verified.

### Alire-managed toolchain image (`Dockerfile`)

| Area                              | Status       | Notes                                                        |
|-----------------------------------|--------------|--------------------------------------------------------------|
| Rootless nerdctl (local)          | Verified     | Ubuntu 22.04 base, nerdctl 2.2.1. Build + smoke test passed.|
| Docker rootful (macOS)            | Verified     | macOS host, Docker 29.2.1. User adaptation and smoke test passed. |
| GitHub Actions build workflow     | Verified     | v2.0.0 CI run passed (both matrix entries).                  |
| GitHub Actions publish workflow   | Verified     | v2.0.0 publish pushed both images to GHCR.                  |
| Podman rootless (local)           | Blocked      | `--userns=keep-id` fails in Parallels VM (kernel restriction). |
| Kubernetes deployment             | Not tested   | Image is designed to be compatible; no cluster available.    |

### System toolchain image (`Dockerfile.system`)

| Area                              | Status       | Notes                                                        |
|-----------------------------------|--------------|--------------------------------------------------------------|
| Rootless nerdctl (local)          | Verified     | Ubuntu 24.04 base, gnat-13, nerdctl 2.2.1. Build + smoke test passed. |
| Docker rootful (macOS)            | Verified     | macOS host, Docker 29.2.1. User adaptation and smoke test passed. |
| GitHub Actions build workflow     | Verified     | v2.0.0 CI run passed (both matrix entries).                  |
| GitHub Actions publish workflow   | Verified     | v2.0.0 publish pushed both images to GHCR.                  |
| Podman rootless (local)           | Blocked      | `--userns=keep-id` fails in Parallels VM (kernel restriction). |
| Kubernetes deployment             | Not tested   | Image is designed to be compatible; no cluster available.    |

---

Copyright (c) 2025 Michael Gardner, A Bit of Help, Inc.
SPDX-License-Identifier: BSD-3-Clause
