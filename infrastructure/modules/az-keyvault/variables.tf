variable "vault_name" {
  description = "Name of the Key Vault."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Azure resource group."
  type        = string
}

variable "location" {
  description = "Azure region for the Key Vault."
  type        = string
  default     = "eastus"
}

variable "tenant_id" {
  description = "Azure AD tenant ID."
  type        = string
}

variable "secrets" {
  description = "Map of secrets to store in the Key Vault. Mark as sensitive in tfvars, not in the variable declaration (required for for_each)."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}
