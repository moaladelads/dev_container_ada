# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.2.2] - 2026-03-11

### Fixed

- Added empty `libiconv.a` stub in Dockerfile to satisfy `-liconv` at link
  time. On glibc systems (Ubuntu), iconv is built into libc and there is no
  separate `libiconv` package, but GNATCOLL iconv links `-liconv` explicitly.

## [2.2.1] - 2026-03-09

### Added

- "Embedded Board Support" section in README with board table and two
  readiness tables (Alire image vs System image) showing Ada compiler and
  C cross-compiler availability per target.
- `alr`/`gprbuild` configuration examples in USER_GUIDE §0.4 for all four
  target/image combinations (desktop Alire, desktop System, Cortex-M7
  bare-metal, Cortex-A7 Linux).

### Fixed

- README badges placed on a single line for correct inline rendering.

## [2.2.0] - 2026-03-10

### Added

- Embedded development toolchain for both images:
  - ARM Cortex-M bare-metal cross-compiler (`gcc-arm-none-eabi`,
    `libnewlib-arm-none-eabi`) for STM32F769I and similar boards.
  - ARM Cortex-A Linux cross-compiler (`gcc-arm-linux-gnueabihf`,
    `libc6-dev-armhf-cross`) for STM32MP135F and similar boards.
  - Hardware tools: `openocd`, `stlink-tools`, `gdb-multiarch`.
- Embedded board support table in README and USER_GUIDE §0.4.
- Updated Dockerfile headers to document embedded development support.

## [2.1.1] - 2026-03-08

### Added

- Makefile `pull` and `pull-system` targets that pull from GHCR and tag for
  local use, so `make run` / `make run-system` work without building locally.
- Makefile convenience aliases: `docker-pull`, `docker-pull-system`,
  `podman-pull`, `podman-pull-system`.

## [2.1.0] - 2026-03-08

### Added

- Multi-architecture support (`linux/amd64` + `linux/arm64`) for the system
  toolchain image (`Dockerfile.system`). Docker pulls the native arm64 variant
  automatically on Apple Silicon.
- QEMU setup in CI workflows for cross-platform builds of the system image.
- Per-architecture Alire checksums (`ALIRE_SHA256_AMD64`, `ALIRE_SHA256_ARM64`)
  in `Dockerfile.system` with dynamic binary selection via `uname -m`.
- Architecture compatibility table and verified test matrix in README.
- USER_GUIDE §0.2 "Supported architectures" section documenting why the
  Alire-managed image is amd64-only.
- Makefile system image parity: `run-root-system`, `run-shell-system`,
  `save-system`, `show-tags-system`, `tag-system`, `tag-latest-system`.
- Makefile convenience aliases: `docker-build-system`, `docker-run-system`,
  `podman-build-system`, `podman-run-system`.

### Changed

- `docker-build.yml` now uses `docker buildx build` with per-matrix platform
  support: amd64-only for the Alire image, amd64+arm64 for the system image.
- `docker-publish.yml` adds `platforms: linux/amd64,linux/arm64` to the
  system image job, producing a multi-arch manifest on GHCR.
- Makefile help text reorganized into clear groups (Alire image, system image,
  Docker aliases, Podman aliases, general) with architecture info visible.
- USER_GUIDE §15.2 updated to document per-Dockerfile Alire upgrade steps.
- The Alire-managed image (`Dockerfile`) remains `linux/amd64` only. Alire
  2.1.0's aarch64 binary requires glibc 2.38 (Ubuntu 22.04 ships 2.35), and
  Alire does not distribute pre-built `gnat_native` toolchains for
  aarch64-linux.

## [2.0.1] - 2026-03-08

### Fixed

- Moved `# syntax=docker/dockerfile:1.7` to line 1 in both Dockerfiles so
  BuildKit actually uses the specified frontend.
- Added `entrypoint.sh` to "Files expected in the build context" header comment
  in both Dockerfiles.
- Removed orphan `examples/hello_ada/hello_ada.adb`; added copyright header to
  the actual source at `src/hello_ada.adb` and fixed GNAT comment style.
- Reject `HOST_USER=root` and `HOST_UID=0` in `entrypoint.sh` to prevent
  accidental modification of the container's root account.
- Added logging to `fixup_symlinks()` so relinked toolchain paths are visible.
- Fixed `alire.toml` author, maintainer, login, website, and "tdb" typo.
- Fixed USER_GUIDE version from 2.1 to 2.0.0.

### Added

- Makefile targets `test-system`, `test-docker-system`, `test-podman-system`
  with `TEST_SCRIPT_SYSTEM` for system-image testing.
- `make -f` usage note in README explaining `CURDIR` bind-mount behavior.

### Changed

- Unified CI build steps into a single matrix-driven step with `build_args`,
  `compile_cmd`, `gnat_cmd`, and `gprbuild_cmd` parameters.
- CI smoke test now matches Makefile test scripts (environment info, direct
  gprbuild for system variant, toolchain versions).

## [2.0.0] - 2026-03-08

### Added

- `Dockerfile.system` for Ubuntu 24.04 with system-packaged GNAT and GPRBuild.
- Makefile targets: `build-system`, `build-system-no-cache`, `run-system`.
- CI matrix build for both Dockerfile variants in `docker-build.yml`.
- Two-job publish workflow (`publish-alire` + `publish-system`) in
  `docker-publish.yml`.
- USER_GUIDE §0 "Choosing a Dockerfile" with rationale and guidance.
- Alire configured with `gnat_external` in system image so `alr build` uses
  the system compiler without downloading toolchains.

### Changed

- **BREAKING**: Default `Dockerfile` base image from Ubuntu 24.04 to Ubuntu
  22.04, matching the platform Alire's GNAT toolchains are built on.
- GitHub Actions pinned by SHA digest for supply-chain security.
- Documentation updated throughout for dual-Dockerfile structure.

## [1.0.0] - 2026-03-06

### Changed

- Promoted from 1.0.0-rc1 to stable release.

### Fixed

- Added `exports/` to `.dockerignore` to exclude temporary files from build
  context.
- Added `exports/` and `examples/` to repository layout in README and
  USER_GUIDE.
- Added `test`, `test-docker`, `test-podman` targets to CHANGELOG.
- Added Alire crate version vs binary version note in USER_GUIDE §15.3.
- Updated pre-release testing status in USER_GUIDE §16 to reflect verified
  GitHub Actions workflows and Docker rootful testing.

## [1.0.0-rc1] - 2026-03-06

### Added

- Ubuntu 24.04 base image pinned by digest for reproducibility.
- Alire 2.1.0 package manager with SHA256 checksum verification.
- GNAT 15.2.1 Ada compiler via Alire toolchain.
- GPRBuild 25.0.1 build system via Alire toolchain.
- Python 3 with venv support.
- Zsh interactive shell with autosuggestions and syntax highlighting.
- Runtime-adaptive user identity via `entrypoint.sh` — no rebuild needed
  per developer.
- Rootless detection via `/proc/self/uid_map` inspection.
- Rootful privilege drop via `gosu`.
- `DISPLAY_USER` environment variable for correct prompt identity in
  rootless mode.
- Container detection markers (`IN_CONTAINER`, `CONTAINER_RUNTIME`)
  exported by entrypoint for reliable `.zshrc` detection.
- Toolchain symlinks in `/usr/local/bin` for non-interactive contexts.
- Symlink fixup in entrypoint after home directory migration.
- Input validation for `HOST_UID`, `HOST_GID`, and `HOST_USER` in
  entrypoint with deterministic fallback on failure.
- Container-aware Zsh prompt with git branch and runtime indicator.
- `container_info` shell function for quick environment diagnostics.
- Makefile with targets: `build`, `build-no-cache`, `run`, `run-root`,
  `run-shell`, `test`, `test-docker`, `test-podman`, `inspect`, `save`,
  `show-tags`, `tag-gnat`, `tag-latest`, `clean`, `compress`.
- Docker convenience aliases: `docker-build`, `docker-run`.
- Podman convenience aliases: `podman-build`, `podman-run` with
  `--userns=keep-id`.
- Configurable container CLI via `CONTAINER_CLI` variable (default: nerdctl).
- GitHub Actions build workflow with smoke test.
- GitHub Actions publish workflow with gated `latest` tag.
- LICENSE, README, and USER_GUIDE copied into image at
  `/usr/share/doc/dev-container-ada/`.
- Comprehensive USER_GUIDE.md covering architecture, security model,
  version upgrade procedures, and design decisions.

### Security

- Base image pinned by SHA256 digest.
- Alire download verified with SHA256 checksum.
- `latest` tag only published on semver tags or explicit opt-in.
- `run-root` bypasses entrypoint to guarantee a true root shell.
- Passwordless sudo kept for development convenience; documented as an
  explicit design decision.
