variable "subscription_id" {
  description = "Azure subscription ID (Floci-AZ default: 00000000-0000-0000-0000-000000000001)."
  type        = string
  default     = "00000000-0000-0000-0000-000000000001"
}

variable "tenant_id" {
  description = "Azure AD tenant ID (Floci-AZ default: 00000000-0000-0000-0000-000000000002)."
  type        = string
  default     = "00000000-0000-0000-0000-000000000002"
}

variable "metadata_host" {
  description = "Floci-AZ metadata endpoint for azurerm provider discovery."
  type        = string
  default     = "localhost:4577"
}

variable "resource_group_name" {
  description = "Name of the Azure resource group."
  type        = string
  default     = "cloudforge-dev-az-rg"
}

variable "location" {
  description = "Azure region for resources."
  type        = string
  default     = "eastus"
}

variable "name_prefix" {
  description = "Prefix for all resource names in the Azure environment."
  type        = string
  default     = "cloudforge"
}
