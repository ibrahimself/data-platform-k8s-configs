cat ~/.ssh/id_ed25519
ll ~/.ssh/id_ed25519
# First, make sure you have your private key
cat ~/.ssh/id_ed25519
# Create the repository secret properly
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: github-repo-private
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
type: Opaque
stringData:
  type: git
  url: git@github.com:ibrahimself/data-platform-k8s-configs.git
  sshPrivateKey: |
$(cat ~/.ssh/id_ed25519 | sed 's/^/    /')
EOF

# Get GitHub's SSH host key
ssh-keyscan github.com > /tmp/github-known-hosts

# Create the known hosts ConfigMap
kubectl create configmap argocd-ssh-known-hosts-cm \
  --from-file=ssh_known_hosts=/tmp/github-known-hosts \
  -n argocd \
  --dry-run=client -o yaml | kubectl apply -f -

# Restart ArgoCD repo server to pick up the changes
kubectl rollout restart deployment argocd-repo-server -n argocd
