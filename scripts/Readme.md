# Repo Sync Script

Simple script to copy specific directories from GitLab repo to your GitHub repo.

## Usage

1. Make the script executable:
   ```bash
   chmod +x repo-sync.sh
   ```

2. Run the script with your GitHub repo URL:
   ```bash
   ./repo-sync.sh https://github.com/your-username/your-repo.git
   ```

## What it does

- Clones the GitHub aiops-modules repo: `https://github.com/awslabs/aiops-modules`
- Clones your GitHub repo
- Copies `.github/workflows` directory to your GitHub repo
- Copies `aiops-modules/manifests/mlops-sagemaker` directory to your GitHub repo
- Commits and pushes changes to your GitHub repo

## Requirements

- Git installed and configured
- Access to both GitHub repos
- Write permissions to your GitHub repo

## Note

The script uses temporary directories and cleans up after execution.
