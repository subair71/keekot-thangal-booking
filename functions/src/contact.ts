import {createHmac} from 'node:crypto';
import {getFirestore} from 'firebase-admin/firestore';
import {defineSecret} from 'firebase-functions/params';
import {onCall, HttpsError} from 'firebase-functions/v2/https';
import {logger} from 'firebase-functions';
import nodemailer from 'nodemailer';

export const contactMailbox = 'keekkottbungalowonline@gmail.com';
const gmailPassword = defineSecret('CONTACT_GMAIL_APP_PASSWORD');

export function validateContact(data: unknown) {
  if (!data || typeof data !== 'object') throw new HttpsError('invalid-argument', 'Please complete the contact form.');
  const input = data as Record<string, unknown>;
  const field = (key: string, min: number, max: number, multiline = false) => {
    const value = typeof input[key] === 'string' ? (input[key] as string).trim() : '';
    if (value.length < min || value.length > max || (!multiline && /[\r\n]/.test(value)) || /[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]/.test(value)) {
      throw new HttpsError('invalid-argument', `Please enter a valid ${key}.`);
    }
    return value;
  };
  const name = field('name', 2, 100), email = field('email', 3, 254);
  const phone = field('phone', 0, 30), subject = field('subject', 3, 120), message = field('message', 10, 3000, true);
  if (!/^[^\s@<>]+@[^\s@<>]+\.[^\s@<>]+$/.test(email) || (phone && !/^[+\d ()-]{6,30}$/.test(phone))) {
    throw new HttpsError('invalid-argument', 'Please check your email address and phone number.');
  }
  return {name, email, phone, subject, message};
}

export function contactMail(data: ReturnType<typeof validateContact>) {
  return {
    from: {name: 'Keekkott Maqam Website', address: contactMailbox},
    to: contactMailbox,
    replyTo: {name: data.name, address: data.email},
    subject: `[Website enquiry] ${data.subject}`,
    text: `Name: ${data.name}\nEmail: ${data.email}\nPhone: ${data.phone || 'Not provided'}\n\n${data.message}`,
    disableFileAccess: true,
    disableUrlAccess: true,
  };
}

export const submitContact = onCall({
  region: 'asia-south1', secrets: [gmailPassword], maxInstances: 3, timeoutSeconds: 60,
  enforceAppCheck: process.env.FUNCTIONS_EMULATOR !== 'true',
}, async request => {
  const data = validateContact(request.data);
  const password = gmailPassword.value();
  if (!password) throw new HttpsError('unavailable', 'Email delivery is temporarily unavailable.');
  // HMAC keeps raw IP addresses out of Firestore. Reuse bounded documents instead of growing a log.
  const ip = request.rawRequest.ip;
  if (!ip) throw new HttpsError('unavailable', 'Please try again later.');
  const fingerprint = createHmac('sha256', password).update(ip).digest('hex');
  const db = getFirestore(), now = Date.now();
  const limits = [
    {ref: db.doc(`contactRateLimits/ip_${fingerprint}`), window: 3600000, maximum: 5},
    {ref: db.doc('contactRateLimits/daily'), window: 86400000, maximum: 100},
  ];
  await db.runTransaction(async tx => {
    const snapshots = await tx.getAll(...limits.map(limit => limit.ref));
    for (const [index, limit] of limits.entries()) {
      const previous = snapshots[index].data();
      const active = previous && previous.resetAt > now;
      const count = active ? Number(previous.count) : 0;
      if (count >= limit.maximum) throw new HttpsError('resource-exhausted', 'Too many messages. Please try again later.');
      tx.set(limit.ref, {count: count + 1, resetAt: active ? previous.resetAt : now + limit.window});
    }
  });
  const transport = nodemailer.createTransport({
    host: 'smtp.gmail.com', port: 465, secure: true,
    auth: {user: contactMailbox, pass: password},
    connectionTimeout: 10000, greetingTimeout: 10000, socketTimeout: 20000,
  });
  try {
    const result = await transport.sendMail(contactMail(data));
    if (!result.accepted.includes(contactMailbox)) throw new Error('Recipient rejected');
    return {sent: true};
  } catch {
    logger.error('Contact email delivery failed');
    throw new HttpsError('unavailable', 'Your message could not be sent. Please try again later.');
  } finally {
    transport.close();
  }
});
