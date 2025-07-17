#!/bin/bash

# Script to create and confirm a Cognito test user
set -e

USER_POOL_ID=$(terraform output -raw cognito_user_pool_id)
USERNAME="test"
PASSWORD="Test@1234"
EMAIL="test@example.com"
REGION="ap-southeast-2"

# Create the user
aws cognito-idp admin-create-user \
  --user-pool-id "$USER_POOL_ID" \
  --username "$USERNAME" \
  --user-attributes Name=email,Value="$EMAIL" \
  --message-action SUPPRESS \
  --region "$REGION"

# Set the password and mark the user as confirmed
aws cognito-idp admin-set-user-password \
  --user-pool-id "$USER_POOL_ID" \
  --username "$USERNAME" \
  --password "$PASSWORD" \
  --permanent \
  --region "$REGION"

echo "✅ Test user created:"
echo "  Username: $USERNAME"
echo "  Password: $PASSWORD"
echo "  Email: $EMAIL" 