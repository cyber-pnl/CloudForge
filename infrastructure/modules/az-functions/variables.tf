variable "function_app_name" {
  description = "Name of the Azure Function App (must be unique across the Floci-AZ account)."
  type        = string
}

variable "function_name" {
  description = "Name of the single HTTP-triggered function deployed into the app. It also becomes the HTTP route: /api/{app}/{function}."
  type        = string
}

variable "endpoint" {
  description = "Floci-AZ base URL for the Functions management API (HTTPS, so invoke/webhook URLs satisfy consumers that require https, e.g. Event Grid)."
  type        = string
  default     = "https://localhost:4577"
}

variable "account_name" {
  description = "Floci-AZ storage account namespace used to scope the Functions API."
  type        = string
  default     = "devstoreaccount1"
}

variable "runtime_version" {
  description = "Python version for the Function App (Python v2 model)."
  type        = string
  default     = "3.12"
}

variable "package_dir" {
  description = "Path to the function package directory (host.json). When empty, the module's bundled package is used. The Python v2 entry point is generated from function_app_name/function_name."
  type        = string
  default     = ""
}

variable "app_settings" {
  description = "Application settings (environment) injected into the Function App."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}
