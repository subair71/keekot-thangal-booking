import {test} from 'node:test';
import assert from 'node:assert/strict';
import {assertCanBook, bookingIdentity, normalizeVisitorPhone} from '../src/booking_identity.js';

test('visitor contact accepts international formatting and rejects ambiguous or invalid numbers', () => {
  for (const [input, expected] of [[' +91 (98765) 43210 ', '+919876543210'], ['+44 20 7946 0958', '+442079460958'], ['+1 (202) 555-0123', '+12025550123']])
    assert.equal(normalizeVisitorPhone(input), expected);
  for (const input of [undefined, null, 919876543210, '', '9876543210', '+0123456789', '+123', '+1234567890123456', '+91abc9876543210', '+919876543210 ext 2'])
    assert.throws(() => normalizeVisitorPhone(input), {code: 'invalid-argument'});
});

test('staff booking keeps creator separate and does not verify a manually entered number', () => {
  const khadim = {uid: 'khadim-1', phone: '+919111111111', khadim: true, permissions: ['bookings'], name: 'Test Khadim'};
  const snapshot = structuredClone(khadim);
  assert.deepEqual(bookingIdentity(khadim, '+44 20 7946 0958'), {
    visitorPhone: '+442079460958', visitorPhoneVerified: false, bookingSource: 'staff',
    bookedByUid: 'khadim-1', bookedByRole: 'khadim', bookedByName: 'Test Khadim',
  });
  assert.deepEqual(khadim, snapshot);
  const admin = {uid: 'admin-1', phone: '', admin: true};
  assert.doesNotThrow(() => assertCanBook(admin));
  assert.equal(bookingIdentity(admin, '+919876543210').bookedByRole, 'admin');
  for (const staff of [khadim, admin]) assert.throws(() => bookingIdentity(staff), {code: 'invalid-argument'});
});

test('self bookings use only the authenticated phone; booking permission cannot be inferred from any staff flag', () => {
  const visitor = {uid: 'visitor-1', phone: '+919876543210'};
  assert.equal(bookingIdentity(visitor).visitorPhone, visitor.phone);
  assert.equal(bookingIdentity(visitor).visitorPhoneVerified, true);
  for (const actor of [visitor, {...visitor, gate: true}, {...visitor, permissions: ['bookings']}])
    assert.throws(() => bookingIdentity(actor, '+12025550123'), {code: 'permission-denied'});
  assert.throws(() => bookingIdentity({...visitor, phone: ''}), {code: 'failed-precondition'});
  assert.throws(() => assertCanBook({...visitor, khadim: true, permissions: ['gate']}), {code: 'permission-denied'});
});
