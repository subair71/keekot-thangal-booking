import {isIP} from 'node:net';
import {Firestore, Timestamp} from 'firebase-admin/firestore';
import {CallableRequest, HttpsError} from 'firebase-functions/v2/https';
import {tokenHash} from './domain.js';

export const enforceAppCheck = process.env.FUNCTIONS_EMULATOR !== 'true';
const minute = 60_000;
const retryMessage = 'Too many requests. Please wait a moment and try again.';
export interface RequestPolicy {
  scope: string;
  authenticated: boolean;
  perIp: number;
  perAccount: number;
  windowMs: number;
}
const policy = (scope: string, perAccount: number, perIp: number, authenticated = true): RequestPolicy =>
  ({scope, perAccount, perIp, authenticated, windowMs: minute});
const policies: Record<string, RequestPolicy> = {
  getAvailability: policy('availability', 60, 300, false),
  getActiveHold: policy('booking-read', 60, 600),
  createHold: policy('holds', 20, 300),
  releaseHold: policy('holds', 20, 300),
  createBooking: policy('confirmation', 20, 300),
  validatePass: policy('scanning', 120, 600),
  registerDevice: policy('devices', 20, 300),
  unregisterDevice: policy('devices', 20, 300),
  adminLogin: policy('login', 60, 60, false),
  khadimLogin: policy('login', 60, 60, false),
};
export const policyFor = (operation: string): RequestPolicy => policies[operation] ?? policy('account-actions', 120, 1200);

export function validateRequest(request: CallableRequest, requireAppCheck = enforceAppCheck): void {
  // The callable SDK verifies the token before constructing request.app. Never
  // accept an app ID, identity, or IP supplied inside request.data.
  if (requireAppCheck && !request.app) {
    throw new HttpsError('unauthenticated', 'App verification is required. Refresh the page and try again.',
      {publicMessage: 'App verification is required. Refresh the page and try again.'});
  }
  if (!request.data || typeof request.data !== 'object' || Array.isArray(request.data)
      || Buffer.byteLength(JSON.stringify(request.data), 'utf8') > 16_384) {
    throw new HttpsError('invalid-argument', 'Send a valid request of no more than 16 KB.',
      {publicMessage: 'This request is invalid or too large. Please refresh and try again.'});
  }
}

export class RequestLimiter {
  constructor(private db: Firestore, private clock: () => number = Date.now) {}

  async check(request: CallableRequest, limits: RequestPolicy): Promise<void> {
    if (limits.authenticated && !request.auth) throw new HttpsError('unauthenticated', 'Please sign in.');
    // Express supplies the source IP. Do not read an arbitrary forwarded header
    // or any caller-provided IP field. The function remains behind Firebase's
    // verified callable transport; CORS is not an authorization control.
    const ip = request.rawRequest?.ip?.toLowerCase().replace(/^::ffff:/, '');
    if (!ip || !isIP(ip)) throw new HttpsError('unavailable', 'Unable to verify the request source. Please try again.');
    const buckets = [{kind: 'ip', identity: ip, maximum: limits.perIp}];
    if (request.auth) buckets.push({kind: 'account', identity: request.auth.uid, maximum: limits.perAccount});
    const refs = buckets.map(b => this.db.doc(`requestRateLimits/${limits.scope}_${b.kind}_${tokenHash(b.identity)}`));
    await this.db.runTransaction(async tx => {
      const snapshots = await tx.getAll(...refs);
      const now = this.clock();
      const windows = snapshots.map(snapshot => {
        const value = snapshot.data();
        const active = Number.isFinite(value?.until) && value!.until > now;
        return {count: active && Number.isInteger(value?.count) ? value!.count : 0,
          until: active ? value!.until : now + limits.windowMs};
      });
      const blocked = windows.filter((w, i) => w.count >= buckets[i].maximum);
      if (blocked.length) {
        throw new HttpsError('resource-exhausted', retryMessage, {
          publicMessage: retryMessage,
          retryAfterSeconds: Math.max(...blocked.map(w => Math.ceil((w.until - now) / 1000))),
        });
      }
      windows.forEach((w, i) => tx.set(refs[i], {
        count: w.count + 1, until: w.until,
        // Pseudonymous IDs, no raw IP/phone/UID or booking payload in counters.
        // TTL is storage cleanup; expired counters reset even before deletion.
        purgeAt: Timestamp.fromMillis(w.until + 86_400_000),
      }));
    });
  }
}
