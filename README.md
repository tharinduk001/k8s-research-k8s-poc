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

### Push to GCP Container Registry

This project includes automated GitHub Actions to build and push Docker images to GCP Container Registry.

#### Step 1: Enable GCP APIs

```bash
gcloud services enable \
  containerregistry.googleapis.com \
  compute.googleapis.com \
  iam.googleapis.com
```

#### Step 2: Create Service Account & Get Permissions

**Option A: Automated (Recommended)**

```bash
chmod +x fix-gcp-permissions.sh
./fix-gcp-permissions.sh my-k8s-project-499007
```

Replace `my-k8s-project-499007` with your actual GCP Project ID.

**Option B: Manual**

```bash
export PROJECT_ID="my-k8s-project-499007"
export SERVICE_ACCOUNT_NAME="github-actions-sa"

gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME \
  --display-name="GitHub Actions Service Account" \
  --project=$PROJECT_ID

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/storage.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/viewer"

gcloud iam service-accounts keys create gcp-key.json \
  --iam-account=${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com
```

#### Step 3: Add GitHub Secrets

1. Go to your GitHub Repository
2. **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**

Add two secrets:

| Name | Value |
|------|-------|
| `GCP_PROJECT_ID` | Your GCP Project ID (e.g., `my-k8s-project-499007`) |
| `GCP_SA_KEY` | Contents of `gcp-key.json` (entire JSON file) |

To get the JSON content:
```bash
cat gcp-key.json
```

#### Step 4: Push Workflow to GitHub

```bash
git add .github/workflows/build-push-gcp.yml
git commit -m "Add GitHub Actions workflow for GCP Container Registry"
git push origin main
```

#### Step 5: Verify Workflow

1. Go to GitHub Repository → **Actions** tab
2. Select **Build and Push to GCP Container Registry**
3. Workflow triggers on push to `main`, `master`, or `develop` branches
4. Monitor execution and verify images are pushed to GCP

### Access Built Images

After successful build, images are available at:

```
gcr.io/YOUR-PROJECT-ID/backend:latest
gcr.io/YOUR-PROJECT-ID/database:latest
gcr.io/YOUR-PROJECT-ID/frontend:latest
```

View images in GCP:

```bash
gcloud container images list --project=YOUR-PROJECT-ID
gcloud container images list-tags gcr.io/YOUR-PROJECT-ID/backend
```

### Deploy to Kubernetes

Update Kubernetes manifests to use GCP images:

```yaml
# In k8s/backend-deployment.yaml
spec:
  containers:
  - name: backend
    image: gcr.io/YOUR-PROJECT-ID/backend:latest
```

Apply manifests:

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/
```

---

## Troubleshooting GitHub Actions

### Error: `Permission 'artifactregistry.repositories.uploadArtifacts' denied`

Run the fix script:
```bash
./fix-gcp-permissions.sh my-k8s-project-499007
```

Then regenerate and update the `GCP_SA_KEY` secret in GitHub.

### Error: `Authentication Failed`

- Verify `GCP_SA_KEY` secret contains **entire JSON content** (no truncation)
- Check both `GCP_PROJECT_ID` and `GCP_SA_KEY` secrets are set
- Regenerate the key file and update the secret

### Workflow Not Triggering

- Verify workflow file is in `.github/workflows/build-push-gcp.yml`
- Check branch is `main`, `master`, or `develop`
- Manually trigger: **Actions** → Select workflow → **Run workflow**

### Build Logs

1. Go to **Actions** → Select failed run
2. Click on job to see detailed logs
3. Check:
   - **Authenticate to Google Cloud** step
   - **Configure Docker for GCP** step
   - **Push to GCP Container Registry** step

---

## Project Files

* `docker-compose.yml` - Local development with Docker
* `.github/workflows/build-push-gcp.yml` - GitHub Actions workflow
* `fix-gcp-permissions.sh` - Utility script for GCP setup
* `k8s/` - Kubernetes manifests for deployment
* `KUBERNETES.md` - Kubernetes setup guide
* `DOCKER.md` - Docker information


