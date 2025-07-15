# AIOps Internal Developer Platform (IDP) with Backstage

This repository contains a Backstage-based Internal Developer Platform (IDP) for deploying and managing AIOps modules on AWS using SeedFarmer.

## Overview

This IDP provides software templates and workflows to streamline the deployment of machine learning and AI operations infrastructure on AWS. It integrates with the [AIOps Modules](https://github.com/awslabs/aiops-modules) repository to provide a self-service platform for developers.

## Features

- **Software Templates**: Pre-built templates for deploying AIOps modules
- **SageMaker Integration**: Templates for SageMaker Studio and Service Catalog deployment
- **AWS CDK Support**: Infrastructure as Code using AWS CDK
- **SeedFarmer Integration**: Automated deployment using SeedFarmer CLI
- **Security Compliance**: GitHub Actions pinned to commit SHAs for security

## Available Templates

### SageMaker Templates Service Catalog
- **Location**: `software-templates/sagemaker-service-catalog/`
- **Purpose**: Deploy SageMaker Templates Service Catalog using SeedFarmer
- **Features**:
  - Automated AWS CDK bootstrapping
  - SeedFarmer toolchain setup
  - GitHub Actions workflow generation
  - Support for deploy/destroy operations

## Prerequisites

- AWS Account with appropriate permissions
- AWS CLI configured
- Node.js 20+
- Python 3.9+
- Backstage instance running

## Quick Start

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd aiops-idp-backstage
   ```

2. **Configure Backstage**:
   - Add this repository as a template location in your Backstage configuration
   - Ensure GitHub integration is properly configured

3. **Use Templates**:
   - Navigate to Backstage Software Templates
   - Select the desired AIOps template
   - Fill in the required parameters
   - Deploy using the generated GitHub Actions workflow

## Template Structure

```
software-templates/
├── sagemaker-service-catalog/
│   ├── template.yaml          # Backstage template definition
│   └── content/
│       ├── catalog-info.yaml  # Backstage catalog registration
│       └── sagemaker-service-catalog.yml  # GitHub Actions workflow
```

## Configuration

### Required Parameters

For SageMaker Templates Service Catalog:
- **AWS Account ID**: Your AWS account identifier
- **Admin Role ARN**: IAM role with administrative permissions
- **AWS Region**: Target deployment region
- **AWS Credentials**: Access Key, Secret Key, and Session Token

### GitHub Secrets

The following secrets must be configured in your GitHub repository:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_SESSION_TOKEN`
- `AWS_REGION`
- `AWS_ACCOUNT_ID`
- `ADMIN_ROLE_ARN`

## Security

- All GitHub Actions are pinned to specific commit SHAs for security compliance
- AWS credentials are handled securely through GitHub Secrets
- IAM roles follow least privilege principles

## Deployment Process

1. **Template Selection**: Choose template from Backstage catalog
2. **Parameter Input**: Provide required AWS and deployment parameters
3. **Repository Creation**: New GitHub repository is created with workflow
4. **Secret Configuration**: Set up required GitHub secrets
5. **Workflow Execution**: Trigger GitHub Actions workflow for deployment

## Supported AIOps Modules

- SageMaker Studio
- SageMaker Templates Service Catalog
- MLOps Pipelines
- Data Processing Workflows

## Troubleshooting

### Common Issues

1. **CDK Bootstrap Failures**:
   - Ensure AWS credentials have sufficient permissions
   - Verify CDK CLI is properly installed

2. **SeedFarmer Errors**:
   - Check Python environment setup
   - Verify all required dependencies are installed

3. **GitHub Actions Failures**:
   - Confirm all required secrets are configured
   - Check AWS credential validity

## License

This project is licensed under the MIT License - see the LICENSE file for details.


## Related Projects

- [AIOps Modules](https://github.com/awslabs/aiops-modules) - Infrastructure modules
- [SeedFarmer](https://github.com/awslabs/seed-farmer) - Deployment orchestration
- [Backstage](https://backstage.io/) - Developer portal platform