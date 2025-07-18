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
aws s3 sync ../application/frontend/ s3://$(terraform output -raw s3_bucket_name) --delete
```

**Important**: Ensure that `index.html` is at the root level of the S3 bucket. If your frontend files are in subdirectories (e.g., `html/index.html`), move the `index.html` file to the root:

```bash
# If index.html is in html/ subdirectory, move it to root
aws s3 mv s3://$(terraform output -raw s3_bucket_name)/html/index.html s3://$(terraform output -raw s3_bucket_name)/index.html
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
4. **CloudFront access issues**: 
   - Ensure `index.html` is at the root of the S3 bucket (not in subdirectories)
   - CloudFront distribution may take 5-10 minutes to update after configuration changes
   - Check that S3 bucket has public read access enabled
5. **Frontend file structure**: The `index.html` file must be at the root level of the S3 bucket for CloudFront to serve it correctly

### Testing Your Deployment

After deployment, test both endpoints:

```bash
# Test frontend access
curl -I https://$(terraform output -raw cloudfront_url)

# Test API endpoint
curl -X GET $(terraform output -raw api_gateway_url)
```

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