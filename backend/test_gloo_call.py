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

# Test actual call
test_r = requests.post(
    'https://platform.ai.gloo.com/ai/v1/responses',
    headers={
        'Content-Type': 'application/json',
        'Authorization': f'Bearer {token}'
    },
    json={
        'model': 'gloo-anthropic-claude-haiku-4.5',
        'instructions': 'You are Lumíne, a warm spiritual companion.',
        'input': [
            {'role': 'user', 'content': 'I feel so anxious and overwhelmed today'}
        ]
    }
)
print('Status:', test_r.status_code)
print('Response:', test_r.text[:1000])