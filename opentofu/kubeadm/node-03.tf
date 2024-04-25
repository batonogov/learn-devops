# Машинка
resource "proxmox_virtual_environment_vm" "kubeadm-node-03" {
  name        = "kubeadm-node-03"
  migrate     = true
  description = "Managed by OpenTofu"
  tags        = ["kubeadm", "test"]
  on_boot     = true

  # Указываем целевой узел, на котором будет запущена ВМ
  node_name = "pve-03"

  # Шоблон из которого будет создавать ВМ
  clone {
    vm_id     = "2204"
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
    dedicated = 32768
  }

  disk {
    size         = "500"
    interface    = "virtio0"
    datastore_id = "k8s-data-01"
    file_format  = "raw"
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  initialization {
    datastore_id = "k8s-data-01"
    ip_config {
      ipv4 {
        address = "10.0.70.74/24"
        gateway = "10.0.70.101"
      }
    }
    dns {
      servers = [
        "10.0.70.65",
        "10.0.70.66",
        "77.88.8.8"
      ]
    }
    user_account {
      username = "infra"
      keys = [
        "ssh-rsa..."
      ]
    }
  }
}
