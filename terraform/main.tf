# Enable required GCP APIs
resource "google_project_service" "artifactregistry" {
  count   = var.enable_apis ? 1 : 0
  project = var.gcp_project_id
  service = "artifactregistry.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "containerregistry" {
  count   = var.enable_apis ? 1 : 0
  project = var.gcp_project_id
  service = "containerregistry.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "iam" {
  count   = var.enable_apis ? 1 : 0
  project = var.gcp_project_id
  service = "iam.googleapis.com"

  disable_on_destroy = false
}

# Create service account for GitHub Actions
resource "google_service_account" "github_actions" {
  project     = var.gcp_project_id
  account_id  = var.service_account_name
  display_name = var.service_account_display_name
  description = "Service account for GitHub Actions CI/CD pipeline - builds and pushes Docker images to Artifact Registry"

  depends_on = [
    google_project_service.iam[0]
  ]
}

# IAM Role: Artifact Registry Writer (for pushing images)
resource "google_project_iam_member" "artifact_registry_writer" {
  project = var.gcp_project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

# IAM Role: Storage Admin (for Cloud Storage / Container Registry)
resource "google_project_iam_member" "storage_admin" {
  project = var.gcp_project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

# IAM Role: Viewer (for basic GCP resource access)
resource "google_project_iam_member" "viewer" {
  project = var.gcp_project_id
  role    = "roles/viewer"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

# Create service account key (JSON format)
resource "google_service_account_key" "github_actions_key" {
  service_account_id = google_service_account.github_actions.name
  public_key_type    = "TYPE_X509_PEM_FILE"
  private_key_type   = "TYPE_GOOGLE_CREDENTIALS_FILE"
}

# Save the key to a local file (for reference - do not commit!)
resource "local_sensitive_file" "service_account_key" {
  filename             = "${path.module}/../key.json"
  content              = base64decode(google_service_account_key.github_actions_key.private_key)
  file_permission      = "0600"
  directory_permission = "0700"
}

# Create Artifact Registry repository
resource "google_artifact_registry_repository" "docker" {
  count       = var.create_artifact_registry ? 1 : 0
  project     = var.gcp_project_id
  location    = var.gcp_region
  repository_id = var.artifact_registry_repository
  description = "Docker container registry for student management system (backend, database, frontend)"
  format      = var.artifact_registry_format

  labels = var.tags

  depends_on = [
    google_project_service.artifactregistry[0]
  ]
}

# Output the image repository details
locals {
  registry_base = var.create_artifact_registry ? "${var.gcp_region}-docker.pkg.dev/${var.gcp_project_id}/${var.artifact_registry_repository}" : ""
  docker_images_info = {
    for image in var.docker_images :
    image => {
      latest = "${var.gcp_region}-docker.pkg.dev/${var.gcp_project_id}/${var.artifact_registry_repository}/${image}:latest"
      sha    = "${var.gcp_region}-docker.pkg.dev/${var.gcp_project_id}/${var.artifact_registry_repository}/${image}:$${GITHUB_SHA}"
    }
  }
}
