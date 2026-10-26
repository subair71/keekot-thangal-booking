import {initializeApp, applicationDefault} from 'firebase-admin/app';
import {getFirestore} from 'firebase-admin/firestore';

const [projectId, accountSid, authToken, fromPhone] = process.argv.slice(2);
if (!projectId || !accountSid || !authToken || !fromPhone) {
  console.error('Usage: npm run configure-twilio -- PROJECT_ID ACCOUNT_SID AUTH_TOKEN FROM_PHONE');
  process.exit(1);
}

initializeApp({projectId, credential: applicationDefault()});
const db = getFirestore();

await db.doc('settings/sms').set({
  accountSid: accountSid.trim(),
  authToken: authToken.trim(),
  fromPhone: fromPhone.trim(),
  provider: 'twilio',
  updatedAt: new Date().toISOString(),
}, {merge: true});

console.log('Twilio SMS configuration saved successfully to settings/sms.');
