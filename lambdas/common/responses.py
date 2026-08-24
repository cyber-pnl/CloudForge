"""HTTP response helpers shared by all API handlers."""

import json


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
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body, default=str),
    }


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
