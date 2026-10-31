#!/usr/bin/env zsh
set -eu
set +x

# Kyverno
echo "🧵 installing kyverno..."
kubectl apply -f mgmt/kyverno.yaml
kubens argocd
argocd app wait kyverno
kubens default