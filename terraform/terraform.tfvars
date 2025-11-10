# ============================================================================
# Terraform Variables - Proxmox K3s Cluster
# ============================================================================
# IMPORTANTE: 
# Este archivo contiene la configuración para tu cluster K3s en Proxmox
# Rellena con tus datos reales antes de ejecutar terraform apply
# ============================================================================

# ----------------------------------------------------------------------------
# Conexión a Proxmox
# ----------------------------------------------------------------------------
# URL del API de Proxmox (cambiar IP por la de tu servidor Proxmox)
# Formato: https://IP_DE_TU_PROXMOX:8006/api2/json
# Ejemplo: proxmox_api_url = "https://192.168.10.111:8006/api2/json"
proxmox_api_url  = "https://TU_IP_PROXMOX:8006/api2/json"

# Usuario de Proxmox (normalmente root@pam para acceso completo)
proxmox_user     = "root@pam"

# Contraseña del usuario de Proxmox
# Obtener: la contraseña que usas para acceder a la Web UI de Proxmox
proxmox_password = "TU_PASSWORD_PROXMOX"

# Nombre del nodo de Proxmox donde se crearán las VMs
# Obtener: ejecuta en Proxmox: pvesh get /nodes
# O verifica en la Web UI de Proxmox (suele ser algo como "pve" o "proxmox")
proxmox_node     = "TU_NODO_PROXMOX"

# ----------------------------------------------------------------------------
# Template Cloud-Init
# ----------------------------------------------------------------------------
# Nombre de la template Ubuntu con cloud-init (debe existir en Proxmox)
# Por defecto, se crea con ID 9000 según la guía del README
template_name = "ubuntu-cloud-template"

# ----------------------------------------------------------------------------
# Configuración de Red
# ----------------------------------------------------------------------------
# Bridge de red en Proxmox (normalmente vmbr0)
# Obtener: ejecuta en Proxmox: ip link show | grep vmbr
network_bridge  = "vmbr0"

# Gateway de tu red local (normalmente tu router)
# Obtener: ejecuta en Proxmox: ip route | grep default
# Ejemplo: 192.168.1.1, 192.168.10.1, 10.0.0.1
network_gateway = "TU_GATEWAY"

# ----------------------------------------------------------------------------
# SSH
# ----------------------------------------------------------------------------
# Tu clave pública SSH para acceder a las VMs
# Obtener: cat ~/.ssh/id_ed25519.pub
# Generar (si no tienes): ssh-keygen -t ed25519 -C "k3s-lab"
# IMPORTANTE: Debe ser la CLAVE PÚBLICA completa (ssh-ed25519 AAAA...)
ssh_public_key = "ssh-ed25519 AAAA_TU_CLAVE_PUBLICA_COMPLETA_AQUI usuario@maquina"

# ----------------------------------------------------------------------------
# Storage
# ----------------------------------------------------------------------------
# Pool de almacenamiento en Proxmox donde se crearán los discos de las VMs
# Opciones comunes: local-lvm, local-zfs, ceph
# Obtener: ejecuta en Proxmox: pvesm status
storage_pool = "local-lvm"

# ============================================================================
# EJEMPLO COMPLETO CON VALORES REALES:
# ============================================================================
# proxmox_api_url  = "https://192.168.10.111:8006/api2/json"
# proxmox_user     = "root@pam"
# proxmox_password = "MiPasswordSeguro123!"
# proxmox_node     = "proxmox-lab"
# template_name    = "ubuntu-cloud-template"
# network_bridge   = "vmbr0"
# network_gateway  = "192.168.10.1"
# ssh_public_key   = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJKLsdf... usuario@laptop"
# storage_pool     = "local-lvm"
# ============================================================================

