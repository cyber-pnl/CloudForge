"""Adapter layer: translates FastAPI requests to Lambda event format
and swaps DynamoDB/S3 backends with PostgreSQL/local filesystem."""

import json
import os
import sys
from pathlib import Path

# Add lambdas/ to path so we can import handler modules
LAMBDAS_DIR = Path(__file__).resolve().parent.parent.parent / "lambdas"
sys.path.insert(0, str(LAMBDAS_DIR))
sys.path.insert(0, str(LAMBDAS_DIR / "common"))
sys.path.insert(0, str(LAMBDAS_DIR / "users"))
sys.path.insert(0, str(LAMBDAS_DIR / "projects"))

from fastapi import Request, Response
from fastapi.responses import JSONResponse

from backends.postgres import DynamoTable, init_schema
from backends.filesystem import LocalS3

# Import and patch common.clients
import clients as _orig_clients

_orig_clients.table = lambda name: DynamoTable(name)
_orig_clients.s3 = lambda: LocalS3()
_orig_clients.artifact_bucket = lambda: os.environ.get("ARTIFACT_DIR", "/data/artifacts")


def _build_event(request: Request, body: str, resource: str = None,
                 path_parameters: dict = None) -> dict:
    """Build an API Gateway proxy event from a FastAPI Request."""
    return {
        "httpMethod": request.method,
        "resource": resource or request.url.path,
        "pathParameters": path_parameters or {},
        "queryStringParameters": dict(request.query_params) or None,
        "headers": dict(request.headers),
        "body": body if body else None,
        "isBase64Encoded": False,
    }


def _to_response(result: dict) -> Response:
    """Convert a Lambda handler response dict to a FastAPI Response."""
    status = result.get("statusCode", 200)
    headers = result.get("headers", {})
    body = result.get("body", "")
    if isinstance(body, dict):
        body = json.dumps(body, default=str)
    return Response(content=body, status_code=status, headers=headers)


async def users_handler(request: Request) -> Response:
    """Route /users/* requests to the Users Lambda handler."""
    from users.handler import handler as users_handler_fn

    body = (await request.body()).decode("utf-8") if request.body else ""
    path_params = {}
    path = request.url.path.rstrip("/")

    # Extract {id} from /users/{id}
    parts = path.strip("/").split("/")
    if len(parts) >= 2 and parts[0] == "users":
        path_params["id"] = parts[1]

    resource = "/users/{id}" if "id" in path_params else "/users"
    event = _build_event(request, body, resource=resource, path_parameters=path_params)

    # Set correct table name for users handler
    os.environ["TABLE_NAME"] = os.environ.get("USERS_TABLE", "cloudforge-users")
    result = users_handler_fn(event, None)
    return _to_response(result)


async def projects_handler(request: Request) -> Response:
    """Route /projects/* requests to the Projects Lambda handler."""
    from projects.handler import handler as projects_handler_fn

    body = (await request.body()).decode("utf-8") if request.body else ""
    path_params = {}
    path = request.url.path.rstrip("/")

    # Extract {id} and detect /artifacts sub-resource
    parts = path.strip("/").split("/")
    resource = "/projects"
    if len(parts) >= 2 and parts[0] == "projects":
        path_params["id"] = parts[1]
        resource = "/projects/{id}"
    if len(parts) >= 3 and parts[2] == "artifacts":
        resource = "/projects/{id}/artifacts"

    event = _build_event(request, body, resource=resource, path_parameters=path_params)

    # Set correct table names for projects handler
    os.environ["TABLE_NAME"] = os.environ.get("PROJECTS_TABLE", "cloudforge-projects")
    os.environ["USERS_TABLE_NAME"] = os.environ.get("USERS_TABLE", "cloudforge-users")
    result = projects_handler_fn(event, None)
    return _to_response(result)


def startup():
    """Initialize database schema on app startup."""
    init_schema()
