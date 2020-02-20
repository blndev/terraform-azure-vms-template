#   ----------------------------------------------------------------------------
#   Create vLan and Network
#   ----------------------------------------------------------------------------
resource "azurerm_virtual_network" "network" {
    name                = "${local.deploymentname}-vnet"
    address_space       = ["10.99.99.0/24"]
    location            = var.location
    tags                = local.default_tags
    resource_group_name = azurerm_resource_group.rg.name
}

#   ----------------------------------------------------------------------------
#   Bastion Network
#   ----------------------------------------------------------------------------
resource "azurerm_subnet" "subnet-bastion" {
    name                 = "${local.deploymentname}-subnet-bastion"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.network.name
    address_prefix       = "10.99.99.0/29"
}

resource "azurerm_network_security_group" "network-security-bastion" {
    name                = "${local.deploymentname}-nsg-bastion"
    location            = var.location
    resource_group_name = azurerm_resource_group.rg.name
    tags                = local.default_tags

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "10.99.99.0/29"
    }
}
resource "azurerm_subnet_network_security_group_association" "bastion" {
  subnet_id                 = azurerm_subnet.subnet-bastion.id
  network_security_group_id = azurerm_network_security_group.network-security-bastion.id
}


#   ----------------------------------------------------------------------------
#   Cluster Network - Mgmt
#   ----------------------------------------------------------------------------
resource "azurerm_subnet" "subnet-cluster-mgmt" {
    name                 = "${local.deploymentname}-subnet-cluster-mgmt"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.network.name
    address_prefix       = "10.99.99.32/27"
}

resource "azurerm_network_security_group" "network-security-cluster-mgmt" {
    name                = "${local.deploymentname}-nsg-cluster-mgmt"
    location            = var.location
    resource_group_name = azurerm_resource_group.rg.name
    tags                = local.default_tags

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "10.99.99.0/29"
        destination_address_prefix = "10.99.99.32/27"
    }
}
resource "azurerm_subnet_network_security_group_association" "cluster-mgmt" {
  subnet_id                 = azurerm_subnet.subnet-cluster-mgmt.id
  network_security_group_id = azurerm_network_security_group.network-security-cluster-mgmt.id
}

#   ----------------------------------------------------------------------------
#   Cluster Network - Data
#   ----------------------------------------------------------------------------
resource "azurerm_subnet" "subnet-cluster-data" {
    name                 = "${local.deploymentname}-subnet-cluster-data"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.network.name
    address_prefix       = "10.99.99.64/27"
}

resource "azurerm_network_security_group" "network-security-cluster-data" {
    name                = "${local.deploymentname}-nsg-cluster-data"
    location            = var.location
    resource_group_name = azurerm_resource_group.rg.name
    tags                = local.default_tags

    security_rule {
        name                       = "ANY"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "10.99.99.64/27"
    }
}
resource "azurerm_subnet_network_security_group_association" "cluster-data" {
  subnet_id                 = azurerm_subnet.subnet-cluster-data.id
  network_security_group_id = azurerm_network_security_group.network-security-cluster-data.id
}