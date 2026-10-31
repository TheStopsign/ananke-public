#!/usr/bin/env zsh
set -eu
set +x
alias kubectx="kubectl ctx"
alias kubens="kubectl ns"
source dev-vars.sh

# vClusters

# Pre
vcluster disconnect || true
kubectl config set-context k3d-ananke-mgmt --namespace default || true
kubectl config delete-context v-ananke-dev || true
kubectl config delete-user v-ananke-dev || true
kubectl config delete-cluster v-ananke-dev || true
kubectl delete Application v-ananke-dev || true
kubectl delete namespace ananke-dev || true

# Cluster API - vCluster Infrastructure
echo ""
echo "🧵 installing capi infrastructure (vcluster)..."
clusterctl init --infrastructure vcluster
echo "🧵 waiting for capi infrastructure (vcluster)..."
sleep 20
kubectl rollout status deploy capi-kubeadm-control-plane-controller-manager \
  -n capi-kubeadm-control-plane-system
kubectl rollout status deploy capi-controller-manager \
  -n capi-system
kubectl rollout status deploy capi-kubeadm-bootstrap-controller-manager \
  -n capi-kubeadm-bootstrap-system
kubectl rollout status deploy cluster-api-provider-vcluster-controller-manager \
  -n cluster-api-provider-vcluster-system
echo "🧵 capi infrastructure (vcluster) installed."

# Deploy vclusters as ArgoCD Applications
echo ""
echo "🧵 installing vclusters (argocd)..."
kubectl apply -f mgmt/vclusters.yaml
echo "🧵 switching over to argocd namespace (kubeconfig)..."
kubens argocd
echo "🧵 waiting for vclusters (argocd)..."
argocd app wait v-ananke-dev || true
echo "🧵 switching back to default namespace (kubeconfig)..."
kubens default
sleep 10
kubectl wait --for=condition=ready vcluster -n ananke-dev ananke-dev
echo "🧵 vclusters (argocd) installed."





# Expose vCluster in kubeconfig
echo ""
echo "🧵 getting vcluster context (kubeconfig)..."
vcluster connect v-ananke-dev -n v-ananke-dev \
  --server=https://v-ananke-dev.ananke.com \
  --service-account admin \
  --cluster-role cluster-admin \
  --kube-config-context-name v-ananke-dev \
  --insecure

sleep 2

echo ""
echo "🧵 available contexts (kubeconfig)..."
kubectl ctx

echo ""
echo "🧵 making sure we're in mgmt context (kubeconfig)..."
kubectl ctx k3d-ananke-mgmt
