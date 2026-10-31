#!/usr/bin/env zsh
set -eu
set +x

# Multicluster
echo "🧵 installing Multicluster..."
kubectl apply -f mgmt/linkerd-multicluster.yaml