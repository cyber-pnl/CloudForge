# Observability

## Signals

The platform is designed to expose:

* Lambda execution logs
* API request metrics
* Lambda errors
* Lambda duration
* SQS queue depth
* DLQ messages
* application errors
* infrastructure events

## Target architecture

```text
AWS Services
     │
     ▼
CloudWatch
     │
     ├── Logs
     ├── Metrics
     └── Alarms
           │
           ▼
      Observability
```

Grafana / Prometheus can be introduced later as an additional observability layer (see [Roadmap](../08-roadmap/roadmap.md)).
