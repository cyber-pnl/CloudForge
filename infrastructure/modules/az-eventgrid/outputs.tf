output "topic_id" {
  description = "Resource ID of the Event Grid topic."
  value       = azurerm_eventgrid_topic.this.id
}

output "topic_name" {
  description = "Name of the Event Grid topic."
  value       = azurerm_eventgrid_topic.this.name
}

output "topic_endpoint" {
  description = "Endpoint to publish events to (data plane)."
  value       = azurerm_eventgrid_topic.this.endpoint
}