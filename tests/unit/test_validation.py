import pytest

from conftest import api_event, load_module

validation = load_module("common", "validation.py")
responses = load_module("common", "responses.py")


def test_parse_body_accepts_json_object():
    body = validation.parse_body(api_event("POST", body={"a": 1}))
    assert body == {"a": 1}


@pytest.mark.parametrize(
    "event",
    [
        {"body": None},
        {"body": ""},
        {"body": "not json"},
        {"body": "[1,2]"},
    ],
)
def test_parse_body_rejects_invalid_payloads(event):
    with pytest.raises(responses.ApiError) as excinfo:
        validation.parse_body(event)
    assert excinfo.value.status == 400


def test_require_fields_reports_all_missing():
    with pytest.raises(responses.ApiError) as excinfo:
        validation.require_fields({"name": "  "}, "name", "email")
    message = excinfo.value.message
    assert "name" in message and "email" in message


def test_require_fields_lists_only_missing_ones():
    with pytest.raises(responses.ApiError) as excinfo:
        validation.require_fields({"name": "Ada", "email": ""}, "name", "email")
    assert excinfo.value.message == "Missing required fields: email"


def test_require_fields_passes_when_present():
    validation.require_fields({"name": "Ada"}, "name")


@pytest.mark.parametrize(
    "email,valid",
    [
        ("ada@example.com", True),
        ("ada+tag@sub.example.io", True),
        ("missing-at.example.com", False),
        ("@no-local-part.com", False),
        ("spaces in@example.com", False),
    ],
)
def test_require_email_validation(email, valid):
    if valid:
        assert validation.require_email({"email": email}) == email
    else:
        with pytest.raises(responses.ApiError):
            validation.require_email({"email": email})
