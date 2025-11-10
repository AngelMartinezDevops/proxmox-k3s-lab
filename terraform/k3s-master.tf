# ============================================================================
# K3s Master Node - Control Plane del Cluster
# ============================================================================
# Esta VM ejecutará el servidor K3s (control plane)
# Gestiona el estado del cluster, API server, scheduler, etc.
# ============================================================================

resource "proxmox_virtual_environment_vm" "k3s-master" {
  name        = "vm-k3s-master"
  node_name   = var.proxmox_node  # Definido en variables.tf
  
  # --------------------------------------------------------------------------
  # Clonar desde template Ubuntu Cloud-Init (debe existir con ID 9000)
  # Ver README para crear la template
  # --------------------------------------------------------------------------
  clone {
    vm_id = 9000  # ID de la template Ubuntu cloud-init
  }
  
  # --------------------------------------------------------------------------
  # Hardware - CPU
  # --------------------------------------------------------------------------
  cpu {
    cores = 2        # 2 cores virtuales
    type  = "host"   # Pasa características completas de la CPU del host
                     # Alternativas: x86-64-v2-AES, kvm64
  }
  
  # --------------------------------------------------------------------------
  # Hardware - Memoria
  # --------------------------------------------------------------------------
  memory {
    dedicated = 4096  # 4GB RAM (mínimo recomendado para K3s master)
  }
  
  # --------------------------------------------------------------------------
  # Disco principal
  # --------------------------------------------------------------------------
  disk {
    datastore_id = var.storage_pool  # Definido en variables.tf (ej: local-lvm)
    interface    = "scsi0"            # Interfaz SCSI (recomendado con VirtIO)
    size         = 20                 # 20GB de disco
    file_format  = "raw"              # Formato raw (mejor rendimiento que qcow2)
  }
  
  # --------------------------------------------------------------------------
  # Red
  # --------------------------------------------------------------------------
  network_device {
    bridge = var.network_bridge  # Definido en variables.tf (normalmente vmbr0)
    model  = "virtio"            # VirtIO para mejor rendimiento
  }
  
  # --------------------------------------------------------------------------
  # Cloud-init - Inicialización automática
  # --------------------------------------------------------------------------
  initialization {
    # Configuración de red estática
    ip_config {
      ipv4 {
        # IP estática del master
        # IMPORTANTE: Esta IP debe ser accesible desde tu red
        # Debe coincidir con la IP en ansible/inventory.yml
        address = "192.168.10.100/24"  # CAMBIAR según tu red
        gateway = var.network_gateway   # Definido en variables.tf
      }
    }
    
    # Usuario SSH
    user_account {
      username = "ubuntu"            # Usuario por defecto en Ubuntu cloud
      keys     = [var.ssh_public_key]  # Tu clave pública SSH
    }
  }
  
  # --------------------------------------------------------------------------
  # Qemu Guest Agent - Para mejor integración con Proxmox
  # --------------------------------------------------------------------------
  agent {
    enabled = true  # Permite a Proxmox obtener IP, hacer shutdown limpio, etc.
  }
}

# ============================================================================
# Output - IP del master para referencia
# ============================================================================
output "k3s_master_ip" {
  value       = "192.168.10.100"
  description = "IP del nodo master K3s"
}

# ============================================================================
# NOTAS:
# 
# 1. La IP 192.168.10.100 debe estar libre en tu red
# 2. Debe coincidir con ansible/inventory.yml
# 3. El master tiene un "taint" aplicado por Ansible para que NO ejecute
#    workloads de usuario (solo componentes del sistema)
# 4. Para cambiar la IP, editar aquí Y en ansible/inventory.yml
# ============================================================================
