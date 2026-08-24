"""Bearer token authentication for API handlers.

The token is provisioned through the API_TOKEN environment variable.
See ADR-002: Floci accepts Cognito resources but does not enforce
authorizers at invocation time, so authentication lives in the
application layer for now.
"""

import hmac
import os

from responses import unauthorized

REQUIRED_SCHEME = "Bearer"


def require_auth(event):
    headers = {k.lower(): v for k, v in (event.get("headers") or {}).items()}
    header = headers.get("authorization", "")
    parts = header.split(" ", 1)
    expected = os.environ.get("API_TOKEN", "")
    if len(parts) != 2 or parts[0] != REQUIRED_SCHEME or not expected:
        raise unauthorized()
    if not hmac.compare_digest(parts[1].strip(), expected):
        raise unauthorized()
