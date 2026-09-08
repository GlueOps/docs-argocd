terraform {
  required_version = ">= 1.2.0"

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

# The OTEL extension frontend is always on, for every cluster -- there is no
# enable/disable switch. That is safe because the frontend renders NOTHING when it
# has no links to show (see StatusPanel in GlueOps/argo-cd-ui-extention): a cluster
# whose backend is not up yet shows no panel at all, rather than an error box.
# That behaviour landed in GlueOps/argo-cd-ui-extention PR #25. Every release cut
# before it -- v0.1.2 and earlier, and anything built from main until #25 merges --
# renders a permanent "Observability unavailable" box instead. Shipping one of those
# always-on would paint that box on every application in every cluster.
#
# The default below is deliberately a PRERELEASE: v0.1.3-rc1 is built from that PR's
# branch and is currently the only published tag with the hide-when-empty behaviour.
# Once #25 merges, cut a real v0.1.3 from main and bump this default to it.
#
# Scope: this module configures the FRONTEND only. The backend (Deployment/Service
# argocd-extension-backend-api) is owned by platform-helm-chart-platform, which
# deploys it as an Argo CD Application into glueops-core-argocd-extension-backend.
# This module must never deploy a second copy of it.
variable "otel_extension_version" {
  type        = string
  description = "GitHub release tag for the ArgoCD OTEL extension tarball. Must be a release that hides the panel when there is no data (v0.1.3-rc1 or newer); v0.1.2 and earlier render a permanent error box. v0.1.3-rc2 additionally stops the panel blanking its links on every Argo CD reconcile."
  default     = "v0.1.3-rc2"
}

locals {
  otel_extension_version_trimmed = trimspace(var.otel_extension_version)
  otel_extension_semver          = trimprefix(local.otel_extension_version_trimmed, "v")

  # The backend Service DNS is the SAME on every cluster: both the Service name and
  # its namespace are hardcoded constants in platform-helm-chart-platform
  # (templates/application-argocd-extension-backend.yaml), not derived from
  # captain_domain or the cluster environment. So there is deliberately nothing
  # per-cluster to substitute here.
  #
  # The namespace is glueops-core-argocd-extension-backend -- the Application's
  # destination namespace -- NOT glueops-core, which does not resolve.
  otel_extension_config = join("\n", [
    "    extension.config: |",
    "      extensions:",
    "        - name: otel-extension",
    "          backend:",
    "            services:",
    "              - url: http://argocd-extension-backend-api.glueops-core-argocd-extension-backend.svc.cluster.local:8000",
  ])
  otel_rbac_policies = join("\n", [
    "      p, role:readonly, extensions, invoke, otel-extension, allow",
    "      p, role:admin, extensions, invoke, otel-extension, allow",
  ])
  otel_server_extensions = join("\n", [
    "  extensions:",
    "    enabled: true",
    # The chart defaults this installer image to quay.io directly, unlike every
    # other image on the platform. Pin it to the gpkg mirror so clusters that
    # cannot egress to quay.io (or that would hit its rate limits) still start:
    # this runs as an initContainer on argocd-server, so a failed pull takes the
    # Argo CD UI down rather than just disabling the extension.
    "    image:",
    "      repository: quay.repo.gpkg.io/argoprojlabs/argocd-extension-installer",
    "    extensionList:",
    "      - name: otel-extension",
    "        env:",
    "          - name: EXTENSION_URL",
    "            value: \"https://github.com/GlueOps/argo-cd-ui-extention/releases/download/placeholder_otel_extension_version/extension.tar.gz\"",
    "          - name: EXTENSION_VERSION",
    "            value: \"placeholder_otel_extension_semver\"",
  ])
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

  rendered_argocd_values_otel_extension_config = replace(
    local.rendered_argocd_values_gatekeeper,
    "    # placeholder_otel_extension_config",
    local.otel_extension_config
  )

  rendered_argocd_values_otel_rbac = replace(
    local.rendered_argocd_values_otel_extension_config,
    "      # placeholder_otel_rbac_policies",
    local.otel_rbac_policies
  )

  rendered_argocd_values_otel_server_extensions = replace(
    local.rendered_argocd_values_otel_rbac,
    "  # placeholder_otel_server_extensions",
    local.otel_server_extensions
  )

  rendered_argocd_values_otel_version = replace(
    local.rendered_argocd_values_otel_server_extensions,
    "placeholder_otel_extension_version",
    local.otel_extension_version_trimmed
  )

  rendered_argocd_values = replace(
    local.rendered_argocd_values_otel_version,
    "placeholder_otel_extension_semver",
    local.otel_extension_semver
  )
}


output "helm_values" {
  value = local.rendered_argocd_values

  # The extension is always on, so these are unconditional: an empty or malformed
  # version would render a broken EXTENSION_URL into every cluster's argocd.yaml.
  precondition {
    condition     = local.otel_extension_version_trimmed != ""
    error_message = "otel_extension_version must be non-empty"
  }

  precondition {
    condition     = length(regexall("\\s", local.otel_extension_version_trimmed)) == 0
    error_message = "otel_extension_version must not contain whitespace"
  }
}
