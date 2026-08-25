"""Redis backend replacing SQS, SNS, and EventBridge for the DR site."""

import json
import os
from datetime import datetime, timezone

import redis


class RedisQueue:
    """Mimics SQS: FIFO list with visibility timeout."""

    def __init__(self, name, redis_client=None):
        self.name = name
        self.r = redis_client or redis.Redis(
            host=os.environ.get("REDIS_HOST", "localhost"),
            port=int(os.environ.get("REDIS_PORT", 6379)),
            db=0,
            decode_responses=True,
        )
        self.key = f"queue:{name}"

    def send_message(self, MessageBody=None, Body=None):
        body = MessageBody or Body
        if isinstance(body, dict):
            body = json.dumps(body, default=str)
        self.r.rpush(self.key, body)
        return {"MessageId": f"msg-{datetime.now(timezone.utc).timestamp()}"}

    def receive_messages(self, MaxNumberOfMessages=1, WaitTimeSeconds=0):
        messages = []
        for _ in range(MaxNumberOfMessages):
            _, raw = self.r.blpop(self.key, timeout=WaitTimeSeconds or 1)
            if raw:
                messages.append({
                    "body": raw,
                    "messageId": f"msg-{datetime.now(timezone.utc).timestamp()}",
                })
        return messages

    def approximate_number_of_messages(self):
        return self.r.llen(self.key)


class RedisPubSub:
    """Mimics SNS/EventBridge: publish-subscribe over Redis channels."""

    def __init__(self, redis_client=None):
        self.r = redis_client or redis.Redis(
            host=os.environ.get("REDIS_HOST", "localhost"),
            port=int(os.environ.get("REDIS_PORT", 6379)),
            db=0,
            decode_responses=True,
        )

    def publish(self, topic_arn=None, Message=None, event_bus_name=None,
                Entries=None, Source=None, DetailType=None, Detail=None):
        channel = topic_arn or event_bus_name or "cloudforge-events"
        if Entries:
            for entry in Entries:
                self.r.publish(channel, json.dumps(entry, default=str))
        else:
            payload = {
                "Source": Source,
                "DetailType": DetailType,
                "Detail": Detail,
                "Time": datetime.now(timezone.utc).isoformat(),
            }
            self.r.publish(channel, json.dumps(payload, default=str))
        return {"FailedEntryCount": 0}
