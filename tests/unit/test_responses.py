import json

import pytest

from conftest import load_module

responses = load_module("common", "responses.py")


def test_json_response_shape_and_content_type():
    response = responses.json_response(201, {"created": True})

    assert response["statusCode"] == 201
    assert response["headers"]["Content-Type"] == "application/json"
    assert json.loads(response["body"]) == {"created": True}


@pytest.mark.parametrize(
    "helper,status,code",
    [
        ("bad_request", 400, "bad_request"),
        ("unauthorized", 401, "unauthorized"),
        ("not_found", 404, "not_found"),
        ("conflict", 409, "conflict"),
        ("server_error", 500, "server_error"),
    ],
)
def test_api_error_helpers_map_status_codes(helper, status, code):
    error = getattr(responses, helper)("boom")

    assert isinstance(error, responses.ApiError)
    body = error.response()
    assert body["statusCode"] == status
    payload = json.loads(body["body"])
    assert payload["error"] == code
    assert payload["message"] == "boom"
