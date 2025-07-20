#!/bin/bash

# ArgoCD Access Script
# Provides easy access to ArgoCD UI and CLI

set -e

# Configuration from deployment
LOADBALANCER_URL="ac618c1d3fad4460b9c904d814a8ee5f-322a8e478d5b0046.elb.eu-west-3.amazonaws.com"
ARGOCD_PASSWORD="rrtjpXygbDmfOB3Y"
NAMESPACE="argocd"

echo "====================================="
echo "ArgoCD Access Information"
echo "====================================="
echo ""
echo "ArgoCD UI URL: http://${LOADBALANCER_URL}"
echo "Username: admin"
echo "Password: ${ARGOCD_PASSWORD}"
echo ""
echo "====================================="
echo ""

# Check if argocd CLI is installed
if command -v argocd &> /dev/null; then
    echo "Logging into ArgoCD CLI..."
    argocd login "${LOADBALANCER_URL}" \
        --username admin \
        --password "${ARGOCD_PASSWORD}" \
        --insecure \
        --grpc-web
    
    echo ""
    echo "ArgoCD CLI configured successfully!"
    echo ""
    echo "Useful commands:"
    echo "  argocd app list"
    echo "  argocd app sync <app-name>"
    echo "  argocd app get <app-name>"
    echo "  argocd app logs <app-name>"
else
    echo "ArgoCD CLI not installed. To install:"
    echo ""
    echo "curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64"
    echo "chmod +x /usr/local/bin/argocd"
fi