variable "virtual_environment_endpoint" {
  type        = string
  description = "The endpoint for the Proxmox Virtual Environment API (example: https://host:port)"
}

variable "virtual_environment_api_token" {
  type        = string
  description = "The api roken the Proxmox Virtual Environment API (example: root@pam!for-terraform-provider=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH Puclic key for VMs (example: ssh-rsa ...)"
}
