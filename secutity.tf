resource "azurerm_network_security_group" "security" {
  name                  = "mySecurityGroup"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name

  # RULE FOR SSH
  security_rule {
    name = "ssh"
    priority = 3000
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_address_prefix = "5.29.18.23"
    source_port_range = "*"
    destination_address_prefix = "*"
    destination_port_ranges = [ "22" ] # IMPORTANT RULE PORT
  }
  # RULE FOR PORT 8080
  security_rule {
    name = "Port8080"
    priority = 3001
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_address_prefix = "*"
    source_port_range = "*"
    destination_address_prefix = "*"
    destination_port_ranges = [ "8080" ] # IMPORTANT RULE PORT
  }
}
