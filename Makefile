.DEFAULT_GOAL := help
COMPOSE  := docker compose
TOFU_DIR := infrastructure/environments/dev
TF_ARGS  ?=
AUTO_APPROVE ?= false

.PHONY: help up down init fmt fmt-check validate plan apply destroy package test test-integration security inject-poison inject-outage ui ui-url

help:
	@printf "%-16s %s\n" \
		up "start local floci + feint environment" \
		down "stop local floci + feint environment" \
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
		security "run trivy report plus secret, iac and dependency gates" \
		inject-poison "inject a poison job and watch it reach the dlq" \
		inject-outage "stop the emulator briefly to exercise api health alerting" \
		ui "print the web console url" \
		ui-url "print the ready-to-paste api base url for the console"

ui:
	@echo "CloudForge console: http://localhost:8080/ (docker compose up -d webapp)"
	@$(MAKE) -s ui-url

ui-url:
	@echo "API base URL to paste in the console:"
	@echo "http://localhost:8080/floci/restapis/$$(cd $(TOFU_DIR) && tofu output -raw rest_api_id)/dev/_user_request_"

inject-poison:
	./scripts/failure-injection.sh poison-job

inject-outage:
	./scripts/failure-injection.sh emulator-outage

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
		find $$dest -name '__pycache__' -type d -prune -exec rm -rf {} +; \
		find $$dest -exec touch -d '@0' {} +; \
	done
	@echo "Lambda packages built under lambdas/*/build"

plan: package
	tofu -chdir=$(TOFU_DIR) plan $(TF_ARGS)

apply: package
	tofu -chdir=$(TOFU_DIR) apply -auto-approve=$(AUTO_APPROVE)

destroy:
	tofu -chdir=$(TOFU_DIR) destroy

test:
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

