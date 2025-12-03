# Quick Reference Guide

## Get Stack Outputs

```bash
# VPC
aws cloudformation describe-stacks --stack-name kiro-vpc --query 'Stacks[0].Outputs' --output table

# EKS
aws cloudformation describe-stacks --stack-name kiro-eks --query 'Stacks[0].Outputs' --output table

# ECR
aws cloudformation describe-stacks --stack-name kiro-ecr --query 'Stacks[0].Outputs' --output table

# Pipeline
aws cloudformation describe-stacks --stack-name kiro-pipeline --query 'Stacks[0].Outputs' --output table
```

## Kubernetes Commands

```bash
# Get all resources
kubectl get all -n kiro-app

# Get pods
kubectl get pods -n kiro-app

# Get service and LoadBalancer URL
kubectl get svc -n kiro-app

# View logs
kubectl logs -n kiro-app -l app=kiro-app -f

# Describe pod
kubectl describe pod -n kiro-app <pod-name>

# Restart deployment
kubectl rollout restart deployment/kiro-app -n kiro-app

# Scale deployment
kubectl scale deployment/kiro-app -n kiro-app --replicas=3
```

## Pipeline Commands

```bash
# View pipeline status
aws codepipeline get-pipeline-state --name kiro-app-pipeline

# List builds
aws codebuild list-builds-for-project --project-name kiro-app-build

# Start pipeline manually
aws codepipeline start-pipeline-execution --name kiro-app-pipeline
```

## ECR Commands

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com

# List images
aws ecr list-images --repository-name kiro-app-repo

# Build and push manually
docker build -t kiro-app-repo:latest .
docker tag kiro-app-repo:latest $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com/kiro-app-repo:latest
docker push $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com/kiro-app-repo:latest
```

## Useful URLs

- CodePipeline Console: https://console.aws.amazon.com/codesuite/codepipeline/pipelines/kiro-app-pipeline/view
- EKS Console: https://console.aws.amazon.com/eks/home#/clusters/kiro-eks-cluster
- ECR Console: https://console.aws.amazon.com/ecr/repositories/kiro-app-repo
