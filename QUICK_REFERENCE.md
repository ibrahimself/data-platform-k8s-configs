# Data Platform Quick Reference

## 🚀 Key Information

### AWS Infrastructure
```
Account ID: 399883341639
Region: eu-west-3
Cluster: data-platform
```

### S3 Buckets
```
Data Lake: data-platform-data-lake-s3d92803
Artifacts: data-platform-artifacts-s3d92803
Logs: data-platform-logs-s3d92803
Backups: data-platform-backups-s3d92803
```

### Access URLs
```
LoadBalancer: ac618c1d3fad4460b9c904d814a8ee5f-322a8e478d5b0046.elb.eu-west-3.amazonaws.com
ArgoCD: http://ac618c1d3fad4460b9c904d814a8ee5f-322a8e478d5b0046.elb.eu-west-3.amazonaws.com
Username: admin
Password: rrtjpXygbDmfOB3Y
```

## 📋 Quick Commands

### Check Platform Status
```bash
./scripts/check-platform-status.sh
```

### Access ArgoCD
```bash
./scripts/access-argocd.sh
```

### Sync All Applications
```bash
./scripts/sync-all-apps.sh
```

### Check Application Pods
```bash
kubectl get pods -n airflow
kubectl get pods -n dremio
kubectl get pods -n spark
kubectl get pods -n monitoring
```

### View Application Logs
```bash
kubectl logs -n airflow -l component=webserver
kubectl logs -n dremio -l app=dremio
kubectl logs -n spark -l app.kubernetes.io/name=spark-operator
kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus
```

## 🔧 Common Tasks

### Update Application Configuration
1. Edit values.yaml in the respective directory
2. Commit and push to CodeCommit
3. ArgoCD will auto-sync (or manually sync)

### Force Application Sync
```bash
# Using ArgoCD CLI
argocd app sync <app-name>

# Using kubectl
kubectl patch application <app-name> -n argocd --type merge \
  -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"true"}}}'
```

### Scale Applications
```bash
# Scale Dremio executors
kubectl scale deployment dremio-executor -n dremio --replicas=5

# Scale Airflow workers (if using CeleryExecutor)
kubectl scale deployment airflow-worker -n airflow --replicas=3
```

### Check Resource Usage
```bash
# Node resources
kubectl top nodes

# Pod resources
kubectl top pods -n <namespace>
```

## 🔐 Security Checklist

- [ ] Change default passwords (Airflow, Grafana)
- [ ] Update RDS password in Airflow config
- [ ] Configure Slack webhook for alerts
- [ ] Create missing IAM roles (Airflow, Prometheus)
- [ ] Update CodeCommit credentials in ArgoCD
- [ ] Enable network policies
- [ ] Configure SSL/TLS for services

## 🆘 Troubleshooting

### Pod Not Starting
```bash
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> --previous
```

### ArgoCD Sync Failed
```bash
# Check application details
kubectl describe application <app-name> -n argocd

# Check ArgoCD logs
kubectl logs -n argocd deployment/argocd-repo-server
kubectl logs -n argocd deployment/argocd-application-controller
```

### Service Not Accessible
```bash
# Check service endpoints
kubectl get svc -n <namespace>
kubectl get endpoints -n <namespace>

# Check ingress
kubectl get ingress -n <namespace>
kubectl describe ingress <ingress-name> -n <namespace>
```

### Out of Resources
```bash
# Check node capacity
kubectl describe nodes | grep -A 5 "Allocated resources"

# Check resource quotas
kubectl get resourcequota -A
```

## 📞 Support Contacts

Update this section with your team's contact information:
- Platform Team: platform-team@company.com
- On-Call: +1-XXX-XXX-XXXX
- Slack: #data-platform-support

---
Last Updated: Generated at deployment time