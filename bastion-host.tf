#   ----------------------------------------------------------------------------
#   Authentication
#   ----------------------------------------------------------------------------


resource "tls_private_key" "bastion" {
  algorithm   = "RSA"
  rsa_bits    = "2048"
}

output "privateKey" {
  value = "${tls_private_key.bastion.private_key_pem}"
  sensitive = true
}
output "publicKey" {
  value = "${tls_private_key.bastion.public_key_pem}"
  sensitive = true
}

resource "local_file" "privateKey" {
    content     = "${tls_private_key.bastion.private_key_pem}"
    filename = "${path.module}/output/id_rsa.pem"
}

resource "local_file" "publicKey" {
    content     = "${tls_private_key.bastion.public_key_pem}"
    filename = "${path.module}/output/id_rsa.pub"
}

#   ----------------------------------------------------------------------------
#   Create Networkcard and public IPs
#   ----------------------------------------------------------------------------


resource "azurerm_public_ip" "publicip-bastion" {
    name                = "pip-${lower(local.deploymentname)}"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    location            = "${var.location}"
    tags                = "${local.default_tags}" 
    allocation_method   = "Dynamic"
    domain_name_label   = "${lower(local.deploymentname)}-bastion"
}

output "ssh" {
    value = "chmod 600 ./output/id_rsa* && ssh ${azurerm_public_ip.publicip-bastion.fqdn} -F sshConfig"
}

resource "azurerm_network_interface" "bastion-nic" {
    name                = "${local.deploymentname}-nic-bastion"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    location            = "${var.location}"
    tags                = "${local.default_tags}" 
    network_security_group_id = "${azurerm_network_security_group.network-security-bastion.id}"

    ip_configuration {
        name                          = "${local.deploymentname}-nic-bastion-ip"
        subnet_id                     = "${azurerm_subnet.subnet-bastion.id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = "${azurerm_public_ip.publicip-bastion.id}"
    }
}

#   ----------------------------------------------------------------------------
#   Define Virtual Machine
#   ----------------------------------------------------------------------------
resource "azurerm_virtual_machine" "bastion" {
    name                  = "${local.deploymentname}-vm-bastion"
    location              = "${var.location}"
    tags                  = "${local.default_tags}" 
    resource_group_name   = "${azurerm_resource_group.rg.name}"
    network_interface_ids = ["${azurerm_network_interface.bastion-nic.id}"]
    vm_size               = "Standard_B2ms"
    delete_os_disk_on_termination    = true
    delete_data_disks_on_termination = true

#   ----------------------------------------------------------------------------
#   Creating Disks
#   ----------------------------------------------------------------------------
    storage_os_disk {
        name              = "${local.deploymentname}-bastion-disk-os"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

#   ----------------------------------------------------------------------------
#   Defining Operating System
#   ----------------------------------------------------------------------------
    os_profile {
        computer_name  = "${local.deploymentname}-bastion"
        admin_username = "${var.sshUser}"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/${var.sshUser}/.ssh/authorized_keys"
            key_data = "${tls_private_key.bastion.public_key_openssh}"
        }
    }

#   ----------------------------------------------------------------------------
#   Set Diagnostics
#   ----------------------------------------------------------------------------
    boot_diagnostics {
        enabled = "true"
        storage_uri = "${azurerm_storage_account.diagnostic.primary_blob_endpoint}"
    }

}

#   ----------------------------------------------------------------------------
#   Post Creation - Install and excute Scripts
#   ----------------------------------------------------------------------------
resource "null_resource" "installBastion" {
    depends_on = [azurerm_virtual_machine.bastion]

    # used for development purposes to execute this step every time
    # triggers = {
    #     key = "${uuid()}"
    # }

    # we will connect from terraform environment via ssh
    # so a private key for the connection is required 
    connection {
        type     = "ssh"
        host     = "${azurerm_public_ip.publicip-bastion.fqdn}"
        user     = "${var.sshUser}"
        agent    = false
        private_key = "${tls_private_key.bastion.private_key_pem}"
    }

    # adding the generated private key to connect to the cluster machines
    provisioner "file" {
        content     = "${tls_private_key.cluster.private_key_pem}"
        destination = "/home/${var.sshUser}/.ssh/id_rsa"
    }

    # setting the default user for the cluster machines to "linux"
    provisioner "file" {
        content     = "Host ${local.deploymentname}*\nUser linux"
        destination = "/home/${var.sshUser}/.ssh/config"
    }

    provisioner "remote-exec" {
        inline = [
        "chmod 600 .ssh/id_rsa",
        "chmod 600 .ssh/config"
     ]
    }


    # provisioner "remote-exec" {
    #     inline = [
    #     "mkdir -p /home/${var.sshUser}/app"
    #  ]
    # }

    # provisioner "file" {
    #     source      = "../python/collectVMs.py"
    #     destination = "/home/${var.sshUser}/collector/collect.py"
    # }

    # provisioner "file" {
    #     source     = "../python/requirements.txt"
    #     destination = "/home/${var.sshUser}/collector/requirements.txt"
    # }

    # provisioner "file" {
    #     source     = "./hostconfig/"
    #     destination = "/home/${var.sshUser}/"
    # }

    # provisioner "remote-exec" {
    #     inline = [
    #     "chmod u+x /home/${var.sshUser}/init.sh"
    #     ,
    #     "source /home/${var.sshUser}/init.sh"
    #  ]
    # }
    provisioner "remote-exec" {
        script     = "./hostconfig/bastion.sh"
    }

}
