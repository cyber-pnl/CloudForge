import importlib.util
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
LAMBDAS = ROOT / "lambdas"
COMMON = LAMBDAS / "common"


COMMON_MODULES = ("responses", "auth", "lifecycle", "validation", "clients")
_registered = False


def _ensure_common_modules():
    """Register shared toolkit modules under their flat names exactly once."""
    global _registered
    if _registered:
        return
    for name in COMMON_MODULES:
        path = COMMON / f"{name}.py"
        spec = importlib.util.spec_from_file_location(name, path)
        module = importlib.util.module_from_spec(spec)
        sys.modules[name] = module
        spec.loader.exec_module(module)
    _registered = True


def load_module(service, filename="handler.py"):
    """Load a lambda source module with the shared toolkit importable."""
    base = COMMON if service == "common" else LAMBDAS / service
    if service == "common":
        _ensure_common_modules()
        return sys.modules[filename.replace(".py", "")]
    path = base / filename
    if str(base) not in sys.path:
        sys.path.insert(0, str(base))
    _ensure_common_modules()
    unique = f"{service}_handler"
    spec = importlib.util.spec_from_file_location(unique, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class FakeDynamo:
    def __init__(self, items=None):
        self.items = {item["pk"]: dict(item) for item in (items or [])}
        self.put_calls = []

    def get_item(self, Key):
        item = self.items.get(Key["pk"])
        return {"Item": dict(item)} if item else {}

    def scan(self, **kwargs):
        values = kwargs.get("ExpressionAttributeValues") or {}
        items = [dict(item) for item in self.items.values()]
        for value in values.values():
            items = [item for item in items if value in item.values()]
        return {"Items": items}

    def put_item(self, Item, **kwargs):
        self.put_calls.append(Item)
        self.items[Item["pk"]] = dict(Item)
        return {}

    def delete_item(self, Key):
        self.items.pop(Key["pk"], None)


class FakeS3:
    def __init__(self):
        self.objects = {}
        self.listed_prefixes = []

    def put_object(self, Bucket, Key, Body):
        self.objects[Key] = Body
        return {}

    def list_objects_v2(self, Bucket, Prefix):
        self.listed_prefixes.append(Prefix)
        contents = [
            {"Key": key, "Size": len(body), "LastModified": "2026-08-23T00:00:00Z"}
            for key, body in sorted(self.objects.items())
            if key.startswith(Prefix)
        ]
        return {"Contents": contents}


def api_event(method, path_params=None, body=None, token="local-dev-token", resource=None):
    event = {
        "httpMethod": method,
        "headers": {},
        "pathParameters": path_params or {},
    }
    if resource is not None:
        event["resource"] = resource
    if token is not None:
        event["headers"]["Authorization"] = f"Bearer {token}"
    if body is not None:
        event["body"] = json.dumps(body)
    return event
