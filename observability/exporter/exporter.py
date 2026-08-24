"""CloudForge metrics exporter.

Polls the local AWS-compatible endpoint and serves Prometheus metrics on
/metrics while pushing the same gauges to CloudWatch so that alarms defined
in infrastructure have real data to evaluate.
"""

import logging
import os
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

LOG = logging.getLogger("exporter")

REGION = os.environ.get("AWS_REGION", "us-east-1")
ENDPOINT = os.environ.get("FLOCI_ENDPOINT", "http://localhost:4566")
PORT = int(os.environ.get("EXPORTER_PORT", "9877"))
POLL_INTERVAL = int(os.environ.get("POLL_INTERVAL", "15"))
API_HEALTH_URL = os.environ.get("API_HEALTH_URL", "")
CW_NAMESPACE_PREFIX = "CloudForge"

STATE_LOCK = threading.Lock()
METRIC_SECTIONS = {}


def publish(section, lines):
    """Update one metric section so staleness stays bounded per section."""
    with STATE_LOCK:
        METRIC_SECTIONS[section] = lines


def clients():
    """Lazy AWS clients so the module stays importable without boto3."""
    import boto3
    from botocore.config import Config

    # Fail fast: without bounded timeouts a poll against an unreachable
    # endpoint blocks for minutes on retries and freezes every metric.
    config = Config(
        connect_timeout=3,
        read_timeout=5,
        retries={"total_max_attempts": 2},
    )
    session = boto3.session.Session(region_name=REGION)
    common = {"region_name": REGION, "config": config}
    if ENDPOINT:
        common["endpoint_url"] = ENDPOINT
    return {
        "sqs": session.client("sqs", **common),
        "dynamodb": session.client("dynamodb", **common),
        "s3": session.client("s3", **common),
        "logs": session.client("logs", **common),
        "cloudwatch": session.client("cloudwatch", **common),
    }


def gauge(name, labels, value, help_text):
    label_str = ""
    if labels:
        joined = ",".join(f'{k}="{v}"' for k, v in sorted(labels.items()))
        label_str = "{" + joined + "}"
    return [
        f"# HELP {name} {help_text}",
        f"# TYPE {name} gauge",
        f"{name}{label_str} {value}",
    ]


def discover_resources(cw_clients):
    queues = []
    try:
        for url in cw_clients["sqs"].list_queues().get("QueueUrls", []):
            name = url.rsplit("/", 1)[-1]
            queues.append({"name": name, "url": url})
    except Exception as exc:
        LOG.warning("queue discovery failed: %s", exc)

    tables = []
    try:
        tables = cw_clients["dynamodb"].list_tables().get("TableNames", [])
    except Exception as exc:
        LOG.warning("table discovery failed: %s", exc)

    buckets = []
    try:
        buckets = [b["Name"] for b in cw_clients["s3"].list_buckets().get("Buckets", [])]
    except Exception as exc:
        LOG.warning("bucket discovery failed: %s", exc)

    functions = []
    try:
        groups = cw_clients["logs"].describe_log_groups(logGroupNamePrefix="/aws/lambda/")["logGroups"]
        functions = [g["logGroupName"].rsplit("/", 1)[-1] for g in groups]
    except Exception as exc:
        LOG.warning("function discovery failed: %s", exc)

    return queues, tables, buckets, functions


def collect_queue_metrics(cw_clients, queues):
    lines, push = [], []
    for queue in queues:
        attrs = cw_clients["sqs"].get_queue_attributes(
            QueueUrl=queue["url"], AttributeNames=["ApproximateNumberOfMessages"]
        )["Attributes"]
        visible = int(attrs["ApproximateNumberOfMessages"])
        kind = "dlq" if queue["name"].endswith("-dlq") else "main"
        lines += gauge(
            "cloudforge_sqs_messages",
            {"queue": queue["name"], "kind": kind},
            visible,
            "Approximate number of visible messages in the queue.",
        )
        push.append(("SQS", "ApproximateNumberOfMessages", [{"Name": "Queue", "Value": queue["name"]}], float(visible)))
    return lines, push


def collect_table_metrics(cw_clients, tables):
    lines, push = [], []
    for table in tables:
        result = cw_clients["dynamodb"].scan(TableName=table, Select="COUNT")
        count = result.get("Count", 0)
        lines += gauge(
            "cloudforge_dynamodb_items", {"table": table}, count, "Number of items in the table."
        )
        push.append(("DynamoDB", "ItemCount", [{"Name": "Table", "Value": table}], float(count)))
    return lines, push


def collect_bucket_metrics(cw_clients, buckets):
    lines, push = [], []
    for bucket in buckets:
        objects = cw_clients["s3"].list_objects_v2(Bucket=bucket).get("KeyCount", 0)
        lines += gauge(
            "cloudforge_s3_objects", {"bucket": bucket}, objects, "Number of objects in the bucket."
        )
        push.append(("S3", "ObjectCount", [{"Name": "Bucket", "Value": bucket}], float(objects)))
    return lines, push


def collect_lambda_metrics(cw_clients, functions):
    lines = []
    now_ms = int(time.time() * 1000)
    window_ms = POLL_INTERVAL * 1000
    for function in functions:
        group = f"/aws/lambda/{function}"
        errors = 0
        try:
            response = cw_clients["logs"].filter_log_events(
                logGroupName=group,
                startTime=max(0, now_ms - window_ms * 4),
                filterPattern="ERROR",
                limit=10000,
            )
            errors = len(response.get("events", []))
        except Exception as exc:
            LOG.warning("log scan failed for %s: %s", group, exc)
        lines += gauge(
            "cloudforge_lambda_recent_errors",
            {"function": function},
            errors,
            "ERROR log entries found recently (windowed approximation).",
        )
    return lines


def collect_api_health():
    if not API_HEALTH_URL:
        return [], []
    import urllib.request

    up = 1
    try:
        with urllib.request.urlopen(API_HEALTH_URL, timeout=5) as response:
            up = 1 if response.status < 500 else 0
    except Exception:
        up = 0
    lines = gauge("cloudforge_api_up", {}, up, "1 when the API invoke URL answers without a server error.")
    push = [("SQS", "ApiHealth", [], float(up))]
    return lines, push


def push_to_cloudwatch(cw_clients, push_data):
    by_namespace = {}
    for namespace, metric, dims, value in push_data:
        by_namespace.setdefault(namespace, []).append(
            {"MetricName": metric, "Dimensions": dims, "Value": value}
        )
    for namespace, batch in by_namespace.items():
        try:
            cw_clients["cloudwatch"].put_metric_data(
                Namespace=f"{CW_NAMESPACE_PREFIX}/{namespace}", MetricData=batch
            )
        except Exception as exc:
            LOG.warning("cloudwatch push failed for %s: %s", namespace, exc)


def poll_once(cw_clients):
    # Health probe first: it is the cheapest signal and must stay fresh even
    # when the AWS calls below hang on timeouts.
    api_lines, api_push = collect_api_health()
    publish("api", api_lines)

    queues, tables, buckets, functions = discover_resources(cw_clients)
    push = list(api_push)
    try:
        q_lines, q_push = collect_queue_metrics(cw_clients, queues)
        publish("queues", q_lines)
        push += q_push
    except Exception as exc:
        LOG.warning("queue metrics failed: %s", exc)
    try:
        t_lines, t_push = collect_table_metrics(cw_clients, tables)
        publish("tables", t_lines)
        push += t_push
    except Exception as exc:
        LOG.warning("table metrics failed: %s", exc)
    try:
        b_lines, b_push = collect_bucket_metrics(cw_clients, buckets)
        publish("buckets", b_lines)
        push += b_push
    except Exception as exc:
        LOG.warning("bucket metrics failed: %s", exc)
    try:
        publish("lambdas", collect_lambda_metrics(cw_clients, functions))
    except Exception as exc:
        LOG.warning("lambda metrics failed: %s", exc)
    push_to_cloudwatch(cw_clients, push)


def render_metrics():
    with STATE_LOCK:
        sections = [list(lines) for lines in METRIC_SECTIONS.values()]
    return "\n".join(line for section in sections for line in section) + "\n"


class MetricsHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/metrics":
            body = render_metrics().encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; version=0.0.4")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        elif self.path == "/health":
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"ok")
        else:
            self.send_error(404)

    def log_message(self, fmt, *args):
        LOG.debug(fmt, *args)


def main():
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
    cw_clients = clients()
    server = ThreadingHTTPServer(("0.0.0.0", PORT), MetricsHandler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    LOG.info("exporter listening on :%s, polling every %ss", PORT, POLL_INTERVAL)
    while True:
        started = time.time()
        poll_once(cw_clients)
        elapsed = time.time() - started
        time.sleep(max(1, POLL_INTERVAL - elapsed))


if __name__ == "__main__":
    main()
