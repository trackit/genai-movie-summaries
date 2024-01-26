import boto3
import json
import os
from botocore.exceptions import ClientError

dynamodb = boto3.resource('dynamodb')
s3 = boto3.client('s3')
bedrock_client = boto3.client('bedrock-runtime')

def lambda_handler(event, context):

    job_name = event['pathParameters']['jobName']
    event_body = json.loads(event['body'])
    table_name = os.environ['DYNAMODB_TABLE_NAME']

    if 'language' in event_body:
        language = event_body['language']
    else:
        language = 'english'

    if 'type' in event_body:
        type = event_body['type']
    else:
        type = 'Synopsis'

    if 'custom' in event_body:
        custom = event_body['custom']
    else:
        custom = ''

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

        transcription = json.loads(transcription_body)["results"]["transcripts"][0]["transcript"]

        prompt = f'''

Human: You are a summary writer, your role is to create a summaries from the movie transcription. Here are the types of summaries you can produce:
 - Synopsis:
    Length: Medium to long (several paragraphs).
    Characteristics: Provides a complete overview of the plot, including the setting, main characters, and major developments of the story. May reveal the ending.
 - Tagline:
    Length: Very short (one sentence).
    Characteristics: Designed to quickly capture attention. Often used in movie posters or DVD covers. Must be impactful and memorable.
 - Back Cover Summary:
    Length: Short (one paragraph).
    Characteristics: Gives an overview of the story without too much detail. Often used on the back of DVDs or in online catalogs. Should arouse interest without revealing key plot elements.
 - Logline:
    Length: Very short (one or two sentences).
    Characteristics: Summarizes the plot by focusing on the central element or conflict of the film. Used to give a quick idea of the main story.
 - Press Summary:
    Length: Variable (a few lines to a paragraph).
    Characteristics: Used in press kits and releases. May include information about the cast, director, and details about the film's production.
 - Festival Program Summary:
    Length: Short to medium (one to several paragraphs).
    Characteristics: Used in film festival programs. Provides enough information about the plot to generate interest, while including details about the directors, actors, and sometimes artistic intentions.
 - Streaming Platform Summary:
    Length: Short (a few lines to a paragraph).
    Characteristics: Must be concise and appealing to encourage instant viewing. Often focuses on the most intriguing or unique elements of the film.
 - {custom}
    Write a summary for the transcript I will give you following the type: {type}, in {language}
    Transcript : {transcription}

Assistant:
'''
        invoke_body = json.dumps({
                "prompt": prompt,
                "max_tokens_to_sample": 600,
                "stop_sequences": ["\n\nHuman:"],
            })

        response = bedrock_client.invoke_model(
            body=invoke_body,
            modelId="anthropic.claude-v2",
            accept="application/json",
            contentType="application/json"
        )

        return {
            'statusCode': 200,
            'body': json.dumps({
                'JobName': job_name,
                'bedrock_response': json.loads(response["body"].read())["completion"],
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
            'jobName': '9621b224-0970-4abb-8e68-838c14a6754f'
        },
        'body': {
        }
    }
    print(lambda_handler(event, None))

