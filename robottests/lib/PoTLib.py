import base64
import hashlib
import hmac
import json


def calculate_pot_signature(body, client_secret):
    if isinstance(body, str):
        body = json.loads(body)
    body_string = json.dumps(
        body,
        sort_keys=True,
        indent=None,
        separators=(',', ': ')
    ).strip()

    digest = hmac.new(
        client_secret.encode('utf-8'),
        body_string.encode('utf-8'),
        hashlib.sha256
    ).digest()

    return base64.b64encode(digest).decode()
