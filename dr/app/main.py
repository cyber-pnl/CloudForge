"""CloudForge DR — FastAPI application.

Replaces API Gateway + Lambda + DynamoDB + S3 with:
- FastAPI (HTTP routing)
- PostgreSQL (data persistence)
- Local filesystem (artifact storage)
- Redis (queue + events)

Lambda handler logic is reused via the adapter layer.
"""

from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.responses import Response

from adapter import startup, users_handler, projects_handler


@asynccontextmanager
async def lifespan(app: FastAPI):
    startup()
    yield


app = FastAPI(
    title="CloudForge DR",
    description="Disaster-recovery site running on Scaleway via Feint",
    version="1.0.0",
    lifespan=lifespan,
)


@app.get("/health")
def health():
    return {"status": "ok", "site": "scaleway-dr"}


# --- Users API (delegates to Lambda handler via adapter) ---

@app.api_route("/users", methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"])
async def users_collection(request: Request):
    return await users_handler(request)


@app.api_route("/users/{user_id}", methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"])
async def users_item(request: Request, user_id: str):
    return await users_handler(request)


# --- Projects API (delegates to Lambda handler via adapter) ---

@app.api_route("/projects", methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"])
async def projects_collection(request: Request):
    return await projects_handler(request)


@app.api_route("/projects/{project_id}", methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"])
async def projects_item(request: Request, project_id: str):
    return await projects_handler(request)


@app.api_route("/projects/{project_id}/artifacts", methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"])
async def projects_artifacts(request: Request, project_id: str):
    return await projects_handler(request)
