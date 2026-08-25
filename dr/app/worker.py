"""DR Worker: consumes Redis queue messages and persists artifacts to local filesystem.

Replaces the Lambda worker that processes SQS messages.
"""

import json
import os
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

import redis


def build_artifact(body, message_id, received_at=None):
    """Compute the local file path and payload for one job message."""
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


def store(key, body):
    """Write artifact to local filesystem."""
    base = Path(os.environ.get("ARTIFACT_DIR", "/data/artifacts"))
    path = base / key
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(body, encoding="utf-8")
    return base


def main():
    queue_name = os.environ.get("QUEUE_NAME", "cloudforge-jobs")
    r = redis.Redis(
        host=os.environ.get("REDIS_HOST", "localhost"),
        port=int(os.environ.get("REDIS_PORT", 6379)),
        db=0,
        decode_responses=True,
    )
    key = f"queue:{queue_name}"
    print(f"Worker started, listening on queue '{key}'")

    while True:
        try:
            _, raw = r.blpop(key, timeout=5)
            if not raw:
                continue

            parsed = json.loads(raw)
            message_id = parsed.get("messageId", f"msg-{time.time()}")
            image = parsed.get("detail", {}).get("new_image", {}) or {}

            # Simulate failure if flagged (same as Lambda worker)
            if isinstance(image, dict) and image.get("simulate_failure", {}).get("BOOL", False):
                print(f"Simulated failure for message {message_id}")
                continue

            artifact = build_artifact(raw, message_id)
            store(artifact["key"], artifact["body"])
            print(f"Stored artifact {artifact['key']}")

        except redis.ConnectionError:
            print("Redis connection lost, retrying in 5s...")
            time.sleep(5)
        except Exception as e:
            print(f"Error processing message: {e}")
            time.sleep(1)


if __name__ == "__main__":
    main()
