variable "api_name" {
  description = "Name of the REST API."
  type        = string
}

variable "stage_name" {
  description = "Name of the deployment stage."
  type        = string
  default     = "dev"
}

variable "routes" {
  description = "Top-level routes backed by Lambda proxy integrations."
  type = map(object({
    path_part         = string
    lambda_name       = string
    lambda_invoke_arn = string
  }))
}

variable "child_routes" {
  description = "Second-level routes nested under a top-level route key, e.g. /users/{id}."
  type = map(object({
    parent            = string
    path_part         = string
    lambda_name       = string
    lambda_invoke_arn = string
  }))
  default = {}
}

variable "grandchild_routes" {
  description = "Third-level routes nested under a child route key, e.g. /projects/{id}/artifacts."
  type = map(object({
    parent            = string
    path_part         = string
    lambda_name       = string
    lambda_invoke_arn = string
  }))
  default = {}
}

variable "environment" {
  description = "Environment the API belongs to."
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Additional tags applied to the API."
  type        = map(string)
  default     = {}
}
