terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "hackathon_bayer_rg" {
  name     = "hackathon-bayer-rg-resources"
  location = "centralindia"
}

resource "azurerm_virtual_network" "hackathon_bayer_vnet" {
  name                = "hackathon-bayer-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.hackathon_bayer_rg.location
  resource_group_name = azurerm_resource_group.hackathon_bayer_rg.name
}

resource "azurerm_subnet" "hackathon_bayer_subnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.hackathon_bayer_rg.name
  virtual_network_name = azurerm_virtual_network.hackathon_bayer_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "hackathon_bayer_nwtwork_interface" {
  name                = "hackathon-bayer-nic"
  location            = azurerm_resource_group.hackathon_bayer_rg.location
  resource_group_name = azurerm_resource_group.hackathon_bayer_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.hackathon_bayer_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "hackathon_bayer_vm" {
  name                = "mybayerhack-machine"
  resource_group_name = azurerm_resource_group.hackathon_bayer_rg.name
  location            = azurerm_resource_group.hackathon_bayer_rg.location
  size                = "Standard_F2"
  admin_username      = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.hackathon_bayer_nwtwork_interface.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

resource "azurerm_kubernetes_cluster" "myfirstckuster" {
  name                = "bayer-trial-hack-aks1"
  location            = azurerm_resource_group.hackathon_bayer_rg.location
  resource_group_name = azurerm_resource_group.hackathon_bayer_rg.name
  dns_prefix          = "aks1"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "Production"
  }
  depends_on = [azurerm_virtual_network.hackathon_bayer_vnet]
}

output "client_certificate" {
  value     = azurerm_kubernetes_cluster.myfirstckuster.kube_config[0].client_certificate

  sensitive = true
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.myfirstckuster.kube_config_raw

  sensitive = true
}