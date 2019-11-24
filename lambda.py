import json
import os
import time
import datetime

import boto3
dynamodb = boto3.resource('dynamodb')

def lambda_handler(event, context):
    data = json.loads(event["body"])
    if 'message' not in data:
        logging.error("Validation Failed")
        raise Exception("Couldn't create the todo item.")
    
    timestamp = str(datetime.datetime.now())

    table = dynamodb.Table(os.environ['DYNAMODB_TABLE'])

    item = {
        'UserId': data['name'],
        'Date': timestamp,
        'text': data['message'],
        'email':data['email']
    }

     # write the todo to the database
    table.put_item(TableName="Cloud_Infrastructure", Item=item)

    # create a response
    response = {
        "statusCode": 200,
        "body": json.dumps(item),
        "headers" : {
            'Access-Control-Allow-Origin' : '*'
            }
    }

    return response