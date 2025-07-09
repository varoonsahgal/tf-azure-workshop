provider "azurerm" {
  features {}
}

provider "tls" {}

locals {
  rootname         = "watech-${var.yourname}-${var.location}"
  trimmed_rootname = "watech${var.yourname}${var.location}"
  tags = {
    "costCenter" = "WaTechInternal"
    "owner"      = var.yourname
    "region"     = var.location
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "watech-rg" {
  name     = "${local.rootname}-rg"
  location = var.location
  tags     = local.tags
}

resource "azurerm_storage_account" "watech-sa" {
  name                = "${local.trimmed_rootname}sa"
  resource_group_name = azurerm_resource_group.watech-rg.name
  location            = var.location
  tags                = local.tags

  account_tier             = "Standard"
  account_replication_type = "LRS"
}

data "azurerm_virtual_network" "watech-vnet" {
  name                = "watech-workshop-vnet"
  resource_group_name = "watech-workshop-rg"
}

resource "azurerm_subnet" "watech-subnet" {
  name                 = "${local.rootname}-subnet"
  resource_group_name  = data.azurerm_virtual_network.watech-vnet.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.watech-vnet.name
  address_prefixes     = ["10.0.90.0/24"]
}

resource "azurerm_public_ip" "watech-pip" {
  name                = "${local.rootname}-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.watech-rg.name
  allocation_method   = "Dynamic"
  tags                = local.tags
}

resource "azurerm_network_interface" "watech-nic" {
  name                = "${local.rootname}-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.watech-rg.name
  tags                = local.tags

  ip_configuration {
    name                          = "${local.rootname}-nic-cfg"
    subnet_id                     = azurerm_subnet.watech-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.watech-pip.id
  }
}

resource "tls_private_key" "watech-ssh-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_linux_virtual_machine" "watech-vm" {
  name                  = "${local.rootname}-vm"
  location              = var.location
  resource_group_name   = azurerm_resource_group.watech-rg.name
  size                  = "Standard_B2ms"
  network_interface_ids = [azurerm_network_interface.watech-nic.id]
  admin_username        = var.yourname
  computer_name         = local.trimmed_rootname
  tags                  = local.tags

  admin_ssh_key {
    username   = var.yourname
    public_key = tls_private_key.watech-ssh-key.public_key_openssh
  }
  disable_password_authentication = true

  # admin_password = "ThisWasSuchACoolWorkshop!1!"
  # disable_password_authentication = false

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.watech-sa.primary_blob_endpoint
  }
}
