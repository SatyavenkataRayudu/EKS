#!/bin/bash

set -e

CLUSTER_NAME="kiro-eks-cluster"
REGION="us-east-1"

echo "Configuring kubectl for EKS cluster..."

# Update kubeconfig
aws eks update-kubeconfig \
  --name $CLUSTER_NAME \
  --region $REGION

echo "✓ kubectl configured successfully"

# Test connection
echo ""
echo "Testing connection to cluster..."
kubectl cluster-info

echo ""
echo "Getting nodes..."
kubectl get nodes

echo ""
echo "kubectl is now configured to use EKS cluster: $CLUSTER_NAME"
