# output "location" {
#   value = azurerm_resource_group.aks_rg.location
# }

# output "resource_group_name" {
#   value = azurerm_resource_group.aks_rg.name
# }

# output "aks_cluster_id" {
#   value = azurerm_kubernetes_cluster.aks_cluster.id
# }

# output "aks_cluster_name" {
#   value = azurerm_kubernetes_cluster.aks_cluster.name
# }

# output "acr_name" {
#   value = azurerm_container_registry.acr.name
# }


output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.aks_rg.name
}

output "aks_cluster_name" {
  description = "The name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks_cluster.name
}

output "acr_name" {
  description = "The name of the Azure Container Registry"
  value       = azurerm_container_registry.acr.name
}
