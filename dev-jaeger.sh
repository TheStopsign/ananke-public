#!/usr/bin/env zsh
set -eu
set +x

# Jaeger
echo "🧵 installing Jaeger..."
kubectl apply -f mgmt/linkerd-jaeger.yaml