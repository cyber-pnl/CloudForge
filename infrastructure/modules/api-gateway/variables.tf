variable "api_name" {
  description = "Name of the REST API."
  type        = string
}

variable "stage_name" {
  description = "Name of the deployed stage."
  type        = string
  default     = "dev"
}

variable "routes" {
  description = "Top-level routes exposed by the API, each backed by a Lambda proxy integration."
  type = list(object({
    path_part         = string
    lambda_name       = string
    lambda_invoke_arn = string
  }))
}

variable "environment" {
  description = "Environment the API belongs to."
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Additional tags applied to all API resources."
  type        = map(string)
  default     = {}
}
