#!/usr/bin/env zsh
set -eu
set +x

source ./dev-vars.sh


# vClusters
vcluster disconnect || true
kubectl config set-context k3d-ananke-mgmt --namespace default || true
kubectl config delete-context v-ananke-dev || true
kubectl config delete-user v-ananke-dev || true
kubectl config delete-cluster v-ananke-dev || true


# Domains
hostctl remove domains ${PROJECT_NAME} ${ORG_DOMAIN} || true
for subdomain in $SUB_DOMAINS ; do
    hostctl remove domains ${PROJECT_NAME} "${subdomain}.${ORG_DOMAIN}" || true
done


# Cluster
k3d cluster delete "${mgmt_cluster}"