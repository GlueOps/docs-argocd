terraform {
  required_providers {
    http = {
      source = "hashicorp/http"
    }
    local = {
      source = "hashicorp/local"
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

variable "otel_enabled" {
  type        = bool
  description = "Enable or disable the global ArgoCD OTEL extension and its backend service for this tenant"
  default     = true
}

variable "otel_extension_version" {
  type        = string
  description = "GitHub release tag for the ArgoCD OTEL extension tarball (example: v0.1.1)"
  default     = "v0.1.1"
}

variable "otel_backend_tag" {
  type        = string
  description = "Image tag (SHA or semver) for ghcr.repo.gpkg.io/glueops/argocd-otel-extension-api"
  default     = "v0.1.1"
}

variable "tempo_base_url" {
  type        = string
  description = "In-cluster Tempo base URL for trace search. Leave empty to disable traces while keeping metrics enabled."
  default     = ""
}

locals {
  otel_enabled_string   = var.otel_enabled ? "true" : "false"
  otel_backend_replicas = var.otel_enabled ? "2" : "0"
  otel_extension_semver = trimprefix(var.otel_extension_version, "v")

  rendered_argocd_values_tenant = replace(
    data.local_file.argocd_template.content,
    "placeholder_tenant_key",
    var.tenant_key
  )

  rendered_argocd_values_environment = replace(
    local.rendered_argocd_values_tenant,
    "placeholder_cluster_environment",
    var.cluster_environment
  )

  rendered_argocd_values_secret = replace(
    local.rendered_argocd_values_environment,
    "placeholder_argocd_oidc_client_secret_from_dex",
    var.client_secret
  )

  rendered_argocd_values_domain = replace(
    local.rendered_argocd_values_secret,
    "placeholder_glueops_root_domain",
    var.glueops_root_domain
  )

  rendered_argocd_values_rbac = replace(
    local.rendered_argocd_values_domain,
    "      placeholder_argocd_rbac_policies",
    var.argocd_rbac_policies
  )

  rendered_argocd_values_app_version = replace(
    local.rendered_argocd_values_rbac,
    "placeholder_argocd_app_version",
    var.argocd_app_version
  )

  rendered_argocd_values_gatekeeper = replace(
    local.rendered_argocd_values_app_version,
    "placeholder_gatekeeper_tag",
    var.gatekeeper_tag
  )

  rendered_argocd_values_otel_enabled = replace(
    local.rendered_argocd_values_gatekeeper,
    "placeholder_otel_enabled",
    local.otel_enabled_string
  )

  rendered_argocd_values_otel_replicas = replace(
    local.rendered_argocd_values_otel_enabled,
    "placeholder_otel_backend_replicas",
    local.otel_backend_replicas
  )

  rendered_argocd_values_otel_version = replace(
    local.rendered_argocd_values_otel_replicas,
    "placeholder_otel_extension_version",
    var.otel_extension_version
  )

  rendered_argocd_values_otel_semver = replace(
    local.rendered_argocd_values_otel_version,
    "placeholder_otel_extension_semver",
    local.otel_extension_semver
  )

  rendered_argocd_values_otel_backend_tag = replace(
    local.rendered_argocd_values_otel_semver,
    "placeholder_otel_backend_tag",
    var.otel_backend_tag
  )

  rendered_argocd_values = replace(
    local.rendered_argocd_values_otel_backend_tag,
    "placeholder_tempo_base_url",
    var.tempo_base_url
  )
}


output "helm_values" {
  value = local.rendered_argocd_values
}
