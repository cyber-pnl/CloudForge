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
