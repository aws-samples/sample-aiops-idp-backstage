#!/bin/zsh

# Fork and Sync Script
# Forks a GitHub repository, clones it, and adds specific directories

set -e

# Prompt for GitHub username
echo "Enter your GitHub username:"
read GITHUB_USERNAME

SOURCE_REPO="awslabs/aiops-modules"
SOURCE_REPO_URL="https://github.com/$SOURCE_REPO.git"
FORKED_REPO_URL="https://github.com/$GITHUB_USERNAME/aiops-modules.git"
TEMP_DIR="/tmp/fork-sync-$(date +%s)"

# Check if GitHub CLI is installed
if ! command -v gh >/dev/null 2>&1; then
  echo "Error: GitHub CLI (gh) is not installed."
  echo "Please install it from https://cli.github.com/ and authenticate with 'gh auth login'"
  exit 1
fi

# Check if user is authenticated with GitHub CLI
if ! gh auth status >/dev/null 2>&1; then
  echo "Error: You are not authenticated with GitHub CLI."
  echo "Please run 'gh auth login' to authenticate."
  exit 1
fi

echo "Creating temporary directory: $TEMP_DIR"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# Fork the repository using GitHub CLI
echo "Forking repository $SOURCE_REPO..."
gh repo fork "$SOURCE_REPO" --clone=false

echo "Repository forked to: $FORKED_REPO_URL"

# Clone the forked repository
echo "Cloning forked repository..."
git clone "$FORKED_REPO_URL" forked-repo
cd forked-repo

# Create directories if they don't exist
mkdir -p .github/workflows
mkdir -p aiops-modules/manifests/mlops-sagemaker

# Create workflow files with correct username reference
cat > .github/workflows/.checkov.yml << 'EOF'
skip-check:
  - CKV_GHA_7  # Workflow dispatch inputs required for deployment parameters
  - CKV2_GHA_1 # Workflow dispatch inputs required for deployment parameters
EOF

cat > .github/workflows/sagemaker-custom-kernel.yml << EOF
#This file will be present in .github/workflow inside aiops-modules repo
name: Deploy SageMaker custom kernel template
on:
  workflow_dispatch:
    inputs:
      deploymentName:
        description: 'Name of the deployment'
        required: true
        default: 'aiops'
      awsRegion:
        description: 'AWS Region for deployment'
        required: true
        default: 'us-east-1'
      action:
        description: 'Action to perform (deploy/destroy)'
        required: true
        type: choice
        options:
          - deploy
          - destroy
      awsAccountId:
        description: 'AWS Account ID'
        required: true
      adminRoleArn:
        description: 'Admin Role ARN'
        required: true
      awsAccessKeyId:
        description: 'AWS Access Key ID'
        required: true
      awsSecretAccessKey:
        description: 'AWS Secret Access Key'
        required: true
      awsSessionToken:
        description: 'AWS Session Token'
        required: true
jobs:
  deploy_sagemaker_templates:
    runs-on: ubuntu-latest
    if: [38;5;2m${{ github.event.inputs.action == 'deploy' }}[0m
    steps:
    - name: Clone AIOps Modules Repository
      run: |
        git clone --origin upstream --branch main https://github.com/$GITHUB_USERNAME/aiops-modules.git
        cd aiops-modules
    
    - name: Setup Python Environment
      run: |
        cd aiops-modules
        python3 -m venv .venv && source .venv/bin/activate
        pip install --upgrade pip setuptools wheel
        pip install -r ./requirements.txt
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '20'
    
    - name: Install CDK CLI
      run: |
        npm install -g aws-cdk
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ github.event.inputs.awsAccessKeyId }}
        aws-secret-access-key: ${{ github.event.inputs.awsSecretAccessKey }}
        aws-session-token: ${{ github.event.inputs.awsSessionToken }}
        aws-region: ${{ github.event.inputs.awsRegion }}
    
    - name: Set Environment Variables
      run: |
        cd aiops-modules
        echo "PRIMARY_ACCOUNT=${{ github.event.inputs.awsAccountId }}" >> $GITHUB_ENV
        echo "ADMIN_ROLE_ARN=${{ github.event.inputs.adminRoleArn }}" >> $GITHUB_ENV
    
    - name: Bootstrap CDK Environment
      run: |
        cd aiops-modules
        source .venv/bin/activate
        npx cdk bootstrap aws://${{ github.event.inputs.awsAccountId }}/${{ github.event.inputs.awsRegion }}
    
    - name: Bootstrap AWS Account for SeedFarmer
      run: |
        cd aiops-modules
        source .venv/bin/activate
        seedfarmer bootstrap toolchain --project ${{ github.event.inputs.deploymentName }} --trusted-principal ${{ github.event.inputs.adminRoleArn }} --as-target
    
    - name: Deploy Using SeedFarmer
      run: |
        cd aiops-modules
        export PRIMARY_REGION=eu-east-1
        source .venv/bin/activate
        seedfarmer apply manifests/mlops-sagemaker/sagemaker-custom-kernel-deployment.yaml

  destroy_sagemaker_templates:
    runs-on: ubuntu-latest
    if: ${{ github.event.inputs.action == 'destroy' }}
    steps:
    - name: Clone AIOps Modules Repository
      run: |
        git clone --origin upstream --branch release/1.8.0 https://github.com/awslabs/aiops-modules
        cd aiops-modules
    
    - name: Setup Python Environment
      run: |
        cd aiops-modules
        python3 -m venv .venv && source .venv/bin/activate
        pip install --upgrade pip setuptools wheel
        pip install -r ./requirements.txt
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '20'
    
    - name: Install CDK CLI
      run: |
        npm install -g aws-cdk
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ github.event.inputs.awsAccessKeyId }}
        aws-secret-access-key: ${{ github.event.inputs.awsSecretAccessKey }}
        aws-session-token: ${{ github.event.inputs.awsSessionToken }}
        aws-region: ${{ github.event.inputs.awsRegion }}
    
    - name: Destroy Using SeedFarmer
      run: |
        cd aiops-modules
        source .venv/bin/activate
        seedfarmer destroy ${{ github.event.inputs.deploymentName }}
EOF

# Repeat for other workflow files, always using $GITHUB_USERNAME in repo URLs
# Example for sagemaker-endpoint.yml
cat > .github/workflows/sagemaker-endpoint.yml << EOF
#This file will be present in .github/workflow inside aiops-modules repo
name: Deploy SageMaker endpoint template
on:
  workflow_dispatch:
    inputs:
      deploymentName:
        description: 'Name of the deployment'
        required: true
        default: 'aiops'
      awsRegion:
        description: 'AWS Region for deployment'
        required: true
        default: 'us-east-1'
      action:
        description: 'Action to perform (deploy/destroy)'
        required: true
        type: choice
        options:
          - deploy
          - destroy
      awsAccountId:
        description: 'AWS Account ID'
        required: true
      adminRoleArn:
        description: 'Admin Role ARN'
        required: true
      awsAccessKeyId:
        description: 'AWS Access Key ID'
        required: true
      awsSecretAccessKey:
        description: 'AWS Secret Access Key'
        required: true
      awsSessionToken:
        description: 'AWS Session Token'
        required: true
jobs:
  deploy_sagemaker_templates:
    runs-on: ubuntu-latest
    if: [38;5;2m${{ github.event.inputs.action == 'deploy' }}[0m
    steps:
    - name: Clone AIOps Modules Repository
      run: |
        git clone --origin upstream --branch main https://github.com/$GITHUB_USERNAME/aiops-modules.git
        cd aiops-modules
    
    - name: Setup Python Environment
      run: |
        cd aiops-modules
        python3 -m venv .venv && source .venv/bin/activate
        pip install --upgrade pip setuptools wheel
        pip install -r ./requirements.txt
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '20'
    
    - name: Install CDK CLI
      run: |
        npm install -g aws-cdk
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ github.event.inputs.awsAccessKeyId }}
        aws-secret-access-key: ${{ github.event.inputs.awsSecretAccessKey }}
        aws-session-token: ${{ github.event.inputs.awsSessionToken }}
        aws-region: ${{ github.event.inputs.awsRegion }}
    
    - name: Set Environment Variables
      run: |
        cd aiops-modules
        echo "PRIMARY_ACCOUNT=${{ github.event.inputs.awsAccountId }}" >> $GITHUB_ENV
        echo "ADMIN_ROLE_ARN=${{ github.event.inputs.adminRoleArn }}" >> $GITHUB_ENV
    
    - name: Bootstrap CDK Environment
      run: |
        cd aiops-modules
        source .venv/bin/activate
        npx cdk bootstrap aws://${{ github.event.inputs.awsAccountId }}/${{ github.event.inputs.awsRegion }}
    
    - name: Bootstrap AWS Account for SeedFarmer
      run: |
        cd aiops-modules
        source .venv/bin/activate
        seedfarmer bootstrap toolchain --project ${{ github.event.inputs.deploymentName }} --trusted-principal ${{ github.event.inputs.adminRoleArn }} --as-target
    
    - name: Deploy Using SeedFarmer
      run: |
        cd aiops-modules
        export PRIMARY_REGION=eu-east-1
        source .venv/bin/activate
        seedfarmer apply manifests/mlops-sagemaker/sagemaker-endpoints-deployment.yaml

  destroy_sagemaker_templates:
    runs-on: ubuntu-latest
    if: ${{ github.event.inputs.action == 'destroy' }}
    steps:
    - name: Clone AIOps Modules Repository
      run: |
        git clone --origin upstream --branch release/1.8.0 https://github.com/awslabs/aiops-modules
        cd aiops-modules
    
    - name: Setup Python Environment
      run: |
        cd aiops-modules
        python3 -m venv .venv && source .venv/bin/activate
        pip install --upgrade pip setuptools wheel
        pip install -r ./requirements.txt
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '20'
    
    - name: Install CDK CLI
      run: |
        npm install -g aws-cdk
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ github.event.inputs.awsAccessKeyId }}
        aws-secret-access-key: ${{ github.event.inputs.awsSecretAccessKey }}
        aws-session-token: ${{ github.event.inputs.awsSessionToken }}
        aws-region: ${{ github.event.inputs.awsRegion }}
    
    - name: Destroy Using SeedFarmer
      run: |
        cd aiops-modules
        source .venv/bin/activate
        seedfarmer destroy ${{ github.event.inputs.deploymentName }}
EOF

cat > .github/workflows/sagemaker-model-monitoring.yml << EOF
#This file will be present in .github/workflow inside aiops-modules repo
name: Deploy SageMaker model monitoring
on:
  workflow_dispatch:
    inputs:
      deploymentName:
        description: 'Name of the deployment'
        required: true
        default: 'aiops'
      awsRegion:
        description: 'AWS Region for deployment'
        required: true
        default: 'us-east-1'
      action:
        description: 'Action to perform (deploy/destroy)'
        required: true
        type: choice
        options:
          - deploy
          - destroy
      awsAccountId:
        description: 'AWS Account ID'
        required: true
      adminRoleArn:
        description: 'Admin Role ARN'
        required: true
      awsAccessKeyId:
        description: 'AWS Access Key ID'
        required: true
      awsSecretAccessKey:
        description: 'AWS Secret Access Key'
        required: true
      awsSessionToken:
        description: 'AWS Session Token'
        required: true
jobs:
  deploy_sagemaker_templates:
    runs-on: ubuntu-latest
    if: [38;5;2m${{ github.event.inputs.action == 'deploy' }}[0m
    steps:
    - name: Clone AIOps Modules Repository
      run: |
        git clone --origin upstream --branch main https://github.com/$GITHUB_USERNAME/aiops-modules.git
        cd aiops-modules
    
    - name: Setup Python Environment
      run: |
        cd aiops-modules
        python3 -m venv .venv && source .venv/bin/activate
        pip install --upgrade pip setuptools wheel
        pip install -r ./requirements.txt
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '20'
    
    - name: Install CDK CLI
      run: |
        npm install -g aws-cdk
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ github.event.inputs.awsAccessKeyId }}
        aws-secret-access-key: ${{ github.event.inputs.awsSecretAccessKey }}
        aws-session-token: ${{ github.event.inputs.awsSessionToken }}
        aws-region: ${{ github.event.inputs.awsRegion }}
    
    - name: Set Environment Variables
      run: |
        cd aiops-modules
        echo "PRIMARY_ACCOUNT=${{ github.event.inputs.awsAccountId }}" >> $GITHUB_ENV
        echo "ADMIN_ROLE_ARN=${{ github.event.inputs.adminRoleArn }}" >> $GITHUB_ENV
    
    - name: Bootstrap CDK Environment
      run: |
        cd aiops-modules
        source .venv/bin/activate
        npx cdk bootstrap aws://${{ github.event.inputs.awsAccountId }}/${{ github.event.inputs.awsRegion }}
    
    - name: Bootstrap AWS Account for SeedFarmer
      run: |
        cd aiops-modules
        source .venv/bin/activate
        seedfarmer bootstrap toolchain --project ${{ github.event.inputs.deploymentName }} --trusted-principal ${{ github.event.inputs.adminRoleArn }} --as-target
    
    - name: Deploy Using SeedFarmer
      run: |
        cd aiops-modules
        export PRIMARY_REGION=eu-east-1
        source .venv/bin/activate
        seedfarmer apply manifests/mlops-sagemaker/sagemaker-model-monitoring-deployment.yaml

  destroy_sagemaker_templates:
    runs-on: ubuntu-latest
    if: ${{ github.event.inputs.action == 'destroy' }}
    steps:
    - name: Clone AIOps Modules Repository
      run: |
        git clone --origin upstream --branch release/1.8.0 https://github.com/awslabs/aiops-modules
        cd aiops-modules
    
    - name: Setup Python Environment
      run: |
        cd aiops-modules
        python3 -m venv .venv && source .venv/bin/activate
        pip install --upgrade pip setuptools wheel
        pip install -r ./requirements.txt
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '20'
    
    - name: Install CDK CLI
      run: |
        npm install -g aws-cdk
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ github.event.inputs.awsAccessKeyId }}
        aws-secret-access-key: ${{ github.event.inputs.awsSecretAccessKey }}
        aws-session-token: ${{ github.event.inputs.awsSessionToken }}
        aws-region: ${{ github.event.inputs.awsRegion }}
    
    - name: Destroy Using SeedFarmer
      run: |
        cd aiops-modules
        source .venv/bin/activate
        seedfarmer destroy ${{ github.event.inputs.deploymentName }}
EOF

cat > .github/workflows/sagemaker-model-package-group.yml << EOF
#This file will be present in .github/workflow inside aiops-modules repo
name: Deploy SageMaker model package group
on:
  workflow_dispatch:
    inputs:
      deploymentName:
        description: 'Name of the deployment'
        required: true
        default: 'aiops'
      awsRegion:
        description: 'AWS Region for deployment'
        required: true
        default: 'us-east-1'
      action:
        description: 'Action to perform (deploy/destroy)'
        required: true
        type: choice
        options:
          - deploy
          - destroy
      awsAccountId:
        description: 'AWS Account ID'
        required: true
      adminRoleArn:
        description: 'Admin Role ARN'
        required: true
      awsAccessKeyId:
        description: 'AWS Access Key ID'
        required: true
      awsSecretAccessKey:
        description: 'AWS Secret Access Key'
        required: true
      awsSessionToken:
        description: 'AWS Session Token'
        required: true
jobs:
  deploy_sagemaker_templates:
    runs-on: ubuntu-latest
    if: [38;5;2m${{ github.event.inputs.action == 'deploy' }}[0m
    steps:
    - name: Clone AIOps Modules Repository
      run: |
        git clone --origin upstream --branch main https://github.com/$GITHUB_USERNAME/aiops-modules.git
        cd aiops-modules
    
    - name: Setup Python Environment
      run: |
        cd aiops-modules
        python3 -m venv .venv && source .venv/bin/activate
        pip install --upgrade pip setuptools wheel
        pip install -r ./requirements.txt
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '20'
    
    - name: Install CDK CLI
      run: |
        npm install -g aws-cdk
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ github.event.inputs.awsAccessKeyId }}
        aws-secret-access-key: ${{ github.event.inputs.awsSecretAccessKey }}
        aws-session-token: ${{ github.event.inputs.awsSessionToken }}
        aws-region: ${{ github.event.inputs.awsRegion }}
    
    - name: Set Environment Variables
      run: |
        cd aiops-modules
        echo "PRIMARY_ACCOUNT=${{ github.event.inputs.awsAccountId }}" >> $GITHUB_ENV
        echo "ADMIN_ROLE_ARN=${{ github.event.inputs.adminRoleArn }}" >> $GITHUB_ENV
    
    - name: Bootstrap CDK Environment
      run: |
        cd aiops-modules
        source .venv/bin/activate
        npx cdk bootstrap aws://${{ github.event.inputs.awsAccountId }}/${{ github.event.inputs.awsRegion }}
    
    - name: Bootstrap AWS Account for SeedFarmer
      run: |
        cd aiops-modules
        source .venv/bin/activate
        seedfarmer bootstrap toolchain --project ${{ github.event.inputs.deploymentName }} --trusted-principal ${{ github.event.inputs.adminRoleArn }} --as-target
    
    - name: Deploy Using SeedFarmer
      run: |
        cd aiops-modules
        export PRIMARY_REGION=eu-east-1
        source .venv/bin/activate
        seedfarmer apply manifests/mlops-sagemaker/sagemaker-model-package-group-deployment.yaml

  destroy_sagemaker_templates:
    runs-on: ubuntu-latest
    if: ${{ github.event.inputs.action == 'destroy' }}
    steps:
    - name: Clone AIOps Modules Repository
      run: |
        git clone --origin upstream --branch release/1.8.0 https://github.com/awslabs/aiops-modules
        cd aiops-modules
    
    - name: Setup Python Environment
      run: |
        cd aiops-modules
        python3 -m venv .venv && source .venv/bin/activate
        pip install --upgrade pip setuptools wheel
        pip install -r ./requirements.txt
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '20'
    
    - name: Install CDK CLI
      run: |
        npm install -g aws-cdk
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ github.event.inputs.awsAccessKeyId }}
        aws-secret-access-key: ${{ github.event.inputs.awsSecretAccessKey }}
        aws-session-token: ${{ github.event.inputs.awsSessionToken }}
        aws-region: ${{ github.event.inputs.awsRegion }}
    
    - name: Destroy Using SeedFarmer
      run: |
        cd aiops-modules
        source .venv/bin/activate
        seedfarmer destroy ${{ github.event.inputs.deploymentName }}
EOF

cat > .github/workflows/sagemaker-model-package-promote-pipeline.yml << EOF
#This file will be present in .github/workflow inside aiops-modules repo
name: Deploy SageMaker model package promote pipeline
on:
  workflow_dispatch:
    inputs:
      deploymentName:
        description: 'Name of the deployment'
        required: true
        default: 'aiops'
      awsRegion:
        description: 'AWS Region for deployment'
        required: true
        default: 'us-east-1'
      action:
        description: 'Action to perform (deploy/destroy)'
        required: true
        type: choice
        options:
          - deploy
          - destroy
      awsAccountId:
        description: 'AWS Account ID'
        required: true
      adminRoleArn:
        description: 'Admin Role ARN'
        required: true
      awsAccessKeyId:
        description: 'AWS Access Key ID'
        required: true
      awsSecretAccessKey:
        description: 'AWS Secret Access Key'
        required: true
      awsSessionToken:
        description: 'AWS Session Token'
        required: true
jobs:
  deploy_sagemaker_templates:
    runs-on: ubuntu-latest
    if: [38;5;2m${{ github.event.inputs.action == 'deploy' }}[0m
    steps:
    - name: Clone AIOps Modules Repository
      run: |
        git clone --origin upstream --branch main https://github.com/$GITHUB_USERNAME/aiops-modules.git
        cd aiops-modules
    
    - name: Setup Python Environment
      run: |
        cd aiops-modules
        python3 -m venv .venv && source .venv/bin/activate
        pip install --upgrade pip setuptools wheel
        pip install -r ./requirements.txt
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '20'
    
    - name: Install CDK CLI
      run: |
        npm install -g aws-cdk
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ github.event.inputs.awsAccessKeyId }}
        aws-secret-access-key: ${{ github.event.inputs.awsSecretAccessKey }}
        aws-session-token: ${{ github.event.inputs.awsSessionToken }}
        aws-region: ${{ github.event.inputs.awsRegion }}
    
    - name: Set Environment Variables
      run: |
        cd aiops-modules
        echo "PRIMARY_ACCOUNT=${{ github.event.inputs.awsAccountId }}" >> $GITHUB_ENV
        echo "ADMIN_ROLE_ARN=${{ github.event.inputs.adminRoleArn }}" >> $GITHUB_ENV
    
    - name: Bootstrap CDK Environment
      run: |
        cd aiops-modules
        source .venv/bin/activate
        npx cdk bootstrap aws://${{ github.event.inputs.awsAccountId }}/${{ github.event.inputs.awsRegion }}
    
    - name: Bootstrap AWS Account for SeedFarmer
      run: |
        cd aiops-modules
        source .venv/bin/activate
        seedfarmer bootstrap toolchain --project ${{ github.event.inputs.deploymentName }} --trusted-principal ${{ github.event.inputs.adminRoleArn }} --as-target
    
    - name: Deploy Using SeedFarmer
      run: |
        cd aiops-modules
        export PRIMARY_REGION=eu-east-1
        source .venv/bin/activate
        seedfarmer apply manifests/mlops-sagemaker/sagemaker-model-package-promote-pipeline-deployment.yaml

  destroy_sagemaker_templates:
    runs-on: ubuntu-latest
    if: ${{ github.event.inputs.action == 'destroy' }}
    steps:
    - name: Clone AIOps Modules Repository
      run: |
        git clone --origin upstream --branch release/1.8.0 https://github.com/awslabs/aiops-modules
        cd aiops-modules
    
    - name: Setup Python Environment
      run: |
        cd aiops-modules
        python3 -m venv .venv && source .venv/bin/activate
        pip install --upgrade pip setuptools wheel
        pip install -r ./requirements.txt
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '20'
    
    - name: Install CDK CLI
      run: |
        npm install -g aws-cdk
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ github.event.inputs.awsAccessKeyId }}
        aws-secret-access-key: ${{ github.event.inputs.awsSecretAccessKey }}
        aws-session-token: ${{ github.event.inputs.awsSessionToken }}
        aws-region: ${{ github.event.inputs.awsRegion }}
    
    - name: Destroy Using SeedFarmer
      run: |
        cd aiops-modules
        source .venv/bin/activate
        seedfarmer destroy ${{ github.event.inputs.deploymentName }}
EOF

cat > .github/workflows/sagemaker-notebook-template.yml << EOF
#This file will be present in .github/workflow inside aiops-modules repo
name: Deploy SageMaker Notebook template
on:
  workflow_dispatch:
    inputs:
      deploymentName:
        description: 'Name of the deployment'
        required: true
        default: 'aiops'
      awsRegion:
        description: 'AWS Region for deployment'
        required: true
        default: 'us-east-1'
      action:
        description: 'Action to perform (deploy/destroy)'
        required: true
        type: choice
        options:
          - deploy
          - destroy
      awsAccountId:
        description: 'AWS Account ID'
        required: true
      adminRoleArn:
        description: 'Admin Role ARN'
        required: true
      awsAccessKeyId:
        description: 'AWS Access Key ID'
        required: true
      awsSecretAccessKey:
        description: 'AWS Secret Access Key'
        required: true
      awsSessionToken:
        description: 'AWS Session Token'
        required: true
jobs:
  deploy_sagemaker_templates:
    runs-on: ubuntu-latest
    if: [38;5;2m${{ github.event.inputs.action == 'deploy' }}[0m
    steps:
    - name: Clone AIOps Modules Repository
      run: |
        git clone --origin upstream --branch main https://github.com/$GITHUB_USERNAME/aiops-modules.git
        cd aiops-modules
    
    - name: Setup Python Environment
      run: |
        cd aiops-modules
        python3 -m venv .venv && source .venv/bin/activate
        pip install --upgrade pip setuptools wheel
        pip install -r ./requirements.txt
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '20'
    
    - name: Install CDK CLI
      run: |
        npm install -g aws-cdk
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ github.event.inputs.awsAccessKeyId }}
        aws-secret-access-key: ${{ github.event.inputs.awsSecretAccessKey }}
        aws-session-token: ${{ github.event.inputs.awsSessionToken }}
        aws-region: ${{ github.event.inputs.awsRegion }}
    
    - name: Set Environment Variables
      run: |
        cd aiops-modules
        echo "PRIMARY_ACCOUNT=${{ github.event.inputs.awsAccountId }}" >> $GITHUB_ENV
        echo "ADMIN_ROLE_ARN=${{ github.event.inputs.adminRoleArn }}" >> $GITHUB_ENV
    
    - name: Bootstrap CDK Environment
      run: |
        cd aiops-modules
        source .venv/bin/activate
        npx cdk bootstrap aws://${{ github.event.inputs.awsAccountId }}/${{ github.event.inputs.awsRegion }}
    
    - name: Bootstrap AWS Account for SeedFarmer
      run: |
        cd aiops-modules
        source .venv/bin/activate
        seedfarmer bootstrap toolchain --project ${{ github.event.inputs.deploymentName }} --trusted-principal ${{ github.event.inputs.adminRoleArn }} --as-target
    
    - name: Deploy Using SeedFarmer
      run: |
        cd aiops-modules
        export PRIMARY_REGION=eu-east-1
        source .venv/bin/activate
        seedfarmer apply manifests/mlops-sagemaker/sagemaker-notebook-deployment.yaml

  destroy_sagemaker_templates:
    runs-on: ubuntu-latest
    if: ${{ github.event.inputs.action == 'destroy' }}
    steps:
    - name: Clone AIOps Modules Repository
      run: |
        git clone --origin upstream --branch release/1.8.0 https://github.com/awslabs/aiops-modules
        cd aiops-modules
    
    - name: Setup Python Environment
      run: |
        cd aiops-modules
        python3 -m venv .venv && source .venv/bin/activate
        pip install --upgrade pip setuptools wheel
        pip install -r ./requirements.txt
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '20'
    
    - name: Install CDK CLI
      run: |
        npm install -g aws-cdk
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ github.event.inputs.awsAccessKeyId }}
        aws-secret-access-key: ${{ github.event.inputs.awsSecretAccessKey }}
        aws-session-token: ${{ github.event.inputs.awsSessionToken }}
        aws-region: ${{ github.event.inputs.awsRegion }}
    
    - name: Destroy Using SeedFarmer
      run: |
        cd aiops-modules
        source .venv/bin/activate
        seedfarmer destroy ${{ github.event.inputs.deploymentName }}
EOF

cat > .github/workflows/sagemaker-service-catalog.yml << EOF
name: Deploy SageMaker Templates Service Catalog
on:
  workflow_dispatch:
    inputs:
      deploymentName:
        description: 'Name of the deployment'
        required: true
        default: 'aiops'
      awsRegion:
        description: 'AWS Region for deployment'
        required: true
        default: 'us-east-1'
      action:
        description: 'Action to perform (deploy/destroy)'
        required: true
        type: choice
        options:
          - deploy
          - destroy
      awsAccountId:
        description: 'AWS Account ID'
        required: true
      adminRoleArn:
        description: 'Admin Role ARN'
        required: true
      awsAccessKeyId:
        description: 'AWS Access Key ID'
        required: true
      awsSecretAccessKey:
        description: 'AWS Secret Access Key'
        required: true
      awsSessionToken:
        description: 'AWS Session Token'
        required: true
jobs:
  deploy_sagemaker_templates:
    runs-on: ubuntu-latest
    if: [38;5;2m${{ github.event.inputs.action == 'deploy' }}[0m
    steps:
    - name: Clone AIOps Modules Repository
      run: |
        git clone --origin upstream --branch main https://github.com/$GITHUB_USERNAME/aiops-modules.git
        cd aiops-modules
    
    - name: Setup Python Environment
      run: |
        cd aiops-modules
        python3 -m venv .venv && source .venv/bin/activate
        pip install --upgrade pip setuptools wheel
        pip install -r ./requirements.txt
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '20'
    
    - name: Install CDK CLI
      run: |
        npm install -g aws-cdk
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ github.event.inputs.awsAccessKeyId }}
        aws-secret-access-key: ${{ github.event.inputs.awsSecretAccessKey }}
        aws-session-token: ${{ github.event.inputs.awsSessionToken }}
        aws-region: ${{ github.event.inputs.awsRegion }}
    
    - name: Set Environment Variables
      run: |
        cd aiops-modules
        echo "PRIMARY_ACCOUNT=${{ github.event.inputs.awsAccountId }}" >> $GITHUB_ENV
        echo "ADMIN_ROLE_ARN=${{ github.event.inputs.adminRoleArn }}" >> $GITHUB_ENV
    
    - name: Bootstrap CDK Environment
      run: |
        cd aiops-modules
        source .venv/bin/activate
        npx cdk bootstrap aws://${{ github.event.inputs.awsAccountId }}/${{ github.event.inputs.awsRegion }}
    
    - name: Bootstrap AWS Account for SeedFarmer
      run: |
        cd aiops-modules
        source .venv/bin/activate
        seedfarmer bootstrap toolchain --project ${{ github.event.inputs.deploymentName }} --trusted-principal ${{ github.event.inputs.adminRoleArn }} --as-target
    
    - name: Deploy Using SeedFarmer
      run: |
        cd aiops-modules
        export PRIMARY_REGION=eu-east-1
        source .venv/bin/activate
        seedfarmer apply manifests/mlops-sagemaker/sagemaker-template-servicecatalog-deployment.yaml

  destroy_sagemaker_templates:
    runs-on: ubuntu-latest
    if: ${{ github.event.inputs.action == 'destroy' }}
    steps:
    - name: Clone AIOps Modules Repository
      run: |
        git clone --origin upstream --branch release/1.8.0 https://github.com/awslabs/aiops-modules
        cd aiops-modules
    
    - name: Setup Python Environment
      run: |
        cd aiops-modules
        python3 -m venv .venv && source .venv/bin/activate
        pip install --upgrade pip setuptools wheel
        pip install -r ./requirements.txt
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '20'
    
    - name: Install CDK CLI
      run: |
        npm install -g aws-cdk
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ github.event.inputs.awsAccessKeyId }}
        aws-secret-access-key: ${{ github.event.inputs.awsSecretAccessKey }}
        aws-session-token: ${{ github.event.inputs.awsSessionToken }}
        aws-region: ${{ github.event.inputs.awsRegion }}
    
    - name: Destroy Using SeedFarmer
      run: |
        cd aiops-modules
        source .venv/bin/activate
        seedfarmer destroy ${{ github.event.inputs.deploymentName }}
EOF

cat > .github/workflows/sagemaker-studio-template.yml << EOF
name: Deploy SageMaker Studio Templates
on:
  workflow_dispatch:
    inputs:
      deploymentName:
        description: 'Name of the deployment'
        required: true
        default: 'aiops'
      awsRegion:
        description: 'AWS Region for deployment'
        required: true
        default: 'us-east-1'
      action:
        description: 'Action to perform (deploy/destroy)'
        required: true
        type: choice
        options:
          - deploy
          - destroy
      awsAccountId:
        description: 'AWS Account ID'
        required: true
      adminRoleArn:
        description: 'Admin Role ARN'
        required: true
      awsAccessKeyId:
        description: 'AWS Access Key ID'
        required: true
      awsSecretAccessKey:
        description: 'AWS Secret Access Key'
        required: true
      awsSessionToken:
        description: 'AWS Session Token'
        required: true
jobs:
  deploy_sagemaker_templates:
    runs-on: ubuntu-latest
    if: [38;5;2m${{ github.event.inputs.action == 'deploy' }}[0m
    steps:
    - name: Clone AIOps Modules Repository
      run: |
        git clone --origin upstream --branch main https://github.com/$GITHUB_USERNAME/aiops-modules.git
        cd aiops-modules
    
    - name: Setup Python Environment
      run: |
        cd aiops-modules
        python3 -m venv .venv && source .venv/bin/activate
        pip install --upgrade pip setuptools wheel
        pip install -r ./requirements.txt
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '20'
    
    - name: Install CDK CLI
      run: |
        npm install -g aws-cdk
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ github.event.inputs.awsAccessKeyId }}
        aws-secret-access-key: ${{ github.event.inputs.awsSecretAccessKey }}
        aws-session-token: ${{ github.event.inputs.awsSessionToken }}
        aws-region: ${{ github.event.inputs.awsRegion }}
    
    - name: Set Environment Variables
      run: |
        cd aiops-modules
        echo "PRIMARY_ACCOUNT=${{ github.event.inputs.awsAccountId }}" >> $GITHUB_ENV
        echo "ADMIN_ROLE_ARN=${{ github.event.inputs.adminRoleArn }}" >> $GITHUB_ENV
    
    - name: Bootstrap CDK Environment
      run: |
        cd aiops-modules
        source .venv/bin/activate
        npx cdk bootstrap aws://${{ github.event.inputs.awsAccountId }}/${{ github.event.inputs.awsRegion }}
    
    - name: Bootstrap AWS Account for SeedFarmer
      run: |
        cd aiops-modules
        source .venv/bin/activate
        seedfarmer bootstrap toolchain --project ${{ github.event.inputs.deploymentName }} --trusted-principal ${{ github.event.inputs.adminRoleArn }} --as-target
    
    - name: Deploy Using SeedFarmer
      run: |
        cd aiops-modules
        export PRIMARY_REGION=eu-east-1
        source .venv/bin/activate
        seedfarmer apply manifests/mlops-sagemaker/sagemaker-studio-deployment.yaml

  destroy_sagemaker_templates:
    runs-on: ubuntu-latest
    if: ${{ github.event.inputs.action == 'destroy' }}
    steps:
    - name: Clone AIOps Modules Repository
      run: |
        git clone --origin upstream --branch release/1.8.0 https://github.com/awslabs/aiops-modules
        cd aiops-modules
    
    - name: Setup Python Environment
      run: |
        cd aiops-modules
        python3 -m venv .venv && source .venv/bin/activate
        pip install --upgrade pip setuptools wheel
        pip install -r ./requirements.txt
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '20'
    
    - name: Install CDK CLI
      run: |
        npm install -g aws-cdk
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ github.event.inputs.awsAccessKeyId }}
        aws-secret-access-key: ${{ github.event.inputs.awsSecretAccessKey }}
        aws-session-token: ${{ github.event.inputs.awsSessionToken }}
        aws-region: ${{ github.event.inputs.awsRegion }}
    
    - name: Destroy Using SeedFarmer
      run: |
        cd aiops-modules
        source .venv/bin/activate
        seedfarmer destroy ${{ github.event.inputs.deploymentName }}
EOF

# Create manifest files
cat > aiops-modules/manifests/mlops-sagemaker/sagemaker-custom-kernel-deployment.yaml << 'EOF'
name: mlops-sagemaker
toolchainRegion: us-east-1
forceDependencyRedeploy: true
groups:
  - name: networking
    path: manifests/mlops-sagemaker/networking-modules.yaml
  - name: storage
    path: manifests/mlops-sagemaker/storage-modules.yaml
  - name: sagemaker-studio
    path: manifests/mlops-sagemaker/sagemaker-studio-modules.yaml
  - name: sagemaker-kernel
    path: manifests/mlops-sagemaker/sagemaker-kernels-modules.yaml
targetAccountMappings:
  - alias: primary
    accountId:
      valueFrom:
        envVariable: PRIMARY_ACCOUNT
    default: true
    regionMappings:
      - region: us-east-1
        default: true
EOF

cat > aiops-modules/manifests/mlops-sagemaker/sagemaker-endpoints-deployment.yaml << 'EOF'
name: mlops-sagemaker
toolchainRegion: us-east-1
forceDependencyRedeploy: true
groups:
  - name: networking
    path: manifests/mlops-sagemaker/networking-modules.yaml
  - name: sagemaker-studio
    path: manifests/mlops-sagemaker/sagemaker-studio-modules.yaml
  - name: sagemaker-endpoints-module
    path: manifests/mlops-sagemaker/sagemaker-endpoints-modules.yaml
targetAccountMappings:
  - alias: primary
    accountId:
      valueFrom:
        envVariable: PRIMARY_ACCOUNT
    default: true
    regionMappings:
      - region: us-east-1
        default: true
EOF

cat > aiops-modules/manifests/mlops-sagemaker/sagemaker-model-monitoring-deployment.yaml << 'EOF'
name: mlops-sagemaker
toolchainRegion: us-east-1
forceDependencyRedeploy: true
groups:
  - name: networking
    path: manifests/mlops-sagemaker/networking-modules.yaml
  - name: sagemaker-endpoints-module
    path: manifests/mlops-sagemaker/sagemaker-endpoints-modules.yaml
  - name: sagemaker-model-monitoring
    path: manifests/mlops-sagemaker/sagemaker-model-monitoring-modules.yaml
targetAccountMappings:
  - alias: primary
    accountId:
      valueFrom:
        envVariable: PRIMARY_ACCOUNT
    default: true
    regionMappings:
      - region: us-east-1
        default: true
EOF

cat > aiops-modules/manifests/mlops-sagemaker/sagemaker-model-package-group-deployment.yaml << 'EOF'
name: mlops-sagemaker
toolchainRegion: us-east-1
forceDependencyRedeploy: true
groups:
  - name: networking
    path: manifests/mlops-sagemaker/networking-modules.yaml
  - name: storage
    path: manifests/mlops-sagemaker/storage-modules.yaml
  - name: model-package-package-group
    path: manifests/mlops-sagemaker/sagemaker-model-package-group-modules.yaml
targetAccountMappings:
  - alias: primary
    accountId:
      valueFrom:
        envVariable: PRIMARY_ACCOUNT
    default: true
    regionMappings:
      - region: us-east-1
        default: true
EOF

cat > aiops-modules/manifests/mlops-sagemaker/sagemaker-model-package-promote-pipeline-deployment.yaml << 'EOF'
name: mlops-sagemaker
toolchainRegion: us-east-1
forceDependencyRedeploy: true
groups:
  - name: networking
    path: manifests/mlops-sagemaker/networking-modules.yaml
  - name: storage
    path: manifests/mlops-sagemaker/storage-modules.yaml
  - name: model-package-promote-pipeline-module
    path: manifests/mlops-sagemaker/sagemaker-model-package-promote-pipeline-modules.yaml
targetAccountMappings:
  - alias: primary
    accountId:
      valueFrom:
        envVariable: PRIMARY_ACCOUNT
    default: true
    regionMappings:
      - region: us-east-1
        default: true
EOF

cat > aiops-modules/manifests/mlops-sagemaker/sagemaker-notebook-deployment.yaml << 'EOF'
name: mlops-sagemaker
toolchainRegion: us-east-1
forceDependencyRedeploy: true
groups:
  - name: networking
    path: manifests/mlops-sagemaker/networking-modules.yaml
  - name: sagemaker-notebook
    path: manifests/mlops-sagemaker/sagemaker-notebook-modules.yaml
targetAccountMappings:
  - alias: primary
    accountId:
      valueFrom:
        envVariable: PRIMARY_ACCOUNT
    default: true
    regionMappings:
      - region: us-east-1
        default: true
EOF

cat > aiops-modules/manifests/mlops-sagemaker/sagemaker-studio-deployment.yaml << 'EOF'
name: mlops-sagemaker
toolchainRegion: us-east-1
forceDependencyRedeploy: true
groups:
  - name: networking
    path: manifests/mlops-sagemaker/networking-modules.yaml
  - name: storage
    path: manifests/mlops-sagemaker/storage-modules.yaml
  - name: sagemaker-studio
    path: manifests/mlops-sagemaker/sagemaker-studio-modules.yaml
targetAccountMappings:
  - alias: primary
    accountId:
      valueFrom:
        envVariable: PRIMARY_ACCOUNT
    default: true
    regionMappings:
      - region: us-east-1
        default: true
EOF

cat > aiops-modules/manifests/mlops-sagemaker/sagemaker-template-servicecatalog-deployment.yaml << 'EOF'
name: mlops-sagemaker
toolchainRegion: us-east-1
forceDependencyRedeploy: true
groups:
  - name: networking
    path: manifests/mlops-sagemaker/networking-modules.yaml
  - name: storage
    path: manifests/mlops-sagemaker/storage-modules.yaml
  - name: sagemaker-studio
    path: manifests/mlops-sagemaker/sagemaker-template-modules.yaml
targetAccountMappings:
  - alias: primary
    accountId:
      valueFrom:
        envVariable: PRIMARY_ACCOUNT
    default: true
    regionMappings:
      - region: us-east-1
        default: true
EOF

git add .
git commit -m "Add workflows and mlops-sagemaker files from script"
git push origin main

echo "Done!"