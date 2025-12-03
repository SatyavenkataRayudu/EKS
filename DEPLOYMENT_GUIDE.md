# Complete EKS Deployment Guide

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [GitHub Setup](#github-setup)
3. [Configuration](#configuration)
4. [Deployment](#deployment)
5. [Verification](#verification)
6. [CI/CD Usage](#cicd-usage)
7. [Monitoring](#monitoring)
8. [Troubleshooting](#troubleshooting)
9. [Cleanup](#cleanup)

## Prerequisites

### Required Tools

**AWS CLI**
```bash
# Check if installed
aws --version

# Should show: aws-cli/2.x.x or higher
```

**kubectl**
```bash
# Check if installed
kubectl version --client

# Install on Windows: https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/
# Install on Linux/Mac: https://kubernetes.io/docs/tasks/tools/
```

**Docker** (optional, for local testing)
```bash
docker --version
```

### AWS Configuration

Ensure AWS CLI is configured with credentials:
```bash
aws configure

# Or verify existing configuration
aws sts get-caller-identity
```

Required AWS permissions:
- CloudFormation (full access)
- EKS (full access)
- EC2 (full access)
- ECR (full access)
- IAM (create roles and policies)
- CodePipeline and CodeBuild (full access)

## GitHub Setup

### 1. Create or Use Existing Repository

Create a new repository on GitHub or use an existing one.

### 2. Generate Personal Access Token

1. Go to GitHub Settings: https://github.com/settings/tokens
2. Click "Generate new token" → "Generate new token (classic)"
3. Give it a name: "AWS EKS Pipeline"
4. Select scopes:
   - ✅ `repo` (all)
   - ✅ `admin:repo_hook` (write:repo_hook, read:repo_hook)
5. Click "Generate token"
6. **IMPORTANT**: Copy the token immediately (you won't see it again)

### 3. Note Your Repository Details

You'll need:
- Repository format: `username/repository-name`
- Example: `johndoe/my-app`
- Branch: `main` (or your default branch)

## Configuration

### Update Pipeline Parameters

**Windows:**
```powershell
notepad infrastructure\pipeline-parameters.json
```

**Linux/Mac:**
```bash
nano infrastructure/pipeline-parameters.json
```

Update these values:
```json
[
  {
    "ParameterKey": "GitHubRepo",
    "ParameterValue": "YOUR_USERNAME/YOUR_REPO"
  },
  {
    "ParameterKey": "GitHubBranch",
    "ParameterValue": "main"
  },
  {
    "ParameterKey": "GitHubToken",
    "ParameterValue": "ghp_xxxxxxxxxxxxxxxxxxxx"
  }
]
```

## Deployment

### Option 1: Automated Deployment (Windows)

```powershell
cd eks-project
.\deploy-windows.ps1
```

This script will:
- Deploy VPC (~5 minutes)
- Deploy ECR (~1 minute)
- Deploy EKS cluster (~15-20 minutes)
- Deploy CI/CD pipeline (~2 minutes)

**Total time: 25-30 minutes**

### Option 2: Automated Deployment (Linux/Mac)

```bash
cd eks-project
chmod +x scripts/*.sh
./scripts/deploy-all.sh
```

### Option 3: Manual Step-by-Step Deployment

#### Step 1: Deploy VPC

**Windows:**
```powershell
aws cloudformation create-stack `
  --stack-name kiro-vpc `
  --template-body file://infrastructure/vpc-template.yaml `
  --region us-east-1

# Wait for completion
aws cloudformation wait stack-create-complete `
  --stack-name kiro-vpc `
  --region us-east-1

# Check status
aws cloudformation describe-stacks `
  --stack-name kiro-vpc `
  --query 'Stacks[0].StackStatus'
```

**Linux/Mac:**
```bash
aws cloudformation create-stack \
  --stack-name kiro-vpc \
  --template-body file://infrastructure/vpc-template.yaml \
  --region us-east-1

aws cloudformation wait stack-create-complete \
  --stack-name kiro-vpc \
  --region us-east-1
```

#### Step 2: Deploy ECR Repository

**Windows:**
```powershell
aws cloudformation create-stack `
  --stack-name kiro-ecr `
  --template-body file://infrastructure/ecr-template.yaml `
  --region us-east-1

aws cloudformation wait stack-create-complete `
  --stack-name kiro-ecr `
  --region us-east-1
```

**Linux/Mac:**
```bash
aws cloudformation create-stack \
  --stack-name kiro-ecr \
  --template-body file://infrastructure/ecr-template.yaml \
  --region us-east-1

aws cloudformation wait stack-create-complete \
  --stack-name kiro-ecr \
  --region us-east-1
```

#### Step 3: Deploy EKS Cluster (15-20 minutes)

**Windows:**
```powershell
aws cloudformation create-stack `
  --stack-name kiro-eks `
  --template-body file://infrastructure/eks-template.yaml `
  --parameters file://infrastructure/eks-parameters.json `
  --capabilities CAPABILITY_NAMED_IAM `
  --region us-east-1

# This takes 15-20 minutes
aws cloudformation wait stack-create-complete `
  --stack-name kiro-eks `
  --region us-east-1
```

**Linux/Mac:**
```bash
aws cloudformation create-stack \
  --stack-name kiro-eks \
  --template-body file://infrastructure/eks-template.yaml \
  --parameters file://infrastructure/eks-parameters.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1

aws cloudformation wait stack-create-complete \
  --stack-name kiro-eks \
  --region us-east-1
```

#### Step 4: Deploy CI/CD Pipeline

**Windows:**
```powershell
aws cloudformation create-stack `
  --stack-name kiro-pipeline `
  --template-body file://infrastructure/pipeline-template.yaml `
  --parameters file://infrastructure/pipeline-parameters.json `
  --capabilities CAPABILITY_NAMED_IAM `
  --region us-east-1

aws cloudformation wait stack-create-complete `
  --stack-name kiro-pipeline `
  --region us-east-1
```

**Linux/Mac:**
```bash
aws cloudformation create-stack \
  --stack-name kiro-pipeline \
  --template-body file://infrastructure/pipeline-template.yaml \
  --parameters file://infrastructure/pipeline-parameters.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1

aws cloudformation wait stack-create-complete \
  --stack-name kiro-pipeline \
  --region us-east-1
```

### View Stack Outputs

After each stack is created, view outputs:

```bash
# VPC outputs
aws cloudformation describe-stacks --stack-name kiro-vpc --query 'Stacks[0].Outputs' --output table

# EKS outputs
aws cloudformation describe-stacks --stack-name kiro-eks --query 'Stacks[0].Outputs' --output table

# ECR outputs
aws cloudformation describe-stacks --stack-name kiro-ecr --query 'Stacks[0].Outputs' --output table

# Pipeline outputs
aws cloudformation describe-stacks --stack-name kiro-pipeline --query 'Stacks[0].Outputs' --output table
```

## Verification

### 1. Configure kubectl

```bash
aws eks update-kubeconfig --name kiro-eks-cluster --region us-east-1
```

Verify connection:
```bash
kubectl cluster-info
kubectl get nodes
```

Expected output:
```
NAME                          STATUS   ROLES    AGE   VERSION
ip-10-0-x-x.ec2.internal     Ready    <none>   5m    v1.28.x
ip-10-0-x-x.ec2.internal     Ready    <none>   5m    v1.28.x
```

### 2. Deploy Kubernetes Manifests

```bash
# Create namespace
kubectl apply -f kubernetes/namespace.yaml

# Deploy application
kubectl apply -f kubernetes/deployment.yaml

# Create service
kubectl apply -f kubernetes/service.yaml
```

Or apply all at once:
```bash
kubectl apply -f kubernetes/
```

### 3. Check Deployment Status

```bash
# Check namespace
kubectl get namespace kiro-app

# Check pods
kubectl get pods -n kiro-app

# Expected output:
# NAME                        READY   STATUS    RESTARTS   AGE
# kiro-app-xxxxxxxxx-xxxxx    1/1     Running   0          2m
# kiro-app-xxxxxxxxx-xxxxx    1/1     Running   0          2m

# Check deployment
kubectl get deployment -n kiro-app

# Check service
kubectl get svc -n kiro-app
```

### 4. Get Application URL

```bash
kubectl get svc kiro-app-service -n kiro-app
```

Look for the `EXTERNAL-IP` column. It will show:
- `<pending>` initially (wait 2-3 minutes)
- Then: `xxxxx.us-east-1.elb.amazonaws.com`

Access your application:
```bash
# Get the URL
kubectl get svc kiro-app-service -n kiro-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Open in browser or curl
curl http://$(kubectl get svc kiro-app-service -n kiro-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
```

## CI/CD Usage

### Initial Code Push

If you haven't pushed the code to GitHub yet:

```bash
cd eks-project
git init
git add .
git commit -m "Initial EKS project setup"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
git push -u origin main
```

### Triggering Deployments

Every time you push to GitHub, the pipeline automatically:
1. Detects the change via webhook
2. Pulls source code
3. Builds Docker image
4. Pushes to ECR
5. Updates Kubernetes deployment
6. Restarts pods

```bash
# Make changes to your code
echo "Updated" >> index.html

# Commit and push
git add .
git commit -m "Update application"
git push origin main
```

### Monitor Pipeline

**AWS Console:**
- Pipeline: https://console.aws.amazon.com/codesuite/codepipeline/pipelines/kiro-app-pipeline/view

**CLI:**
```bash
# View pipeline state
aws codepipeline get-pipeline-state --name kiro-app-pipeline

# List recent executions
aws codepipeline list-pipeline-executions --pipeline-name kiro-app-pipeline --max-items 5

# View build logs
aws codebuild list-builds-for-project --project-name kiro-app-build
```

## Monitoring

### Pod Status

```bash
# Get all pods
kubectl get pods -n kiro-app

# Watch pods in real-time
kubectl get pods -n kiro-app -w

# Describe a pod
kubectl describe pod -n kiro-app <pod-name>

# Get pod logs
kubectl logs -n kiro-app <pod-name>

# Follow logs
kubectl logs -n kiro-app <pod-name> -f

# Logs from all pods
kubectl logs -n kiro-app -l app=kiro-app --tail=100
```

### Service Status

```bash
# Get service details
kubectl get svc -n kiro-app

# Describe service
kubectl describe svc kiro-app-service -n kiro-app
```

### Deployment Status

```bash
# Get deployment
kubectl get deployment -n kiro-app

# Describe deployment
kubectl describe deployment kiro-app -n kiro-app

# View rollout status
kubectl rollout status deployment/kiro-app -n kiro-app

# View rollout history
kubectl rollout history deployment/kiro-app -n kiro-app
```

### Events

```bash
# View recent events
kubectl get events -n kiro-app --sort-by='.lastTimestamp'
```

### Node Status

```bash
# Get nodes
kubectl get nodes

# Describe node
kubectl describe node <node-name>

# View node resource usage
kubectl top nodes
```

## Troubleshooting

### Pods Not Starting

**Check pod status:**
```bash
kubectl get pods -n kiro-app
kubectl describe pod -n kiro-app <pod-name>
```

**Common issues:**
- ImagePullBackOff: ECR permissions or image doesn't exist
- CrashLoopBackOff: Application error, check logs
- Pending: Insufficient resources

**Solutions:**
```bash
# Check logs
kubectl logs -n kiro-app <pod-name>

# Check events
kubectl get events -n kiro-app

# Restart deployment
kubectl rollout restart deployment/kiro-app -n kiro-app
```

### LoadBalancer Not Accessible

**Check service:**
```bash
kubectl get svc -n kiro-app
kubectl describe svc kiro-app-service -n kiro-app
```

**Wait for provisioning:**
LoadBalancer takes 2-3 minutes to provision. Status will change from `<pending>` to actual hostname.

**Check security groups:**
```bash
# Get LoadBalancer details from AWS
aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `kiro`)]'
```

### Pipeline Failures

**Check pipeline:**
```bash
aws codepipeline get-pipeline-state --name kiro-app-pipeline
```

**Check build logs:**
```bash
# Get recent build ID
BUILD_ID=$(aws codebuild list-builds-for-project --project-name kiro-app-build --query 'ids[0]' --output text)

# Get build details
aws codebuild batch-get-builds --ids $BUILD_ID
```

**Common issues:**
- GitHub token expired: Update token in parameters
- Build timeout: Increase timeout in CodeBuild
- kubectl access denied: Check IAM roles

### Image Pull Errors

**Verify ECR repository:**
```bash
aws ecr describe-repositories --repository-names kiro-app-repo
aws ecr list-images --repository-name kiro-app-repo
```

**Check node IAM role:**
```bash
# Nodes should have AmazonEC2ContainerRegistryReadOnly policy
kubectl describe node <node-name> | grep iam
```

### Stack Creation Failures

**Check stack events:**
```bash
aws cloudformation describe-stack-events --stack-name <stack-name> --max-items 20
```

**Common issues:**
- Resource limits: Check AWS service quotas
- Dependency errors: Deploy stacks in order (VPC → ECR → EKS → Pipeline)
- IAM permissions: Ensure CAPABILITY_NAMED_IAM is specified

## Cleanup

### Delete All Resources

**Windows:**
```powershell
# Delete Kubernetes resources first
kubectl delete namespace kiro-app

# Delete CloudFormation stacks (in reverse order)
aws cloudformation delete-stack --stack-name kiro-pipeline --region us-east-1
aws cloudformation delete-stack --stack-name kiro-eks --region us-east-1
aws cloudformation delete-stack --stack-name kiro-ecr --region us-east-1
aws cloudformation delete-stack --stack-name kiro-vpc --region us-east-1

# Empty artifact bucket
$ACCOUNT_ID = (aws sts get-caller-identity --query Account --output text)
aws s3 rb s3://kiro-pipeline-artifacts-$ACCOUNT_ID --force --region us-east-1
```

**Linux/Mac:**
```bash
# Use the cleanup script
./scripts/cleanup.sh
```

### Verify Deletion

```bash
# Check stack status
aws cloudformation list-stacks --query 'StackSummaries[?contains(StackName, `kiro`)].{Name:StackName,Status:StackStatus}' --output table
```

## Cost Optimization

### Reduce Costs

1. **Use smaller instances:**
   - Edit `eks-parameters.json`
   - Change `NodeInstanceType` to `t3.small`

2. **Reduce node count:**
   - Change `NodeGroupDesiredCapacity` to `1`

3. **Use single NAT Gateway:**
   - Modify VPC template to use one NAT Gateway

4. **Delete when not in use:**
   - Run cleanup script when not testing

### Estimated Costs (us-east-1)

- EKS Cluster: $73/month
- EC2 (2x t3.medium): $60/month
- NAT Gateways (2): $65/month
- LoadBalancer: $20/month
- ECR: $1/month
- **Total: ~$220/month**

## Next Steps

1. ✅ Customize the application (edit `index.html`, `Dockerfile`)
2. ✅ Add environment variables to deployment
3. ✅ Configure auto-scaling (HPA)
4. ✅ Add SSL/TLS with AWS Certificate Manager
5. ✅ Implement monitoring with CloudWatch Container Insights
6. ✅ Add secrets management with AWS Secrets Manager
7. ✅ Configure logging aggregation

## Additional Resources

- [EKS Documentation](https://docs.aws.amazon.com/eks/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [CodePipeline Documentation](https://docs.aws.amazon.com/codepipeline/)
- [ECR Documentation](https://docs.aws.amazon.com/ecr/)
