# K3s Manifiestos - Ejemplos

Manifiestos de Kubernetes para aprender y probar el cluster K3s.

## 📁 Contenido

Esta carpeta contiene ejemplos progresivos de Kubernetes para aprender:

- `01-deployment-simple.yaml` - Deployment básico con nginx
- `02-configmap-secret.yaml` - Uso de ConfigMaps y Secrets
- `03-health-checks.yaml` - Liveness y Readiness probes
- `04-persistent-volume.yaml` - Volúmenes persistentes
- `05-multi-container-pod.yaml` - Pods con múltiples contenedores
- `06-namespace-resourcequota.yaml` - Namespaces y límites de recursos
- `07-job-cronjob.yaml` - Jobs y CronJobs
- `08-ingress.yaml` - Ingress con Traefik

## 🚀 Uso

### Aplicar un ejemplo individual

```bash
# Aplicar un manifest
kubectl apply -f 01-deployment-simple.yaml

# Ver recursos creados
kubectl get all

# Ver logs
kubectl logs deployment/nginx

# Eliminar
kubectl delete -f 01-deployment-simple.yaml
```

### Probar todos los ejemplos

```bash
# Aplicar todos
kubectl apply -f .

# Ver todo
kubectl get all -A

# Limpiar todo
kubectl delete -f .
```

## 📝 Descripción de cada ejemplo

### 01 - Deployment Simple
Deployment básico de nginx con 3 réplicas y un Service tipo NodePort.

```bash
kubectl apply -f 01-deployment-simple.yaml
kubectl get svc
# Acceder: http://192.168.10.100:NODEPORT
```

### 02 - ConfigMap y Secret
Muestra cómo usar configuraciones y secretos en los pods.

```bash
kubectl apply -f 02-configmap-secret.yaml
kubectl exec -it POD_NAME -- env | grep APP_
```

### 03 - Health Checks
Liveness y Readiness probes para monitoring de aplicaciones.

```bash
kubectl apply -f 03-health-checks.yaml
kubectl describe pod POD_NAME
```

### 04 - Persistent Volume
Uso de PersistentVolumeClaim con el storage local de K3s.

```bash
kubectl apply -f 04-persistent-volume.yaml
kubectl get pvc
```

### 05 - Multi-Container Pod
Pod con múltiples contenedores que comparten volumen.

```bash
kubectl apply -f 05-multi-container-pod.yaml
kubectl logs POD_NAME -c nginx
kubectl logs POD_NAME -c sidecar
```

### 06 - Namespace y ResourceQuota
Creación de namespaces con límites de recursos.

```bash
kubectl apply -f 06-namespace-resourcequota.yaml
kubectl get namespace
kubectl describe resourcequota -n dev
```

### 07 - Job y CronJob
Ejecución de tareas puntuales y programadas.

```bash
kubectl apply -f 07-job-cronjob.yaml
kubectl get jobs
kubectl get cronjobs
kubectl logs job/pi-calculation
```

### 08 - Ingress
Ingress con Traefik (incluido en K3s) para exponer servicios.

```bash
kubectl apply -f 08-ingress.yaml
# Añadir a /etc/hosts: 192.168.10.100 app.lab.local
# Acceder: http://app.lab.local
```

## 🧪 Ejercicios sugeridos

1. **Escalar un deployment:**
   ```bash
   kubectl scale deployment nginx --replicas=5
   ```

2. **Actualizar imagen:**
   ```bash
   kubectl set image deployment/nginx nginx=nginx:alpine
   kubectl rollout status deployment/nginx
   ```

3. **Ver historia de rollouts:**
   ```bash
   kubectl rollout history deployment/nginx
   ```

4. **Rollback:**
   ```bash
   kubectl rollout undo deployment/nginx
   ```

5. **Port-forward para debugging:**
   ```bash
   kubectl port-forward deployment/nginx 8080:80
   # Acceder: http://localhost:8080
   ```

## 📚 Más recursos

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [K3s Examples](https://github.com/k3s-io/k3s/tree/master/examples)
- [Kubernetes By Example](https://kubernetesbyexample.com/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
