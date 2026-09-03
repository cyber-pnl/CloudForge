resource "azurerm_storage_account" "this" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  blob_properties {
    versioning_enabled = true
  }

  tags = merge(
    {
      Name        = var.storage_account_name
      Environment = var.resource_group_name
      ManagedBy   = "opentofu"
    },
    var.tags,
  )
}

resource "azurerm_storage_container" "this" {
  for_each = var.containers

  name                  = each.value
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}

resource "azurerm_storage_queue" "this" {
  for_each = var.queues

  name                 = each.value
  storage_account_name = azurerm_storage_account.this.name
}
