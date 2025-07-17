import json
import boto3
import os
from datetime import datetime

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb')
table_name = os.environ.get('DYNAMODB_TABLE_NAME')
table = dynamodb.Table(table_name)

def lambda_handler(event, context):
    """
    Lambda function to update an item in DynamoDB
    """
    try:
        # Parse the request body
        if event.get('body'):
            body = json.loads(event['body'])
        else:
            body = event
        
        # Get item ID from path parameters or body
        item_id = event.get('pathParameters', {}).get('id') or body.get('id')
        
        if not item_id:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                    'Access-Control-Allow-Methods': 'PUT,OPTIONS'
                },
                'body': json.dumps({
                    'error': 'Item ID is required'
                })
            }
        
        # Check if item exists
        existing_item = table.get_item(Key={'id': item_id})
        if 'Item' not in existing_item:
            return {
                'statusCode': 404,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                    'Access-Control-Allow-Methods': 'PUT,OPTIONS'
                },
                'body': json.dumps({
                    'error': 'Item not found'
                })
            }
        
        # Prepare update expression with proper handling of reserved keywords
        update_parts = ["#updated_at = :updated_at"]
        expression_attribute_values = {
            ':updated_at': datetime.utcnow().isoformat()
        }
        expression_attribute_names = {
            '#updated_at': 'updated_at'
        }
        
        # Add fields to update with proper reserved keyword handling
        field_mappings = {
            'name': '#name',
            'description': '#description', 
            'category': '#category',
            'tags': '#tags'
        }
        
        allowed_fields = ['name', 'description', 'category', 'tags']
        for field in allowed_fields:
            if field in body:
                placeholder = field_mappings[field]
                update_parts.append(f"{placeholder} = :{field}")
                expression_attribute_values[f':{field}'] = body[field]
                expression_attribute_names[placeholder] = field
        
        # Construct the update expression
        update_expression = f"SET {', '.join(update_parts)}"
        
        # Update the item
        response = table.update_item(
            Key={'id': item_id},
            UpdateExpression=update_expression,
            ExpressionAttributeValues=expression_attribute_values,
            ExpressionAttributeNames=expression_attribute_names,
            ReturnValues='ALL_NEW'
        )
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                'Access-Control-Allow-Methods': 'PUT,OPTIONS'
            },
            'body': json.dumps({
                'message': 'Item updated successfully',
                'item': response['Attributes']
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
                'Access-Control-Allow-Methods': 'PUT,OPTIONS'
            },
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e)
            })
        } 