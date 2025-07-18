# CloudFormation Deployment for AWS Serverless CRUD Application

This directory contains the CloudFormation template for deploying the AWS serverless CRUD application.

## Prerequisites

1. **AWS CLI** installed and configured
2. **AWS SAM CLI** (optional, for local testing)
3. **Python 3.12** for Lambda functions

## Directory Structure

```
cloudformation/
├── template.yaml        # CloudFormation template
├── README.md           # This file
└── scripts/
    ├── deploy.sh       # Deployment script
    └── package.sh      # Packaging script
```

## Quick Start

### 1. Deploy the Stack

Using AWS CLI:

```bash
cd cloudformation

# Create the stack
aws cloudformation create-stack \
  --stack-name serverless-crud-app \
  --template-body file://template.yaml \
  --parameters ParameterKey=ProjectName,ParameterValue=serverless-crud-app ParameterKey=Environment,ParameterValue=prod \
  --capabilities CAPABILITY_IAM

# Wait for the stack to complete
aws cloudformation wait stack-create-complete --stack-name serverless-crud-app
```

### 2. Get Stack Outputs

```bash
aws cloudformation describe-stacks \
  --stack-name serverless-crud-app \
  --query 'Stacks[0].Outputs'
```

### 3. Deploy Frontend

After the stack is deployed, upload the frontend files to S3:

```bash
# Get the S3 bucket name
S3_BUCKET=$(aws cloudformation describe-stacks \
  --stack-name serverless-crud-app \
  --query 'Stacks[0].Outputs[?OutputKey==`S3BucketName`].OutputValue' \
  --output text)

# Upload frontend files
aws s3 sync ../application/frontend/ s3://$S3_BUCKET --delete
```

## Using AWS SAM (Alternative)

If you prefer using AWS SAM:

```bash
# Install SAM CLI if not already installed
pip install aws-sam-cli

# Deploy using SAM
sam deploy --guided
```

## Configuration

### Parameters

The template accepts the following parameters:

- `ProjectName`: Name of the project (default: "serverless-crud-app")
- `Environment`: Environment name (default: "prod")

### Custom Parameters

You can customize the deployment by passing different parameters:

```bash
aws cloudformation create-stack \
  --stack-name my-crud-app \
  --template-body file://template.yaml \
  --parameters \
    ParameterKey=ProjectName,ParameterValue=my-crud-app \
    ParameterKey=Environment,ParameterValue=dev \
  --capabilities CAPABILITY_IAM
```

## Architecture

The CloudFormation template creates:

1. **DynamoDB Table**: For storing items with pay-per-request billing
2. **Cognito User Pool**: For user authentication with email verification
3. **Lambda Functions**: Four functions for CRUD operations (Create, Read, Update, Delete)
4. **API Gateway**: REST API with four endpoints
5. **S3 Bucket**: For hosting the frontend with public read access
6. **CloudFront Distribution**: For serving the frontend with caching
7. **IAM Roles and Policies**: For Lambda execution permissions

## API Endpoints

- `POST /items` - Create a new item
- `GET /items` - Get all items (with optional pagination)
- `GET /items/{id}` - Get a specific item
- `PUT /items/{id}` - Update an item
- `DELETE /items/{id}` - Delete an item

## Outputs

After deployment, the stack provides these outputs:

- `ApiGatewayUrl`: The API Gateway endpoint URL
- `CloudFrontUrl`: The CloudFront distribution URL
- `CognitoUserPoolId`: The Cognito User Pool ID
- `CognitoClientId`: The Cognito User Pool Client ID
- `DynamoDBTableName`: The DynamoDB table name
- `S3BucketName`: The S3 bucket name for the frontend

## Monitoring

### CloudWatch Logs

Check Lambda function logs:

```bash
# List log groups
aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/serverless-crud-app"

# Get logs for a specific function
aws logs tail /aws/lambda/serverless-crud-app-prod-create-item --follow
```

### CloudWatch Metrics

Monitor API Gateway and Lambda metrics in the AWS Console:
- API Gateway: Request count, latency, error rates
- Lambda: Invocation count, duration, error rates
- DynamoDB: Read/Write capacity units, throttled requests

## Cleanup

To delete the stack and all resources:

```bash
aws cloudformation delete-stack --stack-name serverless-crud-app

# Wait for deletion to complete
aws cloudformation wait stack-delete-complete --stack-name serverless-crud-app
```

## Troubleshooting

### Common Issues

1. **Stack creation fails**: Check CloudFormation events for specific errors
2. **Lambda function errors**: Check CloudWatch logs for detailed error messages
3. **API Gateway 500 errors**: Verify Lambda function permissions and integration
4. **CORS errors**: The template includes CORS headers, but verify in browser dev tools

### Debugging Commands

```bash
# Check stack status
aws cloudformation describe-stacks --stack-name serverless-crud-app

# Get stack events
aws cloudformation describe-stack-events --stack-name serverless-crud-app

# Test API Gateway
curl -X GET "$(aws cloudformation describe-stacks --stack-name serverless-crud-app --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayUrl`].OutputValue' --output text)"
```

## Security Notes

- The current template uses `NONE` authorization for API Gateway
- In production, implement proper authentication using Cognito
- Consider enabling CloudTrail for audit logging
- Review and adjust IAM permissions as needed
- The S3 bucket is configured for public read access (suitable for static websites)

## Cost Optimization

- DynamoDB uses pay-per-request billing (cost-effective for low to moderate usage)
- Lambda functions have 30-second timeout (adjust based on needs)
- CloudFront caching reduces origin requests
- Consider using AWS Cost Explorer to monitor costs 