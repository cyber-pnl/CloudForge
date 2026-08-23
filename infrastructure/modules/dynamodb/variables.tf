variable "table_name" {
  description = "Name of the DynamoDB table."
  type        = string
}

variable "hash_key" {
  description = "Partition key attribute name."
  type        = string
  default     = "pk"
}

variable "hash_key_type" {
  description = "Partition key attribute type (S, N or B)."
  type        = string
  default     = "S"
}

variable "attributes" {
  description = "Additional non-key attribute definitions used by indexes."
  type = list(object({
    name = string
    type = string
  }))
  default = []
}

variable "environment" {
  description = "Environment the table belongs to."
  type        = string
  default     = "dev"
}

variable "pitr_enabled" {
  description = "Enable point-in-time recovery for the table."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags applied to the table."
  type        = map(string)
  default     = {}
}
