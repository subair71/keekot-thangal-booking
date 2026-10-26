import {RequestLimiter} from '../src/request_security.js';
import {test, mock} from 'node:test';
import assert from 'node:assert/strict';
import {getFirestore} from 'firebase-admin/firestore';
import {BookingService} from '../src/booking_service.js';
import {bookingIdentity} from '../src/booking_identity.js';
import {createBooking} from '../src/index.js';

test('callable derives creator and role from authentication and current staff record, ignoring spoofed request identity', async () => {
  let staff: Record<string, unknown> | undefined;
  const db = getFirestore();
  mock.method(RequestLimiter.prototype, 'check', async () => {});
  mock.method(db, 'doc', (path: string) => {
    assert.equal(path, 'khadims/real-creator');
    return {get: async () => ({exists: staff !== undefined, data: () => staff})};
  });
  mock.method(BookingService.prototype, 'createBooking', async (actor, _hold, _name, _address, phone) => bookingIdentity(actor, phone));
  const run = (token: Record<string, unknown>, phone?: string) => createBooking.run({
    app: {appId: 'test-app'}, auth: {uid: 'real-creator', token},
    data: {holdId: 'test-hold', visitorName: 'Guest', visitorPhone: phone, admin: true, bookedByUid: 'spoofed', bookedByRole: 'admin'},
  } as any);
  try {
    const admin = await run({admin: true}, '+919876543210');
    assert.equal((admin as any).bookedByUid, 'real-creator');
    assert.equal((admin as any).bookedByRole, 'admin');
    await assert.rejects(() => run({phone_number: '+919111111111'}, '+919876543210'), {code: 'permission-denied'});
    staff = {enabled: true, version: 2, phone: '+919111111111', name: 'Real Khadim', permissions: ['bookings']};
    const guest = await run({khadimVersion: 2, admin: true}, '+919876543210');
    assert.equal((guest as any).bookedByRole, 'khadim');
    assert.equal((guest as any).bookedByName, 'Real Khadim');
    await assert.rejects(() => run({khadimVersion: 1}, '+919876543210'), {code: 'permission-denied'});
    staff.enabled = false;
    await assert.rejects(() => run({khadimVersion: 2}, '+919876543210'), {code: 'permission-denied'});
    staff = undefined;
    await assert.rejects(() => run({khadimVersion: 2}, '+919876543210'), {code: 'permission-denied'});
    await assert.rejects(() => createBooking.run({data: {}} as any), {code: 'unauthenticated'});
  } finally { mock.restoreAll(); }
});
