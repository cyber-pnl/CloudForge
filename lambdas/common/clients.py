"""Lazy AWS clients so handler modules stay importable without boto3."""

import os

_TABLES = {}


def table(name):
    if name not in _TABLES:
        import boto3

        _TABLES[name] = boto3.resource("dynamodb").Table(name)
    return _TABLES[name]


def s3():
    import boto3

    return boto3.client("s3")


def artifact_bucket():
    return os.environ["ARTIFACT_BUCKET"]
