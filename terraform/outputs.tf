output "service_account_email" {
  description = "Email of the created service account"
  value       = google_service_account.github_actions.email
}

output "service_account_id" {
  description = "ID of the created service account"
  value       = google_service_account.github_actions.unique_id
}

output "service_account_name" {
  description = "Name of the created service account"
  value       = google_service_account.github_actions.name
}

output "github_secret_gcp_sa_key" {
  description = "Service account key in JSON format (for GitHub GCP_SA_KEY secret) - SENSITIVE"
  value       = base64decode(google_service_account_key.github_actions_key.private_key)
  sensitive   = true
}

output "github_secret_gcp_project_id" {
  description = "GCP Project ID (for GitHub GCP_PROJECT_ID secret)"
  value       = var.gcp_project_id
}

output "artifact_registry_url" {
  description = "URL of the Artifact Registry repository"
  value       = var.create_artifact_registry ? "https://${var.gcp_region}-docker.pkg.dev/${var.gcp_project_id}/${var.artifact_registry_repository}" : null
}

output "docker_image_paths" {
  description = "Full paths to the Docker images in Artifact Registry"
  value = {
    for image in var.docker_images :
    image => {
      latest = "${var.gcp_region}-docker.pkg.dev/${var.gcp_project_id}/${var.artifact_registry_repository}/${image}:latest"
      commit = "${var.gcp_region}-docker.pkg.dev/${var.gcp_project_id}/${var.artifact_registry_repository}/${image}:{{ github.sha }}"
    }
  }
}

output "github_secrets_instructions" {
  description = "Instructions for adding GitHub secrets"
  value = <<-EOT
    
    ╔══════════════════════════════════════════════════════════╗
    ║          GitHub Secrets Setup Instructions              ║
    ╚══════════════════════════════════════════════════════════╝
    
    1. Go to: https://github.com/YOUR-REPO/settings/secrets/actions
    
    2. Add these secrets:
    
       Secret 1: GCP_PROJECT_ID
       Value: ${var.gcp_project_id}
    
       Secret 2: GCP_SA_KEY
       Value: (See terraform output "github_secret_gcp_sa_key")
       
       To get the key:
       terraform output -raw github_secret_gcp_sa_key > key.json
       cat key.json
    
    ╔══════════════════════════════════════════════════════════╗
    ║          Verify Service Account Permissions             ║
    ╚══════════════════════════════════════════════════════════╝
    
    gcloud projects get-iam-policy ${var.gcp_project_id} \
      --flatten="bindings[].members" \
      --format="table(bindings.role)" \
      --filter="bindings.members:${google_service_account.github_actions.email}"
    
    ╔══════════════════════════════════════════════════════════╗
    ║          Docker Image Paths for k8s Manifests           ║
    ╚══════════════════════════════════════════════════════════╝
    
    Update your Kubernetes deployment files with:
    
    backend:   ${var.gcp_region}-docker.pkg.dev/${var.gcp_project_id}/${var.artifact_registry_repository}/backend:latest
    database:  ${var.gcp_region}-docker.pkg.dev/${var.gcp_project_id}/${var.artifact_registry_repository}/database:latest
    frontend:  ${var.gcp_region}-docker.pkg.dev/${var.gcp_project_id}/${var.artifact_registry_repository}/frontend:latest
  EOT
}

output "iam_roles_assigned" {
  description = "IAM roles assigned to the service account"
  value = [
    "roles/artifactregistry.writer",
    "roles/storage.admin",
    "roles/viewer"
  ]
}

output "artifact_registry_repository" {
  description = "Name of the Artifact Registry repository"
  value       = var.create_artifact_registry ? google_artifact_registry_repository.docker[0].repository_id : null
}

output "artifact_registry_location" {
  description = "Location of the Artifact Registry repository"
  value       = var.gcp_region
}

output "key_file_path" {
  description = "Path to the saved service account key"
  value       = local_sensitive_file.service_account_key.filename
  sensitive   = true
}
