cnf ?= config.env
include $(cnf)
export $(shell sed 's/=.*//' $(cnf))

DOCKER_REPO=carlosmarte
TARGET=base
PORT=3000
APP_NAME=alpine3_14_nodejs17_6_$(TARGET)
APP_VERSION=latest

.PHONY: help

help: ## This help.
	@echo Target: $(TARGET)
	@echo App Name Release: $(APP_NAME)
	@echo make up TARGET=base
	@echo make up TARGET=sandbox_nodejs
	@echo make up TARGET=sandbox_postgresql
	@echo make up TARGET=sandbox_redis
	@echo make up TARGET=sandbox_bash
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
# @grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help

help-release: ## Release options
	@echo make release TARGET=base
	@echo make release TARGET=dev_postgresql
	@echo make release TARGET=dev_redis
	
build: ## Build the container
	@echo Target: $(TARGET)
	docker build -t $(APP_NAME) --target $(TARGET) .
	
build-nc: ## Build the container without caching
	@echo Target: $(TARGET)
	docker build --no-cache -t $(APP_NAME) --target $(TARGET) .

run: ## Run container on port configured in `config.env`
	docker run -i -t --rm --env-file=./config.env -p=$(PORT):$(PORT) --name="$(APP_NAME)" $(APP_NAME)

up: build run ## Run container on port configured in `config.env` (Alias to run)

stop: ## Stop and remove a running container
	docker stop $(APP_NAME); docker rm $(APP_NAME)

cleanup:
	docker container prune --force --filter "until=10h"

publish-latest: ## Stop and remove a running container
	@echo Docker Repo: $(DOCKER_REPO)
	@echo App Name: $(APP_NAME)
	docker push $(DOCKER_REPO)/$(APP_NAME):$(APP_VERSION)

login: ## check login status
	docker login

release: login build-nc publish-latest ## Prepare build and release

tag-latest: ## Generate container `{version}` tag
	@echo Docker Repo: $(DOCKER_REPO)
	@echo App Name: $(APP_NAME)
	docker build --no-cache -t $(APP_NAME) --target $(TARGET) .
	docker tag $(APP_NAME):$(APP_VERSION) $(DOCKER_REPO)/$(APP_NAME):$(APP_VERSION)
	docker push $(DOCKER_REPO)/$(APP_NAME):$(APP_VERSION)