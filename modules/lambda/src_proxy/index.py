import json
import os
import boto3
import base64
import random
import time
from datetime import datetime

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
            inputText=message,
            enableTrace=True
        )
        
        completion = ""
        citations = {}
        has_real_time_data = False
        cite_counter = 1
        
        for event in response.get('completion', []):
            if 'chunk' in event:
                chunk = event['chunk']
                if 'bytes' in chunk:
                    completion += chunk['bytes'].decode('utf-8')
                
                # Extract citations from chunk attribution
                if 'attribution' in chunk:
                    for cit in chunk['attribution'].get('citations', []):
                        for ref in cit.get('retrievedReferences', []):
                            location = ref.get('location', {}).get('s3Location', {})
                            s3_uri = location.get('uri')
                            if s3_uri:
                                # Avoid duplicates
                                existing = [v['uri'] for v in citations.values()]
                                if s3_uri not in existing:
                                    # Extract filename as source
                                    source_name = s3_uri.split('/')[-1]
                                    citations[cite_counter] = {
                                        "source": source_name,
                                        "uri": s3_uri
                                    }
                                    cite_counter += 1

            if 'trace' in event:
                trace = event['trace'].get('trace', {})
                orchestration = trace.get('orchestrationTrace', {})
                
                # Real-time data detection (Action Group invocation)
                inv_input = orchestration.get('invocationInput', {})
                if 'actionGroupInvocationInput' in inv_input:
                    has_real_time_data = True
                
                # Check for observation from tool use
                if 'observation' in orchestration:
                    if 'actionGroupInvocationOutput' in orchestration['observation']:
                        has_real_time_data = True

                # Backup citation extraction from KB trace
                kb_out = orchestration.get('observation', {}).get('knowledgeBaseLookupOutput', {})
                for ref in kb_out.get('retrievedReferences', []):
                    location = ref.get('location', {}).get('s3Location', {})
                    s3_uri = location.get('uri')
                    if s3_uri:
                        existing = [v['uri'] for v in citations.values()]
                        if s3_uri not in existing:
                            source_name = s3_uri.split('/')[-1]
                            citations[cite_counter] = {
                                "source": source_name,
                                "uri": s3_uri
                            }
                            cite_counter += 1

        # Final Fallback for real-time detection in response text
        final_text = completion.strip()
        lower_text = final_text.lower()
        if any(kw in lower_text for kw in ["fred", "federal reserve", "mortgage rate tool", "dgs10", "mortgage30us"]):
            has_real_time_data = True

        # Log conversation to Databricks (Bronze Layer)
        raw_bucket = os.environ.get('RAW_BUCKET_NAME')
        if raw_bucket:
            try:
                log_record = {
                    "timestamp": datetime.now().isoformat(),
                    "sessionId": session_id,
                    "userMessage": message,
                    "botResponse": final_text,
                    "citations": citations,
                    "hasRealTimeData": has_real_time_data,
                    "metadata": {
                        "agentId": agent_id,
                        "agentAliasId": agent_alias_id
                    }
                }
                log_key = f"chat_logs/session_{session_id}/{int(time.time())}.json"
                print(f"Logging conversation to s3://{raw_bucket}/{log_key}")
                bedrock_agent_runtime._endpoint_prefix = 'bedrock-agent-runtime' # Ensure we use the right client if needed, but we can just use a separate s3 client
                s3 = boto3.client('s3')
                s3.put_object(
                    Bucket=raw_bucket,
                    Key=log_key,
                    Body=json.dumps(log_record),
                    ContentType='application/json'
                )
            except Exception as log_err:
                print(f"Failed to log conversation: {str(log_err)}")

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'response': final_text,
                'citations': citations,
                'hasRealTimeData': has_real_time_data,
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
