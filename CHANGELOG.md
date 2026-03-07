# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0-rc] - 2026-03-06

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
  `run-shell`, `inspect`, `save`, `show-tags`, `tag-gnat`, `tag-latest`,
  `clean`, `compress`.
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
