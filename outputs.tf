output "hostname" {
  value = "${var.hostname}"
}

output "vm_fqdn" {
  value = "${azurerm_public_ip.lbpip.fqdn}"
}

output "vms_ssh_access" {
  value = "${formatlist("SSH_URL=%v:%v", azurerm_public_ip.lbpip.fqdn, azurerm_lb_nat_rule.tcp.*.frontend_port)}"
}
