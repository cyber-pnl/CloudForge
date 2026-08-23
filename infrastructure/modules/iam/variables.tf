variable "role_name" {
  description = "Name of the Lambda execution role."
  type        = string
}

variable "policy_statements" {
  description = "Additional least-privilege statements granted to the function, scoped by resource."
  type = list(object({
    Effect   = string
    Action   = list(string)
    Resource = list(string)
  }))
  default = []
}

variable "environment" {
  description = "Environment the role belongs to."
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Additional tags applied to the role."
  type        = map(string)
  default     = {}
}
