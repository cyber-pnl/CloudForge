"""Local filesystem backend replacing S3 for the DR site."""

import json
import os
from datetime import datetime, timezone
from pathlib import Path


class LocalS3:
    """Mimics boto3 S3 client interface over local filesystem."""

    def __init__(self, base_path=None):
        self.base = Path(base_path or os.environ.get("ARTIFACT_DIR", "/data/artifacts"))
        self.base.mkdir(parents=True, exist_ok=True)

    def put_object(self, Bucket=None, Key=None, Body=None):
        path = self.base / Key
        path.parent.mkdir(parents=True, exist_ok=True)
        if isinstance(body := (Body or b""), str):
            body = body.encode("utf-8")
        path.write_bytes(body)
        return {"ResponseMetadata": {"HTTPStatusCode": 200}}

    def get_object(self, Bucket=None, Key=None):
        path = self.base / Key
        if not path.exists():
            raise Exception("NoSuchKey")
        return {"Body": path.read_bytes()}

    def list_objects_v2(self, Bucket=None, Prefix=""):
        results = []
        for p in sorted(self.base.rglob("*")):
            if p.is_file() and str(p.relative_to(self.base)).startswith(Prefix):
                rel = str(p.relative_to(self.base))
                stat = p.stat()
                results.append({
                    "Key": rel,
                    "Size": stat.st_size,
                    "LastModified": datetime.fromtimestamp(stat.st_mtime, tz=timezone.utc),
                })
        return {"Contents": results}

    def delete_object(self, Bucket=None, Key=None):
        path = self.base / Key
        if path.exists():
            path.unlink()
        return {"ResponseMetadata": {"HTTPStatusCode": 204}}
