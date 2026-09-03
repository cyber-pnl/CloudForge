# Getting Started

## Requirements

Install:

* Docker
* Docker Compose
* OpenTofu
* AWS CLI
* Python
* Git
* Trivy

Verify:

```bash
docker --version
tofu version
aws --version
python --version
trivy --version
```

## 1. Clone the repository

```bash
git clone https://github.com/<your-user>/cloudforge.git
cd cloudforge
```

## 2. Start the local environment

```bash
docker compose up -d
```

This starts all services: Floci (AWS), Floci-AZ (Azure), the unified gateway,
the observability stack and the web console.

Verify that both emulators are running:

```bash
curl -sf http://localhost:4566/_localstack/health | python3 -m json.tool | head -3   # Floci
curl -sf http://localhost:4577/health             | python3 -m json.tool | head -3   # Floci-AZ
```

Test the unified gateway (all traffic routed to Floci / AWS):

```bash
curl -sf http://localhost:4600/_localstack/health | head -c 80
```

## 3. Initialize OpenTofu

```bash
cd infrastructure/environments/dev
tofu init
```

## 4. Validate the infrastructure

```bash
tofu fmt -check
tofu validate
```

## 5. Review the infrastructure plan

```bash
tofu plan
```

Inspect the plan carefully — do not blindly apply.

## 6. Deploy locally

The dev environment (see `docs/04-devops/deployment-strategy.md` for staging
and prod):

```bash
tofu apply
```

To run the integration suite against another environment:

```bash
TOFU_DIR=infrastructure/environments/staging ./scripts/integration-tests.sh
```

## 7. Web console

A browser console manages users, projects and artifacts without curl:

```bash
docker compose up -d webapp   # serves http://localhost:8080
make ui-url                   # prints the API base URL to paste in the console
```

Paste both values in the header (token: `local-dev-token` for dev) and hit
Save. The console talks to the API through a same-origin nginx proxy
(`/floci/` → `localhost:4566`), so no CORS setup is involved; direct browser
calls to the execute plane also work since responses carry CORS headers.

## 8. Run tests

From the repository root (inside a virtual environment, see `requirements-dev.txt`):

```bash
pytest
```

## 8. Run security scans

The full scanner matrix with gates (secrets, IaC, dependencies):

```bash
make security
```

## 9. Observability stack

Start the metrics pipeline alongside Floci:

```bash
docker compose up -d
```

| Service | URL | Purpose |
| ------- | --- | ------- |
| Unified gateway | http://localhost:4600 | Routes traffic to Floci (AWS) |
| Exporter | http://localhost:9877/metrics | Prometheus-format metrics polled from Floci |
| Prometheus | http://localhost:9090 | Scrapes the exporter, evaluates alert rules |
| Grafana | http://localhost:3000 | Provisioned "CloudForge Overview" dashboard (anonymous viewer, admin/admin for editing) |

Alert rules live in `observability/prometheus/rules.yml` — `DeadLetterQueueNotEmpty`
fires when the dead-letter queue holds messages. CloudWatch alarms defined in
Terraform document the same intent but are not evaluated by the emulator (see
`docs/02-infrastructure/local-environment.md`).

## Cleanup

Destroy the local infrastructure:

```bash
# Primary (AWS)
aws s3 rm s3://cloudforge-dev-artifacts --recursive
tofu -chdir=infrastructure/environments/dev destroy

# Secondary (Azure DR)
tofu -chdir=infrastructure/environments/dev-az destroy

# Stop all services
docker compose down
```

## Makefile

To simplify the developer workflow, the project exposes common commands through a `Makefile`:

```bash
make up
make init
make fmt
make validate
make plan              # runs make package first
make apply             # runs make package first; add AUTO_APPROVE=true for non-interactive runs
make test
make test-integration
make security
make destroy
```

The goal is to make the project usable without requiring developers to remember every underlying command.

## Calling the APIs

The application APIs require bearer authentication (see ADR-002). The local execute-plane URL differs from real AWS:

```bash
BASE=http://localhost:4566/restapis/<api_id>/dev/_user_request_
TOKEN='Authorization: Bearer local-dev-token'

curl -H "$TOKEN" "$BASE/users"                                   # list users
curl -XPOST -H "$TOKEN" -d '{"name":"Ada","email":"ada@example.com"}' "$BASE/users"
curl -XPOST -H "$TOKEN" -d '{"name":"Apollo","owner":"<user_id>"}' "$BASE/projects"
curl -XPUT  -H "$TOKEN" -d '{"name":"Apollo","owner":"<user_id>","status":"active"}' "$BASE/projects/<project_id>"
```

Requests without a valid token are rejected with `401`.
