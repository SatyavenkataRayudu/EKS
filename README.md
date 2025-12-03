# AWS EKS Application Deployment Project

Complete infrastructure and CI/CD pipeline for deploying applications to Amazon EKS.

## Architecture Overview

- **VPC**: Custom VPC with public and private subnets across 2 AZs
- **EKS Cluster**: Managed Kubernetes cluster (kiro-eks-cluster)
- **ECR**: Private Docker registry (kiro-app-repo)
- **CodePipeline**: Automated CI/CD from GitHub to EKS
- **CodeBuild**: Docker image building and pushing to ECR

## Prerequisites

- AWS CLI configured with appropriate credentials
- kubectl installed
- GitHub personal access token
- Docker installed (for local testing)

## Quick Start

### 1. Deploy Infrastructure

```bash
# Deploy VPC and networking
aws cloudformation create-stack \
  --stack-name kiro-vpc \
  --template-body file://infrastructure/vpc-template.yaml \
  --region us-east-1

# Deploy EKS cluster
aws cloudformation create-stack \
  --stack-name kiro-eks \
  --template-body file://infrastructure/eks-template.yaml \
  --parameters file://infrastructure/eks-parameters.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1

# Deploy ECR repository
aws cloudformation create-stack \
  --stack-name kiro-ecr \
  --template-body file://infrastructure/ecr-template.yaml \
  --region us-east-1

# Deploy CI/CD pipeline
aws cloudformation create-stack \
  --stack-name kiro-pipeline \
  --template-body file://infrastructure/pipeline-template.yaml \
  --parameters file://infrastructure/pipeline-parameters.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

### 2. Configure kubectl

```bash
aws eks update-kubeconfig --name kiro-eks-cluster --region us-east-1
```

### 3. Deploy Kubernetes Manifests

```bash
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/deployment.yaml
kubectl apply -f kubernetes/service.yaml
```

### 4. Verify Deployment

```bash
kubectl get pods -n kiro-app
kubectl get svc -n kiro-app
```

## Project Structure

```
eks-project/
├── infrastructure/
│   ├── vpc-template.yaml           # VPC, subnets, gateways
│   ├── eks-template.yaml           # EKS cluster and node group
│   ├── eks-parameters.json         # EKS configuration
│   ├── ecr-template.yaml           # ECR repository
│   ├── pipeline-template.yaml      # CodePipeline and CodeBuild
│   └── pipeline-parameters.json    # Pipeline configuration
├── kubernetes/
│   ├── namespace.yaml              # Kubernetes namespace
│   ├── deployment.yaml             # Application deployment
│   └── service.yaml                # LoadBalancer service
├── buildspec.yml                   # CodeBuild build specification
├── scripts/
│   ├── deploy-all.sh               # Deploy all stacks
│   ├── configure-kubectl.sh        # Configure kubectl access
│   └── cleanup.sh                  # Delete all resources
└── README.md
```

## Deployment Flow

1. Developer pushes code to GitHub
2. GitHub webhook triggers CodePipeline
3. CodeBuild pulls source code
4. CodeBuild builds Docker image
5. Image is tagged and pushed to ECR
6. CodeBuild updates Kubernetes deployment
7. EKS pulls new image and updates pods

## Outputs

After deployment, retrieve outputs:

```bash
# Get EKS cluster info
aws cloudformation describe-stacks --stack-name kiro-eks --query 'Stacks[0].Outputs'

# Get LoadBalancer URL
kubectl get svc -n kiro-app -o wide
```

## Triggering Deployments

Simply push to your GitHub repository:

```bash
git add .
git commit -m "Update application"
git push origin main
```

The pipeline will automatically build and deploy your changes.

## Monitoring

```bash
# Watch pipeline execution
aws codepipeline get-pipeline-state --name kiro-app-pipeline

# View CodeBuild logs
aws codebuild batch-get-builds --ids <build-id>

# Check pod status
kubectl get pods -n kiro-app -w

# View pod logs
kubectl logs -n kiro-app <pod-name>
```

## Cleanup

```bash
./scripts/cleanup.sh
```
