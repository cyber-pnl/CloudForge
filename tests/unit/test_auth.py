import pytest

from conftest import load_module

auth = load_module("common", "auth.py")
responses = load_module("common", "responses.py")


def auth_event(header=None):
    headers = {"Authorization": header} if header else {}
    return {"headers": headers}


def expect_unauthorized(event, monkeypatch, token="local-dev-token"):
    monkeypatch.setenv("API_TOKEN", token)
    with pytest.raises(responses.ApiError) as excinfo:
        auth.require_auth(event)
    assert excinfo.value.status == 401


def test_missing_header_is_rejected(monkeypatch):
    expect_unauthorized(auth_event(), monkeypatch)


def test_wrong_scheme_is_rejected(monkeypatch):
    expect_unauthorized(auth_event("Basic local-dev-token"), monkeypatch)


def test_wrong_token_is_rejected(monkeypatch):
    expect_unauthorized(auth_event("Bearer nope"), monkeypatch)


def test_valid_token_passes(monkeypatch):
    monkeypatch.setenv("API_TOKEN", "local-dev-token")
    auth.require_auth(auth_event("Bearer local-dev-token"))


def test_case_insensitive_header_name(monkeypatch):
    monkeypatch.setenv("API_TOKEN", "t")
    auth.require_auth({"headers": {"authorization": "Bearer t"}})


def test_unconfigured_server_rejects_everything(monkeypatch):
    monkeypatch.delenv("API_TOKEN", raising=False)
    with pytest.raises(responses.ApiError) as excinfo:
        auth.require_auth(auth_event("Bearer anything"))
    assert excinfo.value.status == 401
