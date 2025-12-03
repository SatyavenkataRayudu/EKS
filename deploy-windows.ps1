# Windows PowerShell Deployment Script for EKS Project

$ErrorActionPreference = "Stop"
$Region = "us-east-1"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "AWS EKS Infrastructure Deployment" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Check AWS CLI
Write-Host "Checking AWS CLI..." -ForegroundColor Yellow
try {
    $awsVersion = aws --version
    Write-Host "✓ AWS CLI found: $awsVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ AWS CLI not found. Please install AWS CLI first." -ForegroundColor Red
    exit 1
}

# Check kubectl
Write-Host "Checking kubectl..." -ForegroundColor Yellow
try {
    $kubectlVersion = kubectl version --client --short 2>$null
    Write-Host "✓ kubectl found" -ForegroundColor Green
} catch {
    Write-Host "⚠ kubectl not found. You'll need it later." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "This will deploy:" -ForegroundColor Cyan
Write-Host "  1. VPC with subnets and gateways (~5 min)" -ForegroundColor White
Write-Host "  2. ECR repository (~1 min)" -ForegroundColor White
Write-Host "  3. EKS cluster with nodes (~15-20 min)" -ForegroundColor White
Write-Host "  4. CI/CD pipeline (~2 min)" -ForegroundColor White
Write-Host ""
Write-Host "Total time: ~25-30 minutes" -ForegroundColor Yellow
Write-Host "Estimated cost: ~$220/month" -ForegroundColor Yellow
Write-Host ""

$confirm = Read-Host "Continue? (yes/no)"
if ($confirm -ne "yes") {
    Write-Host "Deployment cancelled" -ForegroundColor Red
    exit 0
}

# Step 1: Deploy VPC
Write-Host ""
Write-Host "Step 1/4: Deploying VPC..." -ForegroundColor Cyan
try {
    aws cloudformation create-stack `
        --stack-name kiro-vpc `
        --template-body file://infrastructure/vpc-template.yaml `
        --region $Region
    
    Write-Host "Waiting for VPC stack..." -ForegroundColor Yellow
    aws cloudformation wait stack-create-complete `
        --stack-name kiro-vpc `
        --region $Region
    
    Write-Host "✓ VPC deployed successfully" -ForegroundColor Green
} catch {
    Write-Host "✗ VPC deployment failed: $_" -ForegroundColor Red
    exit 1
}

# Step 2: Deploy ECR
Write-Host ""
Write-Host "Step 2/4: Deploying ECR..." -ForegroundColor Cyan
try {
    aws cloudformation create-stack `
        --stack-name kiro-ecr `
        --template-body file://infrastructure/ecr-template.yaml `
        --region $Region
    
    Write-Host "Waiting for ECR stack..." -ForegroundColor Yellow
    aws cloudformation wait stack-create-complete `
        --stack-name kiro-ecr `
        --region $Region
    
    Write-Host "✓ ECR deployed successfully" -ForegroundColor Green
} catch {
    Write-Host "✗ ECR deployment failed: $_" -ForegroundColor Red
    exit 1
}

# Step 3: Deploy EKS
Write-Host ""
Write-Host "Step 3/4: Deploying EKS cluster..." -ForegroundColor Cyan
Write-Host "This will take 15-20 minutes. Please be patient..." -ForegroundColor Yellow
try {
    aws cloudformation create-stack `
        --stack-name kiro-eks `
        --template-body file://infrastructure/eks-template.yaml `
        --parameters file://infrastructure/eks-parameters.json `
        --capabilities CAPABILITY_NAMED_IAM `
        --region $Region
    
    Write-Host "Waiting for EKS stack (this takes a while)..." -ForegroundColor Yellow
    aws cloudformation wait stack-create-complete `
        --stack-name kiro-eks `
        --region $Region
    
    Write-Host "✓ EKS cluster deployed successfully" -ForegroundColor Green
} catch {
    Write-Host "✗ EKS deployment failed: $_" -ForegroundColor Red
    exit 1
}

# Step 4: Deploy Pipeline
Write-Host ""
Write-Host "Step 4/4: Deploying CI/CD pipeline..." -ForegroundColor Cyan
Write-Host ""
Write-Host "⚠ IMPORTANT: Make sure you've updated pipeline-parameters.json with:" -ForegroundColor Yellow
Write-Host "  - Your GitHub repository (username/repo)" -ForegroundColor White
Write-Host "  - Your GitHub personal access token" -ForegroundColor White
Write-Host ""
$pipelineConfirm = Read-Host "Have you updated pipeline-parameters.json? (yes/no)"
if ($pipelineConfirm -ne "yes") {
    Write-Host "Please update infrastructure/pipeline-parameters.json and run this script again" -ForegroundColor Yellow
    Write-Host "Or deploy the pipeline manually later" -ForegroundColor Yellow
} else {
    try {
        aws cloudformation create-stack `
            --stack-name kiro-pipeline `
            --template-body file://infrastructure/pipeline-template.yaml `
            --parameters file://infrastructure/pipeline-parameters.json `
            --capabilities CAPABILITY_NAMED_IAM `
            --region $Region
        
        Write-Host "Waiting for Pipeline stack..." -ForegroundColor Yellow
        aws cloudformation wait stack-create-complete `
            --stack-name kiro-pipeline `
            --region $Region
        
        Write-Host "✓ Pipeline deployed successfully" -ForegroundColor Green
    } catch {
        Write-Host "✗ Pipeline deployment failed: $_" -ForegroundColor Red
        Write-Host "You can deploy it manually later" -ForegroundColor Yellow
    }
}

# Display outputs
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Retrieving outputs..." -ForegroundColor Yellow
Write-Host ""

Write-Host "VPC Outputs:" -ForegroundColor Cyan
aws cloudformation describe-stacks `
    --stack-name kiro-vpc `
    --region $Region `
    --query 'Stacks[0].Outputs' `
    --output table

Write-Host ""
Write-Host "EKS Outputs:" -ForegroundColor Cyan
aws cloudformation describe-stacks `
    --stack-name kiro-eks `
    --region $Region `
    --query 'Stacks[0].Outputs' `
    --output table

Write-Host ""
Write-Host "ECR Outputs:" -ForegroundColor Cyan
aws cloudformation describe-stacks `
    --stack-name kiro-ecr `
    --region $Region `
    --query 'Stacks[0].Outputs' `
    --output table

if ($pipelineConfirm -eq "yes") {
    Write-Host ""
    Write-Host "Pipeline Outputs:" -ForegroundColor Cyan
    aws cloudformation describe-stacks `
        --stack-name kiro-pipeline `
        --region $Region `
        --query 'Stacks[0].Outputs' `
        --output table
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Configure kubectl:" -ForegroundColor White
Write-Host "   aws eks update-kubeconfig --name kiro-eks-cluster --region us-east-1" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Deploy Kubernetes manifests:" -ForegroundColor White
Write-Host "   kubectl apply -f kubernetes/namespace.yaml" -ForegroundColor Gray
Write-Host "   kubectl apply -f kubernetes/deployment.yaml" -ForegroundColor Gray
Write-Host "   kubectl apply -f kubernetes/service.yaml" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Check deployment:" -ForegroundColor White
Write-Host "   kubectl get pods -n kiro-app" -ForegroundColor Gray
Write-Host "   kubectl get svc -n kiro-app" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Get application URL:" -ForegroundColor White
Write-Host "   kubectl get svc kiro-app-service -n kiro-app" -ForegroundColor Gray
Write-Host ""
Write-Host "5. Push code to GitHub to trigger pipeline" -ForegroundColor White
Write-Host ""
Write-Host "For more details, see DEPLOYMENT_GUIDE.md" -ForegroundColor Cyan
Write-Host ""
