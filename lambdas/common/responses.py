"""HTTP response helpers shared by all API handlers."""

import json

CORS_HEADERS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS",
    "Access-Control-Allow-Headers": "Authorization,Content-Type",
}


class ApiError(Exception):
    def __init__(self, status, code, message):
        super().__init__(message)
        self.status = status
        self.code = code
        self.message = message

    def response(self):
        return json_response(self.status, {"error": self.code, "message": self.message})


def json_response(status, body):
    return {
        "statusCode": status,
        "headers": {"Content-Type": "application/json", **CORS_HEADERS},
        "body": json.dumps(body, default=str),
    }


def preflight():
    """Answer a CORS preflight: browsers send OPTIONS without credentials."""
    return {"statusCode": 204, "headers": dict(CORS_HEADERS), "body": ""}


def bad_request(message):
    return ApiError(400, "bad_request", message)


def unauthorized(message="Missing or invalid credentials"):
    return ApiError(401, "unauthorized", message)


def not_found(message="Resource not found"):
    return ApiError(404, "not_found", message)


def conflict(message):
    return ApiError(409, "conflict", message)


def server_error(message="Internal server error"):
    return ApiError(500, "server_error", message)
