output "watech_rg_id" {
  description = "Returns the ID of the created resource group"
  value       = azurerm_resource_group.watech-rg.id
}

output "public_ip_address" {
  description = "The public IP address for the virtual machine"
  value       = azurerm_public_ip.watech-pip.ip_address
}

# output "private_ssh_key" {
#   description = "The private SSH key to access the VRE"
#   value       = tls_private_key.watech-ssh-key.private_key_pem
#   sensitive   = true
# }
