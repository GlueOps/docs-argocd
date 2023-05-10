terraform {
  required_providers {
    http = {
      source  = "hashicorp/http"
      version = "3.3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.4.0"
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

output "argocd" {
  value = replace(replace(replace(
    replace(
      data.local_file.argocd_template.content,
      "<tenant-name-goes-here>",
      "${var.tenant_key}"
    ),
    "<cluster_env>",
    "${var.cluster_environment}"
    ), "clientSecret: XXXXXXXXXXXXXXXXXXXXXXXXXX", "clientSecret: ${var.client_secret}"),
  "onglueops.rocks", "${var.glueops_root_domain}")



}
