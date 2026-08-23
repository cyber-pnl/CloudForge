output "table_name" {
  description = "Name of the DynamoDB table."
  value       = aws_dynamodb_table.this.name
}

output "table_arn" {
  description = "ARN of the table."
  value       = aws_dynamodb_table.this.arn
}

output "stream_arn" {
  description = "ARN of the table stream. Null when the stream is disabled."
  value       = var.stream_enabled ? aws_dynamodb_table.this.stream_arn : null
}
