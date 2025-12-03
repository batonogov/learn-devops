variable "vm_count" {
  description = "Number of VMs to create"
  default     = 1
}

resource "proxmox_virtual_environment_vm" "vm" {
  count       = var.vm_count
  name        = format("vm-%02d", count.index + 1)
  migrate     = true
  description = "Managed by OpenTofu"
  tags        = ["opentofu", "test"]
  on_boot     = true

  node_name = "pve"

  clone {
    vm_id     = "960"
    node_name = "pve"
    retries   = 2
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
    dedicated = 4096
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
        address = "dhcp"
      }
    }
    dns {
      servers = [
        "77.88.8.8",
        "8.8.8.8"
      ]
    }
    user_account {
      username = "serg"
      keys = [
        var.ssh_public_key
      ]
    }
  }
}
