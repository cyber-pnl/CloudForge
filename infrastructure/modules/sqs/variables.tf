variable "queue_name" {
  description = "Name of the SQS queue."
  type        = string
}

variable "kms_master_key_arn" {
  description = "ARN of the customer managed KMS key encrypting the queue. Falls back to SSE-SQS when unset."
  type        = string
  default     = null
}

variable "visibility_timeout_seconds" {
  description = "Visibility timeout applied to received messages."
  type        = number
  default     = 60
}

variable "message_retention_seconds" {
  description = "How long messages are retained in the queue."
  type        = number
  default     = 345600
}

variable "environment" {
  description = "Environment the queue belongs to."
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Additional tags applied to the queue."
  type        = map(string)
  default     = {}
}
