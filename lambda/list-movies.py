import boto3
import json
import os
from botocore.exceptions import ClientError

dynamodb = boto3.resource('dynamodb')

def lambda_handler(event, context):
    table_name = os.environ['DYNAMODB_TABLE_NAME']

    try:
        table = dynamodb.Table(table_name)
        response = table.scan()
        items = response.get('Items', [])
        movies = [{'id': item['JobName'], 'videoName': item['VideoName']} for item in items if 'JobName' in item and 'VideoName' in item]

        return {
            'statusCode': 200,
            'body': json.dumps(movies)
        }

    except ClientError as e:
        print(e.response['Error']['Message'])
        return {
            'statusCode': 500,
            'body': json.dumps("Internal server error: " + str(e))
        }


if __name__ == '__main__':
    event = {}
    print(lambda_handler(event, None))
