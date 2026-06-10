#!/bin/bash

# Terraform Configuration Verification Script
# Verifies that Terraform-created GCP resources match GitHub workflow requirements

set -e

PROJECT_ID="${1:-my-k8s-project-499007}"
SERVICE_ACCOUNT="github-actions-sa@${PROJECT_ID}.iam.gserviceaccount.com"
REGION="asia-south1"
REPOSITORY="containers"

echo "╔══════════════════════════════════════════════════════════╗"
echo "║     Terraform GCP Resources Verification                 ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0

check_result() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ PASS${NC}: $1"
        ((PASSED++))
    else
        echo -e "${RED}❌ FAIL${NC}: $1"
        ((FAILED++))
    fi
}

# 1. Check Service Account Exists
echo "1️⃣  Checking Service Account..."
gcloud iam service-accounts describe $SERVICE_ACCOUNT \
    --project=$PROJECT_ID > /dev/null 2>&1
check_result "Service account exists: $SERVICE_ACCOUNT"

# 2. Check IAM Roles
echo ""
echo "2️⃣  Checking IAM Roles..."

# Check artifactregistry.writer
gcloud projects get-iam-policy $PROJECT_ID \
    --flatten="bindings[].members" \
    --format="value(bindings.members)" \
    --filter="bindings.role:roles/artifactregistry.writer AND bindings.members:$SERVICE_ACCOUNT" \
    > /dev/null 2>&1
check_result "Role assigned: roles/artifactregistry.writer"

# Check storage.admin
gcloud projects get-iam-policy $PROJECT_ID \
    --flatten="bindings[].members" \
    --format="value(bindings.members)" \
    --filter="bindings.role:roles/storage.admin AND bindings.members:$SERVICE_ACCOUNT" \
    > /dev/null 2>&1
check_result "Role assigned: roles/storage.admin"

# Check viewer
gcloud projects get-iam-policy $PROJECT_ID \
    --flatten="bindings[].members" \
    --format="value(bindings.members)" \
    --filter="bindings.role:roles/viewer AND bindings.members:$SERVICE_ACCOUNT" \
    > /dev/null 2>&1
check_result "Role assigned: roles/viewer"

# 3. Check Artifact Registry Repository
echo ""
echo "3️⃣  Checking Artifact Registry..."

gcloud artifacts repositories describe $REPOSITORY \
    --location=$REGION \
    --project=$PROJECT_ID > /dev/null 2>&1
check_result "Artifact Registry repository exists: $REPOSITORY"

# Check format is DOCKER
FORMAT=$(gcloud artifacts repositories describe $REPOSITORY \
    --location=$REGION \
    --project=$PROJECT_ID \
    --format="value(format)")

if [ "$FORMAT" = "DOCKER" ]; then
    echo -e "${GREEN}✅ PASS${NC}: Repository format is DOCKER"
    ((PASSED++))
else
    echo -e "${RED}❌ FAIL${NC}: Repository format is $FORMAT (expected DOCKER)"
    ((FAILED++))
fi

# 4. Check Service Account Keys
echo ""
echo "4️⃣  Checking Service Account Keys..."

KEY_COUNT=$(gcloud iam service-accounts keys list \
    --iam-account=$SERVICE_ACCOUNT \
    --project=$PROJECT_ID \
    --filter="keyType:USER_MANAGED" \
    --format="value(name)" | wc -l)

if [ $KEY_COUNT -gt 0 ]; then
    echo -e "${GREEN}✅ PASS${NC}: Service account has $KEY_COUNT key(s)"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠️  WARNING${NC}: No user-managed keys found"
fi

# 5. Check APIs Enabled
echo ""
echo "5️⃣  Checking Enabled APIs..."

# Check Artifact Registry API
gcloud services list --enabled --project=$PROJECT_ID \
    --filter="name:artifactregistry.googleapis.com" \
    --format="value(name)" > /dev/null 2>&1
check_result "API enabled: artifactregistry.googleapis.com"

# Check Container Registry API
gcloud services list --enabled --project=$PROJECT_ID \
    --filter="name:containerregistry.googleapis.com" \
    --format="value(name)" > /dev/null 2>&1
check_result "API enabled: containerregistry.googleapis.com"

# Check IAM API
gcloud services list --enabled --project=$PROJECT_ID \
    --filter="name:iam.googleapis.com" \
    --format="value(name)" > /dev/null 2>&1
check_result "API enabled: iam.googleapis.com"

# 6. Check Local Key File
echo ""
echo "6️⃣  Checking Local Key File..."

if [ -f "../key.json" ]; then
    echo -e "${GREEN}✅ PASS${NC}: Key file exists: ../key.json"
    ((PASSED++))
    
    # Check permissions
    PERMS=$(stat -c "%a" "../key.json" 2>/dev/null || stat -f "%OLp" "../key.json" 2>/dev/null | tail -c 3)
    if [ "$PERMS" = "600" ]; then
        echo -e "${GREEN}✅ PASS${NC}: Key file has correct permissions: $PERMS"
        ((PASSED++))
    else
        echo -e "${YELLOW}⚠️  WARNING${NC}: Key file permissions are $PERMS (expected 600)"
    fi
else
    echo -e "${RED}❌ FAIL${NC}: Key file not found: ../key.json"
    ((FAILED++))
fi

# 7. Check Terraform State
echo ""
echo "7️⃣  Checking Terraform State..."

if [ -f "terraform.tfstate" ]; then
    echo -e "${GREEN}✅ PASS${NC}: Terraform state file exists"
    ((PASSED++))
    
    # Check state has resources
    RESOURCE_COUNT=$(grep -c '"type"' terraform.tfstate || echo 0)
    if [ $RESOURCE_COUNT -ge 10 ]; then
        echo -e "${GREEN}✅ PASS${NC}: Terraform state has $RESOURCE_COUNT resources"
        ((PASSED++))
    else
        echo -e "${RED}❌ FAIL${NC}: Terraform state has $RESOURCE_COUNT resources (expected >= 10)"
        ((FAILED++))
    fi
else
    echo -e "${RED}❌ FAIL${NC}: Terraform state file not found"
    ((FAILED++))
fi

# Summary
echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║                    Verification Summary                  ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo -e "${GREEN}✅ Passed:${NC} $PASSED"
echo -e "${RED}❌ Failed:${NC} $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All verifications passed!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Add GitHub secrets:"
    echo "   - GCP_PROJECT_ID: $(terraform output -raw github_secret_gcp_project_id)"
    echo "   - GCP_SA_KEY: $(terraform output -raw github_secret_gcp_sa_key | head -c 50)..."
    echo ""
    echo "2. Update Kubernetes deployment files with:"
    echo "   - backend:   asia-south1-docker.pkg.dev/$PROJECT_ID/containers/backend:latest"
    echo "   - database:  asia-south1-docker.pkg.dev/$PROJECT_ID/containers/database:latest"
    echo "   - frontend:  asia-south1-docker.pkg.dev/$PROJECT_ID/containers/frontend:latest"
    echo ""
    exit 0
else
    echo -e "${RED}❌ Some verifications failed!${NC}"
    exit 1
fi
