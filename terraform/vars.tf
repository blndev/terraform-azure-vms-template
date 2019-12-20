#   ----------------------------------------------------------------------------
#   Configuration Variables
#   ----------------------------------------------------------------------------

variable "location" { 
    default = "westeurope"
    description="use \"az account list-locations\" to see available locations"
}
variable "deploymentprefix" { default = "Openstack" }


#   ----------------------------------------------------------------------------
#   Tags
#   ----------------------------------------------------------------------------
variable "tagOwner" { 
    description = "Added as Tag to all created Resources called 'owner'. Used to identify you."
}

variable "tagStage" { 
    description = "Added as Tag to all created Resources called 'stage'"
    default = "development" 
}
variable "tagDescription" { 
    description = "This Text will be added as a Tag 'Info' to all created resources"
    default = "MCSPaaS-Consumption" 
}

#   ----------------------------------------------------------------------------
#   Database Configuration
#   ----------------------------------------------------------------------------

variable "databaseName" { 
    default = "Consumption"
    description = "Name of the Database which stores the Data inside the MongoDB Server"
}

variable "collectionName" { 
    default = "Kubernetes"
    description = "Name of the collection which stores the Data inside the MongoDB Database"
}


#   ----------------------------------------------------------------------------
#   Calculated Variables
#   ----------------------------------------------------------------------------

resource "random_id" "deploymentsuffix" {
    keepers = {
        # Generate a new ID only when a new prefix is defined
        resource_group = "${var.deploymentprefix}"
    }
    byte_length = 2
}

locals {
  deploymentname = "${var.deploymentprefix}-${random_id.deploymentsuffix.hex}"
  deploymentnameCN = "${var.deploymentprefix}${random_id.deploymentsuffix.hex}" # only characters and numbers e.g. for storage accounts
}

locals {
default_tags = { 
    Owner               = "${var.tagOwner}" 
    Environment         = "${var.tagStage}"
    DevelopmentStatus   = "${local.status}"
    Architecture        = "${local.architecture}"
    Deployment          = "${local.deploymentname}"
    Info                = "${var.tagDescription}"
  } 
} 