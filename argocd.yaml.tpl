crds:
  install: false

# @ignored
notifications:
  metrics:
    enabled: true

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
  # Pin every first-party argo-cd component to the glueops-platform nodes from one
  # place: components without their own affinity inherit this preset; components that
  # set their own affinity (e.g. controller) override it. The redis-ha subchart and the
  # gatekeeper extraObject are not reached by global and keep their own settings.
  affinity:
    podAntiAffinity: soft
    nodeAffinity:
      type: hard
      matchExpressions:
        - key: "glueops.dev/role"
          operator: In
          values:
            - "glueops-platform"
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
  # nodeSelector applies to the redis-ha server, haproxy, AND the chart's
  # helm-test pods (which only honor nodeSelector, not additionalAffinities),
  # keeping every redis-ha pod on the glueops-platform nodes.
  nodeSelector:
    glueops.dev/role: "glueops-platform"
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
# @ignored
applicationSet:
  metrics:
    enabled: true
  replicas: 2
configs:
  params:
    server.insecure: true
    # Always true: the OTEL extension ships to every cluster. Required for
    # argocd-server to proxy the extension's calls to its backend.
    server.enable.proxy.extension: true
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
    # Application health assessment only takes effect for Applications that are children of another Application (e.g. tenant apps under captain-manifests); the platform chart's own Applications are created by Helm and have no parent.
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
      # Accept the edge token minted for the public "toolbox" Dex client, which
      # platform-helm-chart-platform creates on every cluster. GlueOps/toolbox is
      # the CLI that mints and presents it. One token then satisfies both
      # oauth2-proxy at the edge and ArgoCD itself, so no loopback callback is
      # needed -- which is what makes the CLI usable from a machine whose browser
      # lives somewhere else.
      #
      # The CLI must send that token in BOTH headers, because each side reads only
      # its own: ARGOCD_AUTH_TOKEN becomes "Token:" for ArgoCD, and a separate
      # "Authorization: Bearer" is what oauth2-proxy reads. Sending only the env
      # var gets a login redirect the CLI reports as "rpc error: unexpected EOF".
      #
      # This REPLACES the default audience check rather than extending it, so
      # "argocd" must stay listed or browser UI login breaks for everyone.
      allowedAudiences:
        - argocd
        - toolbox
    # The Argo CD OTEL observability extension is always installed -- there is no
    # enable/disable input. The backend Service DNS is the SAME on every cluster:
    # both the Service name and its namespace are hardcoded constants in
    # platform-helm-chart-platform (templates/application-argocd-extension-backend.yaml),
    # not derived from captain_domain or the cluster environment, so there is
    # deliberately nothing per-cluster to substitute here. The namespace is
    # glueops-core-argocd-extension-backend -- the Application's destination
    # namespace -- NOT glueops-core, which does not resolve.
    extension.config: |
      extensions:
        - name: otel-extension
          backend:
            services:
              - url: http://argocd-extension-backend-api.glueops-core-argocd-extension-backend.svc.cluster.local:8000
  rbac:
    # -- A good reference for this is: https://argo-cd.readthedocs.io/en/stable/operator-manual/rbac/
    # This default policy is for GlueOps orgs/teams only. Please change it to reflect your own orgs/teams.
    # `development` is the project that all developers are expected to deploy under
    # @default -- `''` (See [values.yaml])
    policy.csv: |
      placeholder_argocd_rbac_policies
      p, role:readonly, extensions, invoke, otel-extension, allow
      p, role:admin, extensions, invoke, otel-extension, allow
  # @ignored
server:
  extensions:
    enabled: true
    # The chart defaults this installer image to quay.io directly, unlike every
    # other image on the platform. Pin it to the gpkg mirror so clusters that
    # cannot egress to quay.io (or that would hit its rate limits) still start:
    # this runs as an initContainer on argocd-server, so a failed pull takes the
    # Argo CD UI down rather than just disabling the extension.
    image:
      repository: quay.repo.gpkg.io/argoprojlabs/argocd-extension-installer
    extensionList:
      - name: otel-extension
        env:
          - name: EXTENSION_URL
            value: "https://github.com/GlueOps/argo-cd-ui-extention/releases/download/placeholder_otel_extension_version/extension.tar.gz"
          - name: EXTENSION_VERSION
            value: "placeholder_otel_extension_semver"
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
      # oauth2-with-redirect-bearer and oauth2-api are created by the GlueOps
      # platform chart, not here. On an UPGRADE, deploy the platform chart before
      # this one: Traefik drops a router whose middleware does not exist, so
      # argocd.<domain> answers 404 -- browser UI included -- until the middleware
      # is there. It is fail-closed, not an auth bypass, and self-heals as soon as
      # the platform chart lands.
      traefik.ingress.kubernetes.io/router.middlewares: glueops-core-oauth2-proxy-oauth2-with-redirect-bearer@kubernetescrd
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
        traefik.ingress.kubernetes.io/router.middlewares: glueops-core-oauth2-proxy-oauth2-api@kubernetescrd
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
                  value: "glueops-core,placeholder_cluster_environment"
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
