#!/bin/bash

# Script to deploy the AWS serverless CRUD application using CloudFormation
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME=${PROJECT_NAME:-"serverless-crud-app"}
ENVIRONMENT=${ENVIRONMENT:-"prod"}
AWS_REGION=${AWS_REGION:-"ap-southeast-2"}
STACK_NAME=${STACK_NAME:-"$PROJECT_NAME-$ENVIRONMENT"}

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials are not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    # Check if template file exists
    if [ ! -f "template.yaml" ]; then
        print_error "CloudFormation template file 'template.yaml' not found!"
        exit 1
    fi
    
    print_success "All prerequisites are met!"
}

# Function to validate CloudFormation template
validate_template() {
    print_status "Validating CloudFormation template..."
    
    if aws cloudformation validate-template --template-body file://template.yaml &> /dev/null; then
        print_success "CloudFormation template is valid!"
    else
        print_error "CloudFormation template validation failed!"
        exit 1
    fi
}

# Function to check if stack exists
stack_exists() {
    aws cloudformation describe-stacks --stack-name "$STACK_NAME" &> /dev/null
}

# Function to create stack
create_stack() {
    print_status "Creating CloudFormation stack: $STACK_NAME"
    
    aws cloudformation create-stack \
        --stack-name "$STACK_NAME" \
        --template-body file://template.yaml \
        --parameters \
            ParameterKey=ProjectName,ParameterValue="$PROJECT_NAME" \
            ParameterKey=Environment,ParameterValue="$ENVIRONMENT" \
        --capabilities CAPABILITY_IAM \
        --region "$AWS_REGION"
    
    print_status "Waiting for stack creation to complete..."
    aws cloudformation wait stack-create-complete --stack-name "$STACK_NAME" --region "$AWS_REGION"
    
    print_success "Stack created successfully!"
}

# Function to update stack
update_stack() {
    print_status "Updating CloudFormation stack: $STACK_NAME"
    
    aws cloudformation update-stack \
        --stack-name "$STACK_NAME" \
        --template-body file://template.yaml \
        --parameters \
            ParameterKey=ProjectName,ParameterValue="$PROJECT_NAME" \
            ParameterKey=Environment,ParameterValue="$ENVIRONMENT" \
        --capabilities CAPABILITY_IAM \
        --region "$AWS_REGION"
    
    print_status "Waiting for stack update to complete..."
    aws cloudformation wait stack-update-complete --stack-name "$STACK_NAME" --region "$AWS_REGION"
    
    print_success "Stack updated successfully!"
}

# Function to deploy stack
deploy_stack() {
    if stack_exists; then
        print_status "Stack '$STACK_NAME' already exists. Updating..."
        update_stack
    else
        print_status "Stack '$STACK_NAME' does not exist. Creating..."
        create_stack
    fi
}

# Function to get stack outputs
get_stack_outputs() {
    print_status "Getting stack outputs..."
    
    aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$AWS_REGION" \
        --query 'Stacks[0].Outputs' \
        --output table
}

# Function to deploy frontend
deploy_frontend() {
    print_status "Deploying frontend to S3..."
    
    # Get the S3 bucket name from stack outputs
    S3_BUCKET=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$AWS_REGION" \
        --query 'Stacks[0].Outputs[?OutputKey==`S3BucketName`].OutputValue' \
        --output text)
    
    if [ -z "$S3_BUCKET" ] || [ "$S3_BUCKET" = "None" ]; then
        print_warning "Could not get S3 bucket name from stack outputs. Please deploy manually."
        return
    fi
    
    print_status "Uploading frontend files to S3 bucket: $S3_BUCKET"
    
    aws s3 sync ../../application/frontend/ s3://$S3_BUCKET --delete --region "$AWS_REGION"
    
    print_success "Frontend deployed successfully!"
}

# Function to display deployment information
display_deployment_info() {
    print_status "Deployment information:"
    echo ""
    
    # Get specific outputs
    API_URL=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$AWS_REGION" \
        --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayUrl`].OutputValue' \
        --output text 2>/dev/null || echo "Not available")
    
    CLOUDFRONT_URL=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$AWS_REGION" \
        --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontUrl`].OutputValue' \
        --output text 2>/dev/null || echo "Not available")
    
    COGNITO_USER_POOL_ID=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$AWS_REGION" \
        --query 'Stacks[0].Outputs[?OutputKey==`CognitoUserPoolId`].OutputValue' \
        --output text 2>/dev/null || echo "Not available")
    
    COGNITO_CLIENT_ID=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$AWS_REGION" \
        --query 'Stacks[0].Outputs[?OutputKey==`CognitoClientId`].OutputValue' \
        --output text 2>/dev/null || echo "Not available")
    
    S3_BUCKET=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$AWS_REGION" \
        --query 'Stacks[0].Outputs[?OutputKey==`S3BucketName`].OutputValue' \
        --output text 2>/dev/null || echo "Not available")
    
    echo "Stack Name: $STACK_NAME"
    echo "API Gateway URL: $API_URL"
    echo "CloudFront URL: $CLOUDFRONT_URL"
    echo "Cognito User Pool ID: $COGNITO_USER_POOL_ID"
    echo "Cognito Client ID: $COGNITO_CLIENT_ID"
    echo "S3 Bucket Name: $S3_BUCKET"
    echo ""
}

# Function to test the deployment
test_deployment() {
    print_status "Testing deployment..."
    
    API_URL=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$AWS_REGION" \
        --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayUrl`].OutputValue' \
        --output text 2>/dev/null || echo "")
    
    if [ -n "$API_URL" ] && [ "$API_URL" != "None" ]; then
        print_status "Testing API Gateway endpoint..."
        
        # Test GET /items endpoint
        response=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL" || echo "000")
        
        if [ "$response" = "200" ] || [ "$response" = "404" ]; then
            print_success "API Gateway is responding (HTTP $response)"
        else
            print_warning "API Gateway test failed (HTTP $response)"
        fi
    else
        print_warning "Could not get API Gateway URL for testing"
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help              Show this help message"
    echo "  -p, --project-name      Project name (default: serverless-crud-app)"
    echo "  -e, --environment       Environment name (default: prod)"
    echo "  -r, --region            AWS region (default: ap-southeast-2)"
    echo "  -s, --stack-name        Stack name (default: project-name-environment)"
    echo "  --skip-frontend         Skip frontend deployment"
    echo "  --skip-test             Skip deployment testing"
    echo "  --validate-only         Only validate the template"
    echo ""
    echo "Environment variables:"
    echo "  PROJECT_NAME            Project name"
    echo "  ENVIRONMENT             Environment name"
    echo "  AWS_REGION              AWS region"
    echo "  STACK_NAME              CloudFormation stack name"
    echo ""
}

# Parse command line arguments
SKIP_FRONTEND=false
SKIP_TEST=false
VALIDATE_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -p|--project-name)
            PROJECT_NAME="$2"
            shift 2
            ;;
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -r|--region)
            AWS_REGION="$2"
            shift 2
            ;;
        -s|--stack-name)
            STACK_NAME="$2"
            shift 2
            ;;
        --skip-frontend)
            SKIP_FRONTEND=true
            shift
            ;;
        --skip-test)
            SKIP_TEST=true
            shift
            ;;
        --validate-only)
            VALIDATE_ONLY=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Main deployment process
main() {
    echo "=========================================="
    echo "AWS Serverless CRUD Application Deployment"
    echo "=========================================="
    echo ""
    echo "Project Name: $PROJECT_NAME"
    echo "Environment: $ENVIRONMENT"
    echo "AWS Region: $AWS_REGION"
    echo "Stack Name: $STACK_NAME"
    echo ""
    
    # Check prerequisites
    check_prerequisites
    
    # Validate template
    validate_template
    
    # If validate-only flag is set, exit here
    if [ "$VALIDATE_ONLY" = true ]; then
        print_success "Template validation completed successfully!"
        exit 0
    fi
    
    # Deploy stack
    deploy_stack
    
    # Deploy frontend (unless skipped)
    if [ "$SKIP_FRONTEND" = false ]; then
        deploy_frontend
    else
        print_warning "Skipping frontend deployment"
    fi
    
    # Display deployment information
    display_deployment_info
    
    # Test deployment (unless skipped)
    if [ "$SKIP_TEST" = false ]; then
        test_deployment
    else
        print_warning "Skipping deployment testing"
    fi
    
    echo ""
    print_success "Deployment completed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Update the API Gateway URL in the frontend JavaScript file"
    echo "2. Configure Cognito authentication in the frontend"
    echo "3. Test the CRUD operations through the web interface"
    echo ""
}

# Run main function
main "$@" 