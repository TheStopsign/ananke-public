#!/usr/bin/env zsh
set -eu
set +x

source ./dev-vars.sh

hostctl remove domains ${PROJECT_NAME} ${ORG_DOMAIN} || true
for subdomain in $SUB_DOMAINS ; do
    hostctl remove domains ${PROJECT_NAME} "${subdomain}.${ORG_DOMAIN}" || true
done

# /etc/hosts
echo "🧵 updating /etc/hosts, flushing dns..."
external_ip=$(kubectl get svc ambassador -n ambassador -o json | jq '.status.loadBalancer.ingress[0].ip' | tr -d '"')
sudo chmod 777 /etc/hosts
hostctl add domains ${PROJECT_NAME} ${ORG_DOMAIN} --ip "$external_ip"
SUB_DOMAINS="argocd dashboard qotm emojivoto ananke-dev"
for subdomain in $SUB_DOMAINS; do
  hostctl add domains ${PROJECT_NAME} "${subdomain}.${ORG_DOMAIN}" --ip "$external_ip"
done
sudo resolvectl flush-caches
echo "🧵 updated /etc/hosts, flushed dns."

echo "🧵 logging into argocd..."
argocd login "argocd.${ORG_DOMAIN}" --core --insecure
echo "🧵 logged into argocd."
echo ""