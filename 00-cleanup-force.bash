#!/bin/bash

if [[ ${KUBECONFIG} == "" ]]
then
    echo "Please export KUBECONFIG env variable before running script!!!"
    exit 1
else
    echo "Current value of KUBECONFIG --> [${KUBECONFIG}]"
fi

echo "=========================================="
echo "Starting FORCE cleanup process..."
echo "=========================================="

# Delete all ArgoCD applications first (force delete with finalizers removal)
echo "Force deleting ArgoCD applications..."

# Get all applications and remove finalizers
for app in $(kubectl get applications -n argocd -o name 2>/dev/null); do
  echo "Force deleting $app..."
  kubectl patch $app -n argocd -p '{"metadata":{"finalizers":null}}' --type=merge 2>/dev/null || true
  kubectl delete $app -n argocd --force --grace-period=0 2>/dev/null || true
done

# Get all applicationsets and remove finalizers
for appset in $(kubectl get applicationsets -n argocd -o name 2>/dev/null); do
  echo "Force deleting $appset..."
  kubectl patch $appset -n argocd -p '{"metadata":{"finalizers":null}}' --type=merge 2>/dev/null || true
  kubectl delete $appset -n argocd --force --grace-period=0 2>/dev/null || true
done

echo "Waiting for applications to be deleted..."
sleep 3

# Delete Helm releases
echo "Deleting Helm releases..."
helm uninstall bootstrap -n argocd 2>/dev/null || true
helm uninstall init -n argocd 2>/dev/null || true

# Force delete namespaces
echo "Force deleting namespaces..."
kubectl delete namespace argocd --force --grace-period=0 2>/dev/null || true
kubectl delete namespace external-secrets --force --grace-period=0 2>/dev/null || true
kubectl delete namespace ingress-nginx --force --grace-period=0 2>/dev/null || true

# Delete secrets
echo "Deleting initial secrets..."
kubectl delete secret initial-secret --force --grace-period=0 2>/dev/null || true

echo "=========================================="
echo "Force cleanup completed!"
echo "=========================================="
echo ""
echo "Now you can run:"
echo "  1. ./01-init-cluster.bash"
echo "  2. ./02-create-secrets.bash"
echo "  3. ./04-label-cluster.bash"
echo "  4. ./03-bootstrap-cluster.bash"
