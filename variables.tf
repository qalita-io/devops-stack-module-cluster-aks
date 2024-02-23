#######################
## Standard variables
#######################

variable "cluster_name" {
  description = "The name of the Kubernetes cluster to create."
  type        = string
}

variable "base_domain" {
  description = "The base domain used for ingresses. If not provided, nip.io will be used taking the NLB IP address."
  type        = string
}

variable "subdomain" {
  description = "The subdomain used for ingresses."
  type        = string
  default     = "apps"
  nullable    = false
}

variable "location" {
  description = "The location where the Kubernetes cluster will be created along side with it's own resource group and associated resources."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the common resource group (for example, where the virtual network and the DNS zone resides)."
  type        = string
}

variable "dns_zone_resource_group_name" {
  description = "The name of the resource group which contains the DNS zone for the base domain."
  type        = string
  default     = "default"
}

variable "sku_tier" {
  description = "The SKU Tier that should be used for this Kubernetes Cluster. Possible values are `Free` and `Standard`"
  type        = string
  default     = "Free"

  validation {
    condition     = contains(["Free", "Standard"], var.sku_tier)
    error_message = "The SKU Tier must be either `Free` or `Standard`. `Paid` is no longer supported since AzureRM provider v3.51.0."
  }
}

variable "kubernetes_version" {
  description = "The Kubernetes version to use on the control-plane."
  type        = string
  default     = "1.28"
}

variable "automatic_channel_upgrade" {
  description = "The upgrade channel for this Kubernetes Cluster. Possible values are `patch`, `rapid`, `node-image` and `stable`. By default automatic-upgrades are turned off. Note that you cannot specify the patch version using `kubernetes_version` or `orchestrator_version` when using the `patch` upgrade channel. See https://learn.microsoft.com/en-us/azure/aks/auto-upgrade-cluster[the documentation] for more information."
  type        = string
  default     = null

  validation {
    condition = var.automatic_channel_upgrade == null ? true : contains([
      "patch", "stable", "rapid", "node-image"
    ], var.automatic_channel_upgrade)
    error_message = "Possible values for `automatic_channel_upgrade` are `patch`, `stable`, `rapid` or `node-image`."
  }
}

variable "maintenance_window" {
  description = "Maintenance window configuration of the managed cluster. Only has an effect if the automatic upgrades are enabled using the variable `automatic_channel_upgrade`. Please check the variable of the same name https://github.com/Azure/terraform-azurerm-aks/blob/main/variables.tf[on the original module] for more information and to see the required values."
  type        = any
  default     = null
}

variable "node_os_channel_upgrade" {
  description = "The upgrade channel for this Kubernetes Cluster Nodes' OS Image. Possible values are `Unmanaged`, `SecurityPatch`, `NodeImage` and `None`."
  type        = string
  default     = null

  validation {
    condition = var.node_os_channel_upgrade == null ? true : contains([
      "Unmanaged", "SecurityPatch", "NodeImage", "None"
    ], var.node_os_channel_upgrade)
    error_message = "Possible values for `node_os_channel_upgrade` are `Unmanaged`, `SecurityPatch`, `NodeImage` and `None`."
  }
}

variable "maintenance_window_node_os" {
  description = "Maintenance window configuration for this Kubernetes Cluster Nodes' OS Image. Only has an effect if the automatic upgrades are enabled using the variable `node_os_channel_upgrade`. Please check the variable of the same name https://github.com/Azure/terraform-azurerm-aks/blob/main/variables.tf[on the original module] for more information and to see the required values."
  type        = any
  default     = null
}

variable "virtual_network_name" {
  description = "The name of the virtual network where to deploy the cluster."
  type        = string
}

variable "cluster_subnet" {
  description = "The subnet CIDR where to deploy the cluster, included in the virtual network created."
  type        = string
}

# TODO The network plugin on the original azurerm resource seems to be starting to have support for Cilium, but the Azure/aks/azurerm module does not yet support it.
variable "network_policy" {
  description = "Sets up network policy to be used with Azure CNI. https://docs.microsoft.com/azure/aks/use-network-policies[Network policy allows us to control the traffic flow between pods.] Currently supported values are `calico` and `azure`. Changing this forces a new resource to be created."
  type        = string
  default     = "azure"
  nullable    = false

  validation {
    condition     = contains(["calico", "azure"], var.network_policy)
    error_message = "The network policy must be either `calico` and `azure`"
  }
}

variable "rbac_aad_admin_group_object_ids" {
  description = "Object IDs of groups with administrator access to the cluster."
  type        = list(string)
  default     = null
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Any tags that should be present on the AKS cluster resources."
}

################################
## Default node pool variables
################################

variable "agents_pool_name" {
  description = "The default Azure AKS node pool name."
  type        = string
  default     = "default"
  nullable    = false
}

variable "agents_labels" {
  type        = map(string)
  default     = {}
  description = "A map of Kubernetes labels which should be applied to nodes in the default node pool. Changing this forces a new resource to be created."
}

variable "agents_size" {
  description = "The default virtual machine size for the Kubernetes agents. Changing this without specifying `var.temporary_name_for_rotation` forces a new resource to be created. " # TODO Add link to documentation to get available sizes
  type        = string
  default     = "Standard_D2s_v3"
}

variable "agents_count" {
  description = "The number of nodes that should exist in the default node pool."
  type        = number
  default     = 3
}

variable "agents_max_pods" {
  description = "The maximum number of pods that can run on each agent. Changing this forces a new resource to be created."
  type        = number
  default     = null
}

variable "agents_pool_max_surge" {
  type        = string
  description = "The maximum number or percentage of nodes which will be added to the default node pool size during an upgrade."
  default     = "10%"
}

variable "temporary_name_for_rotation" {
  description = "Specifies the name of the temporary node pool used to cycle the default node pool for VM resizing. The `var.agents_size` is no longer ForceNew and can be resized by specifying `temporary_name_for_rotation`."
  type        = string
  default     = null
}

variable "orchestrator_version" {
  description = "The Kubernetes version to use for the default node pool. If undefined, defaults to the most recent version available on Azure."
  type        = string
  default     = null
}

variable "os_disk_size_gb" {
  description = "Disk size for default node pool nodes in GBs. The disk type created is by default `Managed`."
  type        = number
  default     = 50
}

###############################
## Extra node pools variables
###############################

variable "node_pools" {
  description = "A map of node pools that need to be created and attached on the Kubernetes cluster. The key of the map can be the name of the node pool, and the key must be a static string. The required value for the map is a `node_pool` block as defined in the variable of the same name present in the original module, available https://github.com/Azure/terraform-azurerm-aks/blob/main/variables.tf[here]."
  type        = any
  default     = {}
  nullable    = false
}
