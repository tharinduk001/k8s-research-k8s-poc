# Kubernetes Deployment Guide — Student Management System

Deploy the Student Management System as **3 pods** on Kubernetes, with inter-pod networking.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Architecture Overview](#architecture-overview)
3. [Understanding the Key Concepts](#understanding-the-key-concepts)
4. [Project File Structure](#project-file-structure)
5. [Step 1 — Build Docker Images](#step-1--build-docker-images)
6. [Step 2 — Load Images into Minikube](#step-2--load-images-into-minikube)
7. [Step 3 — Create the Namespace](#step-3--create-the-namespace)
8. [Step 4 — Deploy the Database](#step-4--deploy-the-database)
9. [Step 5 — Deploy the Backend](#step-5--deploy-the-backend)
10. [Step 6 — Deploy the Frontend](#step-6--deploy-the-frontend)
11. [Step 7 — Access the Application](#step-7--access-the-application)
12. [How Networking Works](#how-networking-works)
13. [Useful Commands](#useful-commands)
14. [Troubleshooting](#troubleshooting)
15. [Cleanup](#cleanup)

---

## Prerequisites

Install the following tools:

| Tool | Purpose | Install Link |
|------|---------|-------------|
| **Docker** | Build container images | [docker.com](https://docs.docker.com/get-docker/) |
| **Minikube** | Local Kubernetes cluster | [minikube.sigs.k8s.io](https://minikube.sigs.k8s.io/docs/start/) |
| **kubectl** | Kubernetes CLI | [kubernetes.io](https://kubernetes.io/docs/tasks/tools/) |

Verify installation:

```bash
docker --version
minikube version
kubectl version --client
```

---

## Architecture Overview

```
                    ┌─────────────────────────────────────────────────────────┐
                    │              Kubernetes Cluster (Minikube)              │
                    │              Namespace: student-management              │
                    │                                                         │
  User's Browser    │   ┌─────────────┐   ┌─────────────┐   ┌────────────┐  │
  http://NODE:30000─┼──▶│  Frontend   │──▶│   Backend   │──▶│  Database  │  │
                    │   │   (Nginx)   │   │  (FastAPI)  │   │ (Postgres) │  │
                    │   │   Pod :80   │   │  Pod :8000  │   │ Pod :5432  │  │
                    │   └──────┬──────┘   └──────┬──────┘   └─────┬──────┘  │
                    │          │                  │                │         │
                    │   ┌──────┴──────┐   ┌──────┴──────┐   ┌─────┴──────┐  │
                    │   │  Service    │   │  Service    │   │  Service   │  │
                    │   │ (NodePort)  │   │ (ClusterIP) │   │ (ClusterIP)│  │
                    │   │  :30000     │   │  :8000      │   │  :5432     │  │
                    │   └─────────────┘   └─────────────┘   └────────────┘  │
                    │                                              │         │
                    │                                        ┌─────┴──────┐  │
                    │                                        │    PVC     │  │
                    │                                        │   (1Gi)    │  │
                    │                                        └────────────┘  │
                    └─────────────────────────────────────────────────────────┘
```

| Pod | Image | Service Type | Port |
|-----|-------|-------------|------|
| **Frontend** | `student-management-system-frontend` | NodePort (30000) | 80 |
| **Backend** | `student-management-system-backend` | ClusterIP | 8000 |
| **Database** | `postgres:16-alpine` | ClusterIP | 5432 |

---

## Understanding the Key Concepts

Before deploying, here's what each Kubernetes resource does:

### Pod
A Pod is the smallest unit in Kubernetes. Each of our 3 services (frontend, backend, database) runs in its own Pod. Think of a Pod as a single Docker container with extra features.

### Deployment
A Deployment tells Kubernetes: *"I want X replicas of this Pod running at all times."* If a Pod crashes, the Deployment automatically restarts it.

### Service
A Service gives a **stable network address** to a set of Pods. Without Services, Pods can't find each other because Pod IPs change on restart.

There are two types we use:

| Type | Who can access it? | Used for |
|------|-------------------|----------|
| **ClusterIP** | Only other Pods inside the cluster | Database, Backend |
| **NodePort** | Anyone (exposed on a port on the node) | Frontend (user-facing) |

### PersistentVolumeClaim (PVC)
A PVC requests storage from the cluster. We use it so PostgreSQL data survives Pod restarts.

### Secret
A Secret stores sensitive data (passwords, credentials) in base64-encoded format instead of plain text.

### ConfigMap
A ConfigMap stores non-sensitive configuration data. We use it to store the SQL init script.

### Namespace
A Namespace is a virtual cluster inside your Kubernetes cluster. It keeps our resources organized and isolated.

---

## Project File Structure

```
k8s/
├── namespace.yaml              # Creates the namespace
├── database-secret.yaml        # Database credentials
├── database-configmap.yaml     # SQL init script
├── database-pvc.yaml           # Persistent storage for PostgreSQL
├── database-deployment.yaml    # Database Pod definition
├── database-service.yaml       # Database network (ClusterIP)
├── backend-deployment.yaml     # Backend Pod definition
├── backend-service.yaml        # Backend network (ClusterIP)
├── frontend-deployment.yaml    # Frontend Pod definition
└── frontend-service.yaml       # Frontend network (NodePort)
```

---

## Step 1 — Build Docker Images

First, build all 3 Docker images on your machine:

```bash
cd d:\student-management-system
docker-compose build
```

This creates:

- `student-management-system-frontend`
- `student-management-system-backend`
- `student-management-system-database`

Verify the images exist:

```bash
docker images | findstr student-management
```

---

## Step 2 — Load Images into Minikube

Minikube runs its own Docker daemon, so it can't see your local images by default. You need to load them in.

### Option A: Load images directly (recommended)

```bash
minikube image load student-management-system-frontend
minikube image load student-management-system-backend
```

> **Note:** We don't load the database image because we use the public `postgres:16-alpine` image directly. Minikube can pull it from Docker Hub.

### Option B: Use Minikube's Docker daemon

```bash
# Point your shell to Minikube's Docker daemon
eval $(minikube docker-env)

# Now build images inside Minikube
docker-compose build

# Reset back to your local Docker
eval $(minikube docker-env -u)
```

> On Windows PowerShell, use:
> ```powershell
> & minikube docker-env --shell powershell | Invoke-Expression
> docker-compose build
> & minikube docker-env --shell powershell -u | Invoke-Expression
> ```

---

## Step 3 — Create the Namespace

```bash
kubectl apply -f k8s/namespace.yaml
```

Verify:

```bash
kubectl get namespaces
```

You should see `student-management` in the list.

---

## Step 4 — Deploy the Database

Deploy in this order — the database must be running before the backend starts.

```bash
# 1. Create the Secret (credentials)
kubectl apply -f k8s/database-secret.yaml

# 2. Create the ConfigMap (init SQL)
kubectl apply -f k8s/database-configmap.yaml

# 3. Create the PersistentVolumeClaim (storage)
kubectl apply -f k8s/database-pvc.yaml

# 4. Create the Deployment (start the Pod)
kubectl apply -f k8s/database-deployment.yaml

# 5. Create the Service (enable networking)
kubectl apply -f k8s/database-service.yaml
```

Wait for the database Pod to be ready:

```bash
kubectl get pods -n student-management -l app=database -w
```

Wait until STATUS shows `Running` and READY shows `1/1`, then press `Ctrl+C`.

---

## Step 5 — Deploy the Backend

```bash
# 1. Create the Deployment
kubectl apply -f k8s/backend-deployment.yaml

# 2. Create the Service
kubectl apply -f k8s/backend-service.yaml
```

Wait for the backend Pod to be ready:

```bash
kubectl get pods -n student-management -l app=backend -w
```

Wait until STATUS shows `Running` and READY shows `1/1`.

> **How does the backend find the database?**  
> The `DATABASE_URL` environment variable is set to:  
> `postgresql://postgres:postgres123@database:5432/studentdb`  
>  
> The hostname `database` is resolved by Kubernetes DNS to the ClusterIP of the `database` Service. This is automatic — Kubernetes creates a DNS entry for every Service.

---

## Step 6 — Deploy the Frontend

```bash
# 1. Create the Deployment
kubectl apply -f k8s/frontend-deployment.yaml

# 2. Create the Service (NodePort — exposes to outside)
kubectl apply -f k8s/frontend-service.yaml
```

Wait for the frontend Pod to be ready:

```bash
kubectl get pods -n student-management -l app=frontend -w
```

> **How does the frontend reach the backend?**  
> The nginx config inside the frontend container has:
> ```
> location /api/ {
>     proxy_pass http://backend:8000/;
> }
> ```
> The hostname `backend` resolves to the backend Service's ClusterIP via Kubernetes DNS. Nginx forwards all `/api/` requests to the backend Pod.

---

## Step 7 — Access the Application

### Check all pods are running:

```bash
kubectl get all -n student-management
```

You should see 3 Pods, 3 Services, and 3 Deployments — all healthy.

### Get the URL:

```bash
minikube service frontend -n student-management --url
```

This prints a URL like `http://192.168.49.2:30000`. Open it in your browser.

### Alternative — Port forward:

If NodePort doesn't work in your environment:

```bash
kubectl port-forward service/frontend 3000:80 -n student-management
```

Then open `http://localhost:3000`.

---

## How Networking Works

Here is how the 3 pods communicate with each other:

### The Request Flow

```
Browser                Frontend Pod              Backend Pod            Database Pod
   │                       │                         │                       │
   │  GET localhost:30000   │                         │                       │
   │──────────────────────▶│                         │                       │
   │                       │                         │                       │
   │   (Nginx serves       │                         │                       │
   │    React HTML/JS)     │                         │                       │
   │◀──────────────────────│                         │                       │
   │                       │                         │                       │
   │  GET /api/students    │                         │                       │
   │──────────────────────▶│                         │                       │
   │                       │  proxy to               │                       │
   │                       │  http://backend:8000/   │                       │
   │                       │  GET /students           │                       │
   │                       │────────────────────────▶│                       │
   │                       │                         │  SQL: SELECT *        │
   │                       │                         │  FROM students        │
   │                       │                         │──────────────────────▶│
   │                       │                         │                       │
   │                       │                         │  ◀── rows ──────────│
   │                       │  ◀── JSON ────────────│                       │
   │  ◀── JSON ──────────│                         │                       │
```

### Kubernetes DNS Resolution

Every Service in Kubernetes gets a DNS name. Within the same namespace, pods can reach each other using just the service name:

| From | To | DNS Name | Resolves To |
|------|----|----------|------------|
| Frontend Pod | Backend Pod | `backend` | Backend Service ClusterIP |
| Backend Pod | Database Pod | `database` | Database Service ClusterIP |

The full DNS name is: `<service-name>.<namespace>.svc.cluster.local`

For example: `backend.student-management.svc.cluster.local`

But since all our pods are in the same namespace, the short name (`backend`, `database`) works.

### Service Types Explained

```
                 Internet / Browser
                        │
                        ▼
              ┌─────────────────┐
              │    NodePort     │  ◀── Exposes on port 30000
              │   (frontend)    │      Accessible from outside
              └────────┬────────┘
                       │
         ──────────────┼──────────── Cluster Boundary ───
                       │
              ┌────────▼────────┐
              │   ClusterIP     │  ◀── Only reachable inside cluster
              │   (backend)     │
              └────────┬────────┘
                       │
              ┌────────▼────────┐
              │   ClusterIP     │  ◀── Only reachable inside cluster
              │   (database)    │
              └─────────────────┘
```

- **NodePort** (Frontend): Opens a port on every node in the cluster. Users access the app through this port.
- **ClusterIP** (Backend, Database): Only accessible from within the cluster. No external access. This is secure — the database is never exposed to the internet.

---

## Useful Commands

### View all resources

```bash
kubectl get all -n student-management
```

### Check pod logs

```bash
# Database logs
kubectl logs -n student-management -l app=database

# Backend logs
kubectl logs -n student-management -l app=backend

# Frontend (nginx) logs
kubectl logs -n student-management -l app=frontend
```

### Enter a pod (for debugging)

```bash
# Open a shell inside the backend pod
kubectl exec -it -n student-management deployment/backend -- /bin/bash

# Test database connection from inside the backend pod
python -c "from database import engine; print(engine.connect())"
```

### Restart a deployment

```bash
kubectl rollout restart deployment/backend -n student-management
```

### Scale a deployment

```bash
# Run 3 replicas of the backend
kubectl scale deployment backend --replicas=3 -n student-management
```

---

## Troubleshooting

### Pod stuck in `ImagePullBackOff`

The pod can't find the Docker image. Make sure you loaded images into Minikube:

```bash
minikube image load student-management-system-frontend
minikube image load student-management-system-backend
```

Also verify `imagePullPolicy: Never` is set in the deployment YAML.

### Pod stuck in `CrashLoopBackOff`

Check the logs:

```bash
kubectl logs -n student-management <pod-name>
```

Common causes:
- Backend can't connect to database → database pod isn't ready yet
- Wrong environment variables

### Backend can't reach database

Verify the database service exists:

```bash
kubectl get svc -n student-management
```

Test DNS resolution from inside a pod:

```bash
kubectl exec -it -n student-management deployment/backend -- \
  python -c "import socket; print(socket.gethostbyname('database'))"
```

This should print an IP address (the ClusterIP of the database service).

### Frontend loads but API calls fail

Check if the backend service is reachable from the frontend pod:

```bash
kubectl exec -it -n student-management deployment/frontend -- \
  wget -qO- http://backend:8000/students
```

This should return `[]` or a list of students.

---

## Cleanup

### Delete all resources

```bash
kubectl delete namespace student-management
```

This removes everything — Pods, Services, Deployments, PVC, Secrets, ConfigMap.

### Stop Minikube

```bash
minikube stop
```

### Delete the Minikube cluster

```bash
minikube delete
```

---

## Quick Deploy (All at once)

If you want to deploy everything with a single command:

```bash
kubectl apply -f k8s/
```

This applies all YAML files in the `k8s/` directory at once.

> **Note:** Kubernetes handles the dependency order internally — the backend's readiness probe will keep failing until the database is up, and Kubernetes will keep restarting it automatically until it succeeds.

---

## Summary

| What | Resource | YAML File |
|------|----------|-----------|
| Isolate resources | Namespace | `namespace.yaml` |
| Store DB credentials | Secret | `database-secret.yaml` |
| Store SQL init script | ConfigMap | `database-configmap.yaml` |
| Persist DB data | PVC | `database-pvc.yaml` |
| Run PostgreSQL | Deployment | `database-deployment.yaml` |
| Network for DB | Service (ClusterIP) | `database-service.yaml` |
| Run FastAPI | Deployment | `backend-deployment.yaml` |
| Network for API | Service (ClusterIP) | `backend-service.yaml` |
| Run Nginx+React | Deployment | `frontend-deployment.yaml` |
| Expose to users | Service (NodePort) | `frontend-service.yaml` |
