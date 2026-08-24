#!/usr/bin/env bash
# End-to-end integration tests against a running Floci environment.
# Requires: curl, aws cli, jq-free python3, deployed infrastructure.
set -euo pipefail

TOFU_DIR="${TOFU_DIR:-infrastructure/environments/dev}"
ENDPOINT="${FLOCI_ENDPOINT:-http://localhost:4566}"
# The floci access key selects the isolated account (dev uses the "test" key).
export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-test}"
export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-test}"
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"
BASE="$ENDPOINT/restapis/$(tofu -chdir="$TOFU_DIR" output -raw rest_api_id)/dev/_user_request_"
AUTH="Authorization: Bearer ${API_TOKEN:-local-dev-token}"
BUCKET="$(tofu -chdir="$TOFU_DIR" output -raw artifacts_bucket_id)"
SUFFIX="$(date +%s)-$RANDOM"
PASS=0
FAILED=0

aws() { command aws --endpoint-url="$ENDPOINT" "$@"; }

check() {
  local name="$1" expected="$2" actual="$3"
  if [ "$actual" = "$expected" ]; then
    echo "ok   $name ($actual)"
    PASS=$((PASS + 1))
  else
    echo "FAIL $name (expected $expected, got $actual)"
    FAILED=$((FAILED + 1))
  fi
}

status_of() { curl -s -o /tmp/cf-body.json -w '%{http_code}' "$@"; }
json_path() { python3 -c "import json;obj=json.load(open('/tmp/cf-body.json'));print(eval(\"obj$1\"))"; }

echo "== authentication =="
check "reject missing token"  401 "$(status_of "$BASE/users")"
check "reject wrong token"    401 "$(status_of -H 'Authorization: Bearer nope' "$BASE/users")"

echo "== users =="
check "create user"           201 "$(status_of -XPOST -H "$AUTH" -d "{\"name\":\"CI Runner\",\"email\":\"ci-$SUFFIX@example.com\"}" "$BASE/users")"
USER_ID="$(json_path "['user']['pk']")"
check "duplicate email"       409 "$(status_of -XPOST -H "$AUTH" -d "{\"name\":\"Dup\",\"email\":\"ci-$SUFFIX@example.com\"}" "$BASE/users")"
check "get user"              200 "$(status_of -H "$AUTH" "$BASE/users/$USER_ID")"
check "update user"           200 "$(status_of -XPUT -H "$AUTH" -d "{\"name\":\"CI Runner 2\",\"email\":\"ci-$SUFFIX@example.com\"}" "$BASE/users/$USER_ID")"

echo "== projects lifecycle =="
check "create draft project"  201 "$(status_of -XPOST -H "$AUTH" -d "{\"name\":\"ci-project-$SUFFIX\",\"owner\":\"$USER_ID\"}" "$BASE/projects")"
PROJECT_ID="$(json_path "['project']['pk']")"
put_status() { status_of -XPUT -H "$AUTH" -d "{\"name\":\"ci-project-$SUFFIX\",\"owner\":\"$USER_ID\",\"status\":\"$1\"}" "$BASE/projects/$PROJECT_ID"; }
check "unknown owner"         400 "$(status_of -XPOST -H "$AUTH" -d '{"name":"x","owner":"usr-none"}' "$BASE/projects")"
check "transition active"     200 "$(put_status active)"
check "transition archived"   200 "$(put_status archived)"
check "illegal reopen"        409 "$(put_status active)"

echo "== artifacts =="
CONTENT="$(printf 'cloudforge ci artifact %s' "$SUFFIX" | base64)"
check "upload artifact"       201 "$(status_of -XPOST -H "$AUTH" -d "{\"filename\":\"ci.txt\",\"content_base64\":\"$CONTENT\"}" "$BASE/projects/$PROJECT_ID/artifacts")"
if aws s3api head-object --bucket "$BUCKET" --key "projects/$PROJECT_ID/ci.txt" > /dev/null 2>&1; then HEAD_STATUS=200; else HEAD_STATUS=404; fi
check "artifact in s3"        200 "$HEAD_STATUS"

echo "== event flow =="
BEFORE="$(aws s3 ls "s3://$BUCKET/artifacts/" | wc -l)"
status_of -XPOST -H "$AUTH" -d "{\"name\":\"Streamy\",\"email\":\"stream-$SUFFIX@example.com\"}" "$BASE/users" > /dev/null
STREAM_OK=0
for _ in $(seq 1 15); do
  sleep 3
  AFTER="$(aws s3 ls "s3://$BUCKET/artifacts/" | wc -l)"
  if [ "$AFTER" -gt "$BEFORE" ] && [ "$(aws sqs get-queue-attributes --queue-url "$ENDPOINT/000000000000/cloudforge-dev-jobs" --attribute-names ApproximateNumberOfMessages --query Attributes.ApproximateNumberOfMessages --output text)" = "0" ]; then
    STREAM_OK=1
    break
  fi
done
check "stream produced artifact and drained queue" 1 "$STREAM_OK"

echo "== observability =="
EXPORTER_URL="${EXPORTER_URL:-http://localhost:9877}"
PROMETHEUS_URL="${PROMETHEUS_URL:-http://localhost:9090}"
GRAFANA_URL="${GRAFANA_URL:-http://localhost:3000}"
METRICS_OK=0
if curl -sf "$EXPORTER_URL/metrics" | grep -q 'cloudforge_sqs_messages'; then METRICS_OK=1; fi
check "exporter exposes metrics" 1 "$METRICS_OK"
PROM_OK=0
if curl -s --get "$PROMETHEUS_URL/api/v1/query" --data-urlencode 'query=cloudforge_dynamodb_items' | grep -q '"result"'; then PROM_OK=1; fi
check "prometheus serves queries" 1 "$PROM_OK"
GRAFANA_OK=0
if curl -sf "$GRAFANA_URL/api/health" > /dev/null; then GRAFANA_OK=1; fi
check "grafana healthy" 1 "$GRAFANA_OK"

echo
if [ "$FAILED" -ne 0 ]; then
  echo "integration tests: $FAILED failed, $PASS passed"
  exit 1
fi
echo "integration tests: all $PASS checks passed"
