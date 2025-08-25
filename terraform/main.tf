##############################
# GitOps Argo CD (plan only)
# - No cluster/API calls
# - Renders YAML to _out/
##############################

locals {
  out_dir = "${path.module}/_out"

  # ----- AppProject -----
  argocd_project = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"
    metadata = {
      name      = "${var.name_prefix}-apps"
      namespace = "argocd"
      labels = {
        Project     = var.project
        Environment = var.environment
      }
    }
    spec = {
      description = "Project for ${var.name_prefix} apps"
      sourceRepos = ["*"]

      destinations = [
        { server = "https://kubernetes.default.svc", namespace = "apps-staging" },
        { server = "https://kubernetes.default.svc", namespace = "apps-prod" }
      ]

      # Relaxed for demo; tighten in real envs
      clusterResourceWhitelist   = [{ group = "*", kind = "*" }]
      namespaceResourceWhitelist = [{ group = "*", kind = "*" }]
    }
  }

  # ----- Common fields for Applications -----
  app_common_meta = {
    namespace = "argocd"
    labels = {
      Project     = var.project
      Environment = var.environment
    }
  }

  app_common_spec = {
    project = "${var.name_prefix}-apps" # reference the AppProject above
    source = {
      repoURL        = var.repo_url
      targetRevision = "HEAD"
      path           = var.chart_path
      # Example: helm options; keep minimal for demo
      helm = {
        valueFiles = []
      }
    }
    destination = {
      server    = "https://kubernetes.default.svc"
      namespace = "default" # overridden per env below
    }
    syncPolicy = {
      automated = {
        prune    = true
        selfHeal = true
      }
      syncOptions = [
        "CreateNamespace=true",
        "ApplyOutOfSyncOnly=true"
      ]
    }
  }

  # ----- Staging Application -----
  app_staging = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = merge(local.app_common_meta, {
      name = "${var.name_prefix}-app-staging"
      labels = merge(local.app_common_meta.labels, { Stage = "staging" })
    })
    spec = merge(local.app_common_spec, {
      destination = merge(local.app_common_spec.destination, { namespace = "apps-staging" })
      source = merge(local.app_common_spec.source, {
        helm = {
          releaseName  = "${var.name_prefix}-svc-staging"
          valuesObject = {
            replicaCount = 2
            env          = "staging"
          }
        }
      })
    })
  }

  # ----- Production Application -----
  app_prod = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = merge(local.app_common_meta, {
      name = "${var.name_prefix}-app-prod"
      labels = merge(local.app_common_meta.labels, { Stage = "prod" })
    })
    spec = merge(local.app_common_spec, {
      destination = merge(local.app_common_spec.destination, { namespace = "apps-prod" })
      source = merge(local.app_common_spec.source, {
        helm = {
          releaseName  = "${var.name_prefix}-svc-prod"
          valuesObject = {
            replicaCount = 3
            env          = "prod"
          }
        }
      })
    })
  }
}

# ---------- Render YAML files (plan-only) ----------
resource "local_file" "argocd_project_yaml" {
  filename = "${local.out_dir}/argocd-project.yaml"
  content  = yamlencode(local.argocd_project)
}

resource "local_file" "app_staging_yaml" {
  filename = "${local.out_dir}/app-staging.yaml"
  content  = yamlencode(local.app_staging)
}

resource "local_file" "app_prod_yaml" {
  filename = "${local.out_dir}/app-prod.yaml"
  content  = yamlencode(local.app_prod)
}

# ---------- Outputs ----------
output "gitops_summary" {
  value = {
    project_file = local_file.argocd_project_yaml.filename
    staging_file = local_file.app_staging_yaml.filename
    prod_file    = local_file.app_prod_yaml.filename
    repo_url     = var.repo_url
    chart_path   = var.chart_path
    namespaces   = ["apps-staging", "apps-prod"]
  }
}

output "argocd_application_files" {
  value = [
    local_file.app_staging_yaml.filename,
    local_file.app_prod_yaml.filename,
  ]
}
