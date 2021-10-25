provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group
  location = var.location
}

resource "azurerm_storage_account" "stor" {
  name                     = "${var.dns_name}stor"
  location                 = var.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_replication_type
}

resource "azurerm_availability_set" "avset" {
  name                         = "${var.dns_name}avset"
  location                     = var.location
  resource_group_name          = azurerm_resource_group.rg.name
  platform_fault_domain_count  = 1
  platform_update_domain_count = 1
  managed                      = true
}

resource "azurerm_public_ip" "lbpip" {
  name                = "${var.rg_prefix}-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  domain_name_label   = var.lb_ip_dns_name
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.virtual_network_name
  location            = var.location
  address_space       = ["${var.address_space}"]
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "web_subnet" {
  name                 = "${var.rg_prefix}-web_subnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefixes     = ["${var.web_subnet_prefix}"]
}

resource "azurerm_subnet" "db_subnet" {
  name                 = "${var.rg_prefix}-db_subnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefixes     = ["${var.db_subnet_prefix}"]
}

resource "azurerm_lb" "lb" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${var.rg_prefix}-lb"
  location            = var.location

  frontend_ip_configuration {
    name                 = "LoadBalancerFrontEnd"
    public_ip_address_id = azurerm_public_ip.lbpip.id
  }
}

resource "azurerm_lb_backend_address_pool" "backend_pool" {
  #resource_group_name = azurerm_resource_group.rg.name
  loadbalancer_id = azurerm_lb.lb.id
  name            = "BackendPool1"
}

resource "azurerm_lb_nat_rule" "tcp" {
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "SSH-VM-${count.index}"
  protocol                       = "tcp"
  frontend_port                  = "5000${count.index + 1}"
  backend_port                   = 22
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
  count                          = 1
}

resource "azurerm_lb_rule" "lb_rule" {
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "LBRule"
  protocol                       = "tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
  enable_floating_ip             = false
  #backend_address_pool_id        = azurerm_lb_backend_address_pool.backend_pool.id
  idle_timeout_in_minutes = 5
  probe_id                = azurerm_lb_probe.lb_probe.id
  depends_on              = [azurerm_lb_probe.lb_probe]
}

resource "azurerm_lb_probe" "lb_probe" {
  resource_group_name = azurerm_resource_group.rg.name
  loadbalancer_id     = azurerm_lb.lb.id
  name                = "tcpProbe"
  protocol            = "tcp"
  port                = 80
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_network_interface" "web_nic" {
  name                = "web_nic-${count.index}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  count               = 3

  ip_configuration {
    name                          = "ipconfig-web-${count.index}"
    subnet_id                     = azurerm_subnet.web_subnet.id
    private_ip_address_allocation = "Dynamic"

  }
  internal_dns_name_label = "Web-VM-${count.index}"
}

resource "azurerm_network_interface_backend_address_pool_association" "web_nic_association" {
  network_interface_id    = element(azurerm_network_interface.web_nic.*.id, count.index)
  ip_configuration_name   = "ipconfig-web-${count.index}"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id
  count                   = 3

}

resource "azurerm_network_interface" "db_nic" {
  name                    = "db_nic-${count.index}"
  location                = var.location
  resource_group_name     = azurerm_resource_group.rg.name
  count                   = 1
  internal_dns_name_label = "DB-VM-${count.index}"


  ip_configuration {
    name                          = "ipconfig-db-${count.index}"
    subnet_id                     = azurerm_subnet.db_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_nat_rule_association" "natrule" {
  network_interface_id  = element(azurerm_network_interface.web_nic.*.id, count.index)
  ip_configuration_name = "ipconfig-web-${count.index}"
  nat_rule_id           = element(azurerm_lb_nat_rule.tcp.*.id, count.index)
  count                 = 1
}


resource "azurerm_virtual_machine" "web_vm" {
  name                  = "Web-VM-${count.index}"
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg.name
  availability_set_id   = azurerm_availability_set.avset.id
  vm_size               = var.vm_size
  network_interface_ids = ["${element(azurerm_network_interface.web_nic.*.id, count.index)}"]
  count                 = 3

  storage_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  storage_os_disk {
    name          = "osdisk-web-${count.index}"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "Web-VM-${count.index}"
    admin_username = var.admin_username
    #admin_password = var.admin_password
  }



  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/idan/.ssh/authorized_keys"
      key_data = file("vm-key.pub")
    }
  }
}

resource "azurerm_virtual_machine" "db_vm" {
  name                  = "DB-VM-${count.index}"
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg.name
  vm_size               = var.vm_size
  network_interface_ids = ["${element(azurerm_network_interface.db_nic.*.id, count.index)}"]
  count                 = 1

  storage_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  storage_os_disk {
    name          = "osdisk-db-${count.index}"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "DB-VM-${count.index}"
    admin_username = var.admin_username
    #admin_password = var.admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/idan/.ssh/authorized_keys"
      key_data = file("vm-key.pub")
    }
  }
}
