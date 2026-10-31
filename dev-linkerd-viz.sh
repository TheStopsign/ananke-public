#!/usr/bin/env zsh
set -eu
set +x

# Linkerd Viz
echo "🧵 installing linkerd viz..."
kubectl apply -f mgmt/linkerd-viz.yaml