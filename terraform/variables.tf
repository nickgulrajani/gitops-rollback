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
  description = "Git repository URL that Argo CD will sync from"
  default     = "https://github.com/nickgulrajani/gitops-rollback"
}

variable "chart_path" {
  type        = string
  description = "Path in repo where the Helm chart or kustomize lives"
  default     = "helm/app"
}

# Optional: declared just to silence tfvars warnings (not used at runtime)
variable "enable_gitops" {
  type        = bool
  description = "Toggle (declared to avoid warnings); not used in dry run"
  default     = true
}
