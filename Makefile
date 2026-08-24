.DEFAULT_GOAL := help
COMPOSE  := docker compose
TOFU_DIR := infrastructure/environments/dev
TF_ARGS  ?=
AUTO_APPROVE ?= false

.PHONY: help up down init fmt fmt-check validate plan apply destroy package test test-integration security

help:
	@printf "%-16s %s\n" \
		up "start local floci environment" \
		down "stop local floci environment" \
		init "initialize opentofu working directory" \
		fmt "format opentofu files" \
		fmt-check "check opentofu formatting" \
		validate "validate opentofu configuration" \
		package "build lambda packages with vendored dependencies" \
		plan "show infrastructure plan (runs package first)" \
		apply "apply infrastructure plan (runs package first)" \
		destroy "destroy local infrastructure" \
		test "install dev requirements and run unit tests" \
		test-integration "run end-to-end integration tests against floci" \
		security "run trivy report plus secret, iac and dependency gates"

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

package:
	@for src in lambdas/*/; do \
		name=$$(basename $$src); \
		if [ "$$name" = "common" ]; then continue; fi; \
		dest=lambdas/$$name/build; \
		rm -rf $$dest && mkdir -p $$dest; \
		cp $$src*.py $$dest/; \
		cp lambdas/common/*.py $$dest/; \
		if [ -f $$src/requirements.txt ]; then \
			echo "Vendoring dependencies for $$name"; \
			python3 -m pip install -q --disable-pip-version-check -r $$src/requirements.txt -t $$dest; \
		fi; \
	done
	@echo "Lambda packages built under lambdas/*/build"

plan: package
	tofu -chdir=$(TOFU_DIR) plan $(TF_ARGS)

apply: package
	tofu -chdir=$(TOFU_DIR) apply -auto-approve=$(AUTO_APPROVE)

destroy:
	tofu -chdir=$(TOFU_DIR) destroy

test:
	python3 -m pip install -q --disable-pip-version-check -r requirements-dev.txt
	pytest

test-integration:
	./scripts/integration-tests.sh

security: package
	@echo "== Trivy report (all findings, informational) =="
	-@trivy fs --scanners misconfig,secret,vuln .
	@echo "== Gate: secrets (any finding fails) =="
	git check-ignore -q infrastructure/environments/dev/terraform.tfstate || \
		(echo "terraform.tfstate must stay git-ignored"; exit 1)
	trivy fs --scanners secret --skip-files "**/terraform.tfstate" --exit-code 1 .
	@echo "== Gate: IaC misconfigurations (HIGH and CRITICAL fail) =="
	trivy fs --scanners misconfig --severity HIGH,CRITICAL --exit-code 1 .
	@echo "== Gate: dependency vulnerabilities (HIGH and CRITICAL fail) =="
	trivy fs --scanners vuln --severity HIGH,CRITICAL --exit-code 1 .
	@echo "All security gates passed."

