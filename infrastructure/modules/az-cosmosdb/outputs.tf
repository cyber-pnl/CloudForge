output "account_id" {
  description = "Resource ID of the Cosmos DB account."
  value       = azurerm_cosmosdb_account.this.id
}

output "account_name" {
  description = "Name of the Cosmos DB account."
  value       = azurerm_cosmosdb_account.this.name
}

output "database_name" {
  description = "Name of the SQL database."
  value       = azurerm_cosmosdb_sql_database.this.name
}

output "connection_string" {
  description = "Primary connection string of the Cosmos DB account."
  value       = azurerm_cosmosdb_account.this.primary_sql_connection_string
  sensitive   = true
}
