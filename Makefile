
SHELLCHECK = shellcheck
SHELLCHECK_OPTS = -x -s bash

SHELL_SCRIPTS = $(shell find . -type f -name '*.sh')

.PHONY: shellcheck
shellcheck: $(SHELL_SCRIPTS)
	$(SHELLCHECK) $(SHELLCHECK_OPTS) $(SHELL_SCRIPTS)

DOCKER_IMAGE=cloud-backup

# build docker image
.PHONY: build_docker_debian
build_docker_debian:
	docker build -t $(DOCKER_IMAGE):debian . -f ./docker/debian/Dockerfile

.PHONY: build_docker_alpine
build_docker_alpine:
	docker build -t $(DOCKER_IMAGE):alpine . -f ./docker/alpine/Dockerfile

.PHONY: build_docker
build_docker: build_docker_debian build_docker_alpine

# default action -> build_docker
.DEFAULT_GOAL := build_docker
