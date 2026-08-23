.DEFAULT_GOAL := help
COMPOSE  := docker compose
TOFU_DIR := infrastructure/environments/dev

.PHONY: help up down init fmt fmt-check validate plan apply destroy test security

help:
	@printf "%-12s %s\n" \
		up "start local floci environment" \
		down "stop local floci environment" \
		init "initialize opentofu working directory" \
		fmt "format opentofu files" \
		fmt-check "check opentofu formatting" \
		validate "validate opentofu configuration" \
		plan "show infrastructure plan" \
		apply "apply infrastructure plan" \
		destroy "destroy local infrastructure" \
		test "run unit tests" \
		security "run trivy security scan"

up:
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

init:
	tofu -chdir=$(TOFU_DIR) init

fmt:
	tofu -chdir=infrastructure fmt -recursive

fmt-check:
	tofu -chdir=infrastructure fmt -check -recursive

validate:
	tofu -chdir=$(TOFU_DIR) validate

plan:
	tofu -chdir=$(TOFU_DIR) plan

apply:
	tofu -chdir=$(TOFU_DIR) apply

destroy:
	tofu -chdir=$(TOFU_DIR) destroy

test:
	pytest

security:
	trivy fs .
