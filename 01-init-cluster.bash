#!/bin/bash

if [[ ${KUBECONFIG} == "" ]]
then
    echo "Please export KUBECONFIG env variable before running script!!!"
    exit 1
else
    echo "Current value of KUBECONFIG --> [${KUBECONFIG}]"
fi

export $(xargs <.env)

cd "01-init"
helm dependency update
helm upgrade -i init . -f values-${ENV}.yaml -n argocd --create-namespace
cd ..

echo ""
echo "Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s

echo ""
echo "Labeling cluster for ApplicationSet..."
# Get the in-cluster secret
CLUSTER_SECRET=$(kubectl get secret -n argocd -l argocd.argoproj.io/secret-type=cluster -o name 2>/dev/null | head -1)

if [ ! -z "$CLUSTER_SECRET" ]; then
  echo "Found cluster secret: $CLUSTER_SECRET"
  
  # Add label custom=true
  kubectl label $CLUSTER_SECRET -n argocd custom=true --overwrite
  
  # Set cluster name to match ENV
  kubectl patch $CLUSTER_SECRET -n argocd --type=merge -p "{\"metadata\":{\"annotations\":{\"argocd.argoproj.io/cluster-name\":\"${ENV}\"}}}"
  
  echo "Cluster labeled with custom=true and name=${ENV}"
else
  echo "WARNING: Cluster secret not found, will need to label manually"
fi
