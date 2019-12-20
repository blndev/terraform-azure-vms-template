#variable "client_secret" {}
provider "azurerm" {
    version = ">=1.32"


    #subscription_id = "00000000-0000-0000-0000-000000000000"
    #client_id       = "00000000-0000-0000-0000-000000000000"
    #client_secret   = "${var.client_secret}"
    #tenant_id       = "00000000-0000-0000-0000-000000000000"
}


#   ----------------------------------------------------------------------------
#   Developer Information
#   ----------------------------------------------------------------------------

locals {
  architecture = "0.1"
  status = "development"
}

## Snippet to Manage Tags 
# tags = "${merge(map( 
#     "newtag", "newtagvalue"
#     ), 
#     local.default_tags 
# )}" 


#   ----------------------------------------------------------------------------
#   Resourcegroups
#   ----------------------------------------------------------------------------

resource "azurerm_resource_group" "rg" {
  name     = "${local.deploymentname}"
  location = "${var.location}"
  tags     = "${local.default_tags}" 
}

