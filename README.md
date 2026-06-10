# Student Management System for K8s

A full-stack Student Management System built with:

* Frontend: React + Vite + Tailwind CSS
* Backend: FastAPI + SQLAlchemy
* Database: PostgreSQL

## Features

* Add Students
* View Students
* Update Students
* Delete Students
* Search Students
* Dashboard Statistics
* Dark Mode

---

## Project Structure

```text
student_management/
│
├── frontend/
│   ├── src/
│   ├── package.json
│   └── ...
│
├── backend/
│   ├── main.py
│   ├── database.py
│   ├── models.py
│   ├── schemas.py
│   ├── crud.py
│   ├── venv/
│   └── ...
│
└── README.md
```

---

## Prerequisites

Install the following:

* Python 3.10+
* Node.js 18+
* PostgreSQL

---

## Database Setup

Create a PostgreSQL database:

```sql
CREATE DATABASE studentdb;
```

Create the students table:

```sql
CREATE TABLE students (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100),
    course VARCHAR(100)
);
```

---

## Backend Setup

Navigate to backend:

```bash
cd backend
```

Activate virtual environment:

```powershell
.\venv\Scripts\activate
```

Run FastAPI server:

```powershell
uvicorn main:app --reload
```

Backend runs at:

```text
http://127.0.0.1:8000
```

API Documentation:

```text
http://127.0.0.1:8000/docs
```

---

## Frontend Setup

Open a new terminal and navigate to frontend:

```bash
cd frontend
```

Install dependencies:

```bash
npm install
```

Start development server:

```bash
npm run dev
```

Frontend runs at:

```text
http://localhost:5173
```

---

## API Endpoints

| Method | Endpoint       | Description       |
| ------ | -------------- | ----------------- |
| GET    | /students      | Get all students  |
| POST   | /students      | Create student    |
| GET    | /students/{id} | Get student by ID |
| PUT    | /students/{id} | Update student    |
| DELETE | /students/{id} | Delete student    |

---

## Running the Application

### Terminal 1 (Backend)

```powershell
cd backend
.\venv\Scripts\activate
uvicorn main:app --reload
```

### Terminal 2 (Frontend)

```bash
cd frontend
npm run dev
```

Open:

```text
http://localhost:5173
```

---

## Technologies Used

* React
* Vite
* Tailwind CSS
* FastAPI
* SQLAlchemy
* PostgreSQL
* Axios
* Docker
* Kubernetes
* GitHub Actions
* Google Cloud Platform

---

## Docker & Kubernetes Deployment

### Prerequisites for Deployment

* Docker
* Kubernetes cluster (GKE or Minikube)
* kubectl CLI
* GCP Project (for cloud deployment)

### Build and Run with Docker Compose

```bash
docker-compose up -d
```

This will start:
- PostgreSQL database
- FastAPI backend
- React frontend (Nginx)

Access at: `http://localhost` (frontend), `http://localhost:8000` (backend)

### Push to GCP Artifact Registry

This project includes automated GitHub Actions to build and push Docker images to Google Cloud Platform's Artifact Registry.

**For complete setup instructions, see [GCP_SETUP.md](GCP_SETUP.md)**

Quick summary:
1. Enable required GCP APIs
2. Create service account with proper IAM roles
3. Create and download service account key
4. Add GitHub secrets (`GCP_PROJECT_ID` and `GCP_SA_KEY`)
5. Workflow runs automatically on push to `main`/`master`/`develop`

After successful build, images are available at:
```
asia-south1-docker.pkg.dev/YOUR-PROJECT-ID/containers/backend:latest
asia-south1-docker.pkg.dev/YOUR-PROJECT-ID/containers/database:latest
asia-south1-docker.pkg.dev/YOUR-PROJECT-ID/containers/frontend:latest
```

### Deploy to Kubernetes

Update Kubernetes manifests to use Artifact Registry images:

```yaml
# In k8s/backend-deployment.yaml
spec:
  containers:
  - name: backend
    image: asia-south1-docker.pkg.dev/YOUR-PROJECT-ID/containers/backend:latest
```

Apply manifests:

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/
```

---

## GCP Setup & Troubleshooting

**For detailed setup, verification commands, and troubleshooting:**
👉 **See [GCP_SETUP.md](GCP_SETUP.md)** - Single source of truth for all GCP + GitHub Actions configuration


