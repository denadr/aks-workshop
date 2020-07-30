# Configure the Microsoft Azure Active Directory Provider
provider "azuread" {
  version = "=0.7.0"
}
# Configure the Azure Provider
provider "azurerm" {
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  version = "=2.0.0"
  features {}
}

locals {
  expiry_date = "2099-01-01T00:00:00Z"
}

# Create service principal
resource "azuread_application" "app_registration" {
  name = "${var.name}-aks-sp"
}
resource "random_string" "app_secret" {
  length = 16
}
resource "azuread_application_password" "app_password" {
  application_object_id = azuread_application.app_registration.id
  value                 = random_string.app_secret.result
  end_date              = local.expiry_date
}
resource "azuread_service_principal" "service_principal" {
  application_id = azuread_application.app_registration.application_id
}
resource "random_string" "principal_secret" {
  length = 16
}
resource "azuread_service_principal_password" "service_principal" {
  service_principal_id = azuread_service_principal.service_principal.id
  value                = random_string.principal_secret.result
  end_date             = local.expiry_date
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
  address_prefix     = "10.240.0.0/16"
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

resource "azurerm_role_assignment" "acrPul" {
  scope                            = azurerm_container_registry.acr.id
  role_definition_name             = "AcrPull"
  principal_id                     = azuread_service_principal.service_principal.object_id
  skip_service_principal_aad_check = true
}

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

  service_principal {
    client_id     = azuread_service_principal.service_principal.application_id
    client_secret = random_string.principal_secret.result
  }

  addon_profile {
    kube_dashboard {
      enabled = true
    }

    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.workspace.id
    }
  }
}
