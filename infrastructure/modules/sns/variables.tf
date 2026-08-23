variable "topic_name" {
  description = "Name of the SNS topic."
  type        = string
}

variable "display_name" {
  description = "Display name shown in notification payloads."
  type        = string
  default     = null
}

variable "kms_master_key_arn" {
  description = "ARN of the customer managed KMS key encrypting the topic. Falls back to SSE-SNS when unset."
  type        = string
  default     = null
}

variable "environment" {
  description = "Environment the topic belongs to."
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Additional tags applied to the topic."
  type        = map(string)
  default     = {}
}
