# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
