"""Projects API: CRUD with lifecycle rules and S3 artifacts.

Routes (all behind bearer authentication, see ADR-002):

    ANY /projects                    POST create, GET list
    ANY /projects/{id}               GET fetch, PUT update, DELETE remove
    ANY /projects/{id}/artifacts     GET list, POST upload
"""

import base64
import os
import uuid
from datetime import datetime, timezone

from auth import require_auth
from clients import artifact_bucket, s3, table
from lifecycle import VALID_STATUSES, assert_transition
from responses import ApiError, bad_request, conflict, json_response, not_found, server_error
from validation import parse_body, require_fields

MAX_ARTIFACT_BYTES = 5 * 1024 * 1024


def _now():
    return datetime.now(timezone.utc).isoformat()


def _get(dynamo, project_id):
    response = dynamo.get_item(Key={"pk": project_id})
    item = response.get("Item")
    if not item:
        raise not_found(f"Project '{project_id}' does not exist")
    return item


def _require_owner(users_dynamo, owner_id):
    if not users_dynamo.get_item(Key={"pk": owner_id}).get("Item"):
        raise bad_request(f"Owner '{owner_id}' does not exist in the users table")


def _validate_status(body, current=None):
    status = str(body.get("status") or "draft").strip()
    if status not in VALID_STATUSES:
        raise bad_request(f"Invalid status '{status}'. Valid statuses: {', '.join(VALID_STATUSES)}")
    if current is not None:
        assert_transition(current, status)
    return status


def handle_collection(method, dynamo, users_dynamo, event):
    if method == "POST":
        body = parse_body(event)
        require_fields(body, "name", "owner")
        owner_id = str(body["owner"]).strip()
        _require_owner(users_dynamo, owner_id)
        project = {
            "pk": f"prj-{uuid.uuid4()}",
            "name": str(body["name"]).strip(),
            "owner": owner_id,
            "description": str(body.get("description") or ""),
            "status": _validate_status(body),
            "created_at": _now(),
        }
        dynamo.put_item(Item=project, ConditionExpression="attribute_not_exists(pk)")
        return json_response(201, {"project": project})

    if method == "GET":
        response = dynamo.scan(Limit=50)
        return json_response(
            200,
            {"projects": sorted(response["Items"], key=lambda p: p.get("created_at", ""))},
        )

    raise ApiError(405, "method_not_allowed", f"Method {method} not allowed on /projects")


def handle_item(method, dynamo, users_dynamo, event, project_id):
    if method == "GET":
        return json_response(200, {"project": _get(dynamo, project_id)})

    if method == "PUT":
        current = _get(dynamo, project_id)
        body = parse_body(event)
        require_fields(body, "name", "owner")
        owner_id = str(body["owner"]).strip()
        _require_owner(users_dynamo, owner_id)
        updated = {
            "pk": project_id,
            "name": str(body["name"]).strip(),
            "owner": owner_id,
            "description": str(body.get("description") or ""),
            "status": _validate_status(body, current.get("status")),
            "created_at": current.get("created_at"),
            "updated_at": _now(),
        }
        dynamo.put_item(Item=updated)
        return json_response(200, {"project": updated})

    if method == "DELETE":
        _get(dynamo, project_id)
        dynamo.delete_item(Key={"pk": project_id})
        return {"statusCode": 204}

    raise ApiError(405, "method_not_allowed", f"Method {method} not allowed on /projects/{{id}}")


def handle_artifacts(method, dynamo, event, project_id):
    _get(dynamo, project_id)
    bucket = artifact_bucket()
    prefix = f"projects/{project_id}/"

    if method == "GET":
        response = s3().list_objects_v2(Bucket=bucket, Prefix=prefix)
        items = [
            {"key": obj["Key"], "size": obj["Size"], "last_modified": obj["LastModified"]}
            for obj in response.get("Contents", [])
        ]
        return json_response(200, {"artifacts": sorted(items, key=lambda a: a["key"])})

    if method == "POST":
        body = parse_body(event)
        require_fields(body, "filename", "content_base64")
        filename = str(body["filename"]).strip().replace("/", "_")
        try:
            content = base64.b64decode(str(body["content_base64"]), validate=True)
        except Exception:
            raise bad_request("Field 'content_base64' is not valid base64")
        if len(content) > MAX_ARTIFACT_BYTES:
            raise bad_request(f"Artifact exceeds the {MAX_ARTIFACT_BYTES} byte limit")
        key = f"{prefix}{filename}"
        s3().put_object(Bucket=bucket, Key=key, Body=content)
        return json_response(201, {"artifact": {"key": key, "size": len(content)}})

    raise ApiError(405, "method_not_allowed", f"Method {method} not allowed on artifacts")


def handler(event, context):
    try:
        require_auth(event)
        method = event.get("httpMethod", "")
        params = event.get("pathParameters") or {}
        project_id = params.get("id")
        dynamo = table(os.environ["TABLE_NAME"])
        users_dynamo = table(os.environ["USERS_TABLE_NAME"])
        if str(event.get("resource") or "").endswith("/artifacts"):
            return handle_artifacts(method, dynamo, event, project_id)
        if project_id:
            return handle_item(method, dynamo, users_dynamo, event, project_id)
        return handle_collection(method, dynamo, users_dynamo, event)
    except ApiError as error:
        return error.response()
    except Exception:
        import traceback

        traceback.print_exc()
        return server_error().response()
