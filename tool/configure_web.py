#!/usr/bin/env python3
"""Generate public web SDK config. Never use this for credentials or private keys."""
import argparse
import json
from pathlib import Path

p = argparse.ArgumentParser()
p.add_argument('config', help='A dart-define JSON file for this environment')
args = p.parse_args()
root = Path(__file__).resolve().parent.parent
data = json.loads(Path(args.config).read_text())
keys = {'apiKey': 'FIREBASE_API_KEY', 'appId': 'FIREBASE_APP_ID', 'messagingSenderId': 'FIREBASE_MESSAGING_SENDER_ID',
        'projectId': 'FIREBASE_PROJECT_ID', 'authDomain': 'FIREBASE_AUTH_DOMAIN', 'storageBucket': 'FIREBASE_STORAGE_BUCKET'}
for value in keys.values():
    if not data.get(value) or str(data[value]).startswith('REPLACE_'):
        raise SystemExit(f'Provide {value} before building.')
if data.get('ENVIRONMENT') != 'development':
    if data.get('USE_EMULATORS') or not data.get('APP_CHECK_SITE_KEY') or not data.get('VAPID_KEY'):
        raise SystemExit('Hosted builds require App Check and VAPID configuration with emulators disabled.')
    if data['FIREBASE_PROJECT_ID'].startswith('demo-'):
        raise SystemExit('Hosted builds require a real Firebase project.')
config = {k: data[v] for k, v in keys.items()}
(root / 'web/firebase-config.js').write_text('self.KEEKOT_FIREBASE_CONFIG = ' + json.dumps(config) + ';\n' +
    'self.KEEKOT_USE_EMULATORS = ' + json.dumps(bool(data.get('USE_EMULATORS', False))) + ';\n')
print('Public web configuration generated for', data['ENVIRONMENT'])
