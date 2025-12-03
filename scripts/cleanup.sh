#!/bin/bash

set -e

REGION="us-east-1"

echo "=========================================="
echo "Cleaning up AWS Resources"
echo "=========================================="
echo ""
echo "WARNING: This will delete all resources!"
read -p "Are you sure? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
  echo "Cleanup cancelled"
  exit 0
fi

# Delete Kubernetes resources first
echo ""
echo "Deleting Kubernetes resources..."
kubectl delete namespace kiro-app --ignore-not-found=true || true

# Delete stacks in reverse order
echo ""
echo "Deleting Pipeline stack..."
aws cloudformation delete-stack \
  --stack-name kiro-pipeline \
  --region $REGION || true

echo "Waiting for Pipeline stack deletion..."
aws cloudformation wait stack-delete-complete \
  --stack-name kiro-pipeline \
  --region $REGION || true

echo ""
echo "Deleting EKS stack..."
aws cloudformation delete-stack \
  --stack-name kiro-eks \
  --region $REGION || true

echo "Waiting for EKS stack deletion (this may take 10-15 minutes)..."
aws cloudformation wait stack-delete-complete \
  --stack-name kiro-eks \
  --region $REGION || true

echo ""
echo "Deleting ECR stack..."
# Empty ECR repository first
REPO_NAME=$(aws cloudformation describe-stacks \
  --stack-name kiro-ecr \
  --region $REGION \
  --query 'Stacks[0].Outputs[?OutputKey==`RepositoryName`].OutputValue' \
  --output text 2>/dev/null || echo "")

if [ ! -z "$REPO_NAME" ]; then
  echo "Emptying ECR repository..."
  aws ecr batch-delete-image \
    --repository-name $REPO_NAME \
    --image-ids "$(aws ecr list-images --repository-name $REPO_NAME --query 'imageIds[*]' --output json)" \
    --region $REGION 2>/dev/null || true
fi

aws cloudformation delete-stack \
  --stack-name kiro-ecr \
  --region $REGION || true

echo "Waiting for ECR stack deletion..."
aws cloudformation wait stack-delete-complete \
  --stack-name kiro-ecr \
  --region $REGION || true

echo ""
echo "Deleting VPC stack..."
aws cloudformation delete-stack \
  --stack-name kiro-vpc \
  --region $REGION || true

echo "Waiting for VPC stack deletion..."
aws cloudformation wait stack-delete-complete \
  --stack-name kiro-vpc \
  --region $REGION || true

# Empty and delete artifact bucket
echo ""
echo "Deleting artifact bucket..."
BUCKET_NAME="kiro-pipeline-artifacts-$(aws sts get-caller-identity --query Account --output text)"
aws s3 rb s3://$BUCKET_NAME --force --region $REGION 2>/dev/null || true

echo ""
echo "=========================================="
echo "Cleanup Complete!"
echo "=========================================="
