output "artifacts_bucket_id" {
  description = "Name of the artifacts S3 bucket."
  value       = module.artifacts_bucket.bucket_id
}

output "artifacts_bucket_arn" {
  description = "ARN of the artifacts S3 bucket."
  value       = module.artifacts_bucket.bucket_arn
}

output "artifacts_key_arn" {
  description = "ARN of the KMS key encrypting the artifacts bucket."
  value       = module.artifacts_key.key_arn
}

output "users_table_name" {
  description = "Name of the users DynamoDB table."
  value       = module.users_table.table_name
}

output "projects_table_name" {
  description = "Name of the projects DynamoDB table."
  value       = module.projects_table.table_name
}

output "api_invoke_url" {
  description = "Base invoke URL of the dev API stage."
  value       = module.api.invoke_url
}

output "jobs_queue_url" {
  description = "URL of the jobs SQS queue."
  value       = module.jobs_queue.queue_url
}

output "notifications_topic_arn" {
  description = "ARN of the notifications SNS topic."
  value       = module.notifications_topic.topic_arn
}
