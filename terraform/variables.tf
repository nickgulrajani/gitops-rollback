variable "project" {
  type        = string
  description = "Project tag/name"
  default     = "gitops-argocd"
}

variable "environment" {
  type        = string
  description = "Environment tag/name"
  default     = "dryrun"
}

variable "name_prefix" {
  type        = string
  description = "Prefix for names"
  default     = "gitops"
}

variable "repo_url" {
  type        = string
  description = "Git repo URL tracked by Argo CD"
  default     = "https://github.com/nickgulrajani/gitops-rollback"
}

variable "chart_path" {
  type        = string
  description = "Path inside repo to the Helm chart or manifests"
  default     = "helm/app"
}

# Optional: declare to silence your tfvars warning (even if unused)
variable "enable_gitops" {
  type        = bool
  description = "Toggle (declared to avoid warnings); not used in dry run"
  default     = true
}
