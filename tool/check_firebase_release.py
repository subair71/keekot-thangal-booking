#!/usr/bin/env python3
"""Fail before authentication/build when production release inputs are incomplete."""
import json
import os
import re


def validate(env):
    for key in ('FIREBASE_PROJECT_ID', 'WIF_PROVIDER', 'DEPLOY_SERVICE_ACCOUNT', 'WEB_CONFIG'):
        if not env.get(key, '').strip():
            raise ValueError(f'Missing release setting: {key}')
    project = env['FIREBASE_PROJECT_ID']
    if project.startswith('demo-') or not re.fullmatch(r'[a-z][a-z0-9-]{4,28}[a-z0-9]', project):
        raise ValueError('FIREBASE_PROJECT_ID must identify a real Firebase project.')
    try:
        config = json.loads(env['WEB_CONFIG'])
    except json.JSONDecodeError:
        raise ValueError('FIREBASE_WEB_CONFIG must be valid JSON.') from None
    if not isinstance(config, dict):
        raise ValueError('FIREBASE_WEB_CONFIG must be a JSON object.')
    if config.get('FIREBASE_PROJECT_ID') != project:
        raise ValueError('Web configuration and deployment project must match.')
    if config.get('ENVIRONMENT') != 'production' or config.get('USE_EMULATORS') is not False:
        raise ValueError('Production releases require ENVIRONMENT=production and USE_EMULATORS=false.')
    if config.get('FUNCTIONS_REGION') != 'asia-south1':
        raise ValueError('FUNCTIONS_REGION must match the backend region asia-south1.')
    for key in ('FIREBASE_API_KEY', 'FIREBASE_APP_ID', 'FIREBASE_MESSAGING_SENDER_ID',
                'FIREBASE_AUTH_DOMAIN', 'FIREBASE_STORAGE_BUCKET', 'APP_CHECK_SITE_KEY', 'VAPID_KEY'):
        value = config.get(key)
        if not isinstance(value, str) or not value.strip() or value.startswith('REPLACE_'):
            raise ValueError(f'Provide a production value for {key}.')


if __name__ == '__main__':
    try:
        validate(os.environ)
    except ValueError as error:
        raise SystemExit(str(error)) from None
    print('Release inputs validated; cloud IAM and project readiness still require verification.')
