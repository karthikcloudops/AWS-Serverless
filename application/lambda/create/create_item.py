import json
import boto3
import os
from datetime import datetime
import uuid

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb')
table_name = os.environ.get('DYNAMODB_TABLE_NAME')
table = dynamodb.Table(table_name)

def lambda_handler(event, context):
    """
    Lambda function to create a new item in DynamoDB
    """
    try:
        # Parse the request body
        if event.get('body'):
            body = json.loads(event['body'])
        else:
            body = event
        
        # Validate required fields
        required_fields = ['name', 'description']
        for field in required_fields:
            if field not in body:
                return {
                    'statusCode': 400,
                    'headers': {
                        'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': '*',
                        'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                        'Access-Control-Allow-Methods': 'POST,OPTIONS'
                    },
                    'body': json.dumps({
                        'error': f'Missing required field: {field}'
                    })
                }
        
        # Generate unique ID and timestamp
        item_id = str(uuid.uuid4())
        timestamp = datetime.utcnow().isoformat()
        
        # Create item
        item = {
            'id': item_id,
            'name': body['name'],
            'description': body['description'],
            'created_at': timestamp,
            'updated_at': timestamp
        }
        
        # Add optional fields if provided
        if 'category' in body:
            item['category'] = body['category']
        if 'tags' in body:
            item['tags'] = body['tags']
        
        # Insert into DynamoDB
        table.put_item(Item=item)
        
        return {
            'statusCode': 201,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                'Access-Control-Allow-Methods': 'POST,OPTIONS'
            },
            'body': json.dumps({
                'message': 'Item created successfully',
                'item': item
            })
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                'Access-Control-Allow-Methods': 'POST,OPTIONS'
            },
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e)
            })
        } 