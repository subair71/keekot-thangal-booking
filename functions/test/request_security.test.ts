import {test, mock} from 'node:test';
import assert from 'node:assert/strict';
import {Firestore} from 'firebase-admin/firestore';
import {CallableRequest} from 'firebase-functions/v2/https';
import {RequestLimiter, RequestPolicy, validateRequest, policyFor, enforceAppCheck} from '../src/request_security.js';
import {BookingService} from '../src/booking_service.js';
import {createHold, getAvailability, adminLogin} from '../src/index.js';

function fakeStore() {
  const records = new Map<string, any>();
  let tail = Promise.resolve();
  const db = {
    doc: (path: string) => ({path}),
    runTransaction: async (fn: (tx: any) => Promise<void>) => {
      const previous = tail;
      let release!: () => void;
      tail = new Promise<void>(resolve => {release = resolve;});
      await previous;
      const writes = new Map<string, any>();
      try {
        await fn({getAll: async (...refs: {path: string}[]) => refs.map(ref => ({data: () => records.get(ref.path)})),
          set: (ref: {path: string}, value: any) => writes.set(ref.path, value)});
        for (const [key, value] of writes) records.set(key, value);
      } finally {release();}
    },
  } as unknown as Firestore;
  return {db, records};
}
const request = (uid: string | null = 'account-one', ip = '192.0.2.1') => ({
  app: {appId: 'verified-test-app'},
  auth: uid ? {uid} : undefined,
  rawRequest: {ip, headers: {'x-forwarded-for': '198.51.100.77'}},
  data: {ip: '198.51.100.88', uid: 'spoofed-account'},
}) as unknown as CallableRequest;
const limits: RequestPolicy = {scope: 'test', authenticated: true, perAccount: 3, perIp: 10, windowMs: 60_000};

test('missing app verification and malformed or oversized data fail before business logic', async () => {
  assert.equal(enforceAppCheck, true);
  let businessCalls = 0, limiterCalls = 0;
  mock.method(BookingService.prototype, 'availability', async () => {businessCalls++; return {} as any;});
  mock.method(RequestLimiter.prototype, 'check', async () => {limiterCalls++;});
  try {
    await assert.rejects(() => getAvailability.run({data: {visitDate: '2030-01-01', app: {appId: 'forged'}}} as any), {code: 'unauthenticated'});
    for (const data of [null, [], 'invalid', {value: 'x'.repeat(16_384)}, {value: 'അ'.repeat(6000)}]) {
      await assert.rejects(() => getAvailability.run({...request(), data} as any), {code: 'invalid-argument'});
    }
    assert.equal(businessCalls, 0); assert.equal(limiterCalls, 0);
    validateRequest({data: {}} as any, false); // Emulator-only attestation bypass.
    await getAvailability.run({...request(null), data: {visitDate: '2030-01-01'}} as any);
    assert.equal(businessCalls, 1); assert.equal(limiterCalls, 1);
  } finally {mock.restoreAll();}
});

test('callables stop when the server limiter rejects a request', async () => {
  let invoked = 0;
  mock.method(RequestLimiter.prototype, 'check', async (_r, p) => {assert.equal(p.scope, 'holds'); throw new Error('limiter unavailable');});
  mock.method(BookingService.prototype, 'createHold', async () => {invoked++; return {} as any;});
  try {
    await assert.rejects(() => createHold.run(request() as any), {code: 'internal'});
    assert.equal(invoked, 0);
  } finally {mock.restoreAll();}
});

test('account throttles are atomic, cannot be evaded by changing IP, and reset at expiry', async () => {
  const {db, records} = fakeStore(); let now = 100_000;
  const limiter = new RequestLimiter(db, () => now);
  const results = await Promise.allSettled(Array.from({length: 12}, () => limiter.check(request(), limits)));
  assert.equal(results.filter(r => r.status === 'fulfilled').length, 3);
  await assert.rejects(() => limiter.check(request('account-one', '192.0.2.2'), limits), (error: any) => {
    assert.equal(error.code, 'resource-exhausted'); assert.equal(error.details.retryAfterSeconds, 60);
    assert.match(error.details.publicMessage, /Too many requests/); return true;
  });
  assert.equal(records.size, 2); // A rejected request must not partially spend another bucket.
  for (const [key, value] of records) {
    assert.doesNotMatch(key, /192\.0\.2|account-one|spoofed/);
    assert.equal(value.count, 3); assert.equal(value.purgeAt.toMillis(), 160_000 + 86_400_000);
    assert.deepEqual(Object.keys(value).sort(), ['count', 'purgeAt', 'until']);
  }
  now += 60_000;
  await limiter.check(request(), limits);
  assert.ok([...records.values()].every(value => value.count === 1));
});

test('public calls share the source-IP limit despite spoofed headers, identities and mapped IPv4', async () => {
  const {db} = fakeStore(); const limiter = new RequestLimiter(db);
  const publicLimits = {...limits, authenticated: false, perIp: 2};
  await limiter.check(request(null), publicLimits);
  await limiter.check(request(null, '::ffff:192.0.2.1'), publicLimits);
  await assert.rejects(() => limiter.check({...request('different-account'), data: {ip: '203.0.113.10'}} as any, publicLimits), {code: 'resource-exhausted'});
  await limiter.check(request(null, '192.0.2.2'), publicLimits);
});

test('authentication and a verified transport source are required before counter writes', async () => {
  const {db, records} = fakeStore(); const limiter = new RequestLimiter(db);
  await assert.rejects(() => limiter.check(request(null), limits), {code: 'unauthenticated'});
  await assert.rejects(() => limiter.check(request('user', ''), limits), {code: 'unavailable'});
  assert.equal(records.size, 0);
});

test('policies allow normal polling, share budgets across related operations, and throttle logins before credential lookup', async () => {
  assert.equal(policyFor('createHold').scope, policyFor('releaseHold').scope);
  assert.equal(policyFor('adminLogin').scope, policyFor('khadimLogin').scope);
  assert.equal(policyFor('getAvailability').authenticated, false);
  assert.ok(policyFor('getAvailability').perAccount > 3); // App polls every 20 seconds.
  assert.equal(policyFor('adminUpdateSettings').authenticated, true);
  mock.method(RequestLimiter.prototype, 'check', async (_r, p) => {
    assert.equal(p.scope, 'login');
    throw Object.assign(new Error('limited'), {code: 'not-a-domain-error'});
  });
  try {await assert.rejects(() => adminLogin.run(request(null) as any), {code: 'internal'});}
  finally {mock.restoreAll();}
});
