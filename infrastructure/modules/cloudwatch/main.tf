resource "aws_cloudwatch_metric_alarm" "dlq_not_empty" {
  alarm_name          = "${var.name_prefix}-dlq-not-empty"
  alarm_description   = "A message landed in the dead-letter queue: a job failed permanently and must be investigated."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessages"
  namespace           = var.namespace
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    Queue = var.dlq_name
  }

  alarm_actions = [var.notify_topic_arn]
  ok_actions    = [var.notify_topic_arn]

  tags = var.tags

  # Floci does not persist datapoints_to_alarm; ignoring keeps plans clean.
  lifecycle {
    ignore_changes = [datapoints_to_alarm]
  }
}

resource "aws_cloudwatch_metric_alarm" "api_down" {
  alarm_name          = "${var.name_prefix}-api-down"
  alarm_description   = "The API invoke URL stopped answering successfully."
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = var.api_health_metric_name
  namespace           = var.namespace
  period              = 60
  statistic           = "Minimum"
  threshold           = 1
  treat_missing_data  = "breaching"

  alarm_actions = [var.notify_topic_arn]
  ok_actions    = [var.notify_topic_arn]

  tags = var.tags

  lifecycle {
    ignore_changes = [datapoints_to_alarm]
  }
}
