provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "test" {
  name     = "testResourceGroup"
  location = "East US"
}

resource "azurerm_virtual_network" "test" {
  name                = "testVnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name
}

resource "azurerm_subnet" "test" {
  name                 = "testSubnet"
  resource_group_name  = azurerm_resource_group.test.name
  virtual_network_name = azurerm_virtual_network.test.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "test" {
  name                = "testNIC"
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name

  ip_configuration {
    name                          = "testConfiguration"
    subnet_id                     = azurerm_subnet.test.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "test" {
  name                = "testVM"
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name
  network_interface_ids = [azurerm_network_interface.test.id]
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  admin_password      = "Password1234!"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}
