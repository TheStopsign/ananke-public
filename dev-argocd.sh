#!/usr/bin/env zsh
set -eu
set +x

# Argo-CD
kubectl delete namespace argocd || true
kubectl create namespace argocd
kubectl annotate namespace argocd linkerd.io/inject=enabled
echo "🧵 installing argo-cd..."
helm repo add argocd https://argoproj.github.io/argo-helm
helm upgrade --install argocd argocd/argo-cd -n argocd -f mgmt/argocd-values.yaml
helm upgrade --install argo-rollouts argocd/argo-rollouts -n argocd
echo "🧵 installed argo-cd."
echo ""
sleep 5

echo "🧵 waiting for argocd server..."
kubectl -n argocd wait --for condition=available --timeout=180s deploy argocd-server
kubectl -n argocd wait --for condition=available --timeout=180s deploy argocd-repo-server
kubectl -n argocd wait --for condition=available --timeout=180s deploy argocd-notifications-controller
kubectl -n argocd wait --for condition=available --timeout=180s deploy argocd-redis
kubectl -n argocd wait --for condition=available --timeout=180s deploy argocd-dex-server
kubectl -n argocd wait --for condition=available --timeout=180s deploy argocd-applicationset-controller
kubectl -n argocd wait --for condition=available --timeout=180s deploy argo-rollouts
echo "🧵 argocd server ready."
echo ""

echo "🧵 waiting for argocd secret..."
while ! kubectl get secret -n argocd argocd-initial-admin-secret ; do sleep 1; done
ARGO_PASS=`kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`
echo "🧵 argo-cd admin password: ${ARGO_PASS}"
echo ""

echo "🧵 exposing argocd..."
kubectl apply -f mgmt/argocd.yaml
echo "🧵 exposed argocd."
echo ""