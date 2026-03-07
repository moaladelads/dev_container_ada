# ============================================================================
# Makefile
# ============================================================================
# Copyright (c) 2025 Michael Gardner, A Bit of Help, Inc.
# SPDX-License-Identifier: BSD-3-Clause
# See LICENSE file in the project root.
# ============================================================================
#
# Helpful targets for building, testing, tagging, and publishing the
# dev_container_ada image.
#
# User identity is passed at runtime via HOST_USER, HOST_UID, and HOST_GID.
# The image adapts to the host user at container startup via entrypoint.sh.
# ============================================================================

.DEFAULT_GOAL := help

# ----------------------------------------------------------------------------
# Terminal colors
# ----------------------------------------------------------------------------
CYAN             := \033[36m
GREEN            := \033[32m
NC               := \033[0m

# ----------------------------------------------------------------------------
# Project settings
# ----------------------------------------------------------------------------
PROJECT_NAME     ?= dev_container_ada

# ----------------------------------------------------------------------------
# Image settings
# ----------------------------------------------------------------------------
IMAGE_NAME       ?= dev-container-ada
IMAGE_REGISTRY   ?= ghcr.io/abitofhelp
IMAGE_REF        ?= $(IMAGE_REGISTRY)/$(IMAGE_NAME)

# ----------------------------------------------------------------------------
# Toolchain versions (build-time)
# ----------------------------------------------------------------------------
GNAT_VERSION     ?= 15.2.1
GPRBUILD_VERSION ?= 25.0.1

# ----------------------------------------------------------------------------
# Host identity (runtime — passed to entrypoint.sh)
# ----------------------------------------------------------------------------
HOST_USER        ?= $(shell whoami)
HOST_UID         ?= $(shell id -u)
HOST_GID         ?= $(shell id -g)

# ----------------------------------------------------------------------------
# Container CLI (override with CONTAINER_CLI=docker)
# ----------------------------------------------------------------------------
CONTAINER_CLI    ?= nerdctl

.PHONY: help
help:
	@echo "Targets:"
	@echo "  build            Build the image"
	@echo "  build-no-cache   Build the image without cache"
	@echo "  run              Run the image interactively (mounts current directory)"
	@echo "  run-root         Run the image as root, bypassing the entrypoint (diagnostic)"
	@echo "  run-shell        Run the image and open zsh in the user home directory"
	@echo "  inspect          Show configured image and runtime settings"
	@echo "  save             Save the image to dist/"
	@echo "  show-tags        Show suggested tags"
	@echo "  tag-gnat         Tag local image with GNAT version"
	@echo "  tag-latest       Tag local image as latest"
	@echo "  clean            Remove build artifacts (dist/, archives)"
	@echo "  compress         Create a compressed source archive from HEAD"
	@echo "  docker-build     Build with docker instead of nerdctl"
	@echo "  docker-run       Run with docker instead of nerdctl"
	@echo "  podman-build     Build with podman instead of nerdctl"
	@echo "  podman-run       Run with podman (uses --userns=keep-id)"
	@echo ""
	@echo "Variables:"
	@echo "  CONTAINER_CLI    Container CLI to use (default: nerdctl)"
	@echo "  HOST_USER        Host username (default: $$(whoami))"
	@echo "  HOST_UID         Host user ID (default: $$(id -u))"
	@echo "  HOST_GID         Host group ID (default: $$(id -g))"
	@echo "  GNAT_VERSION     GNAT version for build (default: 15.2.1)"
	@echo "  GPRBUILD_VERSION GPRBuild version for build (default: 25.0.1)"

# ----------------------------------------------------------------------------
# Build targets
# ----------------------------------------------------------------------------
.PHONY: build
build:
	$(CONTAINER_CLI) build \
		--build-arg GNAT_VERSION=$(GNAT_VERSION) \
		--build-arg GPRBUILD_VERSION=$(GPRBUILD_VERSION) \
		-t $(IMAGE_NAME) .

.PHONY: build-no-cache
build-no-cache:
	$(CONTAINER_CLI) build --no-cache \
		--build-arg GNAT_VERSION=$(GNAT_VERSION) \
		--build-arg GPRBUILD_VERSION=$(GPRBUILD_VERSION) \
		-t $(IMAGE_NAME) .

# ----------------------------------------------------------------------------
# Run targets
# ----------------------------------------------------------------------------
.PHONY: run
run:
	$(CONTAINER_CLI) run -it --rm \
		-e HOST_UID=$(HOST_UID) \
		-e HOST_GID=$(HOST_GID) \
		-e HOST_USER=$(HOST_USER) \
		-v "$(CURDIR)":/workspace \
		-w /workspace \
		$(IMAGE_NAME)

.PHONY: run-root
run-root:
	$(CONTAINER_CLI) run -it --rm \
		--entrypoint /usr/bin/zsh \
		-u 0 \
		-v "$(CURDIR)":/workspace \
		-w /workspace \
		$(IMAGE_NAME)

.PHONY: run-shell
run-shell:
	$(CONTAINER_CLI) run -it --rm \
		-e HOST_UID=$(HOST_UID) \
		-e HOST_GID=$(HOST_GID) \
		-e HOST_USER=$(HOST_USER) \
		-v "$(CURDIR)":/workspace \
		-w /home/$(HOST_USER) \
		$(IMAGE_NAME)

# ----------------------------------------------------------------------------
# Docker convenience aliases
# ----------------------------------------------------------------------------
.PHONY: docker-build
docker-build:
	$(MAKE) build CONTAINER_CLI=docker

.PHONY: docker-run
docker-run:
	$(MAKE) run CONTAINER_CLI=docker

# ----------------------------------------------------------------------------
# Podman convenience aliases
# ----------------------------------------------------------------------------
# Podman rootless uses --userns=keep-id to map the host UID/GID directly
# into the container, so HOST_* env vars and entrypoint adaptation are not
# needed.  The entrypoint detects a non-root UID and execs the CMD directly.
# ----------------------------------------------------------------------------
.PHONY: podman-build
podman-build:
	$(MAKE) build CONTAINER_CLI=podman

.PHONY: podman-run
podman-run:
	podman run -it --rm \
		--userns=keep-id \
		-v "$(CURDIR)":/workspace \
		-w /workspace \
		$(IMAGE_NAME)

# ----------------------------------------------------------------------------
# Image management
# ----------------------------------------------------------------------------
.PHONY: inspect
inspect:
	@echo "IMAGE_NAME       = $(IMAGE_NAME)"
	@echo "IMAGE_REF        = $(IMAGE_REF)"
	@echo "CONTAINER_CLI    = $(CONTAINER_CLI)"
	@echo "GNAT_VERSION     = $(GNAT_VERSION)"
	@echo "GPRBUILD_VERSION = $(GPRBUILD_VERSION)"
	@echo "HOST_USER        = $(HOST_USER)"
	@echo "HOST_UID         = $(HOST_UID)"
	@echo "HOST_GID         = $(HOST_GID)"

.PHONY: save
save:
	mkdir -p dist
	$(CONTAINER_CLI) save -o dist/$(IMAGE_NAME)-gnat-$(GNAT_VERSION).tar $(IMAGE_NAME)

.PHONY: show-tags
show-tags:
	@echo "$(IMAGE_REF):latest"
	@echo "$(IMAGE_REF):gnat-$(GNAT_VERSION)"
	@echo "$(IMAGE_REF):gnat-$(GNAT_VERSION)-gprbuild-$(GPRBUILD_VERSION)"

.PHONY: tag-gnat
tag-gnat:
	$(CONTAINER_CLI) tag $(IMAGE_NAME) $(IMAGE_REF):gnat-$(GNAT_VERSION)
	$(CONTAINER_CLI) tag $(IMAGE_NAME) $(IMAGE_REF):gnat-$(GNAT_VERSION)-gprbuild-$(GPRBUILD_VERSION)

.PHONY: tag-latest
tag-latest:
	$(CONTAINER_CLI) tag $(IMAGE_NAME) $(IMAGE_REF):latest

# ----------------------------------------------------------------------------
# Cleanup
# ----------------------------------------------------------------------------
.PHONY: clean
clean:
	@echo "$(CYAN)Removing build artifacts...$(NC)"
	rm -rf dist/
	rm -f $(PROJECT_NAME).tar.gz
	@echo "$(GREEN)✓ Clean complete.$(NC)"

# ----------------------------------------------------------------------------
# Source archive
# ----------------------------------------------------------------------------
.PHONY: compress
compress:
	@echo "$(CYAN)Creating compressed source archive...$(NC)"
	git archive --format=tar.gz --prefix=$(PROJECT_NAME)/ -o $(PROJECT_NAME).tar.gz HEAD
	@echo "$(GREEN)✓ Archive created: $(PROJECT_NAME).tar.gz$(NC)"
