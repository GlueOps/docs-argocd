# argocd-otel-extension-api

Backend service for the ArgoCD OTEL UI extension. It proxies Prometheus and Tempo endpoints so the extension frontend can query metrics and traces without direct cluster network access.

## Endpoints

| Path | Proxied to |
|------|------------|
| `GET /healthz` | Local health check — returns `{"status":"ok"}` |
| `ANY /prometheus/*` | `PROMETHEUS_BASE_URL/*` (path prefix stripped) |
| `ANY /tempo/*` | `TEMPO_BASE_URL/*` (path prefix stripped) |

### Prometheus example
```
GET /prometheus/api/v1/query?query=up
```
Proxied to `$PROMETHEUS_BASE_URL/api/v1/query?query=up`.

### Tempo example
```
GET /tempo/api/search?tags=service.name%3Dmyapp
```
Proxied to `$TEMPO_BASE_URL/api/search?tags=service.name%3Dmyapp`.

## Environment variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `PORT` | No | `8000` | Port the server listens on |
| `PROMETHEUS_BASE_URL` | Yes (for metrics) | `""` | In-cluster Prometheus base URL, e.g. `http://kps-prometheus.glueops-core-kube-prometheus-stack.svc.cluster.local:9090` |
| `TEMPO_BASE_URL` | No | `""` | In-cluster Tempo base URL, e.g. `http://tempo.glueops-core-tempo.svc.cluster.local:3200`. Leave empty to disable trace proxying. |
| `LOG_LEVEL` | No | `INFO` | Log verbosity: `DEBUG`, `INFO`, `WARN`, or `ERROR` |

## Running locally

```bash
npm install
PROMETHEUS_BASE_URL=http://localhost:9090 node src/server.js
```

## Container image

The image is published to GHCR on every release:
```
ghcr.io/glueops/argocd-otel-extension-api:<tag>
```
