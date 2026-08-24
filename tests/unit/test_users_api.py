import json

import pytest

from conftest import FakeDynamo, api_event, load_module

users = load_module("users")


@pytest.fixture()
def table(monkeypatch):
    fake = FakeDynamo(
        items=[{"pk": "usr-1", "name": "Ada", "email": "ada@example.com", "created_at": "2026-01-01T00:00:00+00:00"}]
    )
    monkeypatch.setattr(users, "table", lambda name: fake)
    monkeypatch.setenv("API_TOKEN", "local-dev-token")
    monkeypatch.setenv("TABLE_NAME", "users-table")
    return fake


def test_create_user_returns_201(table):
    response = users.handler(api_event("POST", body={"name": "Grace", "email": "grace@example.com"}), None)

    assert response["statusCode"] == 201
    created = json.loads(response["body"])["user"]
    assert created["name"] == "Grace"
    assert created["pk"].startswith("usr-")


def test_duplicate_email_is_conflict(table):
    users.handler(api_event("POST", body={"name": "Clone", "email": "ada@example.com"}), None)
    response = users.handler(api_event("POST", body={"name": "Clone", "email": "ada@example.com"}), None)

    assert response["statusCode"] == 409


def test_get_existing_user(table):
    response = users.handler(api_event("GET", {"id": "usr-1"}), None)

    assert response["statusCode"] == 200
    assert json.loads(response["body"])["user"]["email"] == "ada@example.com"


def test_get_missing_user_is_404(table):
    response = users.handler(api_event("GET", {"id": "usr-none"}), None)

    assert response["statusCode"] == 404


def test_put_updates_user(table):
    response = users.handler(
        api_event("PUT", {"id": "usr-1"}, body={"name": "Ada L.", "email": "ada@example.com"}), None
    )

    assert response["statusCode"] == 200
    assert json.loads(response["body"])["user"]["name"] == "Ada L."


def test_delete_then_404(table):
    deleted = users.handler(api_event("DELETE", {"id": "usr-1"}), None)
    missing = users.handler(api_event("GET", {"id": "usr-1"}), None)

    assert deleted["statusCode"] == 204
    assert missing["statusCode"] == 404


@pytest.mark.parametrize("method,path_params", [("PATCH", {"id": "usr-1"}), ("PATCH", {})])
def test_unsupported_methods_are_405(table, method, path_params):
    response = users.handler(api_event(method, path_params, body={}), None)

    assert response["statusCode"] == 405


def test_invalid_email_is_400(table):
    response = users.handler(api_event("POST", body={"name": "X", "email": "nope"}), None)

    assert response["statusCode"] == 400


def test_missing_fields_are_400(table):
    response = users.handler(api_event("POST", body={"email": "a@b.co"}), None)

    assert response["statusCode"] == 400


def test_requests_without_token_are_401(table):
    response = users.handler(api_event("GET", token=None), None)

    assert response["statusCode"] == 401


def test_preflight_options_bypasses_auth(table):
    response = users.handler(api_event("OPTIONS", token=None), None)

    assert response["statusCode"] == 204
    assert response["headers"]["Access-Control-Allow-Origin"] == "*"
