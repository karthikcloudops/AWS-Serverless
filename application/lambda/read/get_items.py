import json
import boto3
import os
from boto3.dynamodb.conditions import Key

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb')
table_name = os.environ.get('DYNAMODB_TABLE_NAME')
table = dynamodb.Table(table_name)

def lambda_handler(event, context):
    """
    Lambda function to read items from DynamoDB
    """
    try:
        # Get query parameters
        query_params = event.get('queryStringParameters', {}) or {}
        item_id = query_params.get('id')
        
        if item_id:
            # Get specific item by ID
            response = table.get_item(Key={'id': item_id})
            
            if 'Item' not in response:
                return {
                    'statusCode': 404,
                    'headers': {
                        'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': '*',
                        'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                        'Access-Control-Allow-Methods': 'GET,OPTIONS'
                    },
                    'body': json.dumps({
                        'error': 'Item not found'
                    })
                }
            
            return {
                'statusCode': 200,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                    'Access-Control-Allow-Methods': 'GET,OPTIONS'
                },
                'body': json.dumps({
                    'item': response['Item']
                })
            }
        else:
            # Get all items (with pagination)
            limit = int(query_params.get('limit', 10))
            last_key = query_params.get('last_key')
            
            scan_kwargs = {
                'Limit': limit
            }
            
            if last_key:
                scan_kwargs['ExclusiveStartKey'] = {'id': last_key}
            
            response = table.scan(**scan_kwargs)
            
            return {
                'statusCode': 200,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                    'Access-Control-Allow-Methods': 'GET,OPTIONS'
                },
                'body': json.dumps({
                    'items': response.get('Items', []),
                    'count': len(response.get('Items', [])),
                    'last_evaluated_key': response.get('LastEvaluatedKey'),
                    'scanned_count': response.get('ScannedCount', 0)
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
                'Access-Control-Allow-Methods': 'GET,OPTIONS'
            },
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e)
            })
        } 