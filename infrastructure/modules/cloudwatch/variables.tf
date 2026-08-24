variable "name_prefix" {
  description = "Prefix used to name the alarms."
  type        = string
}

variable "namespace" {
  description = "CloudWatch namespace the exporter pushes metrics to."
  type        = string
}

variable "dlq_name" {
  description = "Queue dimension value of the dead-letter queue."
  type        = string
}

variable "api_health_metric_name" {
  description = "Metric name carrying the API health gauge (1 healthy, 0 down)."
  type        = string
}

variable "notify_topic_arn" {
  description = "SNS topic that receives alarm transitions."
  type        = string
}

variable "tags" {
  description = "Tags applied to every alarm."
  type        = map(string)
}
