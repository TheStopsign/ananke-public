#!/usr/bin/env zsh
set -eu
set +x

# Grafana Tempo (Traces/Spans)
echo "🧵 installing Grafana Tempo for traces/spans..."
kubectl apply -f mgmt/tempo.yaml
kubens argocd
argocd app wait tempo
kubens default