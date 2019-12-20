/*
resource "azurerm_public_ip" "publicip" {
    name                         = "${var.deploymentname}-pip-${var.postfix}"
    location                     = "${var.location}"
    resource_group_name          = "${var.resourceGroup}"
    public_ip_address_allocation = "dynamic"

    tags = "${merge(map(), 
        var.tags 
    )}" 
}
*/

resource "azurerm_availability_set" "avs" {
  name                = "${var.deploymentname}-avs-${var.postfix}"
  resource_group_name = "${var.resourceGroup}"
  location            = "${var.location}"
  managed             = "true"
}

resource "azurerm_network_interface" "nic" {
    count = "${var.servers}"
    name                      = "${var.deploymentname}-nic-${var.postfix}-${count.index+1}"
    location                  = "${var.location}"
    resource_group_name       = "${var.resourceGroup}"
    tags                      = "${var.tags}" 
    internal_dns_name_label   = "${var.deploymentname}-${var.postfix}-${count.index+1}"

    ip_configuration {
        name                          = "${var.deploymentname}-nic-${var.postfix}-${count.index+1}-ip"
        subnet_id                     = "${var.subnet}"
        private_ip_address_allocation = "dynamic"
        #private_ip_address  = "10.0.2.${typeIPrange} ${count.index}"
        #public_ip_address_id          = "${azurerm_public_ip.publicip.id}"
    }
}

resource "azurerm_virtual_machine" "host" {
    count = "${var.servers}"
    depends_on = ["azurerm_availability_set.avs", "azurerm_network_interface.nic"]

    name                  = "${var.deploymentname}-vm-${var.postfix}-${count.index+1}"
    location              = "${var.location}"
    resource_group_name   = "${var.resourceGroup}"
    tags                  = "${var.tags}" 
    vm_size               = "${var.machinesize}"

    network_interface_ids = ["${azurerm_network_interface.nic.*.id[count.index]}"]
    availability_set_id   = "${azurerm_availability_set.avs.id}"

    delete_os_disk_on_termination    = true
    delete_data_disks_on_termination = true

    storage_os_disk {
        name              = "${var.deploymentname}-${var.postfix}-${count.index+1}-disk-os"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_data_disk {
        name              = "${var.deploymentname}-${var.postfix}-${count.index+1}-disk-data"
        caching           = "ReadWrite"
        create_option     = "empty"
        managed_disk_type = "Premium_LRS"
        lun               = 0
        disk_size_gb      = "${var.datadisk_gb}"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "${var.deploymentname}-${var.postfix}-${count.index+1}"
        admin_username = "${var.sshUser}"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/${var.sshUser}/.ssh/authorized_keys"
            key_data = "${var.sshKey}"
        }
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = "${var.diag_storage_uri}"
    }
}