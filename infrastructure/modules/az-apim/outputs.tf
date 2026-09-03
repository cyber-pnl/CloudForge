output "apim_id" {
  description = "Resource ID of the API Management instance."
  value       = azurerm_api_management.this.id
}

output "apim_name" {
  description = "Name of the API Management instance."
  value       = azurerm_api_management.this.name
}

output "gateway_url" {
  description = "Gateway URL of the API Management instance."
  value       = azurerm_api_management.this.gateway_url
}

output "api_ids" {
  description = "Map of API names to their resource IDs."
  value       = { for k, v in azurerm_api_management_api.this : k => v.id }
}
