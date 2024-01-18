output "cluster_name" {
  description = "Name of the AKS cluster."
  value       = module.cluster.aks_name
}

output "base_domain" {
  description = "The base domain for the cluster."
  value       = var.base_domain
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = module.cluster.oidc_issuer_url
}

output "node_resource_group_name" {
  description = "The name of the resource group in which the cluster was created."
  value       = resource.azurerm_resource_group.this.name
}

output "kubernetes_host" {
  description = "Endpoint for your Kubernetes API server."
  value       = module.cluster.admin_host
}

output "kubernetes_username" {
  description = "Username for Kubernetes basic auth."
  value       = module.cluster.admin_username
}

output "kubernetes_password" {
  description = "Password for Kubernetes basic auth."
  value       = module.cluster.admin_password
  sensitive   = true
}

output "kubernetes_cluster_ca_certificate" {
  description = "Certificate data required to communicate with the cluster."
  value       = base64decode(module.cluster.admin_cluster_ca_certificate)
  sensitive   = true
}

output "kubernetes_client_key" {
  description = "Certificate Client Key required to communicate with the cluster."
  value       = base64decode(module.cluster.admin_client_key)
  sensitive   = true
}

output "kubernetes_client_certificate" {
  description = "Certificate Client Certificate required to communicate with the cluster."
  value       = base64decode(module.cluster.admin_client_certificate)
  sensitive   = true
}
