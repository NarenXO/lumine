import base64
import requests
import os
from dotenv import load_dotenv

load_dotenv()

cid = os.getenv('GLOO_CLIENT_ID')
csec = os.getenv('GLOO_CLIENT_SECRET')

print('CLIENT_ID:', cid[:10] if cid else 'MISSING')
print('CLIENT_SECRET:', csec[:10] if csec else 'MISSING')

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

print('Status:', r.status_code)
print('Response:', r.text[:500])