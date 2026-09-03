resource "azurerm_resource_group" "datasync-rg" {
  name = "datasync-rg"
  location = "North Europe"
}

resource "azurerm_storage_account" "datasync-sa" {
  name = "datasyncstorageaccountte"
  resource_group_name = azurerm_resource_group.datasync-rg.name
  location = azurerm_resource_group.datasync-rg.location
  account_tier = "Standard"
  account_replication_type = "LRS"
  account_kind = "StorageV2"

  tags = {
    Project = "InternalApp"
  }
}

resource "azurerm_storage_container" "datasync-source" {
  name = "datasync-source"
  storage_account_name = azurerm_storage_account.datasync-sa.name
  container_access_type = "private"
}