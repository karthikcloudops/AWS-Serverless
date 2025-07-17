# Terraform Deployment for AWS Serverless CRUD Application

This directory contains the Terraform configuration for deploying the AWS serverless CRUD application.

## Prerequisites

1. **AWS CLI** installed and configured
2. **Terraform** (version >= 1.0) installed
3. **Python 3.12** for Lambda functions
4. **zip** command available for packaging Lambda functions

## Directory Structure

```
terraform/
├── main.tf              # Main Terraform configuration
├── variables.tf         # Variable definitions
├── outputs.tf          # Output values
├── README.md           # This file
└── scripts/
    ├── package-lambda.sh  # Script to package Lambda functions
    └── deploy.sh          # Deployment script
```

## Quick Start

### 1. Package Lambda Functions

First, package the Lambda functions:

```bash
cd terraform
./scripts/package-lambda.sh
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Plan the Deployment

```bash
terraform plan
```

### 4. Deploy the Infrastructure

```bash
terraform apply
```

### 5. Deploy Frontend

After the infrastructure is deployed, upload the frontend files to S3:

```bash
aws s3 sync ../application/frontend/ s3://$(terraform output -raw frontend_bucket_name) --delete
```

## Configuration

### Variables

You can customize the deployment by setting variables:

```bash
terraform apply -var="project_name=my-crud-app" -var="environment=dev"
```

Available variables:
- `project_name`: Name of the project (default: "serverless-crud-app")
- `environment`: Environment name (default: "prod")

### Outputs

After deployment, Terraform will output:
- API Gateway URL
- CloudFront Distribution URL
- Cognito User Pool ID
- Cognito Client ID
- DynamoDB Table Name

## Architecture

The Terraform configuration creates:

1. **DynamoDB Table**: For storing items
2. **Cognito User Pool**: For user authentication
3. **Lambda Functions**: Four functions for CRUD operations
4. **API Gateway**: REST API with four endpoints
5. **S3 Bucket**: For hosting the frontend
6. **CloudFront Distribution**: For serving the frontend
7. **IAM Roles and Policies**: For Lambda execution permissions

## API Endpoints

- `POST /items` - Create a new item
- `GET /items` - Get all items (with optional pagination)
- `GET /items/{id}` - Get a specific item
- `PUT /items/{id}` - Update an item
- `DELETE /items/{id}` - Delete an item

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

## Troubleshooting

### Common Issues

1. **Lambda packaging errors**: Ensure Python 3.12 and zip are installed
2. **Permission errors**: Check AWS credentials and permissions
3. **API Gateway errors**: Wait a few minutes after deployment for propagation

### Logs

Check CloudWatch logs for Lambda functions:
- `serverless-crud-app-prod-create-item`
- `serverless-crud-app-prod-get-items`
- `serverless-crud-app-prod-update-item`
- `serverless-crud-app-prod-delete-item`

## Security Notes

- The current configuration uses `NONE` authorization for API Gateway
- In production, implement proper authentication using Cognito
- Consider enabling CloudTrail for audit logging
- Review and adjust IAM permissions as needed 