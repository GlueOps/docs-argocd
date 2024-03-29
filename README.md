# docs-argocd

This repo outlines how to install argocd using the official argocd helm chart. This is part of the opionated GlueOps Platform. If you came here directly then you should probably visit https://github.com/glueops/admiral as that is the starting point.

## Prerequisites

- Connection to the Kubernetes server. The authentication methods will vary by Cloud Provider and are documented within their respective wikis.

- Prepare a argocd.yaml to use for your argocd installation
  
```bash
wget -O argocd.yaml https://raw.githubusercontent.com/GlueOps/docs-argocd/main/argocd.yaml.tpl
```

- Read the comments in the file and update the values in the argocd.yaml file.
  - Quick Notes:
    - Replace `placeholder_tenant_key` with your tenant/company key. Example: `antoniostacos`
    - Replace `placeholder_cluster_environment` with your cluster_environment name. Example: `nonprod`
    - The `placeholder_argocd_oidc_client_secret_from_dex` that you specify needs to be the same one you use in the `platform.yaml` for ArgoCD. If they do not match you will not be able to login.

- Install ArgoCD

```bash
kubectl apply -k "https://github.com/argoproj/argo-cd/tree/v2.8.6/manifests/crds" # You need to install the CRD's that match the version of the app in the helm chart.
helm repo add argo https://argoproj.github.io/argo-helm # Adds the argo helm repository to your local environment
helm install argocd argo/argo-cd --skip-crds --version 5.50.0 -f argocd.yaml --namespace=glueops-core --create-namespace #this command includes --skip-crds but the way the chart works we also have a value we need to set to false so that the CRD's do not work. This value is in the argocd.yaml
```

- Check to see if all ArgoCD pods are in a good state with: 

```bash
kubectl get pods -n glueops-core
```

- Using the command above, ensure that the ArgoCD pods are stable and no additional pods/containers are coming online. If there is a pod that is 1/3 wait until it's 3/3 and has been running for at least a minute. This entire bootstrap can take about 5mins as we are deploying a number of services in HA mode.

## If you are using the terraform module, below is an example

```hcl
module "argocd_helm_values" {
  source              = "git::https://github.com/GlueOps/docs-argocd.git"
  tenant_key          = "antoniostacos"
  cluster_environment = "nonprod"
  client_secret       = "Zsbui/29YEqoGOzuI8snlqGcdaRYPSLocwLXDB5GhZY="
  glueops_root_domain = "onglueops.com"
}

output "argocd_helm_values" {
  value = module.argocd_yaml.argocd
}
```
