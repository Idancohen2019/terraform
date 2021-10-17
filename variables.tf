variable "location" {
  description = "The location/region where the virtual network is created. Changing this forces a new resource to be created."
  default     = "West Europe"
}

variable "prefix" {
  description = "The name of the resource group in which to create the virtual network."
  default = "rg"
}

variable "virtual_network_name" {
  description = "The name for the virtual network."
  default     = "vnet"
}

variable "subnet_prefix" {
  description = "The address prefix to use for the subnet."
  default     = "10.0.10.0/24"
}

variable "name" { default = "resources" }

variable "name_count" { default = ["server1", "server2", "server3"] }

variable "vm_size" {
    description = "Specifies the size of the virtual machine."
    type = map(string)
    default = {
        "dev"  = "Standard_B1s"
        "prod" = "Standard_DS2_v2"
    }

# variable "lb_ip_dns_name" {
#     description = "DNS for Load Balancer IP"
#     default = "fats_and_happy"
# }
}