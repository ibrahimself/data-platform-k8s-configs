#!/bin/bash

# Platform Status Check Script
# Checks the status of all data platform components

set -e

echo "=============================================="
echo "Data Platform Status Check"
echo "=============================================="
echo ""

# Check cluster connectivity
echo "🔍 Checking cluster connectivity..."
if kubectl cluster-info &> /dev/null; then
    echo "✅ Connected to cluster"
    kubectl cluster-info | grep "Kubernetes control plane"
else
    echo "❌ Cannot connect to cluster"
    exit 1
fi
echo ""

# Check nodes
echo "🔍 Checking node status..."
echo "Nodes:"
kubectl get nodes -o wide | grep -E "(NAME|Ready)" || echo "No nodes found"
echo ""

# Check namespaces
echo "🔍 Checking namespaces..."
NAMESPACES=("argocd" "airflow" "dremio" "spark" "monitoring" "nifi" "openmetadata")
for ns in "${NAMESPACES[@]}"; do
    if kubectl get namespace "$ns" &> /dev/null; then
        echo "✅ Namespace $ns exists"
    else
        echo "❌ Namespace $ns not found"
    fi
done
echo ""

# Check ArgoCD applications
echo "🔍 Checking ArgoCD applications..."
if kubectl get applications -n argocd &> /dev/null; then
    echo "ArgoCD Applications:"
    kubectl get applications -n argocd -o custom-columns=NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status,REVISION:.status.sync.revision | column -t
else
    echo "⚠️  No ArgoCD applications found"
fi
echo ""

# Check pods in each namespace
echo "🔍 Checking pods in application namespaces..."
for ns in "${NAMESPACES[@]}"; do
    echo ""
    echo "Namespace: $ns"
    echo "----------------------------------------"
    POD_COUNT=$(kubectl get pods -n "$ns" --no-headers 2>/dev/null | wc -l)
    if [ "$POD_COUNT" -gt 0 ]; then
        kubectl get pods -n "$ns" -o custom-columns=NAME:.metadata.name,READY:.status.conditions[?(@.type==\"Ready\")].status,STATUS:.status.phase,RESTARTS:.status.containerStatuses[*].restartCount,AGE:.metadata.creationTimestamp --no-headers | column -t
    else
        echo "No pods running in $ns"
    fi
done
echo ""

# Check services
echo "🔍 Checking services..."
echo "LoadBalancer Services:"
kubectl get svc -A | grep LoadBalancer | awk '{print $1 " " $2 " " $5}' | column -t || echo "No LoadBalancer services found"
echo ""

# Check ingress
echo "🔍 Checking ingress resources..."
kubectl get ingress -A --no-headers 2>/dev/null | awk '{print $1 " " $2 " " $4}' | column -t || echo "No ingress resources found"
echo ""

# Check persistent volumes
echo "🔍 Checking persistent volumes..."
PVC_COUNT=$(kubectl get pvc -A --no-headers 2>/dev/null | wc -l)
if [ "$PVC_COUNT" -gt 0 ]; then
    echo "Persistent Volume Claims:"
    kubectl get pvc -A -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,STATUS:.status.phase,SIZE:.spec.resources.requests.storage,STORAGECLASS:.spec.storageClassName --no-headers | column -t
else
    echo "No persistent volume claims found"
fi
echo ""

# Summary
echo "=============================================="
echo "Summary"
echo "=============================================="
echo ""

# Count running pods
TOTAL_PODS=$(kubectl get pods -A --no-headers 2>/dev/null | wc -l)
RUNNING_PODS=$(kubectl get pods -A --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
echo "Total Pods: $TOTAL_PODS"
echo "Running Pods: $RUNNING_PODS"
echo ""

# Get LoadBalancer URL
LB_URL=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "Not found")
if [ "$LB_URL" != "Not found" ]; then
    echo "🌐 LoadBalancer URL: http://$LB_URL"
    echo ""
    echo "Access URLs:"
    echo "  ArgoCD: http://$LB_URL"
    echo "  Airflow: http://$LB_URL/airflow (after deployment)"
    echo "  Dremio: http://$LB_URL/dremio (after deployment)"
    echo "  Grafana: http://$LB_URL/grafana (after deployment)"
fi
echo ""

echo "=============================================="
echo "Status check complete!"
echo "=============================================="