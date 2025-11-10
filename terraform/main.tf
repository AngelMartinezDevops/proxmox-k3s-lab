# Configuración de Terraform y Provider de Proxmox
# Este archivo configura la conexión a Proxmox

terraform {
  required_version = ">= 1.0"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.50"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox_api_url
  username = var.proxmox_user
  password = var.proxmox_password
  insecure = true  # Permite certificados autofirmados
}

