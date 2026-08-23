import json
import os


def handler(event, context):
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(
            {
                "service": os.environ.get("SERVICE_NAME", "projects"),
                "environment": os.environ.get("ENVIRONMENT", "dev"),
                "status": "ok",
                "resource": event.get("resource"),
                "method": event.get("httpMethod"),
            }
        ),
    }
