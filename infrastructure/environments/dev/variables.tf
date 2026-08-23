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

variable "artifacts_bucket_name" {
  description = "Name of the artifacts S3 bucket."
  type        = string
  default     = "cloudforge-dev-artifacts"
}
