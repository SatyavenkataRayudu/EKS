#!/bin/bash

set -e

REGION="us-east-1"

echo "=========================================="
echo "Deploying AWS EKS Infrastructure"
echo "=========================================="

# Step 1: Deploy VPC
echo ""
echo "Step 1/4: Deploying VPC and networking..."
aws cloudformation create-stack \
  --stack-name kiro-vpc \
  --template-body file://infrastructure/vpc-template.yaml \
  --region $REGION

echo "Waiting for VPC stack to complete..."
aws cloudformation wait stack-create-complete \
  --stack-name kiro-vpc \
  --region $REGION

echo "✓ VPC deployed successfully"

# Step 2: Deploy ECR
echo ""
echo "Step 2/4: Deploying ECR repository..."
aws cloudformation create-stack \
  --stack-name kiro-ecr \
  --template-body file://infrastructure/ecr-template.yaml \
  --region $REGION

echo "Waiting for ECR stack to complete..."
aws cloudformation wait stack-create-complete \
  --stack-name kiro-ecr \
  --region $REGION

echo "✓ ECR deployed successfully"

# Step 3: Deploy EKS Cluster
echo ""
echo "Step 3/4: Deploying EKS cluster (this may take 15-20 minutes)..."
aws cloudformation create-stack \
  --stack-name kiro-eks \
  --template-body file://infrastructure/eks-template.yaml \
  --parameters file://infrastructure/eks-parameters.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --region $REGION

echo "Waiting for EKS stack to complete..."
aws cloudformation wait stack-create-complete \
  --stack-name kiro-eks \
  --region $REGION

echo "✓ EKS cluster deployed successfully"

# Step 4: Deploy Pipeline
echo ""
echo "Step 4/4: Deploying CI/CD pipeline..."
echo "NOTE: Make sure you've updated pipeline-parameters.json with your GitHub details"
read -p "Press enter to continue or Ctrl+C to cancel..."

aws cloudformation create-stack \
  --stack-name kiro-pipeline \
  --template-body file://infrastructure/pipeline-template.yaml \
  --parameters file://infrastructure/pipeline-parameters.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --region $REGION

echo "Waiting for Pipeline stack to complete..."
aws cloudformation wait stack-create-complete \
  --stack-name kiro-pipeline \
  --region $REGION

echo "✓ Pipeline deployed successfully"

# Display outputs
echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""
echo "Retrieving stack outputs..."
echo ""

echo "VPC Outputs:"
aws cloudformation describe-stacks \
  --stack-name kiro-vpc \
  --region $REGION \
  --query 'Stacks[0].Outputs' \
  --output table

echo ""
echo "EKS Outputs:"
aws cloudformation describe-stacks \
  --stack-name kiro-eks \
  --region $REGION \
  --query 'Stacks[0].Outputs' \
  --output table

echo ""
echo "ECR Outputs:"
aws cloudformation describe-stacks \
  --stack-name kiro-ecr \
  --region $REGION \
  --query 'Stacks[0].Outputs' \
  --output table

echo ""
echo "Pipeline Outputs:"
aws cloudformation describe-stacks \
  --stack-name kiro-pipeline \
  --region $REGION \
  --query 'Stacks[0].Outputs' \
  --output table

echo ""
echo "Next steps:"
echo "1. Configure kubectl: ./scripts/configure-kubectl.sh"
echo "2. Deploy Kubernetes manifests: kubectl apply -f kubernetes/"
echo "3. Push code to GitHub to trigger the pipeline"
