#!/usr/bin/env zsh
set -eu
set +x

source ./dev-vars.sh

# +------------------+
# | Git Server Start |
# +------------------+

# Clone (Local)
echo "🧵 cloning linkerd-bootstrap (local)..."
rm -rf "$(pwd)/ananke-linkerd-bootstrap"
git clone https://github.com/TheStopsign/ananke-linkerd-bootstrap.git
sleep 2
git -C "$(pwd)/ananke-linkerd-bootstrap" \
    remote add git-server git://localhost/ananke-linkerd-bootstrap.git

# Deploy Git-Server (In-Cluster)
echo "🧵 deploy git-server (in-cluster)..."
kubectl apply -f ananke-linkerd-bootstrap/resources/git-server.yaml
kubectl -n scm rollout status deploy/git-server

# Clone (In-Cluster)
echo "🧵 cloning to git-server (in-cluster)..."
git_server=`kubectl -n scm get po -l app=git-server -oname | awk -F/ '{ print $2 }'`
kubectl -n scm exec "${git_server}" -- \
  git clone --bare https://github.com/TheStopsign/ananke-linkerd-bootstrap.git

# Verify
echo "🧵 verifying git_server installation..."
kubectl -n scm exec "${git_server}" -- ls -al /git/ananke-linkerd-bootstrap.git
kubectl -n scm port-forward "${git_server}" 9418 &

sleep 5

# +------------------+
# |  Git Server End  |
# +------------------+



# +---------------+
# | Linkerd Start |
# +---------------+

# Main (App of Apps)
echo "🧵 applying argo project..."
kubectl apply -f ananke-linkerd-bootstrap/project.yaml

kubens argocd
argocd proj get ananke
kubens default

# echo "🧵 applying main (app-of-apps)..."
# kubectl apply -f ananke-linkerd-bootstrap/main.yaml

# kubens argocd
# argocd app get main
# argocd app sync main
# argocd app wait main

# Cert Manager
echo "🧵 applying cert-manager (argocd)..."
kubectl apply -f ananke-linkerd-bootstrap/argo-apps/cert-manager.yaml
sleep 2
kubens argocd
echo "🧵 waiting for cert-manager (argocd)..."
argocd app sync cert-manager
argocd app wait cert-manager
kubens default
for deploy in "cert-manager" "cert-manager-cainjector" "cert-manager-webhook"; \
  do kubectl -n cert-manager rollout status deploy/${deploy}; \
done

# Sealed Secrets
echo "🧵 applying sealed-secrets (argocd)..."
kubectl apply -f ananke-linkerd-bootstrap/argo-apps/sealed-secrets.yaml
sleep 2
kubens argocd
argocd app sync sealed-secrets
argocd app wait sealed-secrets
kubens default
kubectl -n kube-system rollout status deploy/sealed-secrets

# mTLS Trust Anchor
echo "🧵 creating mTLS trust anchors..."
step certificate create root.linkerd.cluster.local trust.crt trust.key \
    --profile root-ca \
    --no-password \
    --not-after 43800h \
    --insecure \
    -f
step certificate inspect trust.crt

echo "🧵 sealing, applying mTLS trust anchors..."
kubectl create ns linkerd
kubectl -n linkerd create secret tls linkerd-trust-anchor \
        --cert trust.crt \
        --key trust.key \
        --dry-run=client \
        -o yaml \
    | kubeseal --controller-name=sealed-secrets -o yaml - \
    | kubectl patch -f - \
        -p '{"spec": {"template": {"type":"kubernetes.io/tls", "metadata": {"labels": {"linkerd.io/control-plane-component":"identity", "linkerd.io/control-plane-ns":"linkerd"}, "annotations": {"linkerd.io/created-by":"linkerd/cli stable-2.13.0"}}}}}' \
        --dry-run=client \
        --type=merge \
        --local -o yaml > ananke-linkerd-bootstrap/resources/linkerd/trust-anchor.yaml

sleep 2

git -C "$(pwd)/ananke-linkerd-bootstrap" \
    add resources/linkerd/trust-anchor.yaml
git -C "$(pwd)/ananke-linkerd-bootstrap" \
    commit -m "update encrypted trust anchor"
git -C "$(pwd)/ananke-linkerd-bootstrap" \
    push git-server main

sleep 5


# Linkerd Bootstrap
echo "🧵 applying linkerd-bootstrap..."
kubectl apply -f ananke-linkerd-bootstrap/argo-apps/linkerd-bootstrap.yaml
kubens argocd
echo "🧵 waiting for linkerd-bootstrap..."
argocd app sync linkerd-bootstrap
sleep 5
argocd app wait linkerd-bootstrap
sleep 5
echo "🧵 linkerd-bootstrap installed."
kubens default

sleep 5

# Linkerd CRDs
echo "🧵 applying linkerd-crds..."
kubectl apply -f ananke-linkerd-bootstrap/argo-apps/linkerd-crds.yaml
sleep 5
kubens argocd
argocd app sync linkerd-crds
kubens default

sleep 10

# Linkerd CRDs
echo "🧵 getting mTLS trust anchor PEM..."
( while ! kubectl get secret -n linkerd linkerd-trust-anchor ; do sleep 1; done ) > /dev/null 2>&1

kubectl -n linkerd get secret linkerd-trust-anchor -o jsonpath="{.data['tls\.crt']}" \
    | base64 -d -w 0 - \
    > trust_anchor.pem
yq eval -i '.identityTrustAnchorsPEM = "'"$(< trust_anchor.pem)"'"' \
    ananke-linkerd-bootstrap/values/linkerd-control-plane-values.yaml
sed -i 's/identityTrustAnchorsPEM: |-/identityTrustAnchorsPEM: |/g' \
    ananke-linkerd-bootstrap/values/linkerd-control-plane-values.yaml
cat trust_anchor.pem

sleep 5

echo "🧵 applying mTLS trust anchor PEM..."
git -C "$(pwd)/ananke-linkerd-bootstrap" \
    add values/linkerd-control-plane-values.yaml
git -C "$(pwd)/ananke-linkerd-bootstrap" \
    commit -m "set identityTrustAnchorsPEM parameter"
git -C "$(pwd)/ananke-linkerd-bootstrap" \
    push git-server main

sleep 5

# Linkerd Control Plane
echo "🧵 applying linkerd-control-plane..."
kubectl apply -f ananke-linkerd-bootstrap/argo-apps/linkerd-control-plane.yaml
sleep 5
kubectl -n linkerd rollout status deploy/linkerd-identity
kubectl -n linkerd rollout status deploy/linkerd-destination
kubectl -n linkerd rollout status deploy/linkerd-proxy-injector

sleep 2

kubens argocd
argocd app actions run ambassador restart --kind Deployment --all
kubens default
kubectl -n ambassador rollout status deploy/ambassador
kubectl -n ambassador rollout status deploy/ambassador-agent
kubectl -n ambassador rollout status deploy/ambassador-redis

# +---------------+
# |  Linkerd End  |
# +---------------+

kubens default