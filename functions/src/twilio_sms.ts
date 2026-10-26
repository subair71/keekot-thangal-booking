import {Firestore} from 'firebase-admin/firestore';
import {logger} from 'firebase-functions';

export interface TwilioConfig {
  accountSid: string;
  authToken: string;
  fromPhone: string;
}

export async function getTwilioConfig(db: Firestore): Promise<TwilioConfig | null> {
  const envSid = process.env.TWILIO_ACCOUNT_SID?.trim();
  const envToken = process.env.TWILIO_AUTH_TOKEN?.trim();
  const envFrom = process.env.TWILIO_FROM_PHONE?.trim();

  if (envSid && envToken && envFrom) {
    return {
      accountSid: envSid,
      authToken: envToken,
      fromPhone: envFrom,
    };
  }

  try {
    const doc = await db.doc('settings/sms').get();
    if (!doc.exists) return null;
    const d = doc.data();
    if (d?.accountSid && d?.authToken && d?.fromPhone) {
      return {
        accountSid: String(d.accountSid).trim(),
        authToken: String(d.authToken).trim(),
        fromPhone: String(d.fromPhone).trim(),
      };
    }
  } catch (err) {
    logger.error('Failed to read Twilio config from settings/sms', {err});
  }

  return null;
}

export async function sendTwilioSms(
  config: TwilioConfig,
  to: string,
  body: string
): Promise<{ success: boolean; sid?: string; error?: string }> {
  try {
    const url = `https://api.twilio.com/2010-04-01/Accounts/${config.accountSid}/Messages.json`;
    const credentials = Buffer.from(`${config.accountSid}:${config.authToken}`).toString('base64');
    const params = new URLSearchParams({
      To: to,
      From: config.fromPhone,
      Body: body,
    });

    const res = await fetch(url, {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${credentials}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: params.toString(),
    });

    const data = (await res.json()) as any;
    if (!res.ok) {
      const errorMsg = data?.message || `HTTP ${res.status}`;
      logger.error('Twilio SMS delivery failed', {to, error: errorMsg, code: data?.code});
      return { success: false, error: errorMsg };
    }

    logger.info('Twilio SMS sent successfully', {to, sid: data?.sid});
    return { success: true, sid: data?.sid };
  } catch (err: any) {
    logger.error('Error sending Twilio SMS', {to, error: err?.message});
    return { success: false, error: err?.message || 'Network error' };
  }
}

export function formatBookingSmsText(b: {
  visitorName: string;
  bookingReference: string;
  visitDate: string;
  startTime: string;
  endTime: string;
  visitorCount: number;
  tokenStart?: number;
  tokenEnd?: number;
  passViewToken?: string;
}, appUrl = process.env.APP_ORIGIN || 'https://subair71.github.io/keekot-thangal-booking/'): string {
  const base = appUrl.endsWith('/') ? appUrl : `${appUrl}/`;
  const passUrl = b.passViewToken ? `${base}#/pass/${b.passViewToken}` : `${base}#/booking`;

  const tokens = b.tokenStart
    ? (b.tokenStart === b.tokenEnd ? `Token: ${b.tokenStart}` : `Tokens: ${b.tokenStart}–${b.tokenEnd}`)
    : '';

  return [
    `Keekkott Sayyid Attakoya Thangal Maqam`,
    `Visit Confirmed: ${b.visitDate} (${b.startTime} - ${b.endTime})`,
    tokens ? `${tokens} | Visitors: ${b.visitorCount}` : `Visitors: ${b.visitorCount}`,
    `Download your pass: ${passUrl}`
  ].filter(Boolean).join('\n');
}
