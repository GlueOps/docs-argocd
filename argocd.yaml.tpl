crds:
  install: false

# @ignored
notifications:
  metrics:
    enabled: true

# @ignored
global:
  image:
    tag: "placeholder_argocd_app_version"
  nodeSelector:
    glueops.dev/role: "glueops-platform"
  tolerations:
    - key: "glueops.dev/role"
      operator: "Equal"
      value: "glueops-platform"
      effect: "NoSchedule"

# many of these ignored values can be found in the argo-cd helm chart docs: https://artifacthub.io/packages/helm/argo/argo-cd
# @ignored
dex:
  enabled: false
redis-ha:
  haproxy:
    metrics:
      enabled: true
  enabled: true
  nodeSelector:
    glueops.dev/role: "glueops-platform"
  tolerations:
    - key: "glueops.dev/role"
      operator: "Equal"
      value: "glueops-platform"
      effect: "NoSchedule"
# @ignored
controller:
  metrics:
    enabled: true
  replicas: 1
  extraArgs:
    - --application-namespaces=*
# @ignored
repoServer:
  metrics:
    enabled: true
  autoscaling:
    enabled: true
    minReplicas: 6
    maxReplicas: 8
# @ignored
applicationSet:
  metrics:
    enabled: true
  replicas: 2
configs:
  params:
    server.insecure: true
  cm:
    # @ignored
    timeout.reconciliation: 10s
    exec.enabled: "true"
    # This helps argocd know what resources it should be manging. This way if argocd manages an operator and that operator creates a pvc, it won't try and manage the pvc.
    # https://argo-cd.readthedocs.io/en/stable/user-guide/resource_tracking/#choosing-a-tracking-method
    # @ignored
    application.resourceTrackingMethod: "annotation+label"
    # https://argo-cd.readthedocs.io/en/stable/operator-manual/health/#argocd-app
    # https://github.com/argoproj/argo-cd/issues/3781
    # enables health check assessment for argocd applications as we are using sync-waves
    # @ignored
    resource.customizations.health.argoproj.io_Application: |
      hs = {}
      hs.status = "Progressing"
      hs.message = ""
      if obj.status ~= nil then
        if obj.status.health ~= nil then
          hs.status = obj.status.health.status
          if obj.status.health.message ~= nil then
            hs.message = obj.status.health.message
          end
        end
      end
      return hs
    # enables health check assessment for lokialertrulegroup. it'll be in a progressing state if it doesn't get created. we may want to add more health checks in the future for error states
    # @ignored
    resource.customizations.health.metacontroller.glueops.dev_LokiAlertRuleGroup:
      hs = {}
      hs.status = "Progressing"
      hs.message = ""
      if obj.status ~= nil then
        if obj.status.health ~= nil then
          hs.status = obj.status.health.status
          if hs.status ~= "Healthy" then
            hs.status = "Degraded"
            hs.message = "Status is not Healthy"
          end
        end
      end
      return hs
    # @ignored
    resource.customizations.health.metacontroller.glueops.dev_WebApplicationFirewall:
      hs = {}
      if obj.status then
          if obj.status.HEALTHY == "True" then
              hs.status = "Healthy"
              hs.message = "WebApplicationFirewall is healthy"
          else
              hs.status = "Degraded"
              hs.message = "WebApplicationFirewall is not healthy"
          end
      else
          hs.status = "Progressing"
          hs.message = "WebApplicationFirewall is initializing"
      end
      return hs
    # @ignored
    resource.customizations.health.metacontroller.glueops.dev_WebApplicationFirewallWebACL:
      hs = {}
      if obj.status then
          if obj.status.HEALTHY == "True" then
              hs.status = "Healthy"
              hs.message = "WebApplicationFirewallWebACL is healthy"
          else
              hs.status = "Degraded"
              hs.message = "WebApplicationFirewallWebACL is not healthy"
          end
      else
          hs.status = "Progressing"
          hs.message = "WebApplicationFirewallWebACL is initializing"
      end
      return hs
    url: "https://argocd.placeholder_cluster_environment.placeholder_tenant_key.placeholder_glueops_root_domain"
    # -- To create a clientID and clientSecret please reference: https://github.com/GlueOps/github-oauth-apps
    # This dex.config is to create a GitHub connector for SSO to ArgoCD.
    # @default -- `''` (See [values.yaml])
    oidc.config: |
      name: GitHub SSO
      issuer: https://dex.placeholder_cluster_environment.placeholder_tenant_key.placeholder_glueops_root_domain
      clientID: argocd
      clientSecret: placeholder_argocd_oidc_client_secret_from_dex
      redirectURI: https://argocd.placeholder_cluster_environment.placeholder_tenant_key.placeholder_glueops_root_domain/api/dex/callback
  rbac:
    # -- A good reference for this is: https://argo-cd.readthedocs.io/en/stable/operator-manual/rbac/
    # This default policy is for GlueOps orgs/teams only. Please change it to reflect your own orgs/teams.
    # `development` is the project that all developers are expected to deploy under
    # @default -- `''` (See [values.yaml])
    policy.csv: |
      placeholder_argocd_rbac_policies
  # @ignored
server:
  # @ignored
  metrics:
    enabled: true
  # @ignored
  extraArgs:
    - --application-namespaces=*
  # @ignored
  autoscaling:
    enabled: true
    minReplicas: 2
  # @ignored
  service:
    type: ClusterIP
  ingress:
    hosts: ["argocd.placeholder_cluster_environment.placeholder_tenant_key.placeholder_glueops_root_domain"]
    # @ignored
    enabled: true
    # this public-authenticated leverages the authentication proxy (pomerium)
    # @ignored
    ingressClassName: public-authenticated
    # standard annotations for pomerium: https://www.pomerium.com/docs/deploying/k8s/ingress
    # @ignored
    annotations:
      ingress.pomerium.io/allow_any_authenticated_user: 'true'
      ingress.pomerium.io/pass_identity_headers: 'true'
      ingress.pomerium.io/allow_websockets: 'true'
      ingress.pomerium.io/idle_timeout: 0s
