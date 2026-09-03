output "resource_group_name" {
  description = "Name of the Azure resource group."
  value       = azurerm_resource_group.main.name
}

output "cosmosdb_account_name" {
  description = "Name of the Cosmos DB account."
  value       = module.cosmosdb.account_name
}

output "cosmosdb_database_name" {
  description = "Name of the Cosmos DB SQL database."
  value       = module.cosmosdb.database_name
}

output "cosmosdb_connection_string" {
  description = "Primary connection string of the Cosmos DB account."
  value       = module.cosmosdb.connection_string
  sensitive   = true
}

output "storage_account_name" {
  description = "Name of the storage account."
  value       = module.storage.storage_account_name
}

output "storage_primary_blob_endpoint" {
  description = "Primary blob endpoint of the storage account."
  value       = module.storage.primary_blob_endpoint
}

output "storage_primary_connection_string" {
  description = "Primary connection string of the storage account."
  value       = module.storage.primary_connection_string
  sensitive   = true
}

output "keyvault_name" {
  description = "Name of the Key Vault."
  value       = module.keyvault.vault_name
}

output "keyvault_uri" {
  description = "URI of the Key Vault."
  value       = module.keyvault.vault_uri
}
