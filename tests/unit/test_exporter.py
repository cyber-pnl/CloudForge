"""Unit tests for the metrics exporter (pure functions, no AWS calls)."""

import importlib.util
import sys
from pathlib import Path

EXPORTER_PATH = Path(__file__).resolve().parents[2] / "observability" / "exporter" / "exporter.py"
spec = importlib.util.spec_from_file_location("exporter", EXPORTER_PATH)
exporter = importlib.util.module_from_spec(spec)
sys.modules.setdefault("exporter", exporter)
spec.loader.exec_module(exporter)


class TestGauge:
    def test_without_labels(self):
        lines = exporter.gauge("m", {}, 3, "help text")
        assert lines == ["# HELP m help text", "# TYPE m gauge", "m 3"]

    def test_labels_sorted(self):
        lines = exporter.gauge("m", {"b": "2", "a": "1"}, 0.5, "h")
        assert lines[-1] == 'm{a="1",b="2"} 0.5'

    def test_float_value(self):
        assert exporter.gauge("m", None, 2.5, "h")[-1] == "m 2.5"


class TestRender:
    def test_empty_state(self):
        exporter.METRIC_SECTIONS.clear()
        assert exporter.render_metrics() == "\n"

    def test_sections_render_in_order(self):
        exporter.METRIC_SECTIONS.clear()
        exporter.publish("api", ["api_up 1"])
        exporter.publish("queues", ["q 7"])
        out = exporter.render_metrics()
        assert out == "api_up 1\nq 7\n"

    def test_section_replacement(self):
        exporter.METRIC_SECTIONS.clear()
        exporter.publish("api", ["old"])
        exporter.publish("api", ["new"])
        assert exporter.render_metrics() == "new\n"


class TestCollectQueueMetrics:
    class FakeSqs:
        def __init__(self):
            self.calls = []

        def get_queue_attributes(self, QueueUrl, AttributeNames):
            self.calls.append(QueueUrl)
            name = QueueUrl.rsplit("/", 1)[-1]
            return {"Attributes": {"ApproximateNumberOfMessages": "7"}}

    class Clients(dict):
        pass

    def test_main_and_dlq_kinds_and_push_payloads(self):
        fake_sqs = self.FakeSqs()
        clients = self.Clients(sqs=fake_sqs)
        queues = [
            {"name": "cloudforge-dev-jobs", "url": "http://e/queue/cloudforge-dev-jobs"},
            {"name": "cloudforge-dev-jobs-dlq", "url": "http://e/queue/cloudforge-dev-jobs-dlq"},
        ]
        lines, push = exporter.collect_queue_metrics(clients, queues)
        rendered = "\n".join(lines)
        assert 'cloudforge_sqs_messages{kind="main",queue="cloudforge-dev-jobs"} 7' in rendered
        assert 'cloudforge_sqs_messages{kind="dlq",queue="cloudforge-dev-jobs-dlq"} 7' in rendered
        assert len(push) == 2
        ns, metric, dims, value = push[0]
        assert (ns, metric) == ("SQS", "ApproximateNumberOfMessages")
        assert dims == [{"Name": "Queue", "Value": "cloudforge-dev-jobs"}]
        assert value == 7.0


class TestCollectTableMetrics:
    class FakeDynamo:
        def scan(self, TableName, Select):
            assert Select == "COUNT"
            return {"Count": 42}

    def test_items_counted(self):
        clients = type("C", (dict,), {})(dynamodb=self.FakeDynamo())
        lines, push = exporter.collect_table_metrics(clients, ["t1"])
        assert 'cloudforge_dynamodb_items{table="t1"} 42' in "\n".join(lines)
        assert push[0][0] == "DynamoDB" and push[0][-1] == 42.0


class TestApiHealth:
    def test_no_url_configured(self):
        old = exporter.API_HEALTH_URL
        try:
            exporter.API_HEALTH_URL = ""
            assert exporter.collect_api_health() == ([], [])
        finally:
            exporter.API_HEALTH_URL = old

    def test_up_when_url_reachable(self, monkeypatch):
        class Resp:
            status = 200

            def __enter__(self):
                return self

            def __exit__(self, *a):
                return False

        monkeypatch.setattr("urllib.request.urlopen", lambda url, timeout: Resp())
        old = exporter.API_HEALTH_URL
        try:
            exporter.API_HEALTH_URL = "http://probe"
            lines, push = exporter.collect_api_health()
            assert lines[-1] == "cloudforge_api_up 1"
            assert push == [("SQS", "ApiHealth", [], 1.0)]
        finally:
            exporter.API_HEALTH_URL = old
