variable "apim_name" {
  description = "Name of the API Management instance."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Azure resource group."
  type        = string
}

variable "location" {
  description = "Azure region for the API Management instance."
  type        = string
  default     = "eastus"
}

variable "publisher_name" {
  description = "Name of the API Management publisher."
  type        = string
  default     = "CloudForge"
}

variable "publisher_email" {
  description = "Email of the API Management publisher."
  type        = string
  default     = "admin@cloudforge.dev"
}

variable "sku_name" {
  description = "SKU name for the API Management instance (Consumption tier for dev)."
  type        = string
  default     = "Consumption_0"
}

variable "apis" {
  description = "Map of APIs to create in the APIM instance."
  type = map(object({
    path         = string
    display_name = string
    protocols    = list(string)
    description  = optional(string, "")
  }))
  default = {}
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}
