import json
import os
import boto3
import base64
import random
import time

bedrock_agent_runtime = boto3.client('bedrock-agent-runtime')

def lambda_handler(event, context):
    print(f"Event: {json.dumps(event)}")
    
    try:
        body = json.loads(event.get('body', '{}'))
        message = body.get('message')
        session_id = body.get('sessionId')
        
        if not message:
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({'error': 'Message is required'})
            }

        if not session_id:
            timestamp = int(time.time() * 1000)
            random_num = random.randint(0, 1000)
            session_id = f"session-{timestamp}-{random_num}"

        # Invoke Bedrock Agent
        agent_id = os.environ.get('AGENT_ID')
        agent_alias_id = os.environ.get('AGENT_ALIAS_ID')
        
        print(f"Invoking Agent: {agent_id} (Alias: {agent_alias_id}) Session: {session_id}")

        response = bedrock_agent_runtime.invoke_agent(
            agentId=agent_id,
            agentAliasId=agent_alias_id,
            sessionId=session_id,
            inputText=message
        )
        
        completion = ""
        
        for event_stream in response.get('completion', []):
            if 'chunk' in event_stream:
                chunk = event_stream['chunk']
                if 'bytes' in chunk:
                    text_chunk = chunk['bytes'].decode('utf-8')
                    completion += text_chunk

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*' # CORS
            },
            'body': json.dumps({
                'response': completion.strip(),
                'sessionId': session_id
            })
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({
                'error': str(e),
                'details': 'Internal Server Error'
            })
        }
