# variable "location" {
#   type        = string
#   description = "Azure Region where all these resources will be provisioned"
#   default     = "Central India"
# }

# variable "resource_group_name" {
#   type        = string
#   description = "Resource group name"
#   default     = "terraform-aks"
# }

# variable "environment" {
#   type        = string  
#   description = "Environment name"  
#   default     = "dev"
# }

# variable "ssh_public_key" {
#   type        = string
#   description = "SSH Public Key for Linux k8s Worker nodes"
#   default     = "~/.ssh/aks-prod-sshkeys-terraform/aksprodsshkey.pub"
# }

# variable "node_vm_size" {
#   type        = string
#   description = "The VM size for the AKS node pool"
#   default     = "Standard_DS2_v2"
# }

# variable "node_count_min" {
#   type        = number
#   description = "Minimum number of nodes in the node pool"
#   default     = 1
# }

# variable "node_count_max" {
#   type        = number
#   description = "Maximum number of nodes in the node pool"
#   default     = 3
# }

# variable "acr_sku" {
#   type        = string
#   description = "SKU for the Azure Container Registry"
#   default     = "Standard"
# }

# variable "acr_name" {
#   type        = string
#   description = "The name of the Azure Container Registry."
#   default     = "chandancloudops0101" # Change this to your desired name
# }

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "environment" {
  description = "The environment (e.g., dev, prod)"
  type        = string
}

variable "location" {
  description = "The Azure region to deploy resources"
  type        = string
}

variable "node_vm_size" {
  description = "The size of the virtual machines for the AKS cluster"
  type        = string
  default     = "Standard_DS2_v2"
}

variable "node_count_max" {
  description = "Maximum number of nodes in the AKS cluster"
  type        = number
  default     = 5
}

variable "node_count_min" {
  description = "Minimum number of nodes in the AKS cluster"
  type        = number
  default     = 1
}

variable "ssh_public_key" {
  description = "Path to the SSH public key for AKS"
  type        = string
}

variable "ssh_private_key" {
  description = "Path to the SSH public key for AKS"
  type        = string
}

variable "bastion_vm_size" {
  description = "The size of the virtual machines for the AKS cluster"
  type        = string
  default     = "Standard_B2s"
}
variable "acr_name" {
  description = "The name of the Azure Container Registry (ACR)"
  type        = string
}

variable "acr_sku" {
  description = "The SKU for the Azure Container Registry"
  type        = string
  default     = "Basic"
}
