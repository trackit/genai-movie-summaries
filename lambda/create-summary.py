import boto3
import json
import os
from botocore.exceptions import ClientError

dynamodb = boto3.resource('dynamodb')
s3 = boto3.client('s3')
bedrock = boto3.client('bedrock')

bedrock_client = boto3.client('bedrock-runtime')

def lambda_handler(event, context):

    print(bedrock.list_foundation_models())
    print(event)

    #

    bedrock_runtime = bedrock.get_bedrock_client()

    prompt = '''

    Human:test

    Assistant:
    '''

    response = bedrock_client.invoke_model(
        body=json.dumps({
            "prompt": prompt,
            "max_tokens_to_sample": 100,
            "stop_sequences": ["\n\nHuman:"],
        }),
        modelId="anthropic.claude-instant-v1",
        accept="application/json",
        contentType="application/json"
    )

    print(response)

    job_name = event['pathParameters']['jobName']

    table_name = os.environ['DYNAMODB_TABLE_NAME']

    try:
        table = dynamodb.Table(table_name)

        response = table.get_item(Key={'JobName': job_name})

        item = response.get('Item', None)
        if not item:
            return {
                'statusCode': 404,
                'body': 'Item not found'
            }

        transcription_uri = item['Transcription']

        bucket = transcription_uri.split('/')[3]
        key = '/'.join(transcription_uri.split('/')[4:])
        s3_response = s3.get_object(Bucket=bucket, Key=key)
        transcription_body = s3_response['Body'].read().decode('utf-8')

        transcription_json = json.loads(transcription_body)

        return {
            'statusCode': 200,
            'body': json.dumps({
                'JobName': job_name,
                'Transcription': transcription_json["results"]["transcripts"]
            })
        }

    except ClientError as e:
        return {
            'statusCode': 500,
            'body': json.dumps("Internal server error: " + str(e))
        }


if __name__ == '__main__':
    event = {
        'pathParameters': {
            'jobName': 'aaf943a9-d1f3-4488-ba37-52220c648f0b'
        },
        'body': {
            'language': 'English',
            'type': 'entertaining'
        }
    }
    print(lambda_handler(event, None))

