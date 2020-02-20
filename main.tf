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
  name     = local.deploymentname
  location = var.location
  tags     = local.default_tags
}

resource "tls_private_key" "cluster" {
  algorithm   = "RSA"
  rsa_bits    = "2048"
}
module "openstack" {
  source = "./TF_Server"

  servers = var.servercount
  machinesize = var.serversize
  postfix = "worker"

  resourceGroup = azurerm_resource_group.rg.name
  diag_storage_uri = azurerm_storage_account.diagnostic.primary_blob_endpoint
  sshKey = tls_private_key.cluster.public_key_openssh

  deploymentname = local.deploymentname
  location = var.location

  subnet-data = azurerm_subnet.subnet-cluster-data.id
  subnet-mgmt = azurerm_subnet.subnet-cluster-mgmt.id
  tags = local.default_tags
}


output "openstack-servers-mgmt" {
  value = module.openstack.servers-mgmt
}

output "openstack-servers-data" {
  value = module.openstack.servers-data
}