#!/usr/bin/env zsh
set -eu
set +x

# QOTM
echo "🧵 installing QOTM Deployment, Mapping..."
kubectl apply -f ./mgmt/qotm.yaml