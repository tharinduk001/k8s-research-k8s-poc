# GitHub Actions + GCP Container Registry Setup Guide

This guide will help you configure GitHub Actions to automatically build and push your Docker images to Google Cloud Platform (GCP) Container Registry.

## Overview

The workflow (`build-push-gcp.yml`) will:
- Trigger on pushes to `main`, `master`, or `develop` branches
- Build Docker images for: backend, database, and frontend
- Push images to GCP Container Registry (gcr.io)
- Tag images with commit SHA and `latest`
- Optional: Scan images with Trivy for vulnerabilities

## Prerequisites

1. A GCP project with Compute Engine and Container Registry enabled
2. A GitHub repository (public or private)
3. Admin access to both GCP and GitHub

---

## Step 1: Enable Required GCP APIs

Run these commands in GCP Cloud Shell or locally with `gcloud`:

```bash
gcloud services enable \
  containerregistry.googleapis.com \
  compute.googleapis.com \
  iam.googleapis.com
```

---

## Step 2: Create a GCP Service Account

### Option A: Using gcloud CLI (Recommended)

```bash
# Set your GCP project ID
export PROJECT_ID="your-gcp-project-id"
export SERVICE_ACCOUNT_NAME="github-actions-sa"

# Create the service account
gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME \
  --display-name="GitHub Actions Service Account" \
  --project=$PROJECT_ID

# Grant permissions to push to Container Registry
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/storage.admin"

# Create a JSON key
gcloud iam service-accounts keys create gcp-key.json \
  --iam-account=${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com \
  --project=$PROJECT_ID

echo "Service account key created: gcp-key.json"
```

### Option B: Using GCP Console

1. Go to **GCP Console** → **IAM & Admin** → **Service Accounts**
2. Click **Create Service Account**
3. Fill in:
   - Service Account ID: `github-actions-sa`
   - Display Name: `GitHub Actions Service Account`
4. Click **Create and Continue**
5. Assign this role:
   - `Storage Admin` (for Container Registry access)
6. Click **Continue** → **Done**
7. Click on the created service account
8. Go to **Keys** tab → **Add Key** → **Create new key**
9. Select **JSON** and click **Create**
10. Save the JSON file securely

---

## Step 3: Add GitHub Secrets

### In Your GitHub Repository:

1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Add the following secrets:

#### Secret 1: GCP_PROJECT_ID
- Name: `GCP_PROJECT_ID`
- Value: Your GCP Project ID (e.g., `my-k8s-project-499007`)

#### Secret 2: GCP_SA_KEY
- Name: `GCP_SA_KEY`
- Value: Contents of the `gcp-key.json` file created in Step 2
  - Copy the entire JSON content from the key file
  - Paste it as the secret value

---

## Step 4: Update Your GitHub Repository

Push these files to your repository:

```bash
git add .github/workflows/build-push-gcp.yml
git add GCP_SETUP.md
git commit -m "Add GitHub Actions workflow for GCP Container Registry"
git push origin main
```

---

## Step 5: Verify the Workflow

1. Go to your GitHub repository
2. Click **Actions** tab
3. You should see the `Build and Push to GCP Container Registry` workflow
4. Make a test push or commit to trigger it
5. Monitor the workflow run to ensure it completes successfully

---

## Workflow Triggers

The workflow runs automatically when:
- You push to `main`, `master`, or `develop` branches
- Changes are made to `backend/`, `database/`, or `frontend/` directories
- The workflow file itself is modified

You can also manually trigger it:
1. Go to **Actions** tab
2. Select the workflow
3. Click **Run workflow** → **Run workflow**

---

## Accessing Your Images

After a successful build, your images will be available at:

```
gcr.io/YOUR-PROJECT-ID/backend:COMMIT-SHA
gcr.io/YOUR-PROJECT-ID/backend:latest

gcr.io/YOUR-PROJECT-ID/database:COMMIT-SHA
gcr.io/YOUR-PROJECT-ID/database:latest

gcr.io/YOUR-PROJECT-ID/frontend:COMMIT-SHA
gcr.io/YOUR-PROJECT-ID/frontend:latest
```

### View images in GCP:

```bash
gcloud container images list --project=YOUR-PROJECT-ID
gcloud container images list-tags gcr.io/YOUR-PROJECT-ID/backend
```

---

## Troubleshooting

### Permission Denied Error: `artifactregistry.repositories.uploadArtifacts`
This error means the service account doesn't have required permissions. **Quick fix:**

```bash
# Run this from the project directory
chmod +x fix-gcp-permissions.sh
./fix-gcp-permissions.sh my-k8s-project-499007
```

Or manually add permissions:
```bash
export PROJECT_ID="my-k8s-project-499007"
export SERVICE_ACCOUNT_EMAIL="github-actions-sa@${PROJECT_ID}.iam.gserviceaccount.com"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
  --role="roles/storage.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
  --role="roles/viewer"
```

Then regenerate the key:
```bash
gcloud iam service-accounts keys create gcp-key.json \
  --iam-account=$SERVICE_ACCOUNT_EMAIL
```

And update the `GCP_SA_KEY` secret in GitHub with the new key content.

### Authentication Failed
- ✓ Verify `GCP_SA_KEY` secret is set correctly with **entire JSON content**
- ✓ Ensure line breaks and formatting are preserved when copying
- ✓ Check service account has both `Storage Admin` AND `Viewer` roles
- ✓ Regenerate the key if it's old or corrupted

### Build Failed
- ✓ Check Dockerfile paths are correct
- ✓ Verify Docker build context is valid
- ✓ Look at workflow logs for detailed errors

### Images Not Pushed
- ✓ Check Container Registry API is enabled
- ✓ Verify service account has `Storage Admin` role
- ✓ Verify service account has `Viewer` role
- ✓ Check GCP project quota limits
- ✓ Ensure the GCP_PROJECT_ID secret matches your actual project

### View Detailed Logs
1. Go to **Actions** → Select failed workflow run
2. Click on the job to see detailed logs
3. Check the **Authenticate to Google Cloud** step output
4. Check the **Configure Docker for GCP** step output
5. Check the **Push to GCP Container Registry** step output

---

## Security Best Practices

1. **Rotate Keys Regularly**: Regenerate the GCP service account key periodically
2. **Limit Permissions**: Only grant necessary IAM roles to the service account
3. **Branch Protection**: Use branch protection rules to require passing checks
4. **Image Scanning**: The workflow includes optional Trivy scanning for vulnerabilities
5. **Secret Management**: Never commit `gcp-key.json` to version control

---

## Next Steps

### Update Your Kubernetes Manifests

Update your Kubernetes deployment files to use the new GCP Container Registry images:

```yaml
# In k8s/backend-deployment.yaml, frontend-deployment.yaml, database-deployment.yaml
spec:
  containers:
  - name: backend
    image: gcr.io/YOUR-PROJECT-ID/backend:latest  # Updated image reference
    imagePullPolicy: IfNotPresent
```

### Set Up Image Pull Secrets (If Using Private Registry)

If your repository is private, create a Kubernetes secret:

```bash
kubectl create secret docker-registry gcr-secret \
  --docker-server=gcr.io \
  --docker-username=_json_key \
  --docker-password="$(cat gcp-key.json)"
```

Then reference in deployments:
```yaml
imagePullSecrets:
- name: gcr-secret
```

---

## Additional Resources

- [Google Cloud Container Registry Documentation](https://cloud.google.com/container-registry/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [google-github-actions/auth](https://github.com/google-github-actions/auth)
- [Trivy Vulnerability Scanner](https://github.com/aquasecurity/trivy-action)
