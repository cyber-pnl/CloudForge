variable "aws_region" {
  description = "AWS region used across the environment."
  type        = string
  default     = "us-east-1"
}

variable "floci_endpoint" {
  description = "Floci endpoint exposed by docker compose."
  type        = string
  default     = "http://localhost:4566"
}

variable "account_id" {
  description = "Floci account id: the access key maps to the isolated account."
  type        = string
  default     = "test"
}

variable "artifacts_bucket_name" {
  description = "Name of the artifacts S3 bucket."
  type        = string
  default     = "cloudforge-staging-artifacts"
}

variable "api_token" {
  description = "Bearer token required by the application APIs. Local development value only, see ADR-002."
  type        = string
  default     = "local-dev-token"
  sensitive   = true
}
