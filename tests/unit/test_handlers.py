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
