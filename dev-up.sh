#!/usr/bin/env zsh
set -eu
set +x

# ZSH_VERSION=${ZSH_VERSION:-}
# source ~/.zshrc

alias kubectx="kubectl ctx"
alias kubens="kubectl ns"

source ./dev-vars.sh

# +----------------------+
# | Start Infrastructure |
# +----------------------+

# Management Cluster
source ./dev-down.sh
k3d cluster create "${mgmt_cluster}" \
    --network=ananke \
    --k3s-arg='--disable=traefik,metrics-server@server:*' \
    --kubeconfig-update-default \
    --kubeconfig-switch-context=false

sleep 2
kubectl -n kube-system wait --for condition=available --timeout=180s deploy coredns
kubectl -n kube-system wait --for condition=available --timeout=180s deploy local-path-provisioner

kubectx
kubens

# ArgoCD
source dev-argocd.sh

# Ambassador - Edge Stack (Ingress)
source dev-ambassador.sh

# /etc/hosts
source dev-hosts.sh

# Linkerd (Service Mesh, Load Balancing, Multi-Cluster, Failovers)
source dev-linkerd-argocd.sh

# Linkerd Multicluster
source dev-mc.sh

# Promtail (Log Exporter)
source dev-promtail.sh

# Grafana
source dev-grafana.sh

# Linkerd 
source dev-linkerd-viz.sh

# Grafana Loki (Logs)
source dev-loki.sh

# Minio
source dev-minio.sh

# Grafana Tempo (Traces/Spans)
source dev-tempo.sh

# Jaeger
source dev-jaeger.sh

# Kyverno
source dev-kyverno.sh

# +----------------------+
# |  End Infrastructure  |
# +----------------------+



# +---------------+
# | Start Testing |
# +---------------+

# # QOTM
# source dev-qotm.sh

# # Emoji Voto
# source dev-emojivoto.sh

# +---------------+
# |  End Testing  |
# +---------------+



# +-----------------+
# | Start Workloads |
# +-----------------+

# vClusters
source dev-vclusters.sh

# +---------------+
# | End Workloads |
# +---------------+

echo ""
echo "🧵 dev-up done."
ARGO_PASS=`kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`
echo "🧵 argo-cd admin password: ${ARGO_PASS}"
exit 0