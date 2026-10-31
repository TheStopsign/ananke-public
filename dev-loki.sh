#!/usr/bin/env zsh
set -eu
set +x

# Grafana Loki (Logs)
echo "🧵 installing Grafana Loki for logs..."
kubectl apply -f mgmt/loki.yaml