variable "alias_name" {
  description = "Alias assigned to the KMS key."
  type        = string
}

variable "description" {
  description = "Description of the KMS key."
  type        = string
  default     = "Managed by OpenTofu"
}

variable "deletion_window_in_days" {
  description = "Waiting period before a deleted KMS key is destroyed."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Additional tags applied to all key resources."
  type        = map(string)
  default     = {}
}
