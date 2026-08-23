"""Forward DynamoDB stream records to the custom EventBridge bus.

One domain event is published per stream record, batched by chunks of
ten entries as required by PutEvents. Each deployed instance serves a
single table through its TABLE_NAME environment variable: event source
mapping payloads do not reliably carry the stream ARN.
"""

import json
import os

SOURCE = "cloudforge.stream"
MAX_PUT_EVENTS_ENTRIES = 10


def build_entries(event, table_name):
    """Shape an event source mapping payload into PutEvents entries."""
    records = event.get("Records", [])
    entries = []
    for record in records:
        dynamodb = record.get("dynamodb", {})
        detail = {
            "table": table_name,
            "event_name": record.get("eventName"),
            "keys": dynamodb.get("Keys"),
            "new_image": dynamodb.get("NewImage"),
            "old_image": dynamodb.get("OldImage"),
        }
        entries.append(
            {
                "Source": SOURCE,
                "DetailType": f"{table_name}.changed",
                "Detail": json.dumps(detail, default=str),
                "EventBusName": os.environ.get("EVENT_BUS_NAME", "default"),
            }
        )
    return entries


def chunk_entries(entries, size=MAX_PUT_EVENTS_ENTRIES):
    return [entries[i : i + size] for i in range(0, len(entries), size)]


def _publish(chunks):
    import boto3

    events = boto3.client("events")
    failed = 0
    for chunk in chunks:
        response = events.put_events(Entries=chunk)
        failed += sum(1 for entry in response.get("Entries", []) if "ErrorCode" in entry)
    return failed


def handler(event, context):
    table_name = os.environ["TABLE_NAME"]
    entries = build_entries(event, table_name)
    failed = _publish(chunk_entries(entries)) if entries else 0
    if failed:
        raise RuntimeError(f"{failed} event(s) failed to publish")
    print(f"Published {len(entries)} event(s) for {table_name}")
    return {"published": len(entries)}
