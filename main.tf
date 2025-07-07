data "azurerm_dns_zone" "this" {
  name                = var.base_domain
  resource_group_name = var.dns_zone_resource_group_name
}

resource "azurerm_dns_cname_record" "this" {
  name                = format("*.%s", trimprefix("${var.subdomain}.${var.cluster_name}", "."))
  zone_name           = data.azurerm_dns_zone.this.name
  resource_group_name = var.dns_zone_resource_group_name
  ttl                 = 300
  record              = format("%s-%s.%s.cloudapp.azure.com.", var.cluster_name, replace(data.azurerm_dns_zone.this.name, ".", "-"), resource.azurerm_resource_group.this.location)
}

resource "azurerm_subnet" "this" {
  name                 = "${var.cluster_name}-snet"
  resource_group_name  = var.virtual_network_resource_group_name != null ? var.virtual_network_resource_group_name : var.resource_group_name
  address_prefixes     = [var.cluster_subnet]
  virtual_network_name = var.virtual_network_name
}

resource "azurerm_resource_group" "this" {
  name     = "${var.cluster_name}-rg"
  location = var.location
}

module "cluster" {
  source  = "Azure/aks/azurerm"
  version = "~> 10.0"
  location = var.location

  cluster_name        = var.cluster_name
  prefix              = var.cluster_name
  resource_group_name = resource.azurerm_resource_group.this.name

  sku_tier           = var.sku_tier
  kubernetes_version = var.kubernetes_version

  automatic_channel_upgrade  = var.automatic_channel_upgrade
  maintenance_window         = var.maintenance_window
  node_os_channel_upgrade    = var.node_os_channel_upgrade
  maintenance_window_node_os = var.maintenance_window_node_os

  vnet_subnet                          = resource.azurerm_subnet.this.id
  azure_policy_enabled                 = true
  cluster_log_analytics_workspace_name = var.cluster_name
  private_cluster_enabled              = false
  network_plugin                       = "azure"
  network_policy                       = var.network_policy

  key_vault_secrets_provider_enabled = true
  log_analytics_workspace_enabled    = false
  oidc_issuer_enabled                = true
  rbac_aad_admin_group_object_ids    = var.rbac_aad_admin_group_object_ids
  role_based_access_control_enabled  = true
  workload_identity_enabled          = true

  tags = var.tags

  # Settings for the default node pool
  agents_pool_name            = var.agents_pool_name
  agents_labels               = merge({ "devops-stack.io/nodepool" = "default" }, var.agents_labels)
  agents_count                = var.agents_count
  agents_size                 = var.agents_size
  agents_max_pods             = var.agents_max_pods
  agents_pool_max_surge       = var.agents_pool_max_surge
  temporary_name_for_rotation = var.temporary_name_for_rotation
  orchestrator_version        = var.orchestrator_version
  os_disk_size_gb             = var.os_disk_size_gb

  # Extra node pools
  node_pools = { for k, v in var.node_pools : k => merge({
    name           = k
    vnet_subnet_id = resource.azurerm_subnet.this.id
    tags           = var.tags
    }, v, {
    node_labels = merge({
      "devops-stack.io/nodepool" = k
    }, v.node_labels)
    })
  }

  depends_on = [
    resource.azurerm_subnet.this,
    resource.azurerm_resource_group.this,
  ]
}
