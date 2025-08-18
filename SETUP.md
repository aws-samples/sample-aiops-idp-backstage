1. Deployment Prerequisites:

-- An AWS account with necessary permissions (IAM, EKS, RDS, ALB)
-- AWS CLI and Github CLI installed and configured
-- Node.js 16.x or later installed
-- Sufficient AWS service quotas for EKS, RDS, and ALB resources


2. Backstage Deployment steps:

-- Clone and Setup appmod Repository:
git clone https://github.com/aws-samples/appmod-blueprints.git 
cd appmod-blueprints 

-- Install dependencies 
npm install

-- Bootstrap CDK in your AWS account/region
npx cdk bootstrap aws://<AWS_ACCOUNT_ID>/<AWS_REGION>

-- Configure env variables:
Create a .env file in the root directory:
# .env file 
AWS_ACCOUNT_ID=<your-aws-account-id> 
AWS_REGION=<your-aws-region> 
GITHUB_TOKEN=<your-github-token> 
GITHUB_ORG=<your-github-org>

-- Deploy core platform:
npx cdk deploy BackstagePlatform --require-approval never

-> Resources created after deployment:

-- Backstage frontend and backend services.
-- Amazon EKS (Elastic Kubernetes Service) cluster and resources for hosting Backstage
-- Amazon RDS PostgreSQL instance for the backend database
-- Application Load Balancer for handling incoming traffic
-- Integration with Github for authentication.

-> Verify accessing Backstage using ALB endpoint:

![alt text](image.png)


3. Setting up SageMaker template files using script:

-- Clone this GitHub repo:
git clone https://github.com/aws-samples/sample-aiops-idp-backstage.git

-- Setup prerequisites for the script to work (Refer Readme.md):
cd scripts

-- Execute the script.
./fork-and-sync.sh

With this you will have a repository created with all the required sage-maker templates file in place to use them through backstage


4. SageMaker templates integration in backstage:

Our implementation strategy focuses on integrating AIOps modules specifically Amazon SageMaker project templates into an existing Backstage deployment that has been set up using the AWS App Modernization Blueprints and CNOE framework. This integration enables data science teams to self-service their ML infrastructure needs while maintaining organizational standards and security controls.


5. Follow below steps from cnoe backstage instance:

-- Click on Create and Register existing component
-- Add the location of the catalog-info file.
![alt text](image-1.png)
-- Review and finish.
-- Verify all the AIOPS SageMaker templates are added into your backstage instance.
![alt text](image-2.png)


6. Use of Registered Amazon SageMaker templates:

Steps to Use the Amazon SageMaker Studio Template from backstage:

Step1: Access the Backstage Portal: 
 — Navigate to your Backstage instance URL, which is setup in above step.
 — Navigate to the Software Templates
 — Click on the "Create" button in the left sidebar
 — Browse the available templates and click on "SageMaker Studio Template" card

Step2: Fill in Basic Information:
 — Enter a unique component name (e.g., "ml-team-sagemaker-studio")
 — Provide your AWS Account ID where SageMaker will be deployed
 — Enter the Admin Role ARN with sufficient permissions
 — Select "deploy" as the action

![alt text](image-3.png)

Step3: Select Repository Location
 — Choose where the template code will be stored
 — Select an existing GitHub repository or create a new one
 — This repository will store the configuration and workflow files

![alt text](image-4.png)

Step4: Configure AWS Settings
 — Select the AWS region for deployment (e.g., "us-east-1")
 — Enter your AWS Access Key ID, Secret Access Key, and Session Token
 — These credentials must have permissions to create SageMaker resources

![alt text](image-5.png)

Step5: Review and Create
 — Verify all entered information
 — Click "Create" to initiate the template generation process

![alt text](image-6.png)

Step6: Monitor Deployment Progress: 
  Backstage will create a new repository with the necessary files, A GitHub Actions workflow will be automatically triggered, The workflow will use SeedFarmer to deploy SageMaker Studio

![alt text](image-7.png)

Step7: Access Deployment Details: Once complete, Backstage will display links to:
 — The created GitHub repository
 — The component in the Backstage catalog
 — The GitHub Actions workflow logs

![alt text](image-8.png)

Step8: Verification of the resources created by accessing SageMaker Studio
 — Navigate to the AWS Console
 — Go to the SageMaker service in your selected region
 — Find the newly created SageMaker Studio domain and user profile
 — Click on launch studio and begin using the ML environment

![alt text](image-9.png)

Step9: Manage the Deployment:
 - To make changes, update the configuration in the GitHub repository
 - To destroy the resources, trigger the GitHub Actions workflow with "destroy" action
 - Monitor and manage the deployment through the Backstage component page
 - This streamlined process enables data scientists to quickly provision standardized SageMaker environments while ensuring organizational compliance and reducing the operational burden on platform teams.


7. Security Considerations:

-- Ensure minimal required IAM permissions for deployment and runtime
-- Store AWS credentials and GitHub tokens securely
-- Configure VPC, subnets, and security groups appropriately
-- Implement proper RBAC for Backstage users and GitHub repositories
-- Enable CloudTrail and application logs for compliance


8. Troubleshooting:

-> Common Issues:

-- CDK Bootstrap failures: Verify AWS credentials and region configuration
-- EKS cluster access: Check kubectl configuration and IAM permissions
-- ALB connectivity: Ensure security groups allow inbound traffic on port 80/443
-- GitHub integration: Verify GitHub token permissions and organization access
-- SageMaker deployment failures: Check AWS service quotas and IAM permissions

-> Useful Commands:

-- Check EKS cluster status: aws eks describe-cluster --name <cluster-name>
-- View Backstage logs: kubectl logs -n backstage deployment/backstage
-- Monitor GitHub Actions: Check workflow logs in repository Actions tab


9. Cleanup and Resource Management:

-> To destroy Backstage infrastructure:
npx cdk destroy BackstagePlatform

-> To remove SageMaker resources:

-- Trigger GitHub Actions workflow with "destroy" action
-- Manually delete any remaining SageMaker domains/user profiles if needed

-> Cost Optimization:

-- Monitor AWS costs through Cost Explorer
-- Consider using Spot instances for non-production EKS nodes
-- Set up billing alerts for unexpected cost increases
-- Regularly review and cleanup unused resources