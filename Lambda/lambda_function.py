import json
import os


def lambda_handler(event, context):
    """
    AWS Lambda function handler
    """
    environment = os.environ.get('ENVIRONMENT', 'unknown')
    
    print(f"Received event: {json.dumps(event)}")
    
    http_method = event.get('httpMethod', 'Unknown')
    path = event.get('path', 'Unknown')
    
    response_body = {
        'message': 'Hello from Lambda!',
        'environment': environment,
        'method': http_method,
        'path': path,
        'timestamp': context.aws_request_id
    }
    
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(response_body)
    }