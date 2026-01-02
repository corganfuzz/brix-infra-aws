import json
import os
import urllib.request
import boto3
from datetime import datetime

def handler(event, context):
    print(f"Received event: {json.dumps(event)}")
    
    api_key = os.environ.get('FRED_API_KEY')
    raw_bucket = os.environ.get('RAW_BUCKET_NAME')
    series_id = "MORTGAGE30US"
    
    url = f"https://api.stlouisfed.org/fred/series/observations?series_id={series_id}&api_key={api_key}&file_type=json&sort_order=desc&limit=1"
    
    try:
        with urllib.request.urlopen(url) as response:
            data = json.loads(response.read().decode())
            observation = data['observations'][0]
            rate = observation['value']
            date = observation['date']
            
            result = {
                "series_id": series_id,
                "rate": rate,
                "date": date,
                "unit": "percent",
                "ingestion_date": datetime.now().isoformat()
            }

            # Persist to S3
            if raw_bucket:
                s3 = boto3.client('s3')
                filename = f"mortgage_rates/{series_id}_{date}_{int(datetime.now().timestamp())}.json"
                print(f"Uploading to s3://{raw_bucket}/{filename}")
                s3.put_object(
                    Bucket=raw_bucket,
                    Key=filename,
                    Body=json.dumps(result),
                    ContentType='application/json'
                )
            
            response_body = {
                'TEXT': {
                    'body': json.dumps(result)
                }
            }
            
            action_response = {
                'actionGroup': event['actionGroup'],
                'function': event['function'],
                'functionResponse': {
                    'responseBody': response_body
                }
            }
            
            # Wrap directly for simplified protocol, or use messageVersion if full protocol
            # Trying the standard structure expected by most agents now
            return {
                "messageVersion": "1.0",
                "response": action_response
            }
            
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            "messageVersion": "1.0",
            "response": {
                'actionGroup': event['actionGroup'],
                'function': event['function'],
                'functionResponse': {
                    'responseBody': {
                        'TEXT': {
                            'body': json.dumps({"error": str(e)})
                        }
                    }
                }
            }
        }
