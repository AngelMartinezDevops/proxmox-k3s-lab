# Proxmox K3s Lab

<div align="center">

**Cluster K3s automatizado en Proxmox con Terraform y Ansible**

[![Proxmox](https://img.shields.io/badge/Proxmox-VE-orange)](https://www.proxmox.com/)
[![Terraform](https://img.shields.io/badge/Terraform-1.0+-purple)](https://www.terraform.io/)
[![Ansible](https://img.shields.io/badge/Ansible-Automation-red)](https://www.ansible.com/)
[![K3s](https://img.shields.io/badge/K3s-Kubernetes-blue)](https://k3s.io/)

[English](README.md) | **Español**

Canal de YouTube: [@angelmartinezdevops](https://youtube.com/@angelmartinezdevops)

</div>

---

## 📋 Índice

1. [Descripción del Proyecto](#-descripción-del-proyecto)
2. [Arquitectura](#-arquitectura)
3. [Requisitos Previos](#-requisitos-previos)
4. [Instalación](#-instalación)
5. [Uso del Cluster](#-uso-del-cluster)
6. [Gestión y Mantenimiento](#-gestión-y-mantenimiento)
7. [Troubleshooting](#-troubleshooting)
8. [Referencias](#-referencias)

---

## 🎯 Descripción del Proyecto

Este repositorio automatiza el despliegue completo de un cluster **K3s** (Kubernetes ligero) en **Proxmox** utilizando:

- **Terraform** para el aprovisionamiento de infraestructura (VMs)
- **Ansible** para la configuración y despliegue de K3s
- **Cloud-init** para la inicialización de las VMs

El resultado es un cluster de 3 nodos (1 master + 2 workers) completamente funcional y listo para desplegar aplicaciones.

**Hardware del Lab:**
- Intel Core i7-6700T (4 cores / 8 threads @ 2.80GHz)
- 8GB RAM
- 240GB NVMe (Sistema Proxmox)
- Proxmox VE 7.x

---

## 🏗️ Arquitectura

```
Proxmox Host (192.168.10.0/24)
│
└── Cluster K3s
    ├── VM Master (192.168.10.100)
    │   ├── 2 cores, 4GB RAM, 20GB disco
    │   ├── K3s Server (Control Plane)
    │   └── Taint: CriticalAddonsOnly=true:NoExecute
    │
    ├── VM Worker-1 (192.168.10.101)
    │   ├── 1 core, 3GB RAM, 20GB disco
    │   └── K3s Agent (Worker)
    │
    └── VM Worker-2 (192.168.10.102)
        ├── 1 core, 3GB RAM, 20GB disco
        └── K3s Agent (Worker)
```

### Características del Cluster:

- **Master**: Solo para control plane (con taint)
- **Workers**: Ejecutan workloads
- **CNI**: Flannel (incluido en K3s)
- **Load Balancer**: ServiceLB (incluido en K3s)
- **Ingress**: Traefik (incluido en K3s)
- **Storage**: Local-path provisioner (incluido en K3s)

---

## 📦 Requisitos Previos

### Software necesario en tu máquina:

- **Terraform** >= 1.0
- **Ansible** >= 2.9 (requiere Linux o WSL en Windows)
- **kubectl** (para interactuar con el cluster)
- **SSH key** generada (`~/.ssh/id_ed25519`)

### Instrucciones de Instalación

#### En Linux/Mac:

```bash
# Instalar Terraform
curl -fsSL https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip -o terraform.zip
unzip terraform.zip && sudo mv terraform /usr/local/bin/

# Instalar Ansible
pip install ansible

# Instalar kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && sudo mv kubectl /usr/local/bin/

# Generar SSH key si no tienes
ssh-keygen -t ed25519 -C "k3s-lab" -f ~/.ssh/id_ed25519
```

#### En Windows:

**1. Instalar Terraform:**

```powershell
# Método 1: Instalación manual (Recomendado)
# 1. Descargar Terraform desde https://www.terraform.io/downloads
# 2. Extraer el archivo .zip
# 3. Crear directorio:
New-Item -Path "C:\terraform" -ItemType Directory

# 4. Mover terraform.exe a C:\terraform
# 5. Añadir al PATH del sistema:
#    - Abrir Propiedades del Sistema (Win + Pause/Break)
#    - Clic en "Configuración avanzada del sistema"
#    - Clic en "Variables de entorno"
#    - En "Variables del sistema", buscar "Path" y hacer clic en "Editar"
#    - Clic en "Nuevo" y añadir: C:\terraform
#    - Clic en "Aceptar" en todas las ventanas
# 6. Reiniciar PowerShell y verificar:
terraform version

# Método 2: Usando Chocolatey (si está instalado):
choco install terraform

# Método 3: Usando Scoop (si está instalado):
scoop install terraform
```

**2. Instalar WSL2 (necesario para Ansible):**

```powershell
# Abrir PowerShell como Administrador
wsl --install

# Reiniciar el ordenador
# Después del reinicio, abrir WSL (Ubuntu) desde el Menú Inicio

# Dentro de WSL, instalar Ansible:
sudo apt update
sudo apt install ansible python3-pip -y
```

**3. Instalar kubectl:**

```powershell
# Descargar kubectl desde https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/
# O usando Chocolatey:
choco install kubernetes-cli

# O usando Scoop:
scoop install kubectl

# Verificar instalación:
kubectl version --client
```

**4. Generar SSH Key:**

```powershell
# Abrir PowerShell
ssh-keygen -t ed25519 -C "k3s-lab"

# Presionar Enter para aceptar la ubicación por defecto (C:\Users\TuUsuario\.ssh\id_ed25519)
# Introducir passphrase (opcional)

# Ver tu clave pública:
Get-Content $env:USERPROFILE\.ssh\id_ed25519.pub

# Copiar esta clave para usar en terraform.tfvars
```

**5. Configurar SSH para WSL:**

```bash
# Dentro de WSL, crear directorio .ssh
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Copiar clave SSH de Windows a WSL
cp /mnt/c/Users/TU_USUARIO_WINDOWS/.ssh/id_ed25519* ~/.ssh/
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

### En Proxmox:

- **Proxmox VE** 7.x o superior instalado y funcionando
- **Template VM** con Ubuntu 24.04 + Cloud-init (ID 9000)
- Acceso API con usuario **root@pam**

---

## 🚀 Instalación

### Paso 1: Crear Template Cloud-Init en Proxmox

Ejecuta esto en el **host Proxmox** (SSH):

```bash
# Descargar imagen Ubuntu Cloud
cd /tmp
wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img

# Crear VM template
qm create 9000 --name ubuntu-template --memory 2048 --net0 virtio,bridge=vmbr0

# Importar disco
qm importdisk 9000 noble-server-cloudimg-amd64.img local-lvm

# Configurar disco y cloud-init
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --serial0 socket --vga serial0
qm set 9000 --agent enabled=1

# Convertir a template
qm template 9000

# Verificar
qm list
```

### Paso 2: Clonar este repositorio

```bash
git clone https://github.com/angelmartinezdevops/proxmox-k3s-lab.git
cd proxmox-k3s-lab
```

### Paso 3: Configurar Terraform

```bash
cd terraform/

# Editar terraform.tfvars con tus datos
nano terraform.tfvars
```

**Edita `terraform.tfvars` y reemplaza los placeholders:**

El archivo ya existe con placeholders y comentarios detallados. Reemplaza:
- `TU_IP_PROXMOX` con la IP de tu servidor Proxmox
- `TU_PASSWORD_PROXMOX` con tu contraseña de Proxmox
- `TU_NODO_PROXMOX` con el nombre de tu nodo Proxmox
- `TU_GATEWAY` con tu gateway de red
- `ssh-ed25519 AAAA_TU_CLAVE_PUBLICA...` con tu clave SSH pública completa

Cada variable tiene comentarios explicando cómo obtener el valor.

### Paso 4: Desplegar VMs con Terraform

```bash
# Inicializar Terraform
terraform init

# Verificar plan
terraform plan

# Aplicar (crear VMs)
terraform apply

# Confirmar con "yes"
```

**Tiempo estimado:** 3-5 minutos

**Output esperado:**

```
k3s_master_ip = "192.168.10.100"
k3s_worker_1_ip = "192.168.10.101"
k3s_worker_2_ip = "192.168.10.102"
```

### Paso 5: Instalar K3s con Ansible

```bash
cd ../ansible/

# Verificar conectividad SSH
ansible all -i inventory.yml -m ping

# Desplegar K3s
ansible-playbook -i inventory.yml playbook-k3s.yml
```

**Tiempo estimado:** 5-10 minutos

**Output esperado:**

```
TASK [Mostrar estado del cluster] 
ok: [master] => {
    "msg": [
        "NAME              STATUS   ROLES                  AGE   VERSION",
        "vm-k3s-master     Ready    control-plane,master   2m    v1.28.4+k3s1",
        "vm-k3s-worker-1   Ready    <none>                 1m    v1.28.4+k3s1",
        "vm-k3s-worker-2   Ready    <none>                 1m    v1.28.4+k3s1"
    ]
}
```

### Paso 6: Configurar kubectl en tu máquina

```bash
# Copiar kubeconfig desde el master
scp ubuntu@192.168.10.100:/etc/rancher/k3s/k3s.yaml ~/.kube/config

# Cambiar IP del servidor (localhost → IP del master)
sed -i 's/127.0.0.1/192.168.10.100/g' ~/.kube/config

# Verificar acceso
kubectl get nodes
kubectl cluster-info
```

---

## 🖥️ Instalar Lens (Opcional - Recomendado)

[Lens](https://k8slens.dev/) es un potente IDE para Kubernetes que proporciona una interfaz gráfica para gestionar tu cluster.

### Instalar Lens

**En Windows/Mac/Linux:**

1. Descargar Lens desde: https://k8slens.dev/
2. Instalar la aplicación
3. Ejecutar Lens

### Añadir tu cluster K3s a Lens

**Opción 1: Detección automática**

1. Abrir Lens
2. Hacer clic en **"+"** (Añadir Cluster) en la esquina superior izquierda
3. Lens detectará automáticamente los clusters desde `~/.kube/config`
4. Seleccionar tu cluster K3s y hacer clic en **"Añadir Cluster"**

**Opción 2: Configuración manual**

1. Abrir Lens
2. Hacer clic en **"+" → "Añadir desde kubeconfig"**
3. Pegar el contenido de tu kubeconfig:

```bash
# Linux/Mac
cat ~/.kube/config

# Windows PowerShell
Get-Content $env:USERPROFILE\.kube\config
```

4. Hacer clic en **"Añadir Cluster"**

### Usar Lens

Una vez conectado, puedes:
- **Ver todos los recursos** en una interfaz gráfica
- **Acceder a logs de pods** con resaltado de sintaxis
- **Ejecutar comandos** en pods con terminal integrado
- **Monitorizar recursos** (CPU, Memoria) en tiempo real
- **Editar recursos** con un editor YAML integrado
- **Port-forward** servicios con un clic
- **Instalar Helm charts** desde un catálogo

**Extensiones recomendadas de Lens:**
- Resource Metrics (ver uso de CPU/Memoria)
- Pod Security
- Helm

---

## 🎮 Uso del Cluster

### Verificar estado del cluster

```bash
# Ver nodos
kubectl get nodes -o wide

# Ver todos los recursos
kubectl get all -A

# Ver pods del sistema
kubectl get pods -n kube-system
```

### Desplegar una aplicación de prueba

```bash
# Crear deployment de nginx
kubectl create deployment nginx --image=nginx --replicas=3

# Exponer como servicio
kubectl expose deployment nginx --port=80 --type=NodePort

# Ver servicio creado
kubectl get svc nginx

# Acceder (sustituye NODEPORT por el puerto asignado)
curl http://192.168.10.100:NODEPORT
```

### Usar los ejemplos incluidos

```bash
cd k3s/

# Deployment simple
kubectl apply -f 01-deployment-simple.yaml

# ConfigMap y Secret
kubectl apply -f 02-configmap-secret.yaml

# Health checks
kubectl apply -f 03-health-checks.yaml

# Persistent Volume
kubectl apply -f 04-persistent-volume.yaml

# Ver README de ejemplos
cat README.md
```

---

## 🔧 Gestión y Mantenimiento

### Añadir un nuevo worker

Edita `terraform/k3s-worker-3.tf`:

```hcl
resource "proxmox_virtual_environment_vm" "k3s-worker-3" {
  name        = "vm-k3s-worker-3"
  node_name   = var.proxmox_node
  
  clone {
    vm_id = 9000
  }
  
  cpu {
    cores = 1
    type  = "host"
  }
  
  memory {
    dedicated = 3072
  }
  
  disk {
    datastore_id = var.storage_pool
    interface    = "scsi0"
    size         = 20
    file_format  = "raw"
  }
  
  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }
  
  initialization {
    ip_config {
      ipv4 {
        address = "192.168.10.103/24"
        gateway = var.network_gateway
      }
    }
    
    user_account {
      username = "ubuntu"
      keys     = [var.ssh_public_key]
    }
  }
  
  agent {
    enabled = true
  }
}
```

Luego:

```bash
# Crear VM
terraform apply

# Añadir a inventory de Ansible
nano ../ansible/inventory.yml

# Ejecutar playbook solo en el nuevo worker
ansible-playbook -i inventory.yml playbook-k3s.yml --limit worker-3
```

### Actualizar K3s

```bash
# En el master
ssh ubuntu@192.168.10.100
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="v1.28.5+k3s1" sh -s - server

# En cada worker
ssh ubuntu@192.168.10.101
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="v1.28.5+k3s1" K3S_URL=https://192.168.10.100:6443 K3S_TOKEN="..." sh -
```

### Backup del cluster

```bash
# Backup del etcd (desde el master)
ssh ubuntu@192.168.10.100
sudo k3s etcd-snapshot save --name backup-$(date +%Y%m%d-%H%M%S)

# Los snapshots se guardan en: /var/lib/rancher/k3s/server/db/snapshots/
```

### Monitorizar recursos

```bash
# Ver uso de recursos de los nodos
kubectl top nodes

# Ver uso de recursos de los pods
kubectl top pods -A

# Describir un nodo
kubectl describe node vm-k3s-worker-1
```

---

## 🐛 Troubleshooting

### VMs no se crean con Terraform

```bash
# Verificar conexión a Proxmox
curl -k https://192.168.10.111:8006/api2/json/version

# Ver logs detallados de Terraform
TF_LOG=DEBUG terraform apply

# Verificar que existe el template
ssh root@proxmox-host "qm list"
```

### Ansible no puede conectar a las VMs

```bash
# Verificar que las VMs tienen IP
ssh root@proxmox-host "qm guest cmd 100 network-get-interfaces"

# Probar SSH manual
ssh ubuntu@192.168.10.100

# Ver logs de cloud-init en la VM
ssh ubuntu@192.168.10.100 "sudo cat /var/log/cloud-init.log"
```

### Nodos no se unen al cluster

```bash
# En el master, ver logs de K3s
ssh ubuntu@192.168.10.100
sudo journalctl -u k3s -f

# En el worker, ver logs
ssh ubuntu@192.168.10.101
sudo journalctl -u k3s-agent -f

# Verificar token
ssh ubuntu@192.168.10.100
sudo cat /var/lib/rancher/k3s/server/node-token

# Verificar conectividad del worker al master
ssh ubuntu@192.168.10.101
curl -k https://192.168.10.100:6443
```

### Pods en estado Pending

```bash
# Ver eventos del cluster
kubectl get events -A --sort-by='.lastTimestamp'

# Describir el pod problemático
kubectl describe pod POD_NAME -n NAMESPACE

# Ver logs del pod
kubectl logs POD_NAME -n NAMESPACE
```

### Reiniciar K3s

```bash
# En el master
ssh ubuntu@192.168.10.100
sudo systemctl restart k3s

# En los workers
ssh ubuntu@192.168.10.101
sudo systemctl restart k3s-agent
```

---

## 🗑️ Destruir el Cluster

### Opción 1: Destruir solo con Terraform

```bash
cd terraform/
terraform destroy
```

Esto elimina las VMs pero deja el cluster K3s instalado (si vuelves a crear las VMs, necesitarás reinstalar K3s).

### Opción 2: Destrucción completa

```bash
# 1. Desinstalar K3s de todos los nodos
ansible all -i inventory.yml -b -m shell -a "/usr/local/bin/k3s-uninstall.sh" || true
ansible k3s_workers -i inventory.yml -b -m shell -a "/usr/local/bin/k3s-agent-uninstall.sh" || true

# 2. Destruir VMs con Terraform
cd terraform/
terraform destroy
```

---

## 📚 Referencias

### Documentación oficial:

- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
- [Terraform Proxmox Provider](https://registry.terraform.io/providers/bpg/proxmox/latest/docs)
- [K3s Documentation](https://docs.k3s.io/)
- [Ansible Documentation](https://docs.ansible.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

### Tutoriales y recursos:

- [K3s Quick Start](https://docs.k3s.io/quick-start)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)

---

## 🤝 Contribuciones

¡Las contribuciones son bienvenidas! Si encuentras algún error o tienes mejoras:

1. Fork este repositorio
2. Crea una rama: `git checkout -b feature/mejora`
3. Commit: `git commit -m 'Añade mejora X'`
4. Push: `git push origin feature/mejora`
5. Abre un Pull Request

---

## 📺 Canal de YouTube

Sigue el canal para más contenido de DevOps, Kubernetes y automatización:

**[@angelmartinezdevops](https://youtube.com/@angelmartinezdevops)**

Videos relacionados con este repo:
- Montando un cluster K3s en Proxmox con Terraform
- Automatizando Kubernetes con Ansible
- Desplegando aplicaciones en K3s

---

## 📄 Licencia

MIT License - Uso libre y modificación

---

**Construido con ❤️ para la comunidad HomeLab y DevOps**

*Última actualización: Noviembre 2025*

