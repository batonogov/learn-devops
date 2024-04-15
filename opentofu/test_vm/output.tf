output "ip_address_vm_01" {
  description = "IP адрес vm-01"
  value       = proxmox_virtual_environment_vm.vm-01.ipv4_addresses[1]
}
