resource "azurerm_user_assigned_identity" "this" {
  name                = var.identity_name
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = merge(
    {
      Name      = var.identity_name
      ManagedBy = "opentofu"
    },
    var.tags,
  )
}