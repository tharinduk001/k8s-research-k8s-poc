#!/bin/bash

# Fix GCP Permissions for GitHub Actions + Container Registry
# This script ensures your service account has all required permissions

set -e

# Configuration
PROJECT_ID="${1:-my-k8s-project-499007}"
SERVICE_ACCOUNT_NAME="github-actions-sa"
SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

echo "🔧 Fixing GCP permissions for Container Registry..."
echo "Project ID: $PROJECT_ID"
echo "Service Account: $SERVICE_ACCOUNT_EMAIL"
echo ""

# Check if service account exists
if ! gcloud iam service-accounts describe $SERVICE_ACCOUNT_EMAIL --project=$PROJECT_ID &>/dev/null; then
    echo "❌ Service account does not exist. Creating..."
    gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME \
      --display-name="GitHub Actions Service Account" \
      --project=$PROJECT_ID
    echo "✅ Service account created"
else
    echo "✅ Service account already exists"
fi

echo ""
echo "📋 Assigning IAM roles..."

# Remove existing bindings first (optional - uncomment if you want to clean slate)
# gcloud projects remove-iam-policy-binding $PROJECT_ID \
#   --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
#   --role="roles/storage.admin" 2>/dev/null || true

# Add required roles
roles=(
    "roles/storage.admin"        # Required for Container Registry (gcr.io)
    "roles/viewer"               # Required for basic GCP resource viewing
)

for role in "${roles[@]}"; do
    echo "  - Assigning $role..."
    gcloud projects add-iam-policy-binding $PROJECT_ID \
      --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
      --role="$role" \
      --condition=None \
      --quiet \
      2>&1 | grep -E "Updated|already exists" || true
done

echo "✅ IAM roles assigned"
echo ""

# Check existing key
echo "🔑 Checking for existing service account keys..."
KEY_COUNT=$(gcloud iam service-accounts keys list \
  --iam-account=$SERVICE_ACCOUNT_EMAIL \
  --project=$PROJECT_ID \
  --filter="keyType:USER_MANAGED" \
  --format="value(name)" | wc -l)

if [ $KEY_COUNT -gt 0 ]; then
    echo "⚠️  Found $KEY_COUNT existing key(s)"
    echo "   (You can delete old keys from the console if needed)"
else
    echo "ℹ️  No existing keys found"
fi

echo ""
echo "📝 Creating new JSON key..."
KEY_FILE="gcp-key.json"

# Delete old key file if exists
if [ -f "$KEY_FILE" ]; then
    rm "$KEY_FILE"
    echo "   Removed old $KEY_FILE"
fi

# Create new key
gcloud iam service-accounts keys create $KEY_FILE \
  --iam-account=$SERVICE_ACCOUNT_EMAIL \
  --project=$PROJECT_ID

echo "✅ Key created: $KEY_FILE"
echo ""

# Display instructions
echo "╔════════════════════════════════════════════════════════════╗"
echo "║            NEXT STEPS - Add GitHub Secrets                 ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "1. Go to your GitHub Repository"
echo "2. Navigate to: Settings → Secrets and variables → Actions"
echo "3. Create two secrets:"
echo ""
echo "   Secret 1:"
echo "   ├─ Name: GCP_PROJECT_ID"
echo "   └─ Value: $PROJECT_ID"
echo ""
echo "   Secret 2:"
echo "   ├─ Name: GCP_SA_KEY"
echo "   └─ Value: (contents of $KEY_FILE - copy entire JSON)"
echo ""
echo "To copy the key content, run:"
echo "   cat $KEY_FILE"
echo ""
echo "Then paste the entire output as the GCP_SA_KEY secret value."
echo ""
echo "✅ Setup complete! Your workflow should now work."
