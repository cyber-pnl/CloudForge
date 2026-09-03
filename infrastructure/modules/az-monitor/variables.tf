variable "workspace_name" {
  description = "Name of the Log Analytics workspace."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Azure resource group."
  type        = string
}

variable "location" {
  description = "Azure region for the workspace."
  type        = string
  default     = "eastus"
}

variable "sku" {
  description = "Pricing tier for the Log Analytics workspace."
  type        = string
  default     = "PerGB2018"
}

variable "retention_in_days" {
  description = "Number of days to retain logs."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}