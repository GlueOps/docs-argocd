terraform {
  required_version = ">= 1.2.0"

  required_providers {
    http = {
      source  = "hashicorp/http"
    }
    local = {
      source  = "hashicorp/local"
    }
  }
}

data "local_file" "argocd_template" {
  filename = "${path.module}/argocd.yaml.tpl"
}

variable "tenant_key" {
  type        = string
  description = "this is also known as the tenant name or company key"
}

variable "glueops_root_domain" {
  type        = string
  description = "this is the root domain for the glueops platform (e.g. onglueops.rocks, onglueops.com, etc.))"
}

variable "cluster_environment" {
  type        = string
  description = "this is the cluster environment name (e.g. dev, staging, prod, nonprod, uswestprod, etc.))"
}

variable "client_secret" {
  type        = string
  description = "this is the client secret for the argocd admin user. Should be identical to what is being used in the dex configuration"
}

variable "argocd_rbac_policies" {
  type        = string
  description = "policy csv for tenants: https://argo-cd.readthedocs.io/en/stable/operator-manual/rbac/"
  default     = <<EOT
      g, glueops-rocks:developers, role:developers
      p, role:developers, clusters, get, *, allow
      p, role:developers, *, get, development, allow
      p, role:developers, repositories, *, development/*, allow
      p, role:developers, applications, *, development/*, allow
      p, role:developers, exec, *, development/*, allow
EOT
}

variable "argocd_app_version" {
  type        = string
  description = "This is the appVersion of argocd. Example: v2.7.11"
}

variable "gatekeeper_tag" {
  type        = string
  description = "Image tag (SHA or semver) for ghcr.repo.gpkg.io/glueops/gatekeeper.platform.glueops.dev"
}

# The OTEL extension frontend is always on, for every cluster -- there is no
# enable/disable switch. That is safe because the frontend renders NOTHING when it
# has no links to show (see StatusPanel in GlueOps/argo-cd-ui-extention): a cluster
# whose backend is not up yet shows no panel at all, rather than an error box.
# Releases before v0.1.3-rc1 render a permanent "Observability unavailable" box
# instead, so shipping one of those always-on would paint that box on every
# application in every cluster.
#
# Scope: this module configures the FRONTEND only. The backend (Deployment/Service
# argocd-extension-backend-api) is owned by platform-helm-chart-platform, which
# deploys it as an Argo CD Application into glueops-core-argocd-extension-backend.
# This module must never deploy a second copy of it.
variable "otel_extension_version" {
  type        = string
  description = "GitHub release tag for the ArgoCD OTEL extension tarball. Must be v0.1.3 or newer: v0.1.2 and earlier render a permanent \"Observability unavailable\" box on every application, and every build before v0.1.3 hid any link category the backend marked degraded -- which is all of them except Config Repo."
  default     = "v0.1.3"

  # The extension is always on, so these are unconditional: an empty or malformed
  # version would render a broken EXTENSION_URL into every cluster's argocd.yaml.
  validation {
    condition     = trimspace(var.otel_extension_version) != ""
    error_message = "otel_extension_version must be non-empty"
  }

  validation {
    condition     = length(regexall("\\s", trimspace(var.otel_extension_version))) == 0
    error_message = "otel_extension_version must not contain whitespace"
  }
}

locals {
  otel_extension_version_trimmed = trimspace(var.otel_extension_version)
  otel_extension_semver          = trimprefix(local.otel_extension_version_trimmed, "v")
}


output "helm_values" {
  value = replace(replace(replace(replace(replace(replace(
    replace(
      replace(
        replace(
          data.local_file.argocd_template.content,
        "placeholder_tenant_key", var.tenant_key),
      "placeholder_cluster_environment", var.cluster_environment),
    "placeholder_argocd_oidc_client_secret_from_dex", var.client_secret),
    "placeholder_glueops_root_domain", var.glueops_root_domain),
    "      placeholder_argocd_rbac_policies", var.argocd_rbac_policies),
    "placeholder_argocd_app_version", var.argocd_app_version),
    "placeholder_gatekeeper_tag", var.gatekeeper_tag),
    "placeholder_otel_extension_version", local.otel_extension_version_trimmed),
    "placeholder_otel_extension_semver", local.otel_extension_semver
  )
}
