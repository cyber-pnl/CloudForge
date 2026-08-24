output "dlq_alarm_name" {
  description = "Name of the dead-letter queue alarm."
  value       = aws_cloudwatch_metric_alarm.dlq_not_empty.alarm_name
}

output "api_down_alarm_name" {
  description = "Name of the API health alarm."
  value       = aws_cloudwatch_metric_alarm.api_down.alarm_name
}
