# Build and Deploy Your Custom Application to EKS

Currently, your EKS cluster is running **nginx:alpine** as a test. This guide shows you how to deploy your custom application.

---

## Option 1: Install Docker and Build Locally (Recommended)

### Step 1: Install Docker Desktop for Windows

1. **Download Docker Desktop**:
   - Go to: https://www.docker.com/products/docker-desktop/
   - Download Docker Desktop for Windows
   - Run the installer

2. **Install and Start Docker**:
   - Follow the installation wizard
   - Restart your computer if prompted
   - Start Docker Desktop
   - Wait for Docker to be running (check system tray icon)

3. **Verify Installation**:
   ```powershell
   docker --version
   docker ps
   ```

### Step 2: Login to ECR

```powershell
# Get ECR login credentials
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 047861165149.dkr.ecr.us-east-1.amazonaws.com
```

Expected output: `Login Succeeded`

### Step 3: Build Your Docker Image

```powershell
cd eks-project

# Build the image (uses Dockerfile and index.html in current directory)
docker build -t kiro-app-repo:latest .
```

This will:
- Use the `Dockerfile` in your project
- Copy `index.html` into the nginx container
- Create an image tagged as `kiro-app-repo:latest`

### Step 4: Tag the Image for ECR

```powershell
docker tag kiro-app-repo:latest 047861165149.dkr.ecr.us-east-1.amazonaws.com/kiro-app-repo:latest
```

### Step 5: Push to ECR

```powershell
docker push 047861165149.dkr.ecr.us-east-1.amazonaws.com/kiro-app-repo:latest
```

### Step 6: Update Kubernetes Deployment

```powershell
# Update the deployment to use your custom image
.\kubectl.exe set image deployment/kiro-app kiro-app=047861165149.dkr.ecr.us-east-1.amazonaws.com/kiro-app-repo:latest -n kiro-app

# Watch the rollout
.\kubectl.exe rollout status deployment/kiro-app -n kiro-app

# Verify pods are running
.\kubectl.exe get pods -n kiro-app
```

### Step 7: Access Your Application

```powershell
# Get the LoadBalancer URL
.\kubectl.exe get svc -n kiro-app

# Open in browser
start http://af75256e0174c4ec48728b30194caa379-969056751.us-east-1.elb.amazonaws.com
```

---

## Option 2: Use AWS CodeBuild (No Docker Required)

If you don't want to install Docker locally, you can use AWS CodeBuild to build and push the image.

### Step 1: Create a Simple CodeBuild Project

```powershell
# Create a zip of your project files
Compress-Archive -Path Dockerfile,index.html,buildspec.yml -DestinationPath app-source.zip

# Upload to S3 (create bucket first if needed)
aws s3 mb s3://kiro-build-source-047861165149 --region us-east-1
aws s3 cp app-source.zip s3://kiro-build-source-047861165149/
```

### Step 2: Create CodeBuild Project

Create file `codebuild-project.json`:
```json
{
  "name": "kiro-app-manual-build",
  "source": {
    "type": "S3",
    "location": "kiro-build-source-047861165149/app-source.zip"
  },
  "artifacts": {
    "type": "NO_ARTIFACTS"
  },
  "environment": {
    "type": "LINUX_CONTAINER",
    "image": "aws/codebuild/standard:7.0",
    "computeType": "BUILD_GENERAL1_SMALL",
    "privilegedMode": true,
    "environmentVariables": [
      {
        "name": "AWS_DEFAULT_REGION",
        "value": "us-east-1"
      },
      {
        "name": "AWS_ACCOUNT_ID",
        "value": "047861165149"
      },
      {
        "name": "IMAGE_REPO_NAME",
        "value": "kiro-app-repo"
      },
      {
        "name": "IMAGE_TAG",
        "value": "latest"
      }
    ]
  },
  "serviceRole": "arn:aws:iam::047861165149:role/kiro-codebuild-role"
}
```

### Step 3: Start Build

```powershell
# Create the project
aws codebuild create-project --cli-input-json file://codebuild-project.json

# Start a build
aws codebuild start-build --project-name kiro-app-manual-build
```

---

## Option 3: Update Deployment YAML Manually

If you want to use your custom image later, update the deployment file:

### Edit `kubernetes/deployment.yaml`

Change line with image from:
```yaml
image: ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/kiro-app-repo:latest
```

To:
```yaml
image: 047861165149.dkr.ecr.us-east-1.amazonaws.com/kiro-app-repo:latest
```

Then apply:
```powershell
.\kubectl.exe apply -f kubernetes/deployment.yaml
```

---

## Your Custom Application Files

### Dockerfile (already created)
```dockerfile
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### index.html (already created)
Your custom HTML page with the Kiro App branding.

---

## Verify Image in ECR

After pushing, verify the image exists:

```powershell
# List images in ECR
aws ecr list-images --repository-name kiro-app-repo --region us-east-1

# Get image details
aws ecr describe-images --repository-name kiro-app-repo --region us-east-1
```

---

## Troubleshooting

### Docker Login Issues

If login fails:
```powershell
# Check AWS credentials
aws sts get-caller-identity

# Try login again with explicit region
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 047861165149.dkr.ecr.us-east-1.amazonaws.com
```

### Build Fails

```powershell
# Check Dockerfile syntax
docker build -t test .

# View build logs
docker build -t kiro-app-repo:latest . --progress=plain
```

### Image Pull Errors in Kubernetes

```powershell
# Check if image exists in ECR
aws ecr describe-images --repository-name kiro-app-repo

# Check pod events
.\kubectl.exe describe pod -n kiro-app <pod-name>

# Check node IAM role has ECR permissions
.\kubectl.exe describe node <node-name>
```

### Pods Not Updating

```powershell
# Force rollout restart
.\kubectl.exe rollout restart deployment/kiro-app -n kiro-app

# Delete pods to force recreation
.\kubectl.exe delete pods -n kiro-app -l app=kiro-app
```

---

## Quick Commands Reference

```powershell
# Build and push (after Docker is installed)
docker build -t kiro-app-repo:latest .
docker tag kiro-app-repo:latest 047861165149.dkr.ecr.us-east-1.amazonaws.com/kiro-app-repo:latest
docker push 047861165149.dkr.ecr.us-east-1.amazonaws.com/kiro-app-repo:latest

# Update deployment
.\kubectl.exe set image deployment/kiro-app kiro-app=047861165149.dkr.ecr.us-east-1.amazonaws.com/kiro-app-repo:latest -n kiro-app

# Check status
.\kubectl.exe get pods -n kiro-app
.\kubectl.exe rollout status deployment/kiro-app -n kiro-app

# View logs
.\kubectl.exe logs -n kiro-app -l app=kiro-app

# Get URL
.\kubectl.exe get svc -n kiro-app
```

---

## Next Steps After Deploying Custom Image

1. **Test your application**: Access the LoadBalancer URL
2. **Monitor logs**: `.\kubectl.exe logs -f -n kiro-app -l app=kiro-app`
3. **Scale if needed**: `.\kubectl.exe scale deployment/kiro-app --replicas=3 -n kiro-app`
4. **Set up CI/CD**: Deploy the pipeline stack for automatic deployments
5. **Add custom domain**: Configure Route53 and SSL certificate

---

## Current Status

✅ **Infrastructure**: Fully deployed  
✅ **EKS Cluster**: Running with 2 nodes  
✅ **Application**: Running nginx:alpine (test)  
⏳ **Custom Image**: Waiting for Docker installation and build  

**Once Docker is installed, follow Option 1 to deploy your custom application!**
