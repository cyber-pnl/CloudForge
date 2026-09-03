output "identity_id" {
  description = "Resource ID of the managed identity."
  value       = azurerm_user_assigned_identity.this.id
}

output "identity_name" {
  description = "Name of the managed identity."
  value       = azurerm_user_assigned_identity.this.name
}

output "principal_id" {
  description = "Principal ID of the managed identity."
  value       = azurerm_user_assigned_identity.this.principal_id
}

output "client_id" {
  description = "Client ID of the managed identity."
  value       = azurerm_user_assigned_identity.this.client_id
  sensitive   = true
}