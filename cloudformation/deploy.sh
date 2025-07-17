#!/bin/bash

# CloudFormation Deployment Script
set -e

STACK_NAME="serverless-crud-app"
REGION="ap-southeast-2"
TEMPLATE_FILE="template.yaml"

echo "🚀 Starting CloudFormation deployment..."

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if template file exists
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "❌ Template file $TEMPLATE_FILE not found!"
    exit 1
fi

# Deploy the CloudFormation stack
echo "📦 Deploying CloudFormation stack..."
aws cloudformation deploy \
    --template-file "$TEMPLATE_FILE" \
    --stack-name "$STACK_NAME" \
    --capabilities CAPABILITY_NAMED_IAM \
    --region "$REGION" \
    --parameter-overrides \
        ProjectName=serverless-crud-app \
        Environment=prod

# Wait for stack to be created/updated
echo "⏳ Waiting for stack deployment to complete..."
aws cloudformation wait stack-update-complete \
    --stack-name "$STACK_NAME" \
    --region "$REGION" || \
aws cloudformation wait stack-create-complete \
    --stack-name "$STACK_NAME" \
    --region "$REGION"

# Get stack outputs
echo "📊 Getting stack outputs..."
aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$REGION" \
    --query 'Stacks[0].Outputs' \
    --output table

# Get S3 bucket name for frontend
S3_BUCKET=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$REGION" \
    --query 'Stacks[0].Outputs[?OutputKey==`S3BucketName`].OutputValue' \
    --output text)

if [ "$S3_BUCKET" != "None" ] && [ -n "$S3_BUCKET" ]; then
    echo "📁 Uploading frontend files to S3 bucket: $S3_BUCKET"
    
    # Upload frontend files
    aws s3 cp ../application/frontend/html/index.html s3://$S3_BUCKET/
    aws s3 cp ../application/frontend/css/styles.css s3://$S3_BUCKET/css/
    aws s3 cp ../application/frontend/js/app.js s3://$S3_BUCKET/js/
    
    echo "✅ Frontend files uploaded successfully!"
    
    # Get CloudFront URL
    CLOUDFRONT_URL=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$REGION" \
        --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontUrl`].OutputValue' \
        --output text)
    
    echo "🌐 CloudFront URL: $CLOUDFRONT_URL"
    echo "📱 Your application is now available at: $CLOUDFRONT_URL"
else
    echo "⚠️  Could not retrieve S3 bucket name from stack outputs"
fi

echo "✅ CloudFormation deployment completed successfully!" 