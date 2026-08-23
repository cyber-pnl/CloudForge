"""Process job messages from SQS and persist artifacts to S3.

Failures are deliberate and observable: a message flagged with
simulate_failure raises on every attempt until the queue redrive policy
moves it to the dead letter queue.
"""

import json
import os
from datetime import datetime, timezone


def build_artifact(body, message_id, received_at=None):
    """Compute the S3 key and payload for one job message."""
    parsed = json.loads(body)
    prefix = os.environ.get("ARTIFACT_PREFIX", "artifacts/")
    return {
        "key": f"{prefix}{message_id}.json",
        "body": json.dumps(
            {
                "processed_at": received_at or datetime.now(timezone.utc).isoformat(),
                "original_event": parsed,
            },
            default=str,
        ),
    }


def typed_flag(image, name):
    """Read a boolean attribute from a DynamoDB typed value map."""
    value = image.get(name)
    if isinstance(value, dict):
        return bool(value.get("BOOL", False))
    return bool(value)


def _store(key, body):
    import boto3

    bucket = os.environ["ARTIFACT_BUCKET"]
    boto3.client("s3").put_object(Bucket=bucket, Key=key, Body=body.encode("utf-8"))
    return bucket


def handler(event, context):
    bucket = os.environ["ARTIFACT_BUCKET"]
    stored = 0
    for record in event.get("Records", []):
        body = record.get("body", "")
        parsed = json.loads(body)
        image = parsed.get("detail", {}).get("new_image", {}) or {}
        if typed_flag(image, "simulate_failure"):
            raise RuntimeError(f"Simulated failure for message {record.get('messageId')}")
        artifact = build_artifact(body, record.get("messageId"))
        _store(artifact["key"], artifact["body"])
        stored += 1
    print(f"Stored {stored} artifact(s) in {bucket}")
    return {"stored": stored}
