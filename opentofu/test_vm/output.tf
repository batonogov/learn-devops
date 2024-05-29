output "vm_info" {
  description = "Names and IP addresses of the created VMs"
  value = {
    for i in range(var.vm_count) :
    format("vm-%02d", i + 1) => proxmox_virtual_environment_vm.vm[i].ipv4_addresses[1]
  }
}
