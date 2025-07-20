# Data Platform K8s Configs

This repository contains all Kubernetes configurations for our data platform, deployed via ArgoCD ApplicationSet.

## Structure

- `argocd-apps/`: Contains all applications that ArgoCD will deploy
- `values/`: Shared Helm values files for reference

## Applications

| Application | Purpose | Namespace |
|------------|---------|-----------|
| monitoring | Prometheus & Grafana stack | monitoring |
| spark | Distributed processing | spark |
| airflow | Workflow orchestration | airflow |
| dremio | Data lakehouse platform | dremio |

## Deployment

Applications are automatically deployed by ArgoCD ApplicationSet when directories are added to `argocd-apps/`.

## Access

### Monitoring
- Grafana: `kubectl port-forward -n monitoring svc/prometheus-stack-grafana 3000:80`
- Prometheus: `kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-prometheus 9090:9090`

### Other Services
See individual app directories for access instructions.