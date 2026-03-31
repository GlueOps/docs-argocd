crds:
  install: false

# @ignored
notifications:
  metrics:
    enabled: true
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: "glueops.dev/role"
            operator: In
            values:
            - "glueops-platform"

# @ignored
global:
  domain: "argocd.placeholder_cluster_environment.placeholder_tenant_key.placeholder_glueops_root_domain"
  image:
    repository: "quay.repo.gpkg.io/argoproj/argocd"
    tag: "placeholder_argocd_app_version"
  tolerations:
    - key: "glueops.dev/role"
      operator: "Equal"
      value: "glueops-platform"
      effect: "NoSchedule"
  logging:
    format: json

# many of these ignored values can be found in the argo-cd helm chart docs: https://artifacthub.io/packages/helm/argo/argo-cd
# @ignored
dex:
  image:
    repository: "ghcr.repo.gpkg.io/dexidp/dex"
  enabled: false
redis:
  exporter:
    image:
      repository: "ghcr.repo.gpkg.io/oliver006/redis_exporter"
redis-ha:
  image:
    repository: "ecr.repo.gpkg.io/docker/library/redis"
  haproxy:
    image:
      repository: "ecr.repo.gpkg.io/docker/library/haproxy"
    metrics:
      enabled: true
    tolerations:
      - key: "glueops.dev/role"
        operator: "Equal"
        value: "glueops-platform"
        effect: "NoSchedule"
    additionalAffinities:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
          - matchExpressions:
            - key: "glueops.dev/role"
              operator: In
              values:
              - "glueops-platform"
  enabled: true
  tolerations:
    - key: "glueops.dev/role"
      operator: "Equal"
      value: "glueops-platform"
      effect: "NoSchedule"
  additionalAffinities:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: "glueops.dev/role"
            operator: In
            values:
            - "glueops-platform"
# @ignored
controller:
  # @ignored
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: "glueops.dev/role"
            operator: In
            values:
            - "glueops-platform-argocd-app-controller"
            - "glueops-platform"
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        preference:
          matchExpressions:
          - key: "glueops.dev/role"
            operator: In
            values:
            - "glueops-platform-argocd-app-controller"
  tolerations:
    - key: "glueops.dev/role"
      operator: "Equal"
      value: "glueops-platform-argocd-app-controller"
      effect: "NoSchedule"
    - key: "glueops.dev/role"
      operator: "Equal"
      value: "glueops-platform"
      effect: "NoSchedule"
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
  pdb:
    enabled: true
    minAvailable: 2
  affinity:
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchLabels:
              app.kubernetes.io/name: argocd-repo-server
          topologyKey: kubernetes.io/hostname
      - weight: 50
        podAffinityTerm:
          labelSelector:
            matchExpressions:
            - key: app.kubernetes.io/name
              operator: In
              values:
              - argocd-application-controller
          topologyKey: kubernetes.io/hostname
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: "glueops.dev/role"
            operator: In
            values:
            - "glueops-platform"
# @ignored
applicationSet:
  metrics:
    enabled: true
  replicas: 2
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: "glueops.dev/role"
            operator: In
            values:
            - "glueops-platform"
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
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: "glueops.dev/role"
            operator: In
            values:
            - "glueops-platform"
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
    # @ignored
    enabled: true
    # this public-authenticated leverages the authentication proxy (oauth2-proxy)
    # @ignored
    ingressClassName: platform-traefik
    # standard annotations for pomerium: https://www.pomerium.com/docs/deploying/k8s/ingress
    # @ignored
    annotations:
      traefik.ingress.kubernetes.io/router.middlewares: glueops-core-oauth2-proxy-oauth2-with-redirect@kubernetescrd
      traefik.ingress.kubernetes.io/router.entrypoints: websecure
      traefik.ingress.kubernetes.io/router.tls: "true"
      traefik.ingress.kubernetes.io/router.priority: "10"
      
      #nginx.ingress.kubernetes.io/auth-signin: "https://oauth2.placeholder_cluster_environment.placeholder_tenant_key.placeholder_glueops_root_domain/oauth2/start?rd=https://$host$request_uri"
      #nginx.ingress.kubernetes.io/auth-url: "https://oauth2.placeholder_cluster_environment.placeholder_tenant_key.placeholder_glueops_root_domain/oauth2/auth"
      #nginx.ingress.kubernetes.io/auth-response-headers: "x-auth-request-user, x-auth-request-email, authorization"
    
    hosts:
      - argocd.placeholder_cluster_environment.placeholder_tenant_key.placeholder_glueops_root_domain
    paths:
      - /


extraObjects:
  - apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: argocd-server-api
      annotations:
        traefik.ingress.kubernetes.io/router.entrypoints: websecure
        traefik.ingress.kubernetes.io/router.middlewares: glueops-core-oauth2-proxy-oauth2-no-redirect@kubernetescrd
        traefik.ingress.kubernetes.io/router.priority: "20"
        traefik.ingress.kubernetes.io/router.tls: "true"
    spec:
      ingressClassName: platform-traefik
      rules:
        - host: argocd.placeholder_cluster_environment.placeholder_tenant_key.placeholder_glueops_root_domain
          http:
            paths:
              - path: /api
                pathType: Prefix
                backend:
                  service:
                    name: argocd-server
                    port:
                      number: 80

  - apiVersion: apiextensions.k8s.io/v1
    kind: CustomResourceDefinition
    metadata:
      name: gates.platform.glueops.dev
    spec:
      group: platform.glueops.dev
      scope: Namespaced
      names:
        plural: gates
        singular: gate
        kind: Gate
        shortNames: ["gate"]
      versions:
        - name: v1alpha1
          served: true
          storage: true
          subresources:
            status: {}
          schema:
            openAPIV3Schema:
              type: object
              required: ["spec"]
              properties:
                spec:
                  type: object
                  required: ["checks"]
                  properties:
                    strict:
                      type: boolean
                      default: true
                      description: "If true, the gate will be marked failed if any checks reference disallowed resource kinds or targets. If false, such checks will be ignored but the gate can still pass if all other checks pass."
                    checks:
                      type: array
                      minItems: 1
                      items:
                        type: object
                        required: ["id"]
                        properties:
                          id:
                            type: string
                            minLength: 1
                            maxLength: 63
                          namespace:
                            type: string
                            minLength: 1
                            maxLength: 63
                          deploymentAvailable:
                            type: object
                            required: ["name"]
                            properties:
                              name: { type: string, minLength: 1 }
                              minAvailableReplicas: { type: integer, minimum: 0, default: 1 }
                          statefulSetReady:
                            type: object
                            required: ["name"]
                            properties:
                              name: { type: string, minLength: 1 }
                              minReadyReplicas: { type: integer, minimum: 0, default: 1 }
                              requireUpdatedRevision: { type: boolean, default: true }
                          jobComplete:
                            type: object
                            required: ["name"]
                            properties:
                              name: { type: string, minLength: 1 }
                          serviceReadyEndpoints:
                            type: object
                            required: ["name"]
                            properties:
                              name: { type: string, minLength: 1 }
                              minReadyAddresses: { type: integer, minimum: 0, default: 1 }
                          podLabelReady:
                            type: object
                            required: ["selector"]
                            properties:
                              selector: { type: string, minLength: 1 }
                              minReadyPods: { type: integer, minimum: 0, default: 1 }
                          argoApplicationHealthy:
                            type: object
                            required: ["name"]
                            properties:
                              name: { type: string, minLength: 1 }
                              requireSynced: { type: boolean, default: true }
                              requireHealthy: { type: boolean, default: true }
                status:
                  type: object
                  properties:
                    observedGeneration: { type: integer }
                    ready: { type: boolean }
                    lastEvaluatedTime: { type: string, format: date-time }
                    results:
                      type: array
                      items:
                        type: object
                        required: ["id", "ready"]
                        properties:
                          id: { type: string }
                          ready: { type: boolean }
                          message: { type: string }

  - apiVersion: v1
    kind: Namespace
    metadata:
      name: glueops-core-gatekeeper
      labels:
        gatekeeper.platform.glueops.dev/mode: platform

  - apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: glueops-core-gatekeeper
      namespace: glueops-core-gatekeeper

  - apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRole
    metadata:
      name: glueops-core-gatekeeper
    rules:
      - apiGroups: ["platform.glueops.dev"]
        resources: ["gates"]
        verbs: ["get"]
      - apiGroups: ["platform.glueops.dev"]
        resources: ["gates/status"]
        verbs: ["patch", "update"]
      - apiGroups: ["authentication.k8s.io"]
        resources: ["tokenreviews"]
        verbs: ["create"]
      - apiGroups: ["authorization.k8s.io"]
        resources: ["subjectaccessreviews"]
        verbs: ["create"]
      - apiGroups: ["apps"]
        resources: ["deployments", "statefulsets"]
        verbs: ["get"]
      - apiGroups: ["batch"]
        resources: ["jobs"]
        verbs: ["get"]
      - apiGroups: [""]
        resources: ["services"]
        verbs: ["get"]
      - apiGroups: [""]
        resources: ["pods"]
        verbs: ["list"]
      - apiGroups: [""]
        resources: ["namespaces"]
        verbs: ["get"]
      - apiGroups: ["discovery.k8s.io"]
        resources: ["endpointslices"]
        verbs: ["list"]
      - apiGroups: ["argoproj.io"]
        resources: ["applications"]
        verbs: ["get", "list", "watch"]

  - apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      name: glueops-core-gatekeeper
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: glueops-core-gatekeeper
    subjects:
      - kind: ServiceAccount
        name: glueops-core-gatekeeper
        namespace: glueops-core-gatekeeper

  - apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: gatekeeper
      namespace: glueops-core-gatekeeper
    spec:
      replicas: 1
      selector:
        matchLabels:
          app.kubernetes.io/name: gatekeeper
      template:
        metadata:
          labels:
            app.kubernetes.io/name: gatekeeper
        spec:
          serviceAccountName: glueops-core-gatekeeper
          nodeSelector:
            glueops.dev/role: glueops-platform
          tolerations:
            - key: "glueops.dev/role"
              operator: "Equal"
              value: "glueops-platform"
              effect: "NoSchedule"
          containers:
            - name: gatekeeper
              image: "ghcr.repo.gpkg.io/glueops/platform-gatekeeper:placeholder_gatekeeper_tag"
              imagePullPolicy: IfNotPresent
              ports:
                - containerPort: 8080
                  name: http
                  protocol: TCP
              env:
                - name: PORT
                  value: "8080"
                - name: GATEKEEPER_PLATFORM_ALLOWED_NAMESPACES
                  value: "placeholder_gatekeeper_platform_allowed_namespaces"
                - name: GATEKEEPER_PLATFORM_ALLOWED_NAMESPACE_PREFIXES
                  value: "glueops-core-"
              resources:
                requests:
                  cpu: 10m
                  memory: 32Mi
                limits:
                  cpu: 100m
                  memory: 128Mi

  - apiVersion: v1
    kind: Service
    metadata:
      name: gatekeeper
      namespace: glueops-core-gatekeeper
    spec:
      type: ClusterIP
      selector:
        app.kubernetes.io/name: gatekeeper
      ports:
        - name: http
          port: 8080
          targetPort: 8080
          protocol: TCP
