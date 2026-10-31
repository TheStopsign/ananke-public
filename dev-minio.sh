#!/usr/bin/env zsh
set -eu
set +x

# Grafana Tempo (Traces/Spans)
echo "🧵 installing Grafana Tempo for traces/spans..."
kubectl apply -f mgmt/minio.yaml
kubens argocd
argocd app wait minio
kubens default