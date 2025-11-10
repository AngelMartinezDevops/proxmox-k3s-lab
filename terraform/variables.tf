# Variables de Terraform para el cluster K3s
# Estas variables se rellenan en terraform.tfvars

# Configuración de Proxmox
variable "proxmox_api_url" {
  description = "URL del API de Proxmox"
  type        = string
}

variable "proxmox_user" {
  description = "Usuario de Proxmox (formato: usuario@realm)"
  type        = string
}

variable "proxmox_password" {
  description = "Contraseña del usuario de Proxmox"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Nombre del nodo de Proxmox"
  type        = string
}

# Configuración de la template
variable "template_name" {
  description = "Nombre de la template cloud-init"
  type        = string
  default     = "ubuntu-cloud-template"
}

# Configuración de red
variable "network_bridge" {
  description = "Bridge de red en Proxmox"
  type        = string
  default     = "vmbr0"
}

variable "network_gateway" {
  description = "Gateway de la red"
  type        = string
}

# SSH
variable "ssh_public_key" {
  description = "Clave pública SSH para acceso a las VMs"
  type        = string
}

# Storage
variable "storage_pool" {
  description = "Pool de storage en Proxmox"
  type        = string
  default     = "local-lvm"
}

