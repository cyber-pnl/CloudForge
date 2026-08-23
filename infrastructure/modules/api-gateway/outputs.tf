output "rest_api_id" {
  description = "Identifier of the REST API."
  value       = aws_api_gateway_rest_api.this.id
}

output "execution_arn" {
  description = "Execution ARN of the REST API."
  value       = aws_api_gateway_rest_api.this.execution_arn
}

output "invoke_url" {
  description = "Base invoke URL of the deployed stage."
  value       = aws_api_gateway_stage.this.invoke_url
}
