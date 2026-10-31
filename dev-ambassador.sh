#!/usr/bin/env zsh
set -eu
set +x

# Ambassador Module
echo "🧵 installing ambassador crds (argocd)..."
kubectl apply -f mgmt/ambassador-crds.yaml
echo "🧵 waiting for ambassador crds (argocd)..."
(
    while ! kubectl get application -n argocd ambassador-crds | grep -v Synced | grep -v Healthy ; do
        sleep 1
    done
    while ! kubectl get namespace emissary-system ; do
        sleep 1
    done
    while ! kubectl get deploy -n emissary-system emissary-apiext ; do
        sleep 1
    done
) > /dev/null 2>&1
kubectl wait --timeout=120s --for=condition=available deployment emissary-apiext -n emissary-system
echo "🧵 ambassador crds installed (argocd)..."

echo "🧵 installing ambassador (argocd)..."
kubectl apply -f mgmt/ambassador.yaml
echo "🧵 waiting for ambassador (argocd)..."
(
    while ! kubectl get application -n argocd ambassador | grep -v Synced | grep -v Healthy ; do
        sleep 1
    done
    while ! kubectl get namespace ambassador ; do
        sleep 1
    done
    while ! kubectl get deploy -n ambassador ambassador ; do
        sleep 1
    done
    while ! kubectl get deploy -n ambassador ambassador-agent ; do
        sleep 1
    done
    while ! kubectl get deploy -n ambassador ambassador-redis ; do
        sleep 1
    done
) > /dev/null 2>&1
kubectl -n ambassador wait --for condition=available --timeout=120s deploy ambassador
kubectl -n ambassador wait --for condition=available --timeout=120s deploy ambassador-agent
kubectl -n ambassador wait --for condition=available --timeout=120s deploy ambassador-redis
echo "🧵 ambassador installed (argocd)."

# echo "🧵 creating ambassador namespace..."
# kubectl create namespace ambassador || true
# echo "🧵 applying edge-stack CRDs..."
# kubectl apply -f https://app.getambassador.io/yaml/edge-stack/3.5.1/aes-crds.yaml
# echo "🧵 waiting for edge-stack CRDs..."
# kubectl wait --timeout=90s --for=condition=available deployment emissary-apiext -n emissary-system

# sleep 5

# echo "🧵 installing edge-stack..."
# helm install -n ambassador --create-namespace \
#     edge-stack datawire/edge-stack && \
#     kubectl rollout status  -n ambassador deployment/edge-stack -w

# echo "🧵 waiting for edge-stack..."
# kubectl -n ambassador wait --for condition=available --timeout=90s deploy edge-stack

# # Ambassador Meshing
# echo "🧵 Linkerd meshing with Ambassador..."
# kubectl get deploy -n ambassador edge-stack -o yaml \
#   | linkerd inject - \
#   | kubectl apply -f -
# kubectl get deploy -n ambassador edge-stack-agent -o yaml \
#   | linkerd inject - \
#   | kubectl apply -f -
# kubectl get deploy -n ambassador edge-stack-redis -o yaml \
#   | linkerd inject --opaque-ports 6379 - \
#   | kubectl apply -f -