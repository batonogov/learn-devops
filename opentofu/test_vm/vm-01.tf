# Машинка
resource "proxmox_virtual_environment_vm" "vm-01" {
  name        = "vm-01"
  description = "Managed by OpenTofu"
  tags        = ["opentofu", "test"]
  on_boot     = true

  # Указываем целевой узел, на котором будет запущена ВМ
  node_name = "pve-01"

  # Шоблон из которого будет создавать ВМ
  clone {
    vm_id     = "9000"
    node_name = "pve-01"
    retries   = 2
  }

  # Активируем QEMU для этов ВМ
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

  disk {
    size         = "40"
    interface    = "virtio0"
    datastore_id = "proxmox-data-02"
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
        address = "dhcp"
      }
    }
    dns {
      servers = ["77.88.8.8"]
    }
    user_account {
      username = "infra"
      keys = [
        "ssh-rsa..."
      ]
    }
  }
}
