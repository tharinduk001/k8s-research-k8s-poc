variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.gcp_project_id))
    error_message = "Project ID must be a valid GCP project ID format."
  }
}

variable "gcp_region" {
  description = "GCP Region for resources"
  type        = string
  default     = "asia-south1"
  validation {
    condition     = contains(["asia-south1", "us-central1", "europe-west1", "us-east1"], var.gcp_region)
    error_message = "Region must be one of the supported regions."
  }
}

variable "service_account_name" {
  description = "Name of the service account for GitHub Actions"
  type        = string
  default     = "github-actions-sa"
  validation {
    condition     = can(regex("^[a-z]([a-z0-9-]{0,28}[a-z0-9])?$", var.service_account_name))
    error_message = "Service account name must be lowercase alphanumeric with hyphens, 1-30 characters."
  }
}

variable "service_account_display_name" {
  description = "Display name for the service account"
  type        = string
  default     = "GitHub Actions Service Account"
}

variable "artifact_registry_repository" {
  description = "Name of the Artifact Registry repository"
  type        = string
  default     = "containers"
  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]{0,62}[a-z0-9])?$", var.artifact_registry_repository))
    error_message = "Repository name must be lowercase alphanumeric with hyphens, 1-64 characters."
  }
}

variable "artifact_registry_format" {
  description = "Format of the Artifact Registry repository"
  type        = string
  default     = "DOCKER"
  validation {
    condition     = contains(["DOCKER", "MAVEN", "NPM", "PYTHON", "APT", "YUM", "GOOGET", "GENERIC"], var.artifact_registry_format)
    error_message = "Format must be a valid Artifact Registry format."
  }
}

variable "create_artifact_registry" {
  description = "Whether to create the Artifact Registry repository"
  type        = bool
  default     = true
}

variable "docker_images" {
  description = "List of Docker images to prepare for in the documentation"
  type        = list(string)
  default     = ["backend", "database", "frontend"]
}

variable "enable_apis" {
  description = "Whether to enable required GCP APIs"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Labels to apply to resources"
  type        = map(string)
  default = {
    environment = "github-actions"
    managed_by  = "terraform"
  }
}
