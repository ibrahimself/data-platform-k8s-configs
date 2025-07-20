#!/bin/bash

# Sync All ArgoCD Applications
# This script syncs all data platform applications in ArgoCD

set -e

echo "=============================================="
echo "Syncing All Data Platform Applications"
echo "=============================================="
echo ""

# Check if ArgoCD CLI is available
if ! command -v argocd &> /dev/null; then
    echo "❌ ArgoCD CLI not found. Using kubectl instead."
    USE_KUBECTL=true
else
    echo "✅ ArgoCD CLI found"
    USE_KUBECTL=false
    
    # Check if logged in
    if ! argocd account get-user-info &> /dev/null; then
        echo "⚠️  Not logged into ArgoCD. Run ./access-argocd.sh first"
        USE_KUBECTL=true
    fi
fi

# List of applications to sync
APPS=(
    "monitoring-stack"
    "spark-operator"
    "dremio-enterprise"
    "apache-airflow"
)

echo ""
echo "Applications to sync:"
for app in "${APPS[@]}"; do
    echo "  - $app"
done
echo ""

# Function to sync using kubectl
sync_with_kubectl() {
    local app=$1
    echo "Syncing $app with kubectl..."
    kubectl patch application "$app" -n argocd --type merge -p '{"operation": {"sync": {"revision": "HEAD","prune": true,"syncStrategy": {"hook": {}}}}}'
}

# Function to sync using argocd CLI
sync_with_argocd() {
    local app=$1
    echo "Syncing $app with argocd CLI..."
    argocd app sync "$app" --prune
}

# Sync each application
for app in "${APPS[@]}"; do
    echo ""
    echo "🔄 Syncing $app..."
    
    # Check if application exists
    if ! kubectl get application "$app" -n argocd &> /dev/null; then
        echo "⚠️  Application $app not found. Skipping..."
        continue
    fi
    
    # Sync based on available tool
    if [ "$USE_KUBECTL" = true ]; then
        sync_with_kubectl "$app"
    else
        sync_with_argocd "$app"
    fi
    
    # Wait a bit between syncs
    echo "✅ Sync initiated for $app"
    sleep 5
done

echo ""
echo "=============================================="
echo "Checking sync status..."
echo "=============================================="
echo ""

# Wait for syncs to start
sleep 10

# Check status
if [ "$USE_KUBECTL" = true ]; then
    kubectl get applications -n argocd -o custom-columns=NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status,MESSAGE:.status.conditions[0].message | column -t
else
    argocd app list
fi

echo ""
echo "=============================================="
echo "Sync process complete!"
echo "=============================================="
echo ""
echo "Tips:"
echo "  - Check individual app status: kubectl describe application <app-name> -n argocd"
echo "  - View app logs: kubectl logs -n <namespace> -l app=<app-name>"
echo "  - Force refresh: kubectl patch application <app-name> -n argocd --type merge -p '{\"metadata\":{\"annotations\":{\"argocd.argoproj.io/refresh\":\"true\"}}}'"
echo ""