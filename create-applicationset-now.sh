#!/bin/bash

# Script to apply ArgoCD ApplicationSet and verify deployment

set -e

echo "=== Applying ArgoCD ApplicationSet ==="
echo

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if ApplicationSet YAML exists from Ansible deployment
APPSET_FILE="$HOME/platform-deployment/argocd-applicationset-apps.yaml"

if [ -f "$APPSET_FILE" ]; then
    echo -e "${GREEN}✅ Found ApplicationSet file from Ansible deployment${NC}"
    echo -e "${BLUE}📋 Content:${NC}"
    cat "$APPSET_FILE"
    echo
    echo -e "${BLUE}Applying ApplicationSet...${NC}"
    kubectl apply -f "$APPSET_FILE"
    echo -e "${GREEN}✅ ApplicationSet applied${NC}"
else
    echo -e "${YELLOW}⚠️  ApplicationSet file not found at $APPSET_FILE${NC}"
    echo -e "${BLUE}Creating ApplicationSet directly...${NC}"
    
    # Create ApplicationSet directly
    kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: data-platform-apps
  namespace: argocd
spec:
  generators:
  - git:
      repoURL: git@github.com:ibrahimself/data-platform-k8s-configs.git
      revision: HEAD
      directories:
      - path: argocd-apps/*
  template:
    metadata:
      name: "{{path.basename}}"
    spec:
      project: data-platform
      source:
        repoURL: git@github.com:ibrahimself/data-platform-k8s-configs.git
        targetRevision: HEAD
        path: "{{path}}"
      destination:
        server: https://kubernetes.default.svc
        namespace: "{{path.basename}}"
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
        - CreateNamespace=true
EOF
    echo -e "${GREEN}✅ ApplicationSet created${NC}"
fi

# Wait a moment for ApplicationSet controller to process
echo
echo -e "${BLUE}⏳ Waiting for ApplicationSet controller to process...${NC}"
sleep 5

# Check ApplicationSet status
echo
echo -e "${BLUE}📊 Checking ApplicationSet status...${NC}"
kubectl get applicationset -n argocd
echo

# Check if ApplicationSet is generating applications
echo -e "${BLUE}🔍 Checking generated applications...${NC}"
kubectl get applications -n argocd

# Get more details about the ApplicationSet
echo
echo -e "${BLUE}📋 ApplicationSet details:${NC}"
kubectl describe applicationset data-platform-apps -n argocd | grep -A 10 "Status:"

# Check ApplicationSet controller logs for any errors
echo
echo -e "${BLUE}📜 Recent ApplicationSet controller logs:${NC}"
kubectl logs -n argocd deployment/argocd-applicationset-controller --tail=20

# List directories in the repo (if accessible)
echo
echo -e "${BLUE}🔍 Checking what the ApplicationSet should discover:${NC}"
echo "The ApplicationSet will create apps for these directories:"
echo "- argocd-apps/monitoring"
echo "- argocd-apps/dremio"

# Summary
echo
echo -e "${GREEN}=== Summary ===${NC}"
echo "✅ ApplicationSet is now active and watching your repo"
echo
echo -e "${YELLOW}If you don't see applications yet:${NC}"
echo "1. Check that your GitHub repo has directories under 'argocd-apps/'"
echo "2. Ensure the repo is accessible (SSH key is configured)"
echo "3. Check for sync errors in ArgoCD UI"
echo
echo -e "${BLUE}To manually refresh:${NC}"
echo "  argocd app list"
echo "  argocd appset list"
echo
echo -e "${BLUE}To force a refresh:${NC}"
echo "  kubectl delete pod -n argocd -l app.kubernetes.io/name=argocd-applicationset-controller"