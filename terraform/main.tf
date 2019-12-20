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
  architecture = "1.0"
  status = "stable"
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


#   ----------------------------------------------------------------------------
#   Central Database
#   ----------------------------------------------------------------------------

# used to generate unique db name
resource "random_integer" "dbri" {
  min = 10000
  max = 99999
}

resource "azurerm_cosmosdb_account" "mongo-cosmos-db" {
  name                = "mongo-${lower(local.deploymentname)}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${var.location}"
  tags                = "${local.default_tags}" 
  offer_type          = "Standard"
  kind                = "MongoDB"

    #enableMultipleWriteLocations = "false"
    #isVirtualNetworkFilterEnabled = "false"

  consistency_policy {
    consistency_level       = "BoundedStaleness" # or Strong for write = read
    max_interval_in_seconds = 10
    max_staleness_prefix    = 200
  }

  geo_location {
    location          = "${var.location}"
    failover_priority = 0
  }
}

resource "azurerm_cosmosdb_mongo_database" "consumption" {
  name                = "${var.databaseName}" #"${lower(local.deploymentname)}"
  resource_group_name = "${azurerm_cosmosdb_account.mongo-cosmos-db.resource_group_name}"
  account_name        = "${azurerm_cosmosdb_account.mongo-cosmos-db.name}"
}

resource "azurerm_cosmosdb_mongo_collection" "consumption" {
  name                = "${var.collectionName}"
  resource_group_name = "${azurerm_cosmosdb_account.mongo-cosmos-db.resource_group_name}"
  account_name        = "${azurerm_cosmosdb_account.mongo-cosmos-db.name}"
  database_name       = "${azurerm_cosmosdb_mongo_database.consumption.name}"

# default_ttl_seconds = "777"
# shard_key           = "uniqueKey"

# indexes {
#     key    = "cluster"
#     unique = false
# }

#   indexes {
#     key    = "uniqueKey"
#     unique = true
#   }
}

 output "ConnectionString-PAK-RW" {
 	value = "${azurerm_cosmosdb_account.mongo-cosmos-db.connection_strings[0]}"
    description = "Connection String ReadWrite with Primary Access Key"
 }

 output "ConnectionString-PAK-RO" {
 	value = "${azurerm_cosmosdb_account.mongo-cosmos-db.connection_strings[2]}"
  description = "Connection String ReadOnly with Primary Access Key"
 }
