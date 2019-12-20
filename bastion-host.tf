#   ----------------------------------------------------------------------------
#   Authentication
#   ----------------------------------------------------------------------------

variable "schedulerUser" {
    description = "Name of the User to connect to the  host"
    default = "consumption"
}

resource "tls_private_key" "scheduler" {
  algorithm   = "RSA"
  rsa_bits    = "2048"
}

output "privateKey" {
  value = "${tls_private_key.scheduler.private_key_pem}"
  sensitive = true
}
output "publicKey" {
  value = "${tls_private_key.scheduler.public_key_pem}"
  sensitive = true
}

resource "local_file" "privateKey" {
    content     = "${tls_private_key.scheduler.private_key_pem}"
    filename = "${path.module}/output/id_rsa.pem"
}

resource "local_file" "publicKey" {
    content     = "${tls_private_key.scheduler.public_key_pem}"
    filename = "${path.module}/output/id_rsa.pub"
}

#   ----------------------------------------------------------------------------
#   Create vLan and Network
#   ----------------------------------------------------------------------------
resource "azurerm_virtual_network" "network" {
    name                = "${local.deploymentname}-vnet"
    address_space       = ["10.0.1.0/24"]
    location            = "${var.location}"
    tags                = "${local.default_tags}" 
    resource_group_name = "${azurerm_resource_group.rg.name}"
}

resource "azurerm_subnet" "subnet-scheduler" {
    name                 = "${local.deploymentname}-subnet-scheduler"
    resource_group_name  = "${azurerm_resource_group.rg.name}"
    virtual_network_name = "${azurerm_virtual_network.network.name}"
    address_prefix       = "10.0.1.0/29"
}

resource "azurerm_network_security_group" "network-security-scheduler" {
    name                = "${local.deploymentname}-nsg-scheduler"
    location            = "${var.location}"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    tags                = "${local.default_tags}" 

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "10.0.1.0/29"
    }
}

resource "azurerm_subnet_network_security_group_association" "scheduler" {
  subnet_id                 = "${azurerm_subnet.subnet-scheduler.id}"
  network_security_group_id = "${azurerm_network_security_group.network-security-scheduler.id}"
}

#   ----------------------------------------------------------------------------
#   Create Networkcard and public IPs
#   ----------------------------------------------------------------------------


resource "azurerm_public_ip" "publicip-scheduler" {
    name                = "pip-${lower(local.deploymentname)}"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    location            = "${var.location}"
    tags                = "${local.default_tags}" 
    allocation_method   = "Static"

}

resource "azurerm_network_interface" "scheduler-nic" {
    name                = "${local.deploymentname}-nic-scheduler"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    location            = "${var.location}"
    tags                = "${local.default_tags}" 
    network_security_group_id = "${azurerm_network_security_group.network-security-scheduler.id}"

    ip_configuration {
        name                          = "${local.deploymentname}-nic-scheduler-ip"
        subnet_id                     = "${azurerm_subnet.subnet-scheduler.id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = "${azurerm_public_ip.publicip-scheduler.id}"
    }
}

output "Scheduler-IP" {
    value = "${azurerm_public_ip.publicip-scheduler.ip_address}"
}

#   ----------------------------------------------------------------------------
#   Define Virtual Machine
#   ----------------------------------------------------------------------------
resource "azurerm_virtual_machine" "scheduler" {
    name                  = "${local.deploymentname}-vm-scheduler"
    location              = "${var.location}"
    tags                  = "${local.default_tags}" 
    resource_group_name   = "${azurerm_resource_group.rg.name}"
    network_interface_ids = ["${azurerm_network_interface.scheduler-nic.id}"]
    vm_size               = "Standard_B1ls"
    delete_os_disk_on_termination    = true
    delete_data_disks_on_termination = true

#   ----------------------------------------------------------------------------
#   Creating Disks
#   ----------------------------------------------------------------------------
    storage_os_disk {
        name              = "${local.deploymentname}-scheduler-disk-os"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
    }

    storage_image_reference {
        publisher = "OpenLogic"
        offer     = "CentOS"
        sku       = "7.5"
        version   = "latest"
    }

#   ----------------------------------------------------------------------------
#   Defining Operating System
#   ----------------------------------------------------------------------------
    os_profile {
        computer_name  = "${local.deploymentname}-scheduler"
        admin_username = "${var.schedulerUser}"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/${var.schedulerUser}/.ssh/authorized_keys"
            key_data = "${tls_private_key.scheduler.public_key_openssh}"
        }
    }

#   ----------------------------------------------------------------------------
#   Set Diagnostics
#   ----------------------------------------------------------------------------
    # boot_diagnostics {
    #     enabled = "true"
    #     storage_uri = "${azurerm_storage_account.diagnostic.primary_blob_endpoint}"
    # }

}

#   ----------------------------------------------------------------------------
#   Post Creation - Install and excute Scripts
#   ----------------------------------------------------------------------------
resource "null_resource" remoteExecProvisionerWFolder {
    depends_on = [azurerm_virtual_machine.scheduler]

    # used for development purposes to execute this step every time
    # triggers = {
    #     key = "${uuid()}"
    # }

    # we will connect from terraform environment via ssh
    # so a private key for the connection is required 
    connection {
        type     = "ssh"
        host     = "${azurerm_public_ip.publicip-scheduler.ip_address}"
        user     = "${var.schedulerUser}"
        agent    = false
        private_key = "${tls_private_key.scheduler.private_key_pem}"
    }

    provisioner "remote-exec" {
        inline = [
        "mkdir -p /home/${var.schedulerUser}/collector"
     ]
    }

    provisioner "file" {
        source      = "../python/collectVMs.py"
        destination = "/home/${var.schedulerUser}/collector/collect.py"
    }

    provisioner "file" {
        source     = "../python/requirements.txt"
        destination = "/home/${var.schedulerUser}/collector/requirements.txt"
    }

    provisioner "file" {
        source     = "scheduler/"
        destination = "/home/${var.schedulerUser}/"
    }

    provisioner "remote-exec" {
        inline = [
        "chmod u+x /home/${var.schedulerUser}/init.sh",
        "source /home/${var.schedulerUser}/init.sh"
     ]
    }
}
