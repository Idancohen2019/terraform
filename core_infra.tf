# Configure the Microsoft Azure Provider
provider "azurerm" {  
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-resources"
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.virtual_network_name}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}
# subnet public
resource "azurerm_subnet" "subnet1" {
  name                 = "subnet1"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefixes     = ["10.0.0.0/24"]
}
# subnet private
resource "azurerm_subnet" "subnet2" {
  name                 = "subnet2"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefixes     = ["10.0.1.0/24"]
}
resource "azurerm_network_interface" "main" {
  count               = length(var.name_count)
  name                = "${var.prefix}-nic-${count.index+1}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name



  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
  }
}
  # ip_configuration {
  #   name                          = "testconfiguration2"
  #   subnet_id                     = azurerm_subnet.subnet2.id
  #   private_ip_address_allocation = "Dynamic"
  # }

resource "azurerm_network_interface_security_group_association" "NIC1_to_NSG1" {
  count                     = length(var.name_count)
  network_interface_id      = element(azurerm_network_interface.main.*.id, count.index)
  network_security_group_id = azurerm_network_security_group.security.id
}
resource "azurerm_subnet_network_security_group_association" "subnetVM_assoc" {
  subnet_id                 = azurerm_subnet.subnet1.id
  network_security_group_id = azurerm_network_security_group.security.id
}

