"""PostgreSQL backend replacing DynamoDB for the DR site."""

import json
import os
from datetime import datetime, timezone

import psycopg2
import psycopg2.extras

_CONN = None


def _conn():
    global _CONN
    if _CONN is None:
        _CONN = psycopg2.connect(
            host=os.environ.get("PG_HOST", "localhost"),
            port=int(os.environ.get("PG_PORT", 5432)),
            dbname=os.environ.get("PG_DB", "cloudforge"),
            user=os.environ.get("PG_USER", "cloudforge"),
            password=os.environ.get("PG_PASSWORD", "cloudforge"),
        )
        _CONN.autocommit = True
    return _CONN


def init_schema():
    """Create tables if they don't exist."""
    conn = _conn()
    cur = conn.cursor()
    cur.execute("""
        CREATE TABLE IF NOT EXISTS items (
            pk          TEXT NOT NULL,
            table_name  TEXT NOT NULL,
            data        JSONB NOT NULL,
            created_at  TIMESTAMPTZ DEFAULT NOW(),
            PRIMARY KEY (pk, table_name)
        );
        CREATE INDEX IF NOT EXISTS idx_items_table ON items(table_name);
    """)
    cur.close()


class DynamoTable:
    """Mimics boto3 DynamoDB Table interface over PostgreSQL."""

    def __init__(self, table_name):
        self.table_name = table_name

    def get_item(self, Key):
        pk = Key["pk"]
        cur = _conn().cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        cur.execute(
            "SELECT data FROM items WHERE pk = %s AND table_name = %s",
            (pk, self.table_name),
        )
        row = cur.fetchone()
        cur.close()
        if row:
            data = row["data"] if isinstance(row["data"], dict) else json.loads(row["data"])
            return {"Item": data}
        return {}

    def put_item(self, Item, ConditionExpression=None):
        pk = Item["pk"]
        conn = _conn()
        cur = conn.cursor()
        if ConditionExpression == "attribute_not_exists(pk)":
            cur.execute(
                "INSERT INTO items (pk, table_name, data) VALUES (%s, %s, %s) ON CONFLICT DO NOTHING",
                (pk, self.table_name, json.dumps(Item, default=str)),
            )
            if cur.rowcount == 0:
                cur.close()
                raise Exception("ConditionalCheckFailedException")
        else:
            cur.execute(
                "INSERT INTO items (pk, table_name, data) VALUES (%s, %s, %s) "
                "ON CONFLICT (pk, table_name) DO UPDATE SET data = EXCLUDED.data",
                (pk, self.table_name, json.dumps(Item, default=str)),
            )
        cur.close()

    def delete_item(self, Key):
        pk = Key["pk"]
        cur = _conn().cursor()
        cur.execute(
            "DELETE FROM items WHERE pk = %s AND table_name = %s",
            (pk, self.table_name),
        )
        cur.close()

    def scan(self, Limit=50, FilterExpression=None, ExpressionAttributeNames=None,
             ExpressionAttributeValues=None):
        cur = _conn().cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        cur.execute(
            "SELECT data FROM items WHERE table_name = %s LIMIT %s",
            (self.table_name, Limit),
        )
        rows = cur.fetchall()
        cur.close()
        items = [r["data"] if isinstance(r["data"], dict) else json.loads(r["data"]) for r in rows]

        if FilterExpression and ExpressionAttributeValues:
            attr_name = list(ExpressionAttributeNames.values())[0] if ExpressionAttributeNames else ""
            attr_val = list(ExpressionAttributeValues.values())[0]
            items = [i for i in items if i.get(attr_name) == attr_val]

        return {"Items": items}
