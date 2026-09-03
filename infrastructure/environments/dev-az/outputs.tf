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

output "users_function_app_name" {
  description = "Name of the Users Function App."
  value       = module.users_function.function_app_name
}

output "projects_function_app_name" {
  description = "Name of the Projects Function App."
  value       = module.projects_function.function_app_name
}

output "worker_function_app_name" {
  description = "Name of the Worker Function App."
  value       = module.worker_function.function_app_name
}

output "dispatcher_function_app_name" {
  description = "Name of the Dispatcher Function App."
  value       = module.dispatcher_function.function_app_name
}

output "apim_name" {
  description = "Name of the API Management instance."
  value       = module.apim.apim_name
}

output "apim_gateway_url" {
  description = "Gateway URL of the API Management instance."
  value       = module.apim.gateway_url
}
