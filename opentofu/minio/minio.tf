variable "minio_vms" {
  type = list(object({
    name      = string
    address   = string
    node_name = string
  }))
  default = [
    {
      name      = "minio1"
      address   = "10.0.75.55/24"
      node_name = "pve-01"
    },
    {
      name      = "minio2"
      address   = "10.0.75.56/24"
      node_name = "pve-02"
    },
    {
      name      = "minio3"
      address   = "10.0.75.57/24"
      node_name = "pve-01"
    },
    {
      name      = "minio4"
      address   = "10.0.75.58/24"
      node_name = "pve-02"
    }
  ]
}

# Создание виртуальных машин
resource "proxmox_virtual_environment_vm" "minio" {
  for_each = { for vm in var.minio_vms : vm.name => vm }

  name    = each.value.name
  migrate = true
  # protection  = true
  description = "Managed by OpenTofu"
  tags        = ["minio", "opentofu"]
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
    datastore_id = "proxmox-data-02"
    file_format  = "raw"
  }

  disk {
    size         = "450"
    interface    = "virtio1"
    datastore_id = "minio-data-01"
    file_format  = "raw"
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  initialization {
    datastore_id = "proxmox-data-02"
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

# Создание ресурсов высокой доступности
# resource "proxmox_virtual_environment_haresource" "patroni" {
#   for_each = { for vm in var.minio_vms : vm.name => vm }

#   resource_id = "vm:${proxmox_virtual_environment_vm.patroni[each.key].vm_id}"
#   state       = "started"
#   group       = "prod"
#   comment     = "Managed by OpenTofu"
# }
