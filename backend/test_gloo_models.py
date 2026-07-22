import base64
import requests
import os
from dotenv import load_dotenv

load_dotenv()

cid = os.getenv('GLOO_CLIENT_ID')
csec = os.getenv('GLOO_CLIENT_SECRET')

# Get token
auth = base64.b64encode(f'{cid}:{csec}'.encode()).decode()
r = requests.post(
    'https://platform.ai.gloo.com/oauth2/token',
    headers={
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': f'Basic {auth}'
    },
    data={
        'grant_type': 'client_credentials',
        'scope': 'api/access'
    }
)
token = r.json()['access_token']
print('Token obtained successfully')

# Try to list models
models_r = requests.get(
    'https://platform.ai.gloo.com/ai/v1/models',
    headers={
        'Authorization': f'Bearer {token}'
    }
)
print('Models status:', models_r.status_code)
print('Models response:', models_r.text[:2000])

# Test one call with detailed error
print('\n--- Testing API call ---')
test_r = requests.post(
    'https://platform.ai.gloo.com/ai/v1/responses',
    headers={
        'Content-Type': 'application/json',
        'Authorization': f'Bearer {token}'
    },
    json={
        'model': 'gloo-openai-gpt-4o-mini',
        'instructions': 'You are a helpful assistant.',
        'input': [
            {'role': 'user', 'content': 'Say hello in one sentence.'}
        ]
    }
)
print('API call status:', test_r.status_code)
print('API call response:', test_r.text[:1000])