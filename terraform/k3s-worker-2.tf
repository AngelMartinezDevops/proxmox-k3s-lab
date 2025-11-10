# ============================================================================
# K3s Worker Node 2 - Nodo de carga
# ============================================================================
# Esta VM ejecutará el agente K3s (worker)
# Ejecuta los pods y workloads de las aplicaciones
# ============================================================================

resource "proxmox_virtual_environment_vm" "k3s-worker-2" {
  name        = "vm-k3s-worker-2"
  node_name   = var.proxmox_node  # Definido en variables.tf
  
  # --------------------------------------------------------------------------
  # Clonar desde template Ubuntu Cloud-Init (debe existir con ID 9000)
  # --------------------------------------------------------------------------
  clone {
    vm_id = 9000  # ID de la template Ubuntu cloud-init
  }
  
  # --------------------------------------------------------------------------
  # Hardware - CPU
  # --------------------------------------------------------------------------
  cpu {
    cores = 1        # 1 core (suficiente para worker en lab)
    type  = "host"   # Pasa características completas de la CPU
  }
  
  # --------------------------------------------------------------------------
  # Hardware - Memoria
  # --------------------------------------------------------------------------
  memory {
    dedicated = 3072  # 3GB RAM (mínimo recomendado para worker)
  }
  
  # --------------------------------------------------------------------------
  # Disco principal
  # --------------------------------------------------------------------------
  disk {
    datastore_id = var.storage_pool  # Definido en variables.tf
    interface    = "scsi0"
    size         = 20                 # 20GB de disco
    file_format  = "raw"
  }
  
  # --------------------------------------------------------------------------
  # Red
  # --------------------------------------------------------------------------
  network_device {
    bridge = var.network_bridge  # Definido en variables.tf
    model  = "virtio"
  }
  
  # --------------------------------------------------------------------------
  # Cloud-init - Inicialización automática
  # --------------------------------------------------------------------------
  initialization {
    ip_config {
      ipv4 {
        # IP estática del worker 2
        # IMPORTANTE: Debe coincidir con ansible/inventory.yml
        address = "192.168.10.102/24"  # CAMBIAR según tu red
        gateway = var.network_gateway
      }
    }
    
    user_account {
      username = "ubuntu"
      keys     = [var.ssh_public_key]
    }
  }
  
  # --------------------------------------------------------------------------
  # Qemu Guest Agent
  # --------------------------------------------------------------------------
  agent {
    enabled = true
  }
}

# ============================================================================
# Output - IP del worker para referencia
# ============================================================================
output "k3s_worker_2_ip" {
  value       = "192.168.10.102"
  description = "IP del worker 2 K3s"
}

# ============================================================================
# NOTAS:
# 
# 1. La IP 192.168.10.102 debe estar libre en tu red
# 2. Debe coincidir con ansible/inventory.yml (worker-2)
# 3. Los workers NO tienen taint, ejecutan workloads de usuario
# 4. Para añadir más workers, duplica este archivo como k3s-worker-3.tf
#    y actualiza:
#    - Nombre del resource
#    - Nombre de la VM (name)
#    - IP estática (address)
#    - Output name
# ============================================================================
