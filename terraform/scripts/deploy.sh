#!/bin/bash

# Script to deploy the AWS serverless CRUD application using Terraform
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
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install it first."
        exit 1
    fi
    
    # Check if Python is installed
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 is not installed. Please install it first."
        exit 1
    fi
    
    # Check if zip is installed
    if ! command -v zip &> /dev/null; then
        print_error "zip command is not available. Please install it first."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials are not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    print_success "All prerequisites are met!"
}

# Function to package Lambda functions
package_lambda_functions() {
    print_status "Packaging Lambda functions..."
    
    if [ -f "./scripts/package-lambda.sh" ]; then
        chmod +x ./scripts/package-lambda.sh
        ./scripts/package-lambda.sh
        print_success "Lambda functions packaged successfully!"
    else
        print_error "package-lambda.sh script not found!"
        exit 1
    fi
}

# Function to initialize Terraform
init_terraform() {
    print_status "Initializing Terraform..."
    
    terraform init
    print_success "Terraform initialized successfully!"
}

# Function to plan Terraform deployment
plan_terraform() {
    print_status "Planning Terraform deployment..."
    
    terraform plan \
        -var="project_name=$PROJECT_NAME" \
        -var="environment=$ENVIRONMENT"
    
    print_success "Terraform plan completed!"
}

# Function to apply Terraform deployment
apply_terraform() {
    print_status "Applying Terraform deployment..."
    
    terraform apply \
        -var="project_name=$PROJECT_NAME" \
        -var="environment=$ENVIRONMENT" \
        -auto-approve
    
    print_success "Terraform deployment completed!"
}

# Function to deploy frontend
deploy_frontend() {
    print_status "Deploying frontend to S3..."
    
    # Get the S3 bucket name from Terraform output
    S3_BUCKET=$(terraform output -raw frontend_bucket_name 2>/dev/null || echo "")
    
    if [ -z "$S3_BUCKET" ]; then
        print_warning "Could not get S3 bucket name from Terraform output. Please deploy manually."
        return
    fi
    
    print_status "Uploading frontend files to S3 bucket: $S3_BUCKET"
    
    aws s3 sync ../application/frontend/ s3://$S3_BUCKET --delete
    
    print_success "Frontend deployed successfully!"
}

# Function to display outputs
display_outputs() {
    print_status "Deployment outputs:"
    echo ""
    terraform output
    echo ""
    
    # Get specific outputs
    API_URL=$(terraform output -raw api_gateway_url 2>/dev/null || echo "Not available")
    CLOUDFRONT_URL=$(terraform output -raw cloudfront_url 2>/dev/null || echo "Not available")
    COGNITO_USER_POOL_ID=$(terraform output -raw cognito_user_pool_id 2>/dev/null || echo "Not available")
    COGNITO_CLIENT_ID=$(terraform output -raw cognito_client_id 2>/dev/null || echo "Not available")
    
    echo "API Gateway URL: $API_URL"
    echo "CloudFront URL: $CLOUDFRONT_URL"
    echo "Cognito User Pool ID: $COGNITO_USER_POOL_ID"
    echo "Cognito Client ID: $COGNITO_CLIENT_ID"
    echo ""
}

# Function to test the deployment
test_deployment() {
    print_status "Testing deployment..."
    
    API_URL=$(terraform output -raw api_gateway_url 2>/dev/null || echo "")
    
    if [ -n "$API_URL" ]; then
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
    echo "  --skip-package          Skip Lambda packaging"
    echo "  --skip-frontend         Skip frontend deployment"
    echo "  --skip-test             Skip deployment testing"
    echo ""
    echo "Environment variables:"
    echo "  PROJECT_NAME            Project name"
    echo "  ENVIRONMENT             Environment name"
    echo "  AWS_REGION              AWS region"
    echo ""
}

# Parse command line arguments
SKIP_PACKAGE=false
SKIP_FRONTEND=false
SKIP_TEST=false

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
        --skip-package)
            SKIP_PACKAGE=true
            shift
            ;;
        --skip-frontend)
            SKIP_FRONTEND=true
            shift
            ;;
        --skip-test)
            SKIP_TEST=true
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
    echo ""
    
    # Check prerequisites
    check_prerequisites
    
    # Package Lambda functions (unless skipped)
    if [ "$SKIP_PACKAGE" = false ]; then
        package_lambda_functions
    else
        print_warning "Skipping Lambda packaging"
    fi
    
    # Initialize Terraform
    init_terraform
    
    # Plan deployment
    plan_terraform
    
    # Apply deployment
    apply_terraform
    
    # Deploy frontend (unless skipped)
    if [ "$SKIP_FRONTEND" = false ]; then
        deploy_frontend
    else
        print_warning "Skipping frontend deployment"
    fi
    
    # Display outputs
    display_outputs
    
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