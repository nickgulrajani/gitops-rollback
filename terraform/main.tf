locals {
  out_dir = "${path.module}/out"

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
      description  = "Project for ${var.name_prefix} apps"
      sourceRepos  = ["*"]
      destinations = [
        { server = "https://kubernetes.default.svc", namespace = "apps-staging" },
        { server = "https://kubernetes.default.svc", namespace = "apps-prod" }
      ]
      clusterResourceWhitelist    = [{ group = "*", kind = "*" }]
      namespaceResourceWhitelist  = [{ group = "*", kind = "*" }]
    }
  }

  app_staging = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "${var.name_prefix}-app-staging"
      namespace = "argocd"
      labels = {
        Project     = var.project
        Environment = var.environment
        Stage       = "staging"
      }
    }
    spec = {
      project = local.argocd_project.metadata.name
      source = {
        repoURL        = var.repo_url
        targetRevision = "HEAD"
        path           = var.chart_path
        helm = {
          releaseName  = "${var.name_prefix}-svc-staging"
          valuesObject = {
            replicaCount = 2
            env          = "staging"
          }
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "apps-staging"
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
  }

  app_prod = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "${var.name_prefix}-app-prod"
      namespace = "argocd"
      labels = {
        Project     = var.project
        Environment = var.environment
        Stage       = "prod"
      }
    }
    spec = {
      project = local.argocd_project.metadata.name
      source = {
        repoURL        = var.repo_url
        targetRevision = "HEAD"
        path           = var.chart_path
        helm = {
          releaseName  = "${var.name_prefix}-svc-prod"
          valuesObject = {
            replicaCount = 3
            env          = "prod"
          }
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "apps-prod"
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
  }
}

# Render YAML files (no cluster interaction)
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

output "gitops_summary" {
  value = {
    project_file   = local_file.argocd_project_yaml.filename
    staging_file   = local_file.app_staging_yaml.filename
    prod_file      = local_file.app_prod_yaml.filename
    repo_url       = var.repo_url
    chart_path     = var.chart_path
    namespaces     = ["apps-staging", "apps-prod"]
  }
}
