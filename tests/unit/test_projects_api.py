import json
import types

import pytest

from conftest import FakeDynamo, FakeS3, api_event, load_module

projects = load_module("projects")


@pytest.fixture()
def tables(monkeypatch):
    dynamo = FakeDynamo(
        items=[
            {
                "pk": "prj-1",
                "name": "Apollo",
                "owner": "usr-1",
                "description": "",
                "status": "draft",
                "created_at": "2026-01-01T00:00:00+00:00",
            }
        ]
    )
    users_dynamo = FakeDynamo(items=[{"pk": "usr-1", "name": "Ada", "email": "ada@example.com"}])
    fake_s3 = FakeS3()
    table_map = {"projects-table": dynamo, "users-table": users_dynamo}
    monkeypatch.setattr(projects, "table", lambda name: table_map[name])
    monkeypatch.setattr(projects, "s3", lambda: fake_s3)
    monkeypatch.delenv("API_TOKEN", raising=False)
    monkeypatch.setenv("API_TOKEN", "local-dev-token")
    monkeypatch.setenv("ARTIFACT_BUCKET", "artifacts-bucket")
    monkeypatch.setenv("TABLE_NAME", "projects-table")
    monkeypatch.setenv("USERS_TABLE_NAME", "users-table")
    return dynamo, users_dynamo, fake_s3


def test_create_project_defaults_to_draft(tables):
    response = projects.handler(api_event("POST", body={"name": "Zephyr", "owner": "usr-1"}), None)

    assert response["statusCode"] == 201
    assert json.loads(response["body"])["project"]["status"] == "draft"


def test_create_project_with_unknown_owner_is_400(tables):
    response = projects.handler(api_event("POST", body={"name": "X", "owner": "usr-none"}), None)

    assert response["statusCode"] == 400


def test_put_transition_active_then_archived(tables):
    first = projects.handler(
        api_event("PUT", {"id": "prj-1"}, body={"name": "Apollo", "owner": "usr-1", "status": "active"}), None
    )
    second = projects.handler(
        api_event("PUT", {"id": "prj-1"}, body={"name": "Apollo", "owner": "usr-1", "status": "archived"}), None
    )

    assert first["statusCode"] == 200
    assert json.loads(first["body"])["project"]["status"] == "active"
    assert second["statusCode"] == 200
    assert json.loads(second["body"])["project"]["status"] == "archived"


def test_illegal_reopen_after_archival_is_409(tables):
    projects.handler(api_event("PUT", {"id": "prj-1"}, body={"name": "A", "owner": "usr-1", "status": "archived"}), None)
    response = projects.handler(
        api_event("PUT", {"id": "prj-1"}, body={"name": "A", "owner": "usr-1", "status": "active"}), None
    )

    assert response["statusCode"] == 409


def test_unknown_status_value_is_400(tables):
    response = projects.handler(
        api_event("PUT", {"id": "prj-1"}, body={"name": "A", "owner": "usr-1", "status": "flying"}), None
    )

    assert response["statusCode"] == 400


def test_artifact_upload_and_listing(tables):
    _, _, s3 = tables
    content_base64 = __import__("base64").b64encode(b"payload").decode()

    uploaded = projects.handler(
        api_event(
            "POST",
            {"id": "prj-1", "subresource": "artifacts"},
            body={"filename": "spec.txt", "content_base64": content_base64},
            resource="/projects/{id}/artifacts",
        ),
        None,
    )
    listed = projects.handler(
        api_event("GET", {"id": "prj-1", "subresource": "artifacts"}, resource="/projects/{id}/artifacts"), None
    )

    assert uploaded["statusCode"] == 201
    artifact = json.loads(uploaded["body"])["artifact"]
    assert artifact["key"] == "projects/prj-1/spec.txt"
    assert artifact["size"] == 7
    assert s3.objects["projects/prj-1/spec.txt"] == b"payload"
    items = json.loads(listed["body"])["artifacts"]
    assert [i["key"] for i in items] == ["projects/prj-1/spec.txt"]


def test_invalid_base64_is_400(tables):
    response = projects.handler(
        api_event(
            "POST",
            {"id": "prj-1", "subresource": "artifacts"},
            body={"filename": "x.bin", "content_base64": "!!!not-base64!!!"},
            resource="/projects/{id}/artifacts",
        ),
        None,
    )

    assert response["statusCode"] == 400


def test_artifact_upload_for_missing_project_is_404(tables):
    content = __import__("base64").b64encode(b"x").decode()
    response = projects.handler(
        api_event(
            "POST",
            {"id": "prj-none", "subresource": "artifacts"},
            body={"filename": "a", "content_base64": content},
            resource="/projects/{id}/artifacts",
        ),
        None,
    )

    assert response["statusCode"] == 404


def test_requests_without_token_are_401(tables):
    response = projects.handler(api_event("GET", token=None), None)

    assert response["statusCode"] == 401
