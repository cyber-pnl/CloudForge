output "function_app_id" {
  description = "Resource ID of the Function App."
  value       = azurerm_linux_function_app.this.id
}

output "function_app_name" {
  description = "Name of the Function App."
  value       = azurerm_linux_function_app.this.name
}

output "default_hostname" {
  description = "Default hostname of the Function App."
  value       = azurerm_linux_function_app.this.default_hostname
}
