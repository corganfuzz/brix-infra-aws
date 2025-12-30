import json
import os
import urllib.request

def handler(event, context):
    print(f"Received event: {json.dumps(event)}")
    
    api_key = os.environ.get('FRED_API_KEY')
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
                "unit": "percent"
            }
            
            response_body = {
                'application/json': {
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
            
            return action_response
            
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'actionGroup': event['actionGroup'],
            'function': event['function'],
            'functionResponse': {
                'responseBody': {
                    'application/json': {
                        'body': json.dumps({"error": str(e)})
                    }
                }
            }
        }
