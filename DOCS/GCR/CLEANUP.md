# GCP Resource Cleanup Guide

This guide removes all GCP resources created for the GitHub Actions + Artifact Registry setup.

## Resources to Delete

1. **Service Account**: `github-actions-sa`
2. **Artifact Registry Repository**: `containers`
3. **Local files**: `key.json`, `gcp-key.json`

---

## Step 1: Delete Service Account

```bash
export PROJECT_ID="YOUR-GCP-PROJECT-ID"
export SERVICE_ACCOUNT_EMAIL="github-actions-sa@${PROJECT_ID}.iam.gserviceaccount.com"

# Delete the service account (includes all keys)
gcloud iam service-accounts delete $SERVICE_ACCOUNT_EMAIL \
  --project=$PROJECT_ID \
  --quiet

echo "✅ Service account deleted"
```

---

## Step 2: Delete Artifact Registry Repository

```bash
export PROJECT_ID="YOUR-GCP-PROJECT-ID"

# Delete the Artifact Registry repository
gcloud artifacts repositories delete containers \
  --location=asia-south1 \
  --project=$PROJECT_ID \
  --quiet

echo "✅ Artifact Registry repository deleted"
```

---

## Step 3: Delete Container Registry Images (if using gcr.io)

```bash
export PROJECT_ID="YOUR-GCP-PROJECT-ID"

# List images
gcloud container images list --project=$PROJECT_ID

# Delete all images in gcr.io (if any)
gcloud container images delete "gcr.io/${PROJECT_ID}/backend" \
  --project=$PROJECT_ID \
  --quiet || true

gcloud container images delete "gcr.io/${PROJECT_ID}/database" \
  --project=$PROJECT_ID \
  --quiet || true

gcloud container images delete "gcr.io/${PROJECT_ID}/frontend" \
  --project=$PROJECT_ID \
  --quiet || true

echo "✅ Container Registry images deleted"
```

---

## Step 4: Remove Local Key Files

```bash
cd /home/tharindu/projects/k8s-research-k8s-poc

# Remove key files
rm -f key.json gcp-key.json

# Remove from git if already committed (optional)
git rm --cached key.json 2>/dev/null || true
git rm --cached gcp-key.json 2>/dev/null || true

echo "✅ Local key files deleted"
```

---

## Step 5: Remove GitHub Secrets (Manual)

1. Go to GitHub Repository → **Settings** → **Secrets and variables** → **Actions**
2. Delete these secrets:
   - `GCP_PROJECT_ID`
   - `GCP_SA_KEY`

---

## Step 6: Disable GCP APIs (Optional)

If you no longer need these APIs:

```bash
export PROJECT_ID="YOUR-GCP-PROJECT-ID"

gcloud services disable \
  artifactregistry.googleapis.com \
  containerregistry.googleapis.com \
  --project=$PROJECT_ID \
  --quiet

echo "✅ APIs disabled"
```

---

## Full Cleanup Script

Run all steps at once:

```bash
#!/bin/bash

export PROJECT_ID="YOUR-GCP-PROJECT-ID"
export SERVICE_ACCOUNT_EMAIL="github-actions-sa@${PROJECT_ID}.iam.gserviceaccount.com"

echo "🗑️  Starting GCP resource cleanup..."
echo ""

# Step 1: Delete Service Account
echo "Step 1: Deleting service account..."
gcloud iam service-accounts delete $SERVICE_ACCOUNT_EMAIL \
  --project=$PROJECT_ID \
  --quiet
echo "✅ Service account deleted"
echo ""

# Step 2: Delete Artifact Registry
echo "Step 2: Deleting Artifact Registry repository..."
gcloud artifacts repositories delete containers \
  --location=asia-south1 \
  --project=$PROJECT_ID \
  --quiet
echo "✅ Artifact Registry repository deleted"
echo ""

# Step 3: Clean up local files
echo "Step 3: Cleaning up local key files..."
cd /home/tharindu/projects/k8s-research-k8s-poc
rm -f key.json gcp-key.json
git rm --cached key.json 2>/dev/null || true
git rm --cached gcp-key.json 2>/dev/null || true
echo "✅ Local key files deleted"
echo ""

# Step 4: Disable APIs (optional)
echo "Step 4: Disabling GCP APIs..."
gcloud services disable \
  artifactregistry.googleapis.com \
  containerregistry.googleapis.com \
  --project=$PROJECT_ID \
  --quiet
echo "✅ APIs disabled"
echo ""

echo "🎉 Cleanup complete!"
echo ""
echo "⏭️  Next steps:"
echo "1. Go to GitHub Repository"
echo "2. Settings → Secrets and variables → Actions"
echo "3. Delete these secrets:"
echo "   - GCP_PROJECT_ID"
echo "   - GCP_SA_KEY"
```

---

## Verify Cleanup

```bash
export PROJECT_ID="YOUR-GCP-PROJECT-ID"

# Verify service account is deleted
echo "Checking service accounts..."
gcloud iam service-accounts list --project=$PROJECT_ID

# Verify Artifact Registry is deleted
echo "Checking Artifact Registry repositories..."
gcloud artifacts repositories list --project=$PROJECT_ID

# Verify APIs are disabled (optional)
echo "Checking enabled APIs..."
gcloud services list --enabled --project=$PROJECT_ID | grep -E "artifact|container"
```

---

## Notes

- ⚠️ **This is destructive** - All images and configurations will be permanently deleted
- Service account deletion includes all associated keys
- Local key files are sensitive - ensure they're deleted
- GitHub secrets must be deleted manually
- This does NOT delete the GCP project itself

## Safety

If you want to keep the service account but just delete the images:
- Skip Step 1 (don't delete service account)
- Keep the GitHub secrets
- Just delete the Artifact Registry repository (Step 2)

This allows you to later recreate the repository and continue using the same service account.
