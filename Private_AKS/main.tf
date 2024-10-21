######### ONLY BASHAN IP IS ACCESS THE AKS ##############

terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Generate a random pet name for unique naming
resource "random_pet" "unique_name" {
  length = 2  # Generates a name with two words, e.g., "happy-llama"
}

# Resource Group
resource "azurerm_resource_group" "aks_rg" {
  name     = "${var.resource_group_name}-${var.environment}"
  location = var.location
}

# Virtual Network
resource "azurerm_virtual_network" "aksvnet" {
  name                = "${var.resource_group_name}-${var.environment}-vnet"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  address_space       = ["10.0.0.0/8"]
}

# Subnet for AKS
resource "azurerm_subnet" "aks_subnet" {
  name                 = "${var.resource_group_name}-${var.environment}-aks-subnet"
  virtual_network_name = azurerm_virtual_network.aksvnet.name
  resource_group_name  = azurerm_resource_group.aks_rg.name
  address_prefixes     = ["10.240.0.0/16"]
}

# Subnet for Bastion Host
resource "azurerm_subnet" "bastion_subnet" {
  name                 = "${var.resource_group_name}-${var.environment}-bastion-subnet"
  virtual_network_name = azurerm_virtual_network.aksvnet.name
  resource_group_name  = azurerm_resource_group.aks_rg.name
  address_prefixes     = ["10.241.0.0/24"]
}

# Network Security Group (NSG) for the AKS Subnet
resource "azurerm_network_security_group" "aks_nsg" {
  name                = "${var.resource_group_name}-${var.environment}-aks-nsg"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name

  security_rule {
    name                       = "allow-bastion-access"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = azurerm_subnet.bastion_subnet.address_prefixes[0]
    destination_address_prefix = "*"
  }
}

# Associate NSG with the AKS Subnet
resource "azurerm_subnet_network_security_group_association" "aks_subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.aks_subnet.id
  network_security_group_id = azurerm_network_security_group.aks_nsg.id
}

# Bastion Host NSG
resource "azurerm_network_security_group" "bastion_nsg" {
  name                = "${var.resource_group_name}-${var.environment}-bastion-nsg"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name

  security_rule {
    name                       = "allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate NSG with the Bastion Subnet
resource "azurerm_subnet_network_security_group_association" "bastion_subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.bastion_subnet.id
  network_security_group_id = azurerm_network_security_group.bastion_nsg.id
}

# Public IP for the Bastion Host
resource "azurerm_public_ip" "bastion_public_ip" {
  name                = "${var.resource_group_name}-${var.environment}-bastion-pip"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"  # Recommended for production use
}

# Network Interface for the Bastion Host
resource "azurerm_network_interface" "bastion_nic" {
  name                = "${var.resource_group_name}-${var.environment}-bastion-nic"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.bastion_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.bastion_public_ip.id  # Associate Public IP
  }
}

# Azure Bastion Host
resource "azurerm_linux_virtual_machine" "bastion" {
  name                = "${var.resource_group_name}-${var.environment}-bastion"
  resource_group_name = azurerm_resource_group.aks_rg.name
  location            = azurerm_resource_group.aks_rg.location
  size                = var.bastion_vm_size
  admin_username      = "azureuser"


    provisioner "remote-exec" {
    connection {
      type        = "ssh"
      host        = azurerm_public_ip.bastion_public_ip.ip_address
      user        = "azureuser"
      private_key = file(var.ssh_private_key)
    }

    inline = [
      "echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections",
      "sudo apt-get update -y",
      "sudo apt-get upgrade -y",
      "sudo curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl",
      "sudo chmod +x ./kubectl",
      "sudo mv ./kubectl /usr/local/bin/kubectl",
      "sudo curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3",
      "chmod 700 get_helm.sh",
      "./get_helm.sh",
      "curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash"
    ]
  }






  
  network_interface_ids = [
    azurerm_network_interface.bastion_nic.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  admin_ssh_key {
    username   = "azureuser"
    public_key = file(var.ssh_public_key)
  }
}

# Azure Kubernetes Cluster (AKS)
resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = "${var.resource_group_name}-${var.environment}-cluster"  # Ensure name is within the limit
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  dns_prefix          = "${var.resource_group_name}-${var.environment}-dns"

  default_node_pool {
    name       = "systempool"
    vm_size    = var.node_vm_size
    node_count = 1  # Set this to 1 or more
    node_labels = {
      "nodepool-type" = "system"
      "environment"   = var.environment
    }
    vnet_subnet_id = azurerm_subnet.aks_subnet.id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }

  private_cluster_enabled = true

  linux_profile {
    admin_username = "azureuser"
    ssh_key {
      key_data = file(var.ssh_public_key)
    }
  }

  tags = {
    Environment = var.environment
  }
}

# Azure Container Registry (ACR)
resource "azurerm_container_registry" "acr" {
  name                = lower(var.acr_name)
  resource_group_name = azurerm_resource_group.aks_rg.name
  location            = azurerm_resource_group.aks_rg.location
  sku                 = var.acr_sku
  admin_enabled       = true
}

# Assign ACR Pull Permission to AKS
resource "azurerm_role_assignment" "acr_pull" {
  principal_id         = azurerm_kubernetes_cluster.aks_cluster.identity[0].principal_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.acr.id
}



###################################################################
# terraform {
#   required_version = ">= 1.0"

#   required_providers {
#     azurerm = {
#       source  = "hashicorp/azurerm"
#       version = "~> 3.0"
#     }
#     azuread = {
#       source  = "hashicorp/azuread"
#       version = "~> 2.0"
#     }
#     random = {
#       source  = "hashicorp/random"
#       version = "~> 3.0"
#     }
#   }
# }

# provider "azurerm" {
#   features {}
# }

# # Resource Group
# resource "azurerm_resource_group" "aks_rg" {
#   name     = "${var.resource_group_name}-${var.environment}"
#   location = var.location
# }

# # Virtual Network
# resource "azurerm_virtual_network" "aksvnet" {
#   name                = "${var.resource_group_name}-${var.environment}-vnet"
#   location            = azurerm_resource_group.aks_rg.location
#   resource_group_name = azurerm_resource_group.aks_rg.name
#   address_space       = ["10.0.0.0/8"]
# }

# # Subnet for AKS
# resource "azurerm_subnet" "aks_subnet" {
#   name                 = "${var.resource_group_name}-${var.environment}-aks-subnet"
#   virtual_network_name = azurerm_virtual_network.aksvnet.name
#   resource_group_name  = azurerm_resource_group.aks_rg.name
#   address_prefixes     = ["10.240.0.0/16"]
# }

# # Network Security Group (NSG) for the AKS Subnet
# resource "azurerm_network_security_group" "aks_nsg" {
#   name                = "${var.resource_group_name}-${var.environment}-nsg"
#   location            = azurerm_resource_group.aks_rg.location
#   resource_group_name = azurerm_resource_group.aks_rg.name

#   security_rule {
#     name                       = "allow-all"
#     priority                   = 100
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "*"
#     source_port_range          = "*"
#     destination_port_range     = "*"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }
# }

# # Associate NSG with the AKS Subnet
# resource "azurerm_subnet_network_security_group_association" "aks_subnet_nsg_association" {
#   subnet_id                 = azurerm_subnet.aks_subnet.id
#   network_security_group_id = azurerm_network_security_group.aks_nsg.id
# }

# # Azure Kubernetes Cluster (AKS)
# resource "azurerm_kubernetes_cluster" "aks_cluster" {
#   name                = "${azurerm_resource_group.aks_rg.name}-cluster"
#   location            = azurerm_resource_group.aks_rg.location
#   resource_group_name = azurerm_resource_group.aks_rg.name
#   dns_prefix          = "${azurerm_resource_group.aks_rg.name}-cluster"
  
#   default_node_pool {
#     name       = "systempool"
#     vm_size    = var.node_vm_size
#     node_count = 1  # Set this to 1 or more
#     node_labels = {
#       "nodepool-type" = "system"
#       "environment"   = var.environment
#     }
#     vnet_subnet_id = azurerm_subnet.aks_subnet.id
#   }

#   identity {
#     type = "SystemAssigned"
#   }

#   network_profile {
#     network_plugin    = "azure"
#     load_balancer_sku = "standard"
#   }

#   private_cluster_enabled = true

#   linux_profile {
#     admin_username = "azureuser"
#     ssh_key {
#       key_data = file(var.ssh_public_key)
#     }
#   }

#   tags = {
#     Environment = var.environment
#   }
# }

# # Azure Container Registry (ACR)
# resource "azurerm_container_registry" "acr" {
#   name                = lower(var.acr_name)
#   resource_group_name = azurerm_resource_group.aks_rg.name
#   location            = azurerm_resource_group.aks_rg.location
#   sku                 = var.acr_sku
#   admin_enabled       = true
# }

# # Assign ACR Pull Permission to AKS
# resource "azurerm_role_assignment" "acr_pull" {
#   principal_id         = azurerm_kubernetes_cluster.aks_cluster.identity[0].principal_id
#   role_definition_name = "AcrPull"
#   scope                = azurerm_container_registry.acr.id
# }

# # Random Pet Resource for Unique Naming
# resource "random_pet" "gke_random" {}

# # Public IP for Bastion Host
# resource "azurerm_public_ip" "bastion_public_ip" {
#   name                = "${var.resource_group_name}-${var.environment}-bastion-pip"
#   location            = azurerm_resource_group.aks_rg.location
#   resource_group_name = azurerm_resource_group.aks_rg.name
#   allocation_method   = "Static"
#   sku                 = "Standard"
# }

# # Network Interface for Bastion Host
# resource "azurerm_network_interface" "bastion_nic" {
#   name                = "${var.resource_group_name}-${var.environment}-bastion-nic"
#   location            = azurerm_resource_group.aks_rg.location
#   resource_group_name = azurerm_resource_group.aks_rg.name

#   ip_configuration {
#     name                          = "bastion-ip-config"
#     subnet_id                     = azurerm_subnet.aks_subnet.id
#     private_ip_address_allocation = "Dynamic"
#     public_ip_address_id          = azurerm_public_ip.bastion_public_ip.id
#   }
# }

# # Network Security Group Rule for SSH Access to Bastion Host
# resource "azurerm_network_security_rule" "allow_ssh" {
#   name                        = "Allow-SSH"
#   priority                    = 1000
#   direction                   = "Inbound"
#   access                      = "Allow"
#   protocol                    = "Tcp"
#   source_port_range           = "*"
#   destination_port_range      = "22"
#   source_address_prefix       = "*"
#   destination_address_prefix  = "*"
#   resource_group_name         = azurerm_resource_group.aks_rg.name
#   network_security_group_name = azurerm_network_security_group.aks_nsg.name
# }

# # Bastion Host (Linux VM)
# resource "azurerm_linux_virtual_machine" "bastion_host" {
#   name                = "${var.resource_group_name}-${var.environment}-bastion"
#   resource_group_name = azurerm_resource_group.aks_rg.name
#   location            = azurerm_resource_group.aks_rg.location
#   size                = "Standard_B2s"
#   admin_username      = "azureuser"
  
#   network_interface_ids = [azurerm_network_interface.bastion_nic.id]

#   admin_ssh_key {
#     username   = "azureuser"
#     public_key = file(var.ssh_public_key)
#   }

#   os_disk {
#     caching              = "ReadWrite"
#     storage_account_type = "Standard_LRS"
#     disk_size_gb         = 30
#   }

#   source_image_reference {
#     publisher = "Canonical"
#     offer     = "UbuntuServer"
#     sku       = "18.04-LTS"
#     version   = "latest"
#   }

#   tags = {
#     Environment = var.environment
#   }
# }
