import {DomainError} from './domain.js';

// Populated by the callable's authenticated account lookup, never request data.
export interface Actor {uid: string; phone: string; admin?: boolean; khadim?: boolean; khadimVersion?: number; name?: string; gate?: boolean; permissions?: string[]}

export function normalizeVisitorPhone(value: unknown): string {
  if (typeof value !== 'string' || value.length > 40)
    throw new DomainError('invalid-argument', 'Enter the visitor phone number with country code, for example +91 9876543210.');
  const phone = value.trim().replace(/[\s()-]/g, '');
  if (!/^\+[1-9]\d{7,14}$/.test(phone))
    throw new DomainError('invalid-argument', 'Enter the visitor phone number with country code, for example +91 9876543210.');
  return phone;
}

export function assertCanBook(actor: Actor): void {
  if (actor.admin) return;
  if (actor.khadim) {
    if (!actor.permissions?.includes('bookings'))
      throw new DomainError('permission-denied', 'Booking permission is required to book for visitors.');
    return;
  }
  if (!/^\+[1-9]\d{7,14}$/.test(actor.phone))
    throw new DomainError('failed-precondition', 'A verified phone number is required.');
}

export function bookingIdentity(actor: Actor, visitorPhone?: unknown) {
  assertCanBook(actor);
  const assisted = actor.admin === true || actor.khadim === true;
  if (!assisted && visitorPhone !== undefined)
    throw new DomainError('permission-denied', 'Only authorized staff can enter another visitor phone number.');
  return {
    visitorPhone: assisted ? normalizeVisitorPhone(visitorPhone) : actor.phone,
    visitorPhoneVerified: !assisted,
    bookingSource: assisted ? 'staff' : 'self',
    bookedByUid: actor.uid,
    bookedByRole: actor.admin ? 'admin' : actor.khadim ? 'khadim' : 'visitor',
    bookedByName: actor.name || '',
  };
}
