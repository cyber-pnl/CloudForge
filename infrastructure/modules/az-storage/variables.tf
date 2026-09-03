variable "storage_account_name" {
  description = "Name of the Azure storage account (3-24 lowercase alphanumeric)."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Azure resource group."
  type        = string
}

variable "location" {
  description = "Azure region for the storage account."
  type        = string
  default     = "eastus"
}

variable "containers" {
  description = "Set of blob container names to create inside the storage account."
  type        = set(string)
  default     = []
}

variable "queues" {
  description = "Set of queue names to create inside the storage account."
  type        = set(string)
  default     = []
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}
