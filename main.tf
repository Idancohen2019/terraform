# CORE INFRASTRUCUTRE STETTINGS
resource "azurerm_virtual_machine" "vm" {
  count                 = length(var.name_count)
  name                  = "vm-${count.index+1}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [element(azurerm_network_interface.main.*.id, count.index)]
  vm_size               = var.vm_size["dev"]

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

# WHICH OS THE VM WILL HAVE
  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  # MAIN STORAGE DISK
  storage_os_disk {
    name              = "myosdisk-${count.index+1}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  # PROFILE OF THE VM - USER / PASSWORD
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  # TAGS - KEY / VALUE PAIRS
  tags = {
    environment = "staging"
    name        = "vm-${count.index+1}"
    location    = azurerm_resource_group.rg.location
    resource_group_name   = azurerm_resource_group.rg.name
  }
}

output "virtual_machine_name" { value = azurerm_virtual_machine.vm.*.name}
output "virtual_machine_location" { value = azurerm_virtual_machine.vm.*.location}
output "vnet_name" { value = azurerm_network_interface.main.*.name}
output "azurerm_subnet" { value = azurerm_subnet.subnet1.*.name}
output "azurerm_subnet2" { value = azurerm_subnet.subnet2.*.name}
