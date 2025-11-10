# Proxmox K3s Lab

<div align="center">

**Automated K3s Cluster on Proxmox with Terraform and Ansible**

[![Proxmox](https://img.shields.io/badge/Proxmox-VE-orange)](https://www.proxmox.com/)
[![Terraform](https://img.shields.io/badge/Terraform-1.0+-purple)](https://www.terraform.io/)
[![Ansible](https://img.shields.io/badge/Ansible-Automation-red)](https://www.ansible.com/)
[![K3s](https://img.shields.io/badge/K3s-Kubernetes-blue)](https://k3s.io/)

**English** | [Español](README_ES.md)

</div>

---

## 📋 Table of Contents

1. [Project Description](#-project-description)
2. [Architecture](#-architecture)
3. [Prerequisites](#-prerequisites)
4. [Installation](#-installation)
5. [Cluster Usage](#-cluster-usage)
6. [Management and Maintenance](#-management-and-maintenance)
7. [Troubleshooting](#-troubleshooting)
8. [References](#-references)

---

## 🎯 Project Description

This repository automates the complete deployment of a **K3s** cluster (lightweight Kubernetes) on **Proxmox** using:

- **Terraform** for infrastructure provisioning (VMs)
- **Ansible** for K3s configuration and deployment
- **Cloud-init** for VM initialization

The result is a fully functional 3-node cluster (1 master + 2 workers) ready to deploy applications.

**Lab Hardware:**
- Intel Core i7-6700T (4 cores / 8 threads @ 2.80GHz)
- 8GB RAM
- 240GB NVMe (Proxmox System)
- Proxmox VE 7.x

---

## 🏗️ Architecture

```
Proxmox Host (192.168.10.0/24)
│
└── K3s Cluster
    ├── VM Master (192.168.10.100)
    │   ├── 2 cores, 4GB RAM, 20GB disk
    │   ├── K3s Server (Control Plane)
    │   └── Taint: CriticalAddonsOnly=true:NoExecute
    │
    ├── VM Worker-1 (192.168.10.101)
    │   ├── 1 core, 3GB RAM, 20GB disk
    │   └── K3s Agent (Worker)
    │
    └── VM Worker-2 (192.168.10.102)
        ├── 1 core, 3GB RAM, 20GB disk
        └── K3s Agent (Worker)
```

### Cluster Features:

- **Master**: Control plane only (with taint)
- **Workers**: Run workloads
- **CNI**: Flannel (included in K3s)
- **Load Balancer**: ServiceLB (included in K3s)
- **Ingress**: Traefik (included in K3s)
- **Storage**: Local-path provisioner (included in K3s)

---

## 📦 Prerequisites

### Required Software on Your Machine:

- **Terraform** >= 1.0
- **Ansible** >= 2.9 (requires Linux or WSL on Windows)
- **kubectl** (to interact with the cluster)
- **SSH key** generated (`~/.ssh/id_ed25519`)

### Installation Instructions

#### On Linux/Mac:

```bash
# Install Terraform
curl -fsSL https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip -o terraform.zip
unzip terraform.zip && sudo mv terraform /usr/local/bin/

# Install Ansible
pip install ansible

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && sudo mv kubectl /usr/local/bin/

# Generate SSH key if you don't have one
ssh-keygen -t ed25519 -C "k3s-lab" -f ~/.ssh/id_ed25519
```

#### On Windows:

**1. Install Terraform:**

```powershell
# Method 1: Manual installation (Recommended)
# 1. Download Terraform from https://www.terraform.io/downloads
# 2. Extract the .zip file
# 3. Create directory:
New-Item -Path "C:\terraform" -ItemType Directory

# 4. Move terraform.exe to C:\terraform
# 5. Add to System PATH:
#    - Open System Properties (Win + Pause/Break)
#    - Click "Advanced system settings"
#    - Click "Environment Variables"
#    - Under "System variables", find "Path" and click "Edit"
#    - Click "New" and add: C:\terraform
#    - Click "OK" on all windows
# 6. Restart PowerShell and verify:
terraform version

# Method 2: Using Chocolatey (if installed):
choco install terraform

# Method 3: Using Scoop (if installed):
scoop install terraform
```

**2. Install WSL2 (required for Ansible):**

```powershell
# Open PowerShell as Administrator
wsl --install

# Restart your computer
# After restart, open WSL (Ubuntu) from Start Menu

# Inside WSL, install Ansible:
sudo apt update
sudo apt install ansible python3-pip -y
```

**3. Install kubectl:**

```powershell
# Download kubectl from https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/
# Or using Chocolatey:
choco install kubernetes-cli

# Or using Scoop:
scoop install kubectl

# Verify installation:
kubectl version --client
```

**4. Generate SSH Key:**

```powershell
# Open PowerShell
ssh-keygen -t ed25519 -C "k3s-lab"

# Press Enter to accept default location (C:\Users\YourUser\.ssh\id_ed25519)
# Enter passphrase (optional)

# View your public key:
Get-Content $env:USERPROFILE\.ssh\id_ed25519.pub

# Copy this key to use in terraform.tfvars
```

**5. Configure SSH for WSL:**

```bash
# Inside WSL, create .ssh directory
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Copy SSH key from Windows to WSL
cp /mnt/c/Users/YOUR_WINDOWS_USER/.ssh/id_ed25519* ~/.ssh/
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

### On Proxmox:

- **Proxmox VE** 7.x or higher installed and running
- **Template VM** with Ubuntu 24.04 + Cloud-init (ID 9000)
- API access with user **root@pam**

---

## 🚀 Installation

### Step 1: Create Cloud-Init Template on Proxmox

Run this on the **Proxmox host** (SSH):

```bash
# Download Ubuntu Cloud image
cd /tmp
wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img

# Create VM template
qm create 9000 --name ubuntu-template --memory 2048 --net0 virtio,bridge=vmbr0

# Import disk
qm importdisk 9000 noble-server-cloudimg-amd64.img local-lvm

# Configure disk and cloud-init
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --serial0 socket --vga serial0
qm set 9000 --agent enabled=1

# Convert to template
qm template 9000

# Verify
qm list
```

### Step 2: Clone this repository

```bash
git clone https://github.com/angelmartinezdevops/proxmox-k3s-lab.git
cd proxmox-k3s-lab
```

### Step 3: Configure Terraform

```bash
cd terraform/

# Edit terraform.tfvars with your data
nano terraform.tfvars
# On Windows: notepad terraform.tfvars
```

**Edit `terraform.tfvars` and replace placeholders:**

The file already exists with placeholders and detailed comments. Replace:
- `TU_IP_PROXMOX` with your Proxmox server IP
- `TU_PASSWORD_PROXMOX` with your Proxmox password
- `TU_NODO_PROXMOX` with your Proxmox node name
- `TU_GATEWAY` with your network gateway
- `ssh-ed25519 AAAA_TU_CLAVE_PUBLICA...` with your full SSH public key

Each variable has comments explaining how to obtain the value.

### Step 4: Deploy VMs with Terraform

```bash
# Initialize Terraform
terraform init

# Verify plan
terraform plan

# Apply (create VMs)
terraform apply

# Confirm with "yes"
```

**Estimated time:** 3-5 minutes

**Expected output:**

```
k3s_master_ip = "192.168.10.100"
k3s_worker_1_ip = "192.168.10.101"
k3s_worker_2_ip = "192.168.10.102"
```

### Step 5: Install K3s with Ansible

**On Linux/Mac:**

```bash
cd ../ansible/

# Verify SSH connectivity
ansible all -i inventory.yml -m ping

# Deploy K3s
ansible-playbook -i inventory.yml playbook-k3s.yml
```

**On Windows (using WSL):**

```bash
# Open WSL terminal
cd /mnt/d/Workspace/proxmox-k3s-lab/ansible

# Verify SSH connectivity
ansible all -i inventory.yml -m ping

# Deploy K3s
ansible-playbook -i inventory.yml playbook-k3s.yml
```

**Estimated time:** 5-10 minutes

**Expected output:**

```
TASK [Show cluster status] 
ok: [master] => {
    "msg": [
        "NAME              STATUS   ROLES                  AGE   VERSION",
        "vm-k3s-master     Ready    control-plane,master   2m    v1.28.4+k3s1",
        "vm-k3s-worker-1   Ready    <none>                 1m    v1.28.4+k3s1",
        "vm-k3s-worker-2   Ready    <none>                 1m    v1.28.4+k3s1"
    ]
}
```

### Step 6: Configure kubectl on your machine

**On Linux/Mac:**

```bash
# Copy kubeconfig from master
scp ubuntu@192.168.10.100:/etc/rancher/k3s/k3s.yaml ~/.kube/config

# Change server IP (localhost → master IP)
sed -i 's/127.0.0.1/192.168.10.100/g' ~/.kube/config

# Verify access
kubectl get nodes
kubectl cluster-info
```

**On Windows:**

```powershell
# Copy kubeconfig from master
scp ubuntu@192.168.10.100:/etc/rancher/k3s/k3s.yaml $env:USERPROFILE\.kube\config

# Edit config file and change server IP
# Open: C:\Users\YourUser\.kube\config
# Replace: https://127.0.0.1:6443
# With: https://192.168.10.100:6443

# Verify access
kubectl get nodes
kubectl cluster-info
```

---

## 🖥️ Install Lens (Optional - Recommended)

[Lens](https://k8slens.dev/) is a powerful IDE for Kubernetes that provides a graphical interface to manage your cluster.

### Install Lens

**On Windows/Mac/Linux:**

1. Download Lens from: https://k8slens.dev/
2. Install the application
3. Launch Lens

### Add your K3s cluster to Lens

**Option 1: Automatic detection**

1. Open Lens
2. Click on **"+"** (Add Cluster) in the top left
3. Lens will automatically detect clusters from `~/.kube/config`
4. Select your K3s cluster and click **"Add Cluster"**

**Option 2: Manual configuration**

1. Open Lens
2. Click **"+" → "Add from kubeconfig"**
3. Paste the content of your kubeconfig:

```bash
# Linux/Mac
cat ~/.kube/config

# Windows PowerShell
Get-Content $env:USERPROFILE\.kube\config
```

4. Click **"Add Cluster"**

### Using Lens

Once connected, you can:
- **View all resources** in a graphical interface
- **Access pod logs** with syntax highlighting
- **Execute commands** in pods with integrated terminal
- **Monitor resources** (CPU, Memory) in real-time
- **Edit resources** with a built-in YAML editor
- **Port-forward** services with one click
- **Install Helm charts** from a catalog

**Recommended Lens extensions:**
- Resource Metrics (view CPU/Memory usage)
- Pod Security
- Helm

---

## 🎮 Cluster Usage

### Verify cluster status

```bash
# View nodes
kubectl get nodes -o wide

# View all resources
kubectl get all -A

# View system pods
kubectl get pods -n kube-system
```

### Deploy a test application

```bash
# Create nginx deployment
kubectl create deployment nginx --image=nginx --replicas=3

# Expose as service
kubectl expose deployment nginx --port=80 --type=NodePort

# View created service
kubectl get svc nginx

# Access (replace NODEPORT with assigned port)
curl http://192.168.10.100:NODEPORT
```

### Use included examples

```bash
cd k3s/

# Simple deployment
kubectl apply -f 01-deployment-simple.yaml

# ConfigMap and Secret
kubectl apply -f 02-configmap-secret.yaml

# Health checks
kubectl apply -f 03-health-checks.yaml

# Persistent Volume
kubectl apply -f 04-persistent-volume.yaml

# View examples README
cat README.md
```

---

## 🔧 Management and Maintenance

### Add a new worker

Edit `terraform/k3s-worker-3.tf`:

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

Then:

```bash
# Create VM
terraform apply

# Add to Ansible inventory
nano ../ansible/inventory.yml

# Run playbook only on new worker
ansible-playbook -i inventory.yml playbook-k3s.yml --limit worker-3
```

### Update K3s

```bash
# On master
ssh ubuntu@192.168.10.100
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="v1.28.5+k3s1" sh -s - server

# On each worker
ssh ubuntu@192.168.10.101
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="v1.28.5+k3s1" K3S_URL=https://192.168.10.100:6443 K3S_TOKEN="..." sh -
```

### Cluster backup

```bash
# Backup etcd (from master)
ssh ubuntu@192.168.10.100
sudo k3s etcd-snapshot save --name backup-$(date +%Y%m%d-%H%M%S)

# Snapshots are saved in: /var/lib/rancher/k3s/server/db/snapshots/
```

### Monitor resources

```bash
# View node resource usage
kubectl top nodes

# View pod resource usage
kubectl top pods -A

# Describe a node
kubectl describe node vm-k3s-worker-1
```

---

## 🐛 Troubleshooting

### VMs not created with Terraform

```bash
# Verify Proxmox connection
curl -k https://192.168.10.111:8006/api2/json/version

# View detailed Terraform logs
TF_LOG=DEBUG terraform apply

# Verify template exists
ssh root@proxmox-host "qm list"
```

### Ansible cannot connect to VMs

```bash
# Verify VMs have IP
ssh root@proxmox-host "qm guest cmd 100 network-get-interfaces"

# Test SSH manually
ssh ubuntu@192.168.10.100

# View cloud-init logs in VM
ssh ubuntu@192.168.10.100 "sudo cat /var/log/cloud-init.log"
```

### Nodes don't join cluster

```bash
# On master, view K3s logs
ssh ubuntu@192.168.10.100
sudo journalctl -u k3s -f

# On worker, view logs
ssh ubuntu@192.168.10.101
sudo journalctl -u k3s-agent -f

# Verify token
ssh ubuntu@192.168.10.100
sudo cat /var/lib/rancher/k3s/server/node-token

# Verify worker to master connectivity
ssh ubuntu@192.168.10.101
curl -k https://192.168.10.100:6443
```

### Pods in Pending state

```bash
# View cluster events
kubectl get events -A --sort-by='.lastTimestamp'

# Describe problematic pod
kubectl describe pod POD_NAME -n NAMESPACE

# View pod logs
kubectl logs POD_NAME -n NAMESPACE
```

### Restart K3s

```bash
# On master
ssh ubuntu@192.168.10.100
sudo systemctl restart k3s

# On workers
ssh ubuntu@192.168.10.101
sudo systemctl restart k3s-agent
```

---

## 🗑️ Destroy Cluster

### Option 1: Destroy with Terraform only

```bash
cd terraform/
terraform destroy
```

This removes VMs but leaves K3s installed (if you recreate VMs, you'll need to reinstall K3s).

### Option 2: Complete destruction

```bash
# 1. Uninstall K3s from all nodes
ansible all -i inventory.yml -b -m shell -a "/usr/local/bin/k3s-uninstall.sh" || true
ansible k3s_workers -i inventory.yml -b -m shell -a "/usr/local/bin/k3s-agent-uninstall.sh" || true

# 2. Destroy VMs with Terraform
cd terraform/
terraform destroy
```

---

## 📚 References

### Official Documentation:

- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
- [Terraform Proxmox Provider](https://registry.terraform.io/providers/bpg/proxmox/latest/docs)
- [K3s Documentation](https://docs.k3s.io/)
- [Ansible Documentation](https://docs.ansible.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

### Tutorials and Resources:

- [K3s Quick Start](https://docs.k3s.io/quick-start)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)

---

## 🤝 Contributing

Contributions are welcome! If you find any bugs or have improvements:

1. Fork this repository
2. Create a branch: `git checkout -b feature/improvement`
3. Commit: `git commit -m 'Add improvement X'`
4. Push: `git push origin feature/improvement`
5. Open a Pull Request

---

## 🙏 Acknowledgments

- [K3s](https://k3s.io/) by Rancher/SUSE
- [Terraform Proxmox Provider](https://github.com/bpg/terraform-provider-proxmox) by bpg
- [Proxmox VE](https://www.proxmox.com/)
- [Ansible](https://www.ansible.com/)

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 📧 Contact

If you have questions or need help, feel free to open an issue.

---

**Made with ❤️ for the HomeLab and DevOps community**

*Last updated: November 2025*
