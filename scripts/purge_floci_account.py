"""Purge CloudForge resources from one Floci account by name prefix.

The floci access key selects the account. Execute-plane APIs only resolve in
the default account, so environments that were briefly deployed under another
account leave control-plane-only resources behind; this tool removes them.

Usage:
  python3 scripts/purge_floci_account.py --account 000000000001 \
      --prefix cloudforge-staging
"""

import argparse
import sys

import boto3

SERVICES = ("sqs", "dynamodb", "lambda", "apigateway", "s3", "events", "sns", "iam", "logs", "cloudwatch")


def clients(endpoint, account):
    def make(service):
        return boto3.client(
            service,
            region_name="us-east-1",
            endpoint_url=endpoint,
            aws_access_key_id=account,
            aws_secret_access_key="test",
        )

    return {service: make(service) for service in SERVICES}


def purge(c, prefix, dry):
    deleted = []

    def note(kind, name):
        deleted.append(f"{kind}:{name}")

    for q in c["sqs"].list_queues().get("QueueUrls", []):
        if prefix in q.rsplit("/", 1)[-1]:
            if not dry:
                c["sqs"].delete_queue(QueueUrl=q)
            note("sqs", q)

    for t in c["dynamodb"].list_tables().get("TableNames", []):
        if t.startswith(prefix):
            if not dry:
                c["dynamodb"].delete_table(TableName=t)
            note("dynamodb", t)

    lam = c["lambda"]
    for f in lam.list_functions().get("Functions", []):
        name = f["FunctionName"]
        if name.startswith(prefix):
            for m in lam.list_event_source_mappings(FunctionName=name).get("EventSourceMappings", []):
                if not dry:
                    lam.delete_event_source_mapping(UUID=m["UUID"])
                note("esm", m["UUID"])
            if not dry:
                lam.delete_function(FunctionName=name)
            note("lambda", name)

    apigw = c["apigateway"]
    for api in apigw.get_rest_apis()["items"]:
        if api["name"].startswith(prefix):
            if not dry:
                apigw.delete_rest_api(restApiId=api["id"])
            note("api", api["name"])

    s3 = c["s3"]
    for b in s3.list_buckets()["Buckets"]:
        name = b["Name"]
        if name.startswith(prefix) or name.startswith(f"awslambda-{prefix}"):
            if not dry:
                paginator = s3.get_paginator("list_objects_v2")
                objects = [{"Key": o["Key"]} for page in paginator.paginate(Bucket=name) for o in page.get("Contents", [])]
                if objects:
                    s3.delete_objects(Bucket=name, Delete={"Objects": objects})
                s3.delete_bucket(Bucket=name)
            note("s3", name)

    events = c["events"]
    for bus in events.list_event_buses().get("EventBuses", []):
        if bus["Name"].startswith(prefix):
            for rule in events.list_rules(EventBusName=bus["Name"]).get("Rules", []):
                targets = events.list_targets_by_rule(Rule=rule["Name"], EventBusName=bus["Name"]).get("Targets", [])
                if targets and not dry:
                    events.remove_targets(Rule=rule["Name"], EventBusName=bus["Name"], Ids=[t["Id"] for t in targets])
                if not dry:
                    events.delete_rule(Name=rule["Name"], EventBusName=bus["Name"])
                note("rule", rule["Name"])
            if not dry:
                events.delete_event_bus(Name=bus["Name"])
            note("bus", bus["Name"])

    sns = c["sns"]
    for topic in sns.list_topics().get("Topics", []):
        arn = topic["TopicArn"]
        if prefix in arn.split(":")[-1]:
            if not dry:
                sns.delete_topic(TopicArn=arn)
            note("sns", arn)

    iam = c["iam"]
    for role in iam.list_roles()["Roles"]:
        name = role["RoleName"]
        if name.startswith(prefix):
            for p in iam.list_attached_role_policies(RoleName=name)["AttachedPolicies"]:
                if not dry:
                    iam.detach_role_policy(RoleName=name, PolicyArn=p["PolicyArn"])
            for p in iam.list_role_policies(RoleName=name)["PolicyNames"]:
                if not dry:
                    iam.delete_role_policy(RoleName=name, PolicyName=p)
            if not dry:
                iam.delete_role(RoleName=name)
            note("iam", name)

    logs = c["logs"]
    for group in logs.describe_log_groups(logGroupNamePrefix=f"/aws/lambda/{prefix}")["logGroups"]:
        if not dry:
            logs.delete_log_group(logGroupName=group["logGroupName"])
        note("logs", group["logGroupName"])

    cw = c["cloudwatch"]
    for alarm in cw.describe_alarms(AlarmNamePrefix=prefix)["MetricAlarms"]:
        if not dry:
            cw.delete_alarms(AlarmNames=[alarm["AlarmName"]])
        note("alarm", alarm["AlarmName"])

    return deleted


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--account", required=True, help="floci account id (access key)")
    parser.add_argument("--prefix", required=True, help="resource name prefix to purge")
    parser.add_argument("--endpoint", default="http://localhost:4566")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    c = clients(args.endpoint, args.account)
    deleted = purge(c, args.prefix, args.dry_run)
    action = "would delete" if args.dry_run else "deleted"
    for item in sorted(deleted):
        print(f"{action} {item}")
    print(f"total: {len(deleted)} resource(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
