output "bus_name" {
  description = "Name of the custom event bus."
  value       = aws_cloudwatch_event_bus.this.name
}

output "bus_arn" {
  description = "ARN of the custom event bus."
  value       = aws_cloudwatch_event_bus.this.arn
}
