variable "function_app_name" {
  description = "Name of the Azure Function App."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Azure resource group."
  type        = string
}

variable "location" {
  description = "Azure region for the Function App."
  type        = string
  default     = "eastus"
}

variable "storage_account_name" {
  description = "Name of the storage account used for function state."
  type        = string
}

variable "storage_account_access_key" {
  description = "Access key of the storage account."
  type        = string
  sensitive   = true
}

variable "runtime" {
  description = "Azure Functions runtime stack."
  type        = string
  default     = "python"
}

variable "runtime_version" {
  description = "Python runtime version for the Function App."
  type        = string
  default     = "3.12"
}

variable "functions_extension_version" {
  description = "Azure Functions extension version."
  type        = string
  default     = "~4"
}

variable "app_settings" {
  description = "Application settings for the Function App."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}
