#!/usr/bin/env zsh
set -eu
set +x

# Grafana (Dashboards)
echo "🧵 installing grafana..."
kubectl apply -f mgmt/grafana.yaml

# kubectl rollout status -n grafana deployment/grafana -w
# kubectl get deploy -n grafana grafana -o yaml | linkerd inject - | kubectl apply -f -
# kubectl rollout status -n grafana deployment/grafana -w