"""Request parsing and field validation helpers."""

import json
import re

from responses import bad_request

EMAIL_PATTERN = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


def parse_body(event):
    raw = event.get("body") or ""
    if not raw:
        raise bad_request("Request body is required")
    try:
        body = json.loads(raw)
    except ValueError:
        raise bad_request("Request body must be valid JSON")
    if not isinstance(body, dict):
        raise bad_request("Request body must be a JSON object")
    return body


def require_fields(body, *names):
    missing = [name for name in names if not str(body.get(name) or "").strip()]
    if missing:
        raise bad_request(f"Missing required fields: {', '.join(missing)}")


def require_email(body, field="email"):
    value = str(body.get(field) or "").strip()
    if not EMAIL_PATTERN.match(value):
        raise bad_request(f"Field '{field}' is not a valid email address")
    return value
