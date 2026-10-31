#!/usr/bin/env zsh
set -eu
set +x

# Promtail (Log Exporter)
echo "🧵 installing promtail..."
kubectl apply -f mgmt/promtail.yaml
echo "🧵 installed promtail."