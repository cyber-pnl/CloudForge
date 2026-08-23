variable "bus_name" {
  description = "Name of the custom event bus."
  type        = string
}

variable "environment" {
  description = "Environment the bus belongs to."
  type        = string
  default     = "dev"
}

variable "rules" {
  description = "Rules to create on the bus, each routing matching events to a single target."
  type = map(object({
    description   = optional(string)
    event_pattern = string
    target_arn    = string
  }))
  default = {}
}

variable "tags" {
  description = "Additional tags applied to the bus."
  type        = map(string)
  default     = {}
}
