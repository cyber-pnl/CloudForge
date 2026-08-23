variable "bucket_name" {
  description = "Name of the S3 bucket."
  type        = string
}

variable "environment" {
  description = "Environment the bucket belongs to."
  type        = string
  default     = "dev"
}

variable "versioning_enabled" {
  description = "Enable S3 object versioning."
  type        = bool
  default     = true
}

variable "kms_master_key_arn" {
  description = "ARN of the customer managed KMS key used for default encryption. Falls back to SSE-S3 when unset."
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags applied to all bucket resources."
  type        = map(string)
  default     = {}
}
