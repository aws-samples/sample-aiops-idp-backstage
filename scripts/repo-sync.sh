#!/bin/bash

# Repo Sync Script
# Copies specific directories from GitHub aiops-modules repo to your GitHub repo

set -e

# Check if GitHub repo URL is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <github-repo-url>"
    echo "Example: $0 https://github.com/username/repo-name.git"
    exit 1
fi

GITHUB_REPO_URL="$1"
AIOPS_REPO_URL="https://github.com/awslabs/aiops-modules"
TEMP_DIR="/tmp/repo-sync-$(date +%s)"

echo "Creating temporary directory: $TEMP_DIR"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# Clone aiops-modules repo
echo "Cloning aiops-modules repo..."
git clone "$AIOPS_REPO_URL" aiops-repo

# Clone GitHub repo
echo "Cloning GitHub repo..."
git clone "$GITHUB_REPO_URL" github-repo

# Copy .github/workflows directory
echo "Copying .github/workflows directory..."
if [ -d "aiops-repo/.github/workflows" ]; then
    mkdir -p "github-repo/.github"
    cp -r "aiops-repo/.github/workflows" "github-repo/.github/"
    echo "✓ Copied .github/workflows"
else
    echo "⚠ Warning: .github/workflows directory not found in aiops-modules repo"
fi

# Copy aiops-modules/manifests/mlops-sagemaker directory
echo "Copying aiops-modules/manifests/mlops-sagemaker directory..."
if [ -d "aiops-repo/manifests/mlops-sagemaker" ]; then
    mkdir -p "github-repo/aiops-modules/manifests"
    cp -r "aiops-repo/manifests/mlops-sagemaker" "github-repo/aiops-modules/manifests/"
    echo "✓ Copied aiops-modules/manifests/mlops-sagemaker"
else
    echo "⚠ Warning: manifests/mlops-sagemaker directory not found in aiops-modules repo"
fi

# Navigate to GitHub repo and commit changes
cd github-repo

# Check if there are any changes
if [ -n "$(git status --porcelain)" ]; then
    echo "Adding and committing changes..."
    git add .
    git commit -m "Sync directories from aiops-modules repo

- Added .github/workflows
- Added aiops-modules/manifests/mlops-sagemaker"
    
    echo "Pushing changes to GitHub repo..."
    git push origin main || git push origin master
    echo "✓ Changes pushed successfully"
else
    echo "No changes to commit"
fi

# Cleanup
cd /
rm -rf "$TEMP_DIR"
echo "✓ Cleanup completed"
echo "Script execution completed successfully!"