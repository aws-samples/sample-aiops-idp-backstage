# Repo Sync Script

This script automates the process of forking the AWS aiops-modules repository, cloning your fork, and adding all required workflow and manifest files for SageMaker automation.

## Usage

1. Make the script executable:
   ```bash
   chmod +x fork-and-sync.sh
   ```

2. Run the script:
   ```bash
   ./fork-and-sync.sh
   ```

3. When prompted, enter your GitHub username (the one you use for login and your fork).

## What it does

- Forks the AWS aiops-modules repo: `https://github.com/awslabs/aiops-modules` to your GitHub account
- Clones your forked repo
- Adds all required workflow files to `.github/workflows` in your fork
- Adds all required manifest files to `aiops-modules/manifests/mlops-sagemaker` in your fork
- Ensures all workflow files reference your forked repo (using your username)
- Commits and pushes the changes to your fork

## Requirements

- GitHub CLI (`gh`) installed and authenticated (`gh auth login`)
- Git installed
- Write permissions to your GitHub account

## Note

- The script uses a temporary directory for operations and does not modify your local repo.
- All files are created with the correct content and references for SageMaker automation.
- If you need to add more files, update `fork-and-sync.sh` following the same pattern.
