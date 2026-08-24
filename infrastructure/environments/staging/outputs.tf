output "artifacts_bucket_id" {
  description = "Name of the artifacts S3 bucket."
  value       = module.platform.artifacts_bucket_id
}

output "artifacts_bucket_arn" {
  description = "ARN of the artifacts S3 bucket."
  value       = module.platform.artifacts_bucket_arn
}

output "artifacts_key_arn" {
  description = "ARN of the KMS key encrypting the artifacts bucket."
  value       = module.platform.artifacts_key_arn
}

output "users_table_name" {
  description = "Name of the users DynamoDB table."
  value       = module.platform.users_table_name
}

output "projects_table_name" {
  description = "Name of the projects DynamoDB table."
  value       = module.platform.projects_table_name
}

output "api_invoke_url" {
  description = "Base invoke URL of the staging API stage."
  value       = module.platform.api_invoke_url
}

output "rest_api_id" {
  description = "Identifier of the REST API, used to build local execute-plane URLs."
  value       = module.platform.rest_api_id
}

output "jobs_queue_url" {
  description = "URL of the jobs SQS queue."
  value       = module.platform.jobs_queue_url
}

output "jobs_dlq_url" {
  description = "URL of the jobs dead letter queue."
  value       = module.platform.jobs_dlq_url
}

output "event_bus_name" {
  description = "Name of the custom EventBridge bus."
  value       = module.platform.event_bus_name
}

output "notifications_topic_arn" {
  description = "ARN of the notifications SNS topic."
  value       = module.platform.notifications_topic_arn
}
