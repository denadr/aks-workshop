# Configure the Microsoft Azure Active Directory Provider
# provider "azuread" {
#   version = "=0.7.0"
# }
# Configure the Azure Provider
provider "azurerm" {
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  version = "=2.20.0"
  features {}
}

locals {
  password_expiry_date = "2099-01-01T00:00:00Z"
}

# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = "${var.name}-rg"
  location = "westeurope"
}

# Create a vnet with subnet
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.name}-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/8"]
}
resource "azurerm_subnet" "subnet" {
  name                 = "${var.name}-subnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefixes     = ["10.240.0.0/16"]
}

# Create a log analytics workspace and solution
resource "azurerm_log_analytics_workspace" "workspace" {
  name                = "${var.name}-law"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "PerGB2018"
}
resource "azurerm_log_analytics_solution" "solution" {
  solution_name         = "ContainerInsights"
  workspace_resource_id = azurerm_log_analytics_workspace.workspace.id
  workspace_name        = azurerm_log_analytics_workspace.workspace.name
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}

# Create a container registry
resource "azurerm_container_registry" "acr" {
  name                     = "${var.name}cr"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  sku                      = "Basic"
  admin_enabled            = false
}

# Create service principal
# resource "random_string" "app_secret" {
#   length = 16
# }
# resource "azuread_application" "app_registration" {
#   name = "${var.name}-aks-sp"
# }
# resource "azuread_application_password" "app_password" {
#   application_object_id = azuread_application.app_registration.id
#   value                 = random_string.app_secret.result
#   end_date              = local.password_expiry_date
# }
# resource "random_string" "principal_secret" {
#   length = 16
# }
# resource "azuread_service_principal" "service_principal" {
#   application_id = azuread_application.app_registration.application_id
# }
# resource "azuread_service_principal_password" "service_principal" {
#   service_principal_id = azuread_service_principal.service_principal.id
#   value                = random_string.principal_secret.result
#   end_date             = local.password_expiry_date
# }

# # Allow service principal to pull from Azure Container Registry
# resource "azurerm_role_assignment" "assignment" {
#   scope                = azurerm_container_registry.acr.id
#   role_definition_name = "AcrPull"
#   principal_id         = azuread_service_principal.service_principal.object_id
# }

# Create a k8s cluster
resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = "${var.name}-aks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "${var.name}-dns"
  kubernetes_version  = "1.17.7"

  default_node_pool {
    name           = "default"
    node_count     = 1
    vm_size        = "Standard_B2s"
    vnet_subnet_id = azurerm_subnet.subnet.id
    type           = "VirtualMachineScaleSets"
  }

  network_profile {
    network_plugin = "azure"
  }

  # Assign the service principal
  # service_principal {
  #   client_id     = azuread_service_principal.service_principal.application_id
  #   client_secret = random_string.principal_secret.result
  # }
  identity {
    type = "SystemAssigned"
  }

  addon_profile {
    kube_dashboard {
      enabled = true
    }

    # Enable Azure Monitor for Containers
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.workspace.id
    }
  }
}

output "aks" {
  value = azurerm_kubernetes_cluster.aks_cluster
}
# output "app" {
#   value = azuread_application.app_registration
# }
# output "appPw" {
#   value = azuread_application_password.app_password
# }
# output "appPwStr" {
#   value = random_string.app_secret.result
# }
# output "principal" {
#   value = azuread_service_principal.service_principal
# }
# output "principalPw" {
#   value = azuread_service_principal_password.service_principal
# }
# output "principalPwStr" {
#   value = random_string.principal_secret.result
# }

data "azurerm_public_ip" "load_balancer_ip" {
  name                = split("/", sort(azurerm_kubernetes_cluster.aks_cluster.network_profile[0].load_balancer_profile[0].effective_outbound_ips)[0])[length(split("/", sort(azurerm_kubernetes_cluster.aks_cluster.network_profile[0].load_balancer_profile[0].effective_outbound_ips)[0])) - 1]
  resource_group_name = "MC_${azurerm_resource_group.rg.name}_${azurerm_kubernetes_cluster.aks_cluster.name}_${azurerm_resource_group.rg.location}"

  depends_on = [azurerm_kubernetes_cluster.aks_cluster]
}

output "load_balancer_ip" {
  value = data.azurerm_public_ip.load_balancer_ip.ip_address
}

output "resourceGroupName" {
  value = azurerm_resource_group.rg.name
}
output "aksName" {
  value = azurerm_kubernetes_cluster.aks_cluster.name
}
output "registryName" {
  value = azurerm_container_registry.acr.name
}

# output "test" {
#   value = sort(azurerm_kubernetes_cluster.aks_cluster.network_profile[0].load_balancer_profile[0].effective_outbound_ips)[0]
# }

# output "test2" {
#   value = split("/", sort(azurerm_kubernetes_cluster.aks_cluster.network_profile[0].load_balancer_profile[0].effective_outbound_ips)[0])[length(split("/", sort(azurerm_kubernetes_cluster.aks_cluster.network_profile[0].load_balancer_profile[0].effective_outbound_ips)[0])) - 1]
# }

# output "test3" {
#   value = "MC_${azurerm_resource_group.rg.name}_${azurerm_kubernetes_cluster.aks_cluster.name}_${azurerm_resource_group.rg.location}"
# }

# Create a virtual network "{projectName}-ingress-vnet" within the resource group
resource "azurerm_virtual_network" "internet" {
  name                = "${var.projectName}-internet-vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = var.internet_vnet_address_space
}

resource "azurerm_virtual_network_peering" "internet_to_cluster" {
  name                      = "${var.projectName}-internet-to-cluster-peering"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.internet.name
  remote_virtual_network_id = azurerm_virtual_network.cluster.id
}

resource "azurerm_subnet" "frontend" {
  name                 = "${var.projectName}-frontend-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.internet.name
  address_prefixes     = var.internet_frontend_address_space #["10.0.0.1/17"] //Parameter
}

resource "azurerm_subnet" "backend" {
  name                 = "${var.projectName}-backend-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.internet.name
  address_prefixes     = var.internet_backend_address_space #["10.0.0.128/17"] //Parameter
}

resource "azurerm_public_ip" "appl_gateway_pip" {
  name                = "${var.projectName}-appl-gateway-pip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Dynamic"
}

resource "azurerm_application_gateway" "network" {
  name                = "${var.projectName}-appgateway"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  autoscale_configuration {
      min_capacity = 1
  }

  sku {
    name     = "WAF_Medium"
    tier     = "WAF"
  }

  gateway_ip_configuration {
    name      = "${var.projectName}-gateway-ip-configuration"
    subnet_id = azurerm_subnet.frontend.id
  }

  frontend_port {
    name = "${var.projectName}-feport"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "${var.projectName}-feip"
    public_ip_address_id = azurerm_public_ip.appl_gateway_pip.id
  }

  backend_address_pool {
    name = "${var.projectName}-beap"
    ip_addresses = ["${data.azurerm_public_ip.load_balancer_ip.ip_address}"]
  }

  backend_http_settings {
    name                  = "${var.projectName}-be-htst"
    cookie_based_affinity = "Disabled"
    path                  = "/path1/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = "${var.projectName}-httplstn"
    frontend_ip_configuration_name = "${var.projectName}-feip"
    frontend_port_name             = "${var.projectName}-feport"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "${var.projectName}-rqrt"
    rule_type                  = "Basic"
    http_listener_name         = "${var.projectName}-httplstn"
    backend_address_pool_name  = "${var.projectName}-beap"
    backend_http_settings_name = "${var.projectName}-be-htst"
  }
}
