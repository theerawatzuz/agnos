#!/bin/bash

if [[ ${KUBECONFIG} == "" ]]
then
    echo "Please export KUBECONFIG env variable before running script!!!"
    exit 1
else
    echo "Current value of KUBECONFIG --> [${KUBECONFIG}]"
fi

export $(xargs <.env)

echo "=========================================="
echo "Labeling cluster for ArgoCD ApplicationSet"
echo "=========================================="

# Get the in-cluster secret name
CLUSTER_SECRET=$(kubectl get secret -n argocd -l argocd.argoproj.io/secret-type=cluster -o name | head -1)

if [ -z "$CLUSTER_SECRET" ]; then
  echo "ERROR: No cluster secret found!"
  exit 1
fi

echo "Found cluster secret: $CLUSTER_SECRET"

# Label the cluster secret with custom=true and name=production
kubectl label $CLUSTER_SECRET -n argocd \
  custom=true \
  --overwrite

# Patch the secret to set the name field to "production"
kubectl patch $CLUSTER_SECRET -n argocd --type=merge -p '{"metadata":{"annotations":{"argocd.argoproj.io/cluster-name":"production"}}}'

echo ""
echo "Cluster labeled successfully!"
echo "  - Label: custom=true"
echo "  - Name: production"
echo "Environment: ${ENV}"
echo ""
echo "Waiting for ApplicationSets to be created..."
sleep 5

echo ""
echo "Current ApplicationSets:"
kubectl get applicationset -n argocd

echo ""
echo "Current Applications:"
kubectl get application -n argocd
