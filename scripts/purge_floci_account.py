#!/usr/bin/env python3
"""Purge prefixed resources from a Floci account.

Born from Phase 9: a staging deployment made against account
000000000001 had to be abandoned (the execute plane only serves the
default account) but the state file was already empty, leaving
orphaned resources behind. This script removes everything matching a
name prefix so the lab can be reset without wiping other accounts.

Usage:
    PYTHONPATH=lambdas/dispatcher/build python3 \
        scripts/purge_floci_account.py --account 000000000001 \
        --prefix cloudforge-staging- [--dry-run]
"""

import argparse
import os

import boto3
from botocore.config import Config


def client(service, account):
    return boto3.client(
        service,
        endpoint_url=os.environ.get("AWS_ENDPOINT_URL", "http://localhost:4566"),
        region_name="us-east-1",
        aws_access_key_id=account,
        aws_secret_access_key="test",
        config=Config(retries={"total_max_attempts": 2}),
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--account", required=True, help="access key = floci account id")
    parser.add_argument("--prefix", required=True, help="resource name prefix, e.g. cloudforge-staging-")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    suffix = " [dry-run]" if args.dry_run else ""

    def act(message):
        print(f"  {message}{suffix}")
        return not args.dry_run

    apigw = client("apigateway", args.account)
    for api in apigw.get_rest_apis().get("items", []):
        if api["name"].startswith(args.prefix) and act(f"delete rest api {api['id']} ({api['name']})"):
            apigw.delete_rest_api(restApiId=api["id"])

    s3 = client("s3", args.account)
    for bucket in s3.list_buckets().get("Buckets", []):
        name = bucket["Name"]
        if not name.startswith(args.prefix):
            continue
        versions = [
            {"Key": v["Key"], "VersionId": v["VersionId"]}
            for page in s3.get_paginator("list_object_versions").paginate(Bucket=name)
            for section in ("Versions", "DeleteMarkers")
            for v in page.get(section, [])
        ]
        for i in range(0, len(versions), 1000):
            if not args.dry_run:
                s3.delete_objects(Bucket=name, Delete={"Objects": versions[i : i + 1000]})
        print(f"  emptied bucket {name} ({len(versions)} objects){suffix}")
        if act(f"delete bucket {name}"):
            s3.delete_bucket(Bucket=name)

    ddb = client("dynamodb", args.account)
    for table in ddb.list_tables().get("TableNames", []):
        if not table.startswith(args.prefix):
            continue
        stream_arn = ddb.describe_table(TableName=table)["Table"].get("LatestStreamArn")
        if act(f"delete table {table}"):
            ddb.delete_table(TableName=table)
            ddb.get_waiter("table_not_exists").wait(TableName=table)
        if stream_arn and act(f"delete stream {stream_arn.rsplit('/', 1)[-1]}"):
            ddb.delete_stream(StreamArn=stream_arn)

    sqs = client("sqs", args.account)
    for url in sqs.get_paginator("list_queues").paginate().build_full_result().get("QueueUrls", []):
        if url.rsplit("/", 1)[-1].startswith(args.prefix) and act(f"delete queue {url.rsplit('/', 1)[-1]}"):
            sqs.delete_queue(QueueUrl=url)

    lam = client("lambda", args.account)
    esms = lam.list_event_source_mappings().get("EventSourceMappings", [])
    for esm in esms:
        fn = esm.get("FunctionArn", "").rsplit(":", 1)[-1]
        if fn.startswith(args.prefix) and act(f"delete event source mapping {esm['UUID']} ({fn})"):
            lam.delete_event_source_mapping(UUID=esm["UUID"])
    for fn in lam.list_functions().get("Functions", []):
        if fn["FunctionName"].startswith(args.prefix) and act(f"delete function {fn['FunctionName']}"):
            lam.delete_function(FunctionName=fn["FunctionName"])

    sns = client("sns", args.account)
    for topic in sns.list_topics().get("Topics", []):
        arn = topic["TopicArn"]
        if arn.rsplit(":", 1)[-1].startswith(args.prefix) and act(f"delete topic {arn.rsplit(':', 1)[-1]}"):
            sns.delete_topic(TopicArn=arn)

    iam = client("iam", args.account)
    roles = iam.get_paginator("list_roles").paginate().build_full_result().get("Roles", [])
    for role in roles:
        name = role["RoleName"]
        if not name.startswith(args.prefix):
            continue
        attached = iam.list_attached_role_policies(RoleName=name).get("AttachedPolicies", [])
        inline = iam.list_role_policies(RoleName=name).get("PolicyNames", [])
        details = ", ".join([p["PolicyName"] for p in attached] + inline) or "no policies"
        if act(f"delete role {name} ({details})"):
            for pol in attached:
                iam.detach_role_policy(RoleName=name, PolicyArn=pol["PolicyArn"])
            for pol in inline:
                iam.delete_role_policy(RoleName=name, PolicyName=pol)
            iam.delete_role(RoleName=name)

    logs = client("logs", args.account)
    groups = (
        logs.get_paginator("describe_log_groups")
        .paginate(logGroupNamePrefix=f"/aws/lambda/{args.prefix}")
        .build_full_result()
        .get("logGroups", [])
    )
    for group in groups:
        if act(f"delete log group {group['logGroupName']}"):
            logs.delete_log_group(logGroupName=group["logGroupName"])

    events = client("events", args.account)
    for rule in events.list_rules(NamePrefix=args.prefix).get("Rules", []):
        if not act(f"delete rule {rule['Name']}"):
            continue
        try:
            targets = events.list_targets_by_rule(Rule=rule["Name"]).get("Targets", [])
            ids = [t["Id"] for t in targets]
            if ids:
                events.remove_targets(Rule=rule["Name"], Ids=ids)
            events.delete_rule(Name=rule["Name"])
        except events.exceptions.ResourceNotFoundException:
            pass

    cw = client("cloudwatch", args.account)
    names = [
        a["AlarmName"]
        for a in cw.describe_alarms(AlarmNamePrefix=args.prefix).get("MetricAlarms", [])
    ]
    if names and act(f"delete alarms {names}"):
        cw.delete_alarms(AlarmNames=names)

    kms = client("kms", args.account)
    stem = args.prefix.rstrip("-")
    aliased_keys = {
        a["TargetKeyId"]
        for a in kms.list_aliases().get("Aliases", [])
        if a.get("TargetKeyId") and stem in a["AliasName"]
    }
    for alias in sorted(
        a["AliasName"]
        for a in kms.list_aliases().get("Aliases", [])
        if a.get("AliasName") and stem in a["AliasName"]
    ):
        if act(f"delete alias {alias}"):
            kms.delete_alias(AliasName=alias)
    for key in kms.list_keys().get("Keys", []):
        meta = kms.describe_key(KeyId=key["KeyId"])["KeyMetadata"]
        description = meta.get("Description", "")
        if stem not in description and key["KeyId"] not in aliased_keys:
            continue
        if act(f"schedule key deletion {key['KeyId']} ({description or 'no description'})"):
            kms.schedule_key_deletion(KeyId=key["KeyId"], PendingWindowInDays=7)

    print(f"purge complete for prefix '{args.prefix}' in account {args.account}{suffix}")


if __name__ == "__main__":
    main()
