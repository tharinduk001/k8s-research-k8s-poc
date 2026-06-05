# Docker Setup — Student Management System

Run the entire application (frontend + backend + database) with a single command.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) installed and running
- [Docker Compose](https://docs.docker.com/compose/install/) (included with Docker Desktop)

## Architecture

```
┌──────────────────────────────────────────────────────┐
│                  Docker Network                      │
│                                                      │
│  ┌──────────┐    ┌──────────┐    ┌──────────────┐   │
│  │ Frontend │───▶│ Backend  │───▶│   Database   │   │
│  │  (Nginx) │    │ (FastAPI)│    │ (PostgreSQL) │   │
│  │  :3000   │    │  :8000   │    │    :5432     │   │
│  └──────────┘    └──────────┘    └──────────────┘   │
│                                                      │
└──────────────────────────────────────────────────────┘
```

| Service    | Technology        | Internal Port | Host Port |
|------------|-------------------|---------------|-----------|
| `frontend` | Nginx + React     | 80            | 3000      |
| `backend`  | FastAPI + Uvicorn | 8000          | 8000      |
| `database` | PostgreSQL 16     | 5432          | 5432      |

## Quick Start

### 1. Build and Run

```bash
docker-compose up --build -d
```

### 2. Open the App

```
http://localhost:3000
```

### 3. Access the API Docs

```
http://localhost:8000/docs
```

### 4. Check Container Status

```bash
docker-compose ps
```

All 3 services should show as `Up (healthy)`.

## Stop the Application

```bash
docker-compose down
```

To also delete the database data:

```bash
docker-compose down -v
```

## Environment Variables

### Backend

| Variable       | Default                                                    | Description            |
|----------------|------------------------------------------------------------|------------------------|
| `DATABASE_URL` | `postgresql://postgres:postgres123@database:5432/studentdb`| PostgreSQL connection  |

### Database

| Variable            | Default       | Description       |
|---------------------|---------------|-------------------|
| `POSTGRES_DB`       | `studentdb`   | Database name     |
| `POSTGRES_USER`     | `postgres`    | Database user     |
| `POSTGRES_PASSWORD` | `postgres123` | Database password |

## Local Development (without Docker)

The project still works without Docker:

1. Run PostgreSQL locally
2. Start backend: `cd backend && uvicorn main:app --reload`
3. Start frontend: `cd frontend && npm run dev`

The Vite dev server has a proxy configured to forward `/api` calls to `localhost:8000`.

## Kubernetes Preparation

This setup maps cleanly to Kubernetes:

| Docker Service | Kubernetes Resource       |
|----------------|--------------------------|
| `frontend`     | Deployment + Service (NodePort/LoadBalancer) |
| `backend`      | Deployment + Service (ClusterIP) |
| `database`     | StatefulSet + Service (ClusterIP) + PersistentVolumeClaim |

Each service runs in its own pod. The nginx config's `proxy_pass http://backend:8000/` maps directly to a Kubernetes Service named `backend`.
