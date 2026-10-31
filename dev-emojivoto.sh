#!/usr/bin/env zsh
set -eu
set +x

# Emoji Voto
linkerd inject https://run.linkerd.io/emojivoto.yml | kubectl apply -f -
kubectl -n emojivoto rollout status deploy/web
kubectl -n emojivoto set env --all deploy OC_AGENT_HOST=collector.linkerd-jaeger:55678
kubectl apply -f mgmt/emojivoto-mapping.yaml