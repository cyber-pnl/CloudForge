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

## 2. Start Floci

```bash
docker compose up -d
```

Verify that Floci is running:

```bash
aws --endpoint-url=http://localhost:4566 s3 ls
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

```bash
tofu apply
```

## 7. Run tests

From the repository root:

```bash
pytest
```

## 8. Run security scans

```bash
trivy fs .
```

## Cleanup

Destroy the local infrastructure:

```bash
tofu destroy
```

Stop Floci:

```bash
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
