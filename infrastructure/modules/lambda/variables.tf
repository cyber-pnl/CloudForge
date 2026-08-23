variable "function_name" {
  description = "Name of the Lambda function."
  type        = string
}

variable "source_dir" {
  description = "Directory containing the function source code."
  type        = string
}

variable "output_path" {
  description = "Path of the generated deployment package."
  type        = string
}

variable "handler" {
  description = "Entry point of the function (file.function)."
  type        = string
  default     = "handler.handler"
}

variable "runtime" {
  description = "Lambda runtime identifier."
  type        = string
  default     = "python3.13"
}

variable "memory_size" {
  description = "Memory allocated to the function in megabytes."
  type        = number
  default     = 256
}

variable "timeout" {
  description = "Function timeout in seconds."
  type        = number
  default     = 10
}

variable "log_retention_in_days" {
  description = "CloudWatch Logs retention period for the function logs."
  type        = number
  default     = 14
}

variable "role_arn" {
  description = "ARN of the execution role attached to the function."
  type        = string
}

variable "environment_variables" {
  description = "Environment variables passed to the function."
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "Environment the function belongs to."
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Additional tags applied to all function resources."
  type        = map(string)
  default     = {}
}
