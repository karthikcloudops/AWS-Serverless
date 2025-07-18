#!/bin/bash

# Script to package Lambda functions for Terraform deployment
set -e

# Get the absolute path to the project root
PROJECT_ROOT=$(cd "$(dirname "$0")/../.." && pwd)
LAMBDA_ROOT="$PROJECT_ROOT/application/lambda"

cd "$(dirname "$0")/.." # cd to terraform directory

echo "Packaging Lambda functions..."

# Create temporary directory for packaging
TEMP_DIR=$(mktemp -d)
echo "Using temporary directory: $TEMP_DIR"

# Function to package a Lambda function
package_lambda() {
    local function_name=$1
    local source_dir="$LAMBDA_ROOT/$function_name"
    local target_zip="$LAMBDA_ROOT/$function_name/${function_name}_item.zip"
    
    echo "Packaging $function_name..."
    
    # Create function directory
    mkdir -p "$TEMP_DIR/$function_name"
    
    # Copy Python files
    cp "$source_dir"/*.py "$TEMP_DIR/$function_name/"
    
    # Install dependencies if requirements.txt exists
    if [ -f "$source_dir/requirements.txt" ]; then
        echo "Installing dependencies for $function_name in a venv..."
        python3.12 -m venv "$TEMP_DIR/venv"
        source "$TEMP_DIR/venv/bin/activate"
        pip install --upgrade pip
        pip install -r "$source_dir/requirements.txt" -t "$TEMP_DIR/$function_name/" --no-deps
        deactivate
        rm -rf "$TEMP_DIR/venv"
    fi
    
    # Create zip file
    cd "$TEMP_DIR/$function_name"
    zip -r "$target_zip" .
    cd - > /dev/null
    
    echo "Created $target_zip"
}

# Package each Lambda function
package_lambda "create"
package_lambda "read"
package_lambda "update"
package_lambda "delete"

# Clean up
rm -rf "$TEMP_DIR"

echo "Lambda packaging completed successfully!"
echo ""
echo "Generated zip files:"
echo "  - $LAMBDA_ROOT/create/create_item.zip"
echo "  - $LAMBDA_ROOT/read/read_item.zip"
echo "  - $LAMBDA_ROOT/update/update_item.zip"
echo "  - $LAMBDA_ROOT/delete/delete_item.zip" 