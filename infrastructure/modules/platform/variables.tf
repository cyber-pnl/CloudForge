variable "name_prefix" {
  description = "Prefix prepended to every resource name (e.g. cloudforge-dev)."
  type        = string
}

variable "environment" {
  description = "Logical environment name used in tags and build paths."
  type        = string
}

variable "artifacts_bucket_name" {
  description = "Name of the artifacts S3 bucket."
  type        = string
}

variable "api_token" {
  description = "Bearer token required by the application APIs, see ADR-002."
  type        = string
  sensitive   = true
}

variable "lambdas_dir" {
  description = "Absolute path to the lambdas directory containing vendored builds."
  type        = string
}
