import importlib.util
import json
import pathlib

import pytest

ROOT = pathlib.Path(__file__).resolve().parents[2]


def load_handler(service):
    path = ROOT / "lambdas" / service / "handler.py"
    spec = importlib.util.spec_from_file_location(f"{service}_handler", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


@pytest.mark.parametrize("service", ["users", "projects"])
def test_handler_returns_ok_proxy_response(service):
    handler = load_handler(service)

    response = handler.handler(
        {"resource": f"/{service}", "httpMethod": "GET"}, None
    )

    assert response["statusCode"] == 200
    assert response["headers"]["Content-Type"] == "application/json"

    body = json.loads(response["body"])
    assert body["status"] == "ok"
    assert body["service"] == service
    assert body["resource"] == f"/{service}"
    assert body["method"] == "GET"


@pytest.mark.parametrize("service", ["users", "projects"])
def test_handler_defaults_environment_to_dev(service):
    handler = load_handler(service)

    response = handler.handler({}, None)

    assert json.loads(response["body"])["environment"] == "dev"


def stream_event(table_name, count=1):
    arn = f"arn:aws:dynamodb:us-east-1:000000000000:table/{table_name}/stream/2026-08-23T00:00:00.000"
    records = [
        {
            "eventName": "INSERT",
            "eventSourceARN": arn,
            "dynamodb": {
                "Keys": {"pk": {"S": f"id-{index}"}},
                "NewImage": {"pk": {"S": f"id-{index}"}, "simulate_failure": {"BOOL": index % 2 == 1}},
            },
        }
        for index in range(count)
    ]
    return {"Records": records}


def test_dispatcher_shapes_one_entry_per_record():
    dispatcher = load_handler("dispatcher")

    entries = dispatcher.build_entries(
        stream_event("cloudforge-dev-users", 2), "cloudforge-dev-users"
    )

    assert len(entries) == 2
    assert all(entry["Source"] == "cloudforge.stream" for entry in entries)
    assert all(entry["DetailType"] == "cloudforge-dev-users.changed" for entry in entries)
    detail = json.loads(entries[0]["Detail"])
    assert detail["table"] == "cloudforge-dev-users"
    assert detail["keys"] == {"pk": {"S": "id-0"}}
    assert detail["new_image"]["pk"] == {"S": "id-0"}


def test_dispatcher_chunks_entries_by_put_events_limit():
    dispatcher = load_handler("dispatcher")

    chunks = dispatcher.chunk_entries([{"i": i} for i in range(11)])

    assert [len(chunk) for chunk in chunks] == [10, 1]


def test_worker_builds_idempotent_artifact_key_and_payload(monkeypatch):
    worker = load_handler("worker")
    monkeypatch.setenv("ARTIFACT_PREFIX", "artifacts/")

    artifact = worker.build_artifact(
        json.dumps({"detail-type": "cloudforge-dev-users.changed"}),
        message_id="msg-42",
        received_at="2026-08-23T12:00:00+00:00",
    )

    assert artifact["key"] == "artifacts/msg-42.json"
    payload = json.loads(artifact["body"])
    assert payload["processed_at"] == "2026-08-23T12:00:00+00:00"
    assert payload["original_event"]["detail-type"] == "cloudforge-dev-users.changed"


@pytest.mark.parametrize(
    "attribute,expected",
    [
        ({"BOOL": True}, True),
        ({"BOOL": False}, False),
        ({"S": "true"}, False),
        (None, False),
        (True, True),
        (False, False),
    ],
)
def test_worker_typed_flag_reads_dynamodb_boolean_maps(attribute, expected):
    worker = load_handler("worker")

    assert worker.typed_flag({"simulate_failure": attribute}, "simulate_failure") is expected
