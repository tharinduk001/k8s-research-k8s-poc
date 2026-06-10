# GCP Setup for GitHub Actions + Artifact Registry

This is the **single source of truth** for setting up GitHub Actions to build and push Docker images to Google Cloud Platform's Artifact Registry.

## Quick Summary

Your project is configured to:
- Build 3 Docker images: `backend`, `database`, `frontend`
- Push to **Artifact Registry** at `asia-south1-docker.pkg.dev`
- Trigger on push to `main`, `master`, or `develop` branches
- Use a GCP service account with proper IAM roles

---

## Prerequisites

1. GCP project with required APIs enabled
2. GitHub repository (public or private)
3. `gcloud` CLI installed locally
4. Service account with proper roles

---

## Step 1: Enable Required GCP APIs

```bash
gcloud services enable \
  artifactregistry.googleapis.com \
  containerregistry.googleapis.com \
  iam.googleapis.com \
  --project=YOUR-GCP-PROJECT-ID
```

---

## Step 2: Create Service Account and Grant Roles

Replace `YOUR-GCP-PROJECT-ID` with your actual GCP project ID (e.g., `my-k8s-project-499007`)

### Create the service account:

```bash
export PROJECT_ID="YOUR-GCP-PROJECT-ID"
export SERVICE_ACCOUNT_NAME="github-actions-sa"

gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME \
  --display-name="GitHub Actions Service Account" \
  --project=$PROJECT_ID
```

### Grant required IAM roles:

```bash
SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# For Artifact Registry (pushing images to asia-south1-docker.pkg.dev)
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
  --role="roles/artifactregistry.writer"

# For Cloud Storage (fallback for gcr.io if needed)
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
  --role="roles/storage.admin"

# For viewing GCP resources
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
  --role="roles/viewer"
```

### Verify roles were assigned:

```bash
gcloud projects get-iam-policy $PROJECT_ID \
  --flatten="bindings[].members" \
  --format="table(bindings.role)" \
  --filter="bindings.members:$SERVICE_ACCOUNT_EMAIL"
```

Expected output:
```
ROLE
roles/artifactregistry.writer
roles/storage.admin
roles/viewer
```

---

## Step 3: Create and Download Service Account Key

```bash
gcloud iam service-accounts keys create key.json \
  --iam-account=$SERVICE_ACCOUNT_EMAIL \
  --project=$PROJECT_ID
```

This creates `key.json` in your current directory.

**⚠️ Important**: Keep this file secure. Never commit it to version control.

---

## Step 4: Add GitHub Secrets

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**

### Add these two secrets:

#### Secret 1: `GCP_PROJECT_ID`
- **Name**: `GCP_PROJECT_ID`
- **Value**: Your GCP project ID (e.g., `my-k8s-project-499007`)

#### Secret 2: `GCP_SA_KEY`
- **Name**: `GCP_SA_KEY`
- **Value**: Full contents of `key.json`

To copy the key content:
```bash
cat key.json
```

Then:
1. Copy the entire output (from `{` to `}`)
2. Paste into the GitHub secret value field
3. Click **Add secret**

---

## Step 5: Verify Workflow Configuration

The workflow file is at: `.github/workflows/build-push-gcp.yml`

It's already configured to:
- Use Artifact Registry at `asia-south1-docker.pkg.dev`
- Build images for: `backend`, `database`, `frontend`
- Tag with commit SHA and `latest`
- Authenticate using `GCP_SA_KEY` secret

No changes needed to the workflow file.

---

## Step 6: Test the Workflow

### Option A: Manual Trigger (Instant)

1. Go to GitHub → **Actions** tab
2. Select **Build and Push to GCP Container Registry**
3. Click **Run workflow** → **Run workflow**

### Option B: Push to Trigger

```bash
git add .
git commit -m "Trigger GitHub Actions workflow"
git push origin main
```

The workflow triggers on push to `main`, `master`, or `develop` branches.

---

## Accessing Your Images

After successful build, images are available at:

```
asia-south1-docker.pkg.dev/YOUR-PROJECT-ID/containers/backend:latest
asia-south1-docker.pkg.dev/YOUR-PROJECT-ID/containers/database:latest
asia-south1-docker.pkg.dev/YOUR-PROJECT-ID/containers/frontend:latest
```

### List images in GCP:

```bash
gcloud artifacts repositories list --project=$PROJECT_ID

gcloud artifacts docker images list \
  asia-south1-docker.pkg.dev/$PROJECT_ID/containers \
  --project=$PROJECT_ID
```

### View specific image tags:

```bash
gcloud artifacts docker images list \
  asia-south1-docker.pkg.dev/$PROJECT_ID/containers/backend \
  --include-tags \
  --project=$PROJECT_ID
```

---

## Troubleshooting

### Workflow fails with "Permission denied" error

**Problem**: Service account doesn't have required roles

**Solution**: Re-run the role assignment commands from Step 2:
```bash
export PROJECT_ID="YOUR-GCP-PROJECT-ID"
SERVICE_ACCOUNT_EMAIL="github-actions-sa@${PROJECT_ID}.iam.gserviceaccount.com"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
  --role="roles/artifactregistry.writer"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
  --role="roles/storage.admin"
```

### "Authentication failed" error

**Problem**: `GCP_SA_KEY` secret is invalid or corrupted

**Solution**:
1. Regenerate the key:
   ```bash
   export PROJECT_ID="YOUR-GCP-PROJECT-ID"
   SERVICE_ACCOUNT_EMAIL="github-actions-sa@${PROJECT_ID}.iam.gserviceaccount.com"
   
   gcloud iam service-accounts keys create new-key.json \
     --iam-account=$SERVICE_ACCOUNT_EMAIL
   ```

2. Update the GitHub secret:
   - Go to **Settings** → **Secrets and variables** → **Actions**
   - Click **GCP_SA_KEY** → **Update secret**
   - Copy entire contents of `new-key.json`
   - Paste and update

3. Delete old keys (optional cleanup):
   ```bash
   gcloud iam service-accounts keys list \
     --iam-account=$SERVICE_ACCOUNT_EMAIL
   
   # Delete old keys by their key-id if needed
   gcloud iam service-accounts keys delete KEY_ID \
     --iam-account=$SERVICE_ACCOUNT_EMAIL
   ```

### Workflow doesn't trigger

**Problem**: Workflow not executing on push

**Checklist**:
- [ ] Workflow file exists at `.github/workflows/build-push-gcp.yml`
- [ ] Pushing to `main`, `master`, or `develop` branch
- [ ] GitHub Actions is enabled (Settings → Actions)
- [ ] Both `GCP_PROJECT_ID` and `GCP_SA_KEY` secrets are set

**Solution**: Manually trigger via **Actions** → **Run workflow**

### Images not appearing in Artifact Registry

1. Check workflow ran successfully (green checkmark in Actions)
2. Verify secrets are correctly set
3. Check artifact registry repository exists:
   ```bash
   gcloud artifacts repositories list --project=$PROJECT_ID
   ```
4. If repository doesn't exist, the workflow will create it automatically on first push

---

## Security Best Practices

1. **Never commit `key.json`** - Add to `.gitignore`:
   ```bash
   echo "key.json" >> .gitignore
   ```

2. **Rotate keys periodically** - Delete old keys and create new ones every 90 days

3. **Limit service account permissions** - Only grant roles that are needed

4. **Use branch protection** - Require reviews before merging to `main`

5. **Monitor key usage**:
   ```bash
   gcloud logging read \
     "protoPayload.methodName=google.iam.admin.v1.CreateServiceAccountKey" \
     --limit 10 \
     --format json \
     --project=$PROJECT_ID
   ```

---

## Using Images in Kubernetes

Update your Kubernetes deployment files:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  template:
    spec:
      containers:
      - name: backend
        image: asia-south1-docker.pkg.dev/YOUR-PROJECT-ID/containers/backend:latest
        imagePullPolicy: IfNotPresent
```

If using a private Artifact Registry, create an image pull secret:

```bash
kubectl create secret docker-registry artifact-registry-secret \
  --docker-server=asia-south1-docker.pkg.dev \
  --docker-username=_json_key \
  --docker-password="$(cat key.json)" \
  --docker-email=user@example.com
```

Then reference in deployment:
```yaml
imagePullSecrets:
- name: artifact-registry-secret
```

---

## Cleanup (Optional)

### Delete service account:

```bash
gcloud iam service-accounts delete $SERVICE_ACCOUNT_EMAIL \
  --project=$PROJECT_ID
```

### Delete Artifact Registry repository:

```bash
gcloud artifacts repositories delete containers \
  --location=asia-south1 \
  --project=$PROJECT_ID
```

---

## References

- [Artifact Registry Documentation](https://cloud.google.com/artifact-registry/docs)
- [GitHub Actions + GCP Auth](https://github.com/google-github-actions/auth)
- [gcloud IAM Reference](https://cloud.google.com/sdk/gcloud/reference/iam)
