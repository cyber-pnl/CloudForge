variable "topic_name" {
  description = "Name of the Event Grid custom topic."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Azure resource group."
  type        = string
}

variable "location" {
  description = "Azure region for the Event Grid topic."
  type        = string
  default     = "eastus"
}

variable "input_schema" {
  description = "Input schema for the Event Grid topic (EventGridSchema or CloudEventSchemaV1_0)."
  type        = string
  default     = "EventGridSchema"
}

variable "event_subscriptions" {
  description = "Map of event subscriptions keyed by name."
  type = map(object({
    endpoint                  = string
    endpoint_type             = optional(string, "webhook")
    included_event_types      = optional(list(string))
    subject_begins_with       = optional(string)
    subject_ends_with         = optional(string)
    is_subject_case_sensitive = optional(bool, false)
    max_delivery_attempts     = optional(number, 10)
    event_time_to_live        = optional(number, 1440)
  }))
  default = {}
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}