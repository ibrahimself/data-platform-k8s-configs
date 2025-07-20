# Data Platform Deployment Instructions

## Infrastructure Overview

### AWS Infrastructure (from Terraform)
- **Account ID**: 399883341639
- **Region**: eu-west-3
- **EKS Cluster**: data-platform
- **Node Groups**:
  - system: Control plane and system services
  - compute: Spark and processing workloads
  - analytics: Dremio and analytical workloads

### Deployed Components (from Ansible)
- **LoadBalancer URL**: ac618c1d3fad4460b9c904d814a8ee5f-322a8e478d5b0046.elb.eu-west-3.amazonaws.com
- **ArgoCD Password**: rrtjpXygbDmfOB3Y
- **Namespaces**: airflow, argocd, cert-manager, dremio, monitoring, nifi, openmetadata, spark

## Step-by-Step Deployment Guide

### 1. Setup CodeCommit Repository

```bash
# Run the setup script
./setup-codecommit-only.sh

# This will:
# - Create CodeCommit repository: data-platform-k8s-configs
# - Generate Git credentials
# - Create directory structure
```

### 2. Copy Configuration Files

Copy the provided YAML files to their respective directories:
```bash
cp airflow-values.yaml data-platform-k8s-configs/airflow/values.yaml
cp argocd-applications.yaml data-platform-k8s-configs/argocd/applications.yaml
cp dremio-values.yaml data-platform-k8s-configs/dremio/values.yaml
cp monitoring-values.yaml data-platform-k8s-configs/monitoring/values.yaml
cp spark-values.yaml data-platform-k8s-configs/spark/values.yaml
```

### 3. Update Sensitive Values

Before committing, update these values in the YAML files:

#### airflow/values.yaml
- Line 92: `password: "changeme123!"` - Update Airflow admin password
- Line 143: `pass: "YOUR_DB_PASSWORD"` - Update RDS password

#### monitoring/values.yaml
- Line 95: `adminPassword: "changeme123!"` - Update Grafana admin password
- Line 272-276: Configure Slack webhook for critical alerts (currently commented)

#### argocd/applications.yaml
- Line 78-79: Update CodeCommit credentials from codecommit-credentials.txt

### 4. Create Missing IAM Roles

Two IAM roles need to be created:

```bash
# Create Airflow S3 Access Role
aws iam create-role --role-name data-platform-airflow-s3-access \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::399883341639:oidc-provider/oidc.eks.eu-west-3.amazonaws.com/id/7779E7B1C039797EE701B635F04CC99B"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.eu-west-3.amazonaws.com/id/7779E7B1C039797EE701B635F04CC99B:sub": "system:serviceaccount:airflow:airflow"
        }
      }
    }]
  }'

# Attach S3 policy
aws iam attach-role-policy --role-name data-platform-airflow-s3-access \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess

# Create Prometheus S3 Access Role (optional, for remote storage)
aws iam create-role --role-name data-platform-prometheus-s3-access \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::399883341639:oidc-provider/oidc.eks.eu-west-3.amazonaws.com/id/7779E7B1C039797EE701B635F04CC99B"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.eu-west-3.amazonaws.com/id/7779E7B1C039797EE701B635F04CC99B:sub": "system:serviceaccount:monitoring:prometheus"
        }
      }
    }]
  }'

# Attach S3 policy
aws iam attach-role-policy --role-name data-platform-prometheus-s3-access \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
```

### 5. Commit and Push to CodeCommit

```bash
cd data-platform-k8s-configs
git add .
git commit -m "Add data platform configurations"
git push -u origin main
```

### 6. Deploy Applications via ArgoCD

```bash
# Apply ArgoCD applications
kubectl apply -f argocd/applications.yaml

# Check application status
kubectl get applications -n argocd

# Access ArgoCD UI
./scripts/access-argocd.sh
```

## Access URLs

All services are accessible via the LoadBalancer:

- **ArgoCD**: http://ac618c1d3fad4460b9c904d814a8ee5f-322a8e478d5b0046.elb.eu-west-3.amazonaws.com
  - Username: admin
  - Password: rrtjpXygbDmfOB3Y

After deployment, services will be available at:
- **Airflow**: http://<loadbalancer>/airflow
- **Dremio**: http://<loadbalancer>/dremio
- **Grafana**: http://<loadbalancer>/grafana
- **Prometheus**: http://<loadbalancer>/prometheus

## Monitoring Deployment

1. **Via ArgoCD UI**:
   - Login to ArgoCD
   - Monitor application sync status
   - Check for any sync errors

2. **Via CLI**:
   ```bash
   # Watch application status
   watch kubectl get applications -n argocd
   
   # Check specific application
   kubectl describe application apache-airflow -n argocd
   
   # View pod status
   kubectl get pods -n airflow
   kubectl get pods -n dremio
   kubectl get pods -n spark
   kubectl get pods -n monitoring
   ```

## Troubleshooting

### CodeCommit Authentication Issues
```bash
# Reset credentials
aws iam delete-service-specific-credential \
  --user-name <your-iam-user> \
  --service-specific-credential-id <credential-id>

# Create new credentials
aws iam create-service-specific-credential \
  --user-name <your-iam-user> \
  --service-name codecommit.amazonaws.com
```

### ArgoCD Sync Issues
```bash
# Force sync
argocd app sync <app-name>

# Check logs
kubectl logs -n argocd deployment/argocd-server
kubectl logs -n argocd deployment/argocd-repo-server
```

### Application Issues
```bash
# Check pod events
kubectl describe pod <pod-name> -n <namespace>

# Check logs
kubectl logs <pod-name> -n <namespace>

# Check helm release
helm list -n <namespace>
```

## Security Reminders

1. **Change all default passwords** before production use
2. **Configure proper network policies** for namespace isolation
3. **Enable audit logging** on the EKS cluster
4. **Set up backup policies** for persistent volumes
5. **Configure SSL/TLS** for all web interfaces
6. **Implement secret rotation** for credentials

## Next Steps

1. Configure ingress rules for proper path-based routing
2. Set up DNS records for services
3. Configure backup and disaster recovery
4. Set up CI/CD pipelines for DAGs and Spark jobs
5. Configure data governance policies in Dremio
6. Set up monitoring dashboards in Grafana

---

Generated: $(date)