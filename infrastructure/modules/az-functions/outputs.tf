output "function_app_name" {
  description = "Name of the Function App."
  value       = var.function_app_name
}

output "function_name" {
  description = "Name of the HTTP-triggered function deployed into the app."
  value       = var.function_name
}

output "default_hostname" {
  description = "Floci-AZ Functions base host used to route invocations to this app."
  value       = "${trim(var.endpoint, "/")}/${var.account_name}-functions"
}

output "invoke_url" {
  description = "Public URL to invoke the deployed function."
  value       = "${trim(var.endpoint, "/")}/${var.account_name}-functions/api/${var.function_app_name}/${var.function_name}"
}
