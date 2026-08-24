"""Users API: CRUD over the users DynamoDB table.

Routes (all behind bearer authentication, see ADR-002):

    ANY /users        POST create, GET list
    ANY /users/{id}   GET fetch, PUT update, DELETE remove
"""

import os
import uuid
from datetime import datetime, timezone

from auth import require_auth
from clients import table
from responses import ApiError, conflict, json_response, not_found, preflight, server_error
from validation import parse_body, require_email, require_fields


def _now():
    return datetime.now(timezone.utc).isoformat()


def _get(dynamo, user_id):
    response = dynamo.get_item(Key={"pk": user_id})
    item = response.get("Item")
    if not item:
        raise not_found(f"User '{user_id}' does not exist")
    return item


def _build_user(body):
    require_fields(body, "name")
    return {
        "name": str(body["name"]).strip(),
        "email": require_email(body),
    }


def handle_collection(method, dynamo, event):
    if method == "POST":
        user = _build_user(parse_body(event))
        existing = dynamo.scan(
            FilterExpression="#e = :email",
            ExpressionAttributeNames={"#e": "email"},
            ExpressionAttributeValues={":email": user["email"]},
        )
        if existing["Items"]:
            raise conflict(f"A user with email '{user['email']}' already exists")
        record = {"pk": f"usr-{uuid.uuid4()}", "created_at": _now(), **user}
        dynamo.put_item(Item=record, ConditionExpression="attribute_not_exists(pk)")
        return json_response(201, {"user": record})

    if method == "GET":
        response = dynamo.scan(Limit=50)
        return json_response(
            200,
            {"users": sorted(response["Items"], key=lambda u: u.get("created_at", ""))},
        )

    raise ApiError(405, "method_not_allowed", f"Method {method} not allowed on /users")


def handle_item(method, dynamo, event, user_id):
    if method == "GET":
        return json_response(200, {"user": _get(dynamo, user_id)})

    if method == "PUT":
        changes = _build_user(parse_body(event))
        _get(dynamo, user_id)
        updated = {"pk": user_id, "created_at": _now(), **changes}
        dynamo.put_item(Item=updated)
        return json_response(200, {"user": updated})

    if method == "DELETE":
        _get(dynamo, user_id)
        dynamo.delete_item(Key={"pk": user_id})
        return {"statusCode": 204}

    raise ApiError(405, "method_not_allowed", f"Method {method} not allowed on /users/{{id}}")


def handler(event, context):
    try:
        method = event.get("httpMethod", "")
        if method == "OPTIONS":
            return preflight()
        require_auth(event)
        user_id = (event.get("pathParameters") or {}).get("id")
        dynamo = table(os.environ["TABLE_NAME"])
        if user_id:
            return handle_item(method, dynamo, event, user_id)
        return handle_collection(method, dynamo, event)
    except ApiError as error:
        return error.response()
    except Exception:
        import traceback

        traceback.print_exc()
        return server_error().response()
