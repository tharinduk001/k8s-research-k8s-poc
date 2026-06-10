# Terraform Configuration for GCP + GitHub Actions Setup

This directory contains Terraform code to automate the entire GCP resource setup for GitHub Actions CI/CD pipeline.

## Overview

The Terraform configuration creates and manages:

1. ✅ **GCP Service Account** - `github-actions-sa`
2. ✅ **IAM Roles** - Artifact Registry Writer, Storage Admin, Viewer
3. ✅ **Artifact Registry Repository** - `containers` at `asia-south1-docker.pkg.dev`
4. ✅ **Service Account Key** - JSON format for GitHub secrets
5. ✅ **GCP APIs** - Enabled automatically

## Alignment with GitHub Workflow

This Terraform configuration is perfectly aligned with the GitHub Actions workflow (`.github/workflows/build-push-gcp.yml`):

| Component | Terraform | Workflow |
|-----------|-----------|----------|
| Service Account | `google_service_account.github_actions` | Uses `GCP_SA_KEY` secret |
| Region | `asia-south1` | `asia-south1-docker.pkg.dev` |
| Registry | Artifact Registry | Pushes to `asia-south1-docker.pkg.dev` |
| Repository | `containers` | Reference: `/containers/` |
| IAM Roles | All 3 roles | Required for authentication |
| Images | backend, database, frontend | Builds all 3 services |

## Prerequisites

- Terraform >= 1.0
- Google Cloud SDK (`gcloud`) installed and authenticated
- Active GCP project

## Installation

### 1. Install Terraform

```bash
# macOS
brew install terraform

# Ubuntu/Debian
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

### 2. Authenticate with GCP

```bash
gcloud auth application-default login
```

### 3. Configure Variables

```bash
cd terraform

# Copy the example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit with your project ID
nano terraform.tfvars
# or
vi terraform.tfvars
```

Update `gcp_project_id` with your actual GCP project ID:

```hcl
gcp_project_id = "my-k8s-project-499007"  # Change this
gcp_region     = "asia-south1"             # Optional
```

## Usage

### Initialize Terraform

```bash
cd terraform
terraform init
```

This creates:
- `.terraform/` directory
- `terraform.lock.hcl` (dependency lock file)
- `.terraform/modules/` (if using modules)

### Plan (Preview Changes)

```bash
terraform plan
```

This shows what resources will be created. Example output:

```
Terraform will perform the following actions:

  # google_project_service.artifactregistry will be created
  + resource "google_project_service" "artifactregistry" {
      + id       = (known after apply)
      + project  = "my-k8s-project-499007"
      + service  = "artifactregistry.googleapis.com"
      ...
    }

  # google_service_account.github_actions will be created
  + resource "google_service_account" "github_actions" {
      + account_id      = "github-actions-sa"
      + email           = "github-actions-sa@my-k8s-project-499007.iam.gserviceaccount.com"
      ...
    }

Plan: 10 to add, 0 to change, 0 to destroy.
```

### Apply (Create Resources)

```bash
terraform apply
```

This will:
1. Enable required GCP APIs
2. Create the service account
3. Assign IAM roles
4. Create Artifact Registry repository
5. Generate service account key
6. Save key to `../key.json`

### Verify Created Resources

```bash
# Check Terraform state
terraform state list

# Show service account details
terraform output service_account_email

# Show IAM roles
terraform output iam_roles_assigned

# Show Docker image paths
terraform output docker_image_paths
```

### Get GitHub Secrets

```bash
# Get GitHub instructions
terraform output github_secrets_instructions

# Get just the secret values (SENSITIVE)
terraform output github_secret_gcp_project_id
terraform output -raw github_secret_gcp_sa_key
```

## Matching with Existing GitHub Workflow

### Service Account Email

```hcl
# Terraform output
output "service_account_email" {
  value = google_service_account.github_actions.email
  # Example: github-actions-sa@my-k8s-project-499007.iam.gserviceaccount.com
}

# GitHub Workflow uses this via GCP_SA_KEY secret
# .github/workflows/build-push-gcp.yml:
# with:
#   credentials_json: ${{ secrets.GCP_SA_KEY }}
```

### Artifact Registry Configuration

```hcl
# Terraform
resource "google_artifact_registry_repository" "docker" {
  location    = var.gcp_region           # asia-south1
  repository_id = var.artifact_registry_repository  # containers
  format      = var.artifact_registry_format        # DOCKER
}

# Workflow uses this via environment variable
# ENV: REGISTRY_HOSTNAME: asia-south1-docker.pkg.dev
# Images pushed to:
# asia-south1-docker.pkg.dev/PROJECT-ID/containers/SERVICE:TAG
```

### IAM Roles Alignment

```hcl
# Terraform assigns
- roles/artifactregistry.writer  # Can push to Artifact Registry
- roles/storage.admin             # Can push to Cloud Storage / gcr.io
- roles/viewer                    # Can view GCP resources

# Workflow requires these permissions to:
# 1. Authenticate via service account key
# 2. Configure Docker authentication
# 3. Push Docker images to Artifact Registry
```

## Docker Image Paths

After applying Terraform, images will be pushed to:

```
asia-south1-docker.pkg.dev/my-k8s-project-499007/containers/backend:latest
asia-south1-docker.pkg.dev/my-k8s-project-499007/containers/database:latest
asia-south1-docker.pkg.dev/my-k8s-project-499007/containers/frontend:latest
```

Update your Kubernetes manifests:

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
        image: asia-south1-docker.pkg.dev/my-k8s-project-499007/containers/backend:latest
```

## Update GitHub Secrets

After applying Terraform, add these secrets to GitHub:

1. Go to: **Repository Settings** → **Secrets and variables** → **Actions**
2. Create secrets:

**Secret 1: GCP_PROJECT_ID**
```
my-k8s-project-499007
```

**Secret 2: GCP_SA_KEY**
```
# Get from Terraform output
terraform output -raw github_secret_gcp_sa_key
```

Then copy the entire JSON output.

## Cleanup (Destroy Resources)

```bash
terraform destroy
```

This will:
1. Delete the service account and keys
2. Delete the Artifact Registry repository
3. Delete all resources managed by Terraform

**Warning**: This is destructive and cannot be undone. All images in the registry will be deleted.

To keep the repository but just delete the key:

```bash
# Edit terraform.tfvars
create_artifact_registry = false

terraform apply
terraform destroy
```

## Troubleshooting

### Error: "The caller does not have permission"

**Problem**: Your Google Cloud user doesn't have sufficient permissions.

**Solution**: Ensure your user has these roles:
- Editor
- Service Account Admin

```bash
gcloud projects get-iam-policy my-k8s-project-499007
```

### Error: "Resource already exists"

**Problem**: Resources already exist in your project.

**Solution**: Either use `terraform import` or delete existing resources manually:

```bash
gcloud iam service-accounts delete \
  github-actions-sa@my-k8s-project-499007.iam.gserviceaccount.com \
  --project=my-k8s-project-499007

gcloud artifacts repositories delete containers \
  --location=asia-south1 \
  --project=my-k8s-project-499007
```

### Error: "terraform.tfvars not found"

**Problem**: Configuration file is missing.

**Solution**:
```bash
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Edit with your project ID
```

### Error: "Failed to enable API"

**Problem**: API enabling failed.

**Solution**: Enable manually:
```bash
gcloud services enable \
  artifactregistry.googleapis.com \
  containerregistry.googleapis.com \
  iam.googleapis.com \
  --project=my-k8s-project-499007
```

## File Structure

```
terraform/
├── .gitignore                  # Ignore sensitive files
├── provider.tf                 # Google Cloud provider config
├── variables.tf                # Input variables with validation
├── main.tf                     # Main resources
├── outputs.tf                  # Terraform outputs
├── terraform.tfvars            # Configuration (do not commit)
├── terraform.tfvars.example    # Example configuration
└── README.md                   # This file
```

## Security Best Practices

1. **Never commit** `terraform.tfvars` to version control
2. **Never commit** `*.tfstate` files
3. **Rotate keys** periodically (delete and regenerate)
4. **Use** `terraform.tfvars.example` for examples
5. **Review** `terraform plan` output before applying
6. **Backup** `terraform.tfstate` in a secure location

## State Management

Terraform maintains state in `terraform.tfstate`:

```bash
# Never edit directly
# Use Terraform commands instead
terraform state list        # List all resources
terraform state show <name> # Show resource details
terraform state rm <name>   # Remove from state
terraform import <name> <id> # Import existing resources
```

For production, use remote state:

```hcl
terraform {
  backend "gcs" {
    bucket = "my-terraform-state"
    prefix = "gke/gcp-github-actions"
  }
}
```

## Verification Checklist

After running `terraform apply`, verify:

- [ ] Service account created with correct name
- [ ] All 3 IAM roles assigned
- [ ] Artifact Registry repository created
- [ ] Service account key saved to `key.json`
- [ ] Key file has correct permissions (0600)
- [ ] GitHub secrets added correctly
- [ ] Workflow can authenticate and push images

Run verification commands:

```bash
# Check service account
gcloud iam service-accounts describe \
  github-actions-sa@my-k8s-project-499007.iam.gserviceaccount.com

# Check IAM roles
gcloud projects get-iam-policy my-k8s-project-499007 \
  --flatten="bindings[].members" \
  --format="table(bindings.role)" \
  --filter="bindings.members:github-actions-sa@my-k8s-project-499007.iam.gserviceaccount.com"

# Check Artifact Registry
gcloud artifacts repositories list --location=asia-south1

# Check service account keys
gcloud iam service-accounts keys list \
  --iam-account=github-actions-sa@my-k8s-project-499007.iam.gserviceaccount.com
```

## References

- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [GCP Service Accounts](https://cloud.google.com/iam/docs/service-accounts)
- [Artifact Registry](https://cloud.google.com/artifact-registry/docs)
- [GitHub Actions + GCP Integration](https://github.com/google-github-actions/auth)
