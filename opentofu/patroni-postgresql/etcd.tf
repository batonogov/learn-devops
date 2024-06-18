variable "etcd_vms" {
  type = list(object({
    name      = string
    address   = string
    node_name = string
  }))
  default = [
    {
      name      = "etcd-01"
      address   = "10.0.75.114/24"
      node_name = "pve-01"
    },
    {
      name      = "etcd-02"
      address   = "10.0.75.115/24"
      node_name = "pve-02"
    }
  ]
}

# Создание виртуальных машин
resource "proxmox_virtual_environment_vm" "etcd" {
  for_each = { for vm in var.etcd_vms : vm.name => vm }

  name        = each.value.name
  migrate     = true
  description = "Managed by OpenTofu"
  tags        = ["etcd"]
  on_boot     = true
  node_name   = each.value.node_name

  clone {
    vm_id     = "2404"
    node_name = "pve-01"
    retries   = 3
  }

  agent {
    enabled = true
  }

  operating_system {
    type = "l26"
  }

  cpu {
    cores = 2
    type  = "host"
    numa  = true
  }

  memory {
    dedicated = 2048
  }

  vga {
    memory = 4
    type   = "serial0"
  }

  disk {
    size         = "20"
    interface    = "virtio0"
    datastore_id = "proxmox-data-01"
    file_format  = "raw"
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  initialization {
    datastore_id = "proxmox-data-01"
    ip_config {
      ipv4 {
        address = each.value.address
        gateway = "10.0.75.1"
      }
    }
    dns {
      servers = [
        "10.0.75.65",
        "10.0.75.66"
      ]
    }
    user_account {
      username = "infra"
      keys = [
        var.ssh_public_key
      ]
    }
  }
}
