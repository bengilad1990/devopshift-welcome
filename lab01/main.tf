provider "azurerm" {
  features {}
}

variable "location" {
  default = "East US"
}

resource "azurerm_resource_group" "rg-beno" {
  name     = "beno-resources"
  location = var.location
}

resource "azurerm_virtual_network" "vnet-beno" {
  name                = "beno-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg-beno.name
}

resource "azurerm_subnet" "subnet-beno" {
  name                 = "beno-subnet"
  resource_group_name  = azurerm_resource_group.rg-beno.name
  virtual_network_name = azurerm_virtual_network.vnet-beno.name
  address_prefixes     = ["10.0.1.0/24"]
}



resource "azurerm_public_ip" "pip-beno" {
  name                = "beno-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg-beno.name
  allocation_method   = "Dynamic"  
  sku = "Basic"  
}

resource "azurerm_network_interface" "nic-beno" {
  name                = "beno-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg-beno.name

  ip_configuration {
    name                          = "beno-ipconfig"
    subnet_id                     = azurerm_subnet.subnet-beno.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip-beno.id
  }
}


variable "vm_size" {
  default = "Standard_B1ms"
}

variable "admin_username" {
  default = "adminuser-beno"
}

variable "admin_password" {
  default = "Password123!"
}


resource "azurerm_linux_virtual_machine" "vm-beno" {
  name                  = "beno-vm"
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg-beno.name
  network_interface_ids = [azurerm_network_interface.nic-beno.id]
  size                  = var.vm_size

  os_disk {
    name              = "beno-os-disk"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_username = var.admin_username
  admin_password = var.admin_password

  disable_password_authentication = false

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name = "beno-vm"
}

resource "time_sleep" "wait_for_ip" {
  create_duration = "30s"  # Wait for 30 seconds
}

output "vm_public_ip" {
  value = azurerm_public_ip.pip-beno.ip_address
  description = "Public IP address of the VM"
}

