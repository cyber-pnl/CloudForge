variable "account_name" {
  description = "Name of the Cosmos DB account."
  type        = string
}

variable "database_name" {
  description = "Name of the SQL database inside the Cosmos DB account."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Azure resource group."
  type        = string
}

variable "location" {
  description = "Azure region for the Cosmos DB account."
  type        = string
  default     = "eastus"
}

variable "containers" {
  description = "Map of SQL containers to create inside the database. Each value must have a partition_key_path."
  type = map(object({
    partition_key_path = string
  }))
  default = {}
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}
