variable "node_vms" {
  type = list(object({
    name      = string
    address   = string
    node_name = string
  }))
  default = [
    {
      name      = "kubeadm-node-01"
      address   = "192.168.0.61/24"
      node_name = "pve"
    },
    {
      name      = "kubeadm-node-02"
      address   = "192.168.0.62/24"
      node_name = "pve"
    },
    {
      name      = "kubeadm-node-03"
      address   = "192.168.0.63/24"
      node_name = "pve"
    },
    {
      name      = "kubeadm-node-04"
      address   = "192.168.0.64/24"
      node_name = "pve"
    }
  ]
}

# Создание виртуальных машин
resource "proxmox_virtual_environment_vm" "node" {
  for_each = { for vm in var.node_vms : vm.name => vm }

  name    = each.value.name
  migrate = true
  # protection  = true
  description = "Managed by OpenTofu"
  tags        = ["kubeadm", "kubernetes", "deb-12"]
  on_boot     = true
  node_name   = each.value.node_name

  clone {
    vm_id     = "9012"
    node_name = "pve"
    retries   = 3
  }

  agent {
    enabled = true
  }

  operating_system {
    type = "l26"
  }

  cpu {
    cores = 4
    type  = "host"
    numa  = true
  }

  memory {
    dedicated = 8192
  }

  vga {
    memory = 4
    type   = "serial0"
  }

  disk {
    size         = "20"
    interface    = "virtio0"
    datastore_id = "local-lvm"
    file_format  = "raw"
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  initialization {
    datastore_id = "local-lvm"
    ip_config {
      ipv4 {
        address = each.value.address
        gateway = "192.168.0.1"
      }
    }
    dns {
      servers = [
        "192.168.0.110"
      ]
    }
    user_account {
      username = "root"
      keys = [
        var.ssh_public_key
      ]
    }
  }
}

# Создание ресурсов высокой доступности
# resource "proxmox_virtual_environment_haresource" "patroni" {
#   for_each = { for vm in var.node_vms : vm.name => vm }

#   resource_id = "vm:${proxmox_virtual_environment_vm.patroni[each.key].vm_id}"
#   state       = "started"
#   group       = "prod"
#   comment     = "Managed by OpenTofu"
# }
