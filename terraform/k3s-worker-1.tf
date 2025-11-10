# ============================================================================
# K3s Worker Node 1 - Nodo de carga
# ============================================================================
# Esta VM ejecutará el agente K3s (worker)
# Ejecuta los pods y workloads de las aplicaciones
# ============================================================================

resource "proxmox_virtual_environment_vm" "k3s-worker-1" {
  name        = "vm-k3s-worker-1"
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
        # IP estática del worker 1
        # IMPORTANTE: Debe coincidir con ansible/inventory.yml
        address = "192.168.10.101/24"  # CAMBIAR según tu red
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
output "k3s_worker_1_ip" {
  value       = "192.168.10.101"
  description = "IP del worker 1 K3s"
}

# ============================================================================
# NOTAS:
# 
# 1. La IP 192.168.10.101 debe estar libre en tu red
# 2. Debe coincidir con ansible/inventory.yml (worker-1)
# 3. Los workers NO tienen taint, ejecutan workloads de usuario
# 4. Para escalabilidad, duplica este archivo y cambia IPs/nombres
# ============================================================================
