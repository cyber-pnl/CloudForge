#!/usr/bin/env bash
# Controlled failure injection against the local CloudForge environment.
#
# Scenarios:
#   poison-job      send a well-formed job flagged simulate_failure; the worker
#                   fails maxReceiveCount times and the message lands in the DLQ.
#   emulator-outage stop the emulator container for a bounded window to exercise
#                   the API health probe and alerting path.
#
# Requirements: docker, aws cli pointed at http://localhost:4566, curl.
set -euo pipefail

ENDPOINT="${AWS_ENDPOINT_URL:-http://localhost:4566}"
export AWS_ENDPOINT_URL="$ENDPOINT"
export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-test}"
export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-test}"
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"
JOBS_QUEUE="$ENDPOINT/000000000000/cloudforge-dev-jobs"
DLQ_QUEUE="$ENDPOINT/000000000000/cloudforge-dev-jobs-dlq"
FLOCI_CONTAINER="${FLOCI_CONTAINER:-cloudforge-floci}"
EXPORTER_URL="${EXPORTER_URL:-http://localhost:9877/metrics}"

queue_depth() {
  aws sqs get-queue-attributes --queue-url "$1" \
    --attribute-names ApproximateNumberOfMessages \
    --query Attributes.ApproximateNumberOfMessages --output text
}

scenario_poison_job() {
  echo "== scenario: poison job -> retries -> dead-letter queue =="
  local before after
  before="$(queue_depth "$DLQ_QUEUE")"
  local payload
  payload='{"detail":{"event_name":"INSERT","new_image":{"entity":"incident","id":"poison","simulate_failure":true}}}'
  # The aws cli v2.31.x on python 3.14 crashes on sqs send-message, so enqueue
  # through the vendored boto3 shipped with the lambda builds.
  PYTHONPATH="${PYTHONPATH:-}:$PWD/lambdas/dispatcher/build" python3 -c "
import boto3, json
sqs = boto3.client('sqs', region_name='us-east-1', endpoint_url='$ENDPOINT')
sqs.send_message(QueueUrl='$JOBS_QUEUE', MessageBody=json.dumps(json.loads('$payload')))
" || { echo "failed to enqueue poison message"; exit 1; }
  echo "poison message enqueued (worker must fail it 3 times, see maxReceiveCount)"
  for _ in $(seq 1 40); do
    sleep 5
    after="$(queue_depth "$DLQ_QUEUE")"
    if [ "$after" -gt "$before" ]; then
      echo "detected: DLQ depth went $before -> $after"
      echo "expected detection signals:"
      echo "  - prometheus alert DeadLetterQueueNotEmpty firing"
      echo "  - cloudforge_sqs_messages{kind=\"dlq\"} increased on $EXPORTER_URL"
      exit 0
    fi
  done
  echo "timeout: message did not reach the DLQ within 200s"
  exit 1
}

scenario_emulator_outage() {
  echo "== scenario: emulator outage -> api health probe fails =="
  echo "stopping $FLOCI_CONTAINER for ${OUTAGE_SECONDS:-150}s"
  docker stop "$FLOCI_CONTAINER" > /dev/null
  trap 'docker start "$FLOCI_CONTAINER" > /dev/null' EXIT
  sleep "${OUTAGE_SECONDS:-150}"
  echo "restarting $FLOCI_CONTAINER"
  docker start "$FLOCI_CONTAINER" > /dev/null
  trap - EXIT
  echo "expected detection signals during the outage:"
  echo "  - cloudforge_api_up drops to 0 on the exporter within one poll cycle"
  echo "  - prometheus alert ApiDown goes pending then firing after 2m"
}

case "${1:-}" in
  poison-job) scenario_poison_job ;;
  emulator-outage) scenario_emulator_outage ;;
  *)
    echo "usage: $0 {poison-job|emulator-outage}" >&2
    exit 2
    ;;
esac
