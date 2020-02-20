# Common Objects for Monitoring and diagnostics are created here

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "diagnostic" {
    name                        = "${local.deploymentnameCN}diag"
    resource_group_name         = azurerm_resource_group.rg.name
    location                    = var.location
    account_tier                = "Standard"
    account_replication_type    = "LRS"
    
    tags                        = local.default_tags
}