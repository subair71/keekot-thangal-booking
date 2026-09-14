import {createHash, randomBytes} from 'node:crypto';

export class DomainError extends Error {
  constructor(public code: 'invalid-argument' | 'failed-precondition' | 'resource-exhausted' | 'permission-denied' | 'not-found', message: string) { super(message); }
}
export interface BookingSettings {
  timezone: 'Asia/Kolkata'; openingTime: string; closingTime: string;
  slotDurationMinutes: number; bookingWindowDays: number; allowSameDayBooking: boolean;
  maxVisitorsPerBooking: number; defaultSlotCapacity: number; reminderEnabled: boolean;
  reminderMinutes: number; bookingEnabled: boolean; environment: string;
  locationUrl: string; contactPhone: string; arrivalMinutes: number;
  scheduleLockedUntil?: string;
}
export interface Slot {
  slotId: string; visitDate: string; startTime: string; endTime: string;
  startAt: number; endAt: number; capacity: number; occupancy: number;
  blocked: boolean; blockReason: string;
}
export interface HoldEntry {userId: string; visitorCount: number; expiresAt: number}
export type HoldMap = Record<string, HoldEntry>;
const IST = 330 * 60_000;
export const dateKey = (now: number) => new Date(now + IST).toISOString().slice(0, 10);
export const midnight = (day: string) => Date.parse(`${day}T00:00:00+05:30`);
export const addDays = (day: string, count: number) => dateKey(midnight(day) + count * 86_400_000);
export function validDate(day: unknown): string {
  if (typeof day !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(day) || !Number.isFinite(midnight(day)) || dateKey(midnight(day)) !== day)
    throw new DomainError('invalid-argument', 'Choose a valid visit date.');
  return day;
}
export function minutes(time: string): number {
  if (typeof time !== 'string' || !/^([01]\d|2[0-3]):[0-5]\d$/.test(time)) throw new DomainError('invalid-argument', 'Use a valid 24-hour time.');
  const [h, m] = time.split(':').map(Number); return h * 60 + m;
}
export const timeText = (value: number) => `${String(Math.floor(value / 60)).padStart(2, '0')}:${String(value % 60).padStart(2, '0')}`;
export function integer(value: unknown, min: number, max: number, label: string): number {
  if (typeof value !== 'number' || !Number.isInteger(value) || value < min || value > max)
    throw new DomainError('invalid-argument', `${label} must be between ${min} and ${max}.`);
  return value;
}
export function textValue(value: unknown, min: number, max: number, label: string): string {
  if (typeof value !== 'string' || value.trim().length < min || value.trim().length > max)
    throw new DomainError('invalid-argument', `Enter a valid ${label}.`);
  return value.trim();
}
export function settingsFrom(value: unknown): BookingSettings {
  const c = value as BookingSettings;
  if (!c || c.timezone !== 'Asia/Kolkata') throw new DomainError('failed-precondition', 'Booking is awaiting administrator configuration.');
  const open = minutes(c.openingTime), close = minutes(c.closingTime);
  integer(c.slotDurationMinutes, 15, 120, 'Slot duration');
  if (close <= open || (close-open) % c.slotDurationMinutes !== 0) throw new DomainError('invalid-argument', 'Hours must contain complete slots.');
  integer(c.bookingWindowDays, 1, 30, 'Booking window');
  integer(c.defaultSlotCapacity, 1, 500, 'Slot capacity');
  integer(c.maxVisitorsPerBooking, 1, c.defaultSlotCapacity, 'Visitors per booking');
  integer(c.reminderMinutes, 5, 1440, 'Reminder lead time');
  integer(c.arrivalMinutes, 0, 60, 'Arrival lead time');
  for (const k of ['bookingEnabled', 'reminderEnabled', 'allowSameDayBooking'] as const)
    if (typeof c[k] !== 'boolean') throw new DomainError('invalid-argument', `Set ${k}.`);
  if (c.locationUrl) {
    let url: URL; try { url = new URL(c.locationUrl); } catch { throw new DomainError('invalid-argument', 'Enter a valid directions URL.'); }
    if (url.protocol !== 'https:') throw new DomainError('invalid-argument', 'Directions must use HTTPS.');
  }
  if (c.contactPhone && !/^\+[1-9]\d{6,14}$/.test(c.contactPhone)) throw new DomainError('invalid-argument', 'Use an international contact number.');
  return c;
}
export function validateDay(day: string, c: BookingSettings, now: number): void {
  validDate(day);
  const today = dateKey(now), first = c.allowSameDayBooking ? today : addDays(today, 1);
  if (day < first || day >= addDays(today, c.bookingWindowDays))
    throw new DomainError('failed-precondition', 'This date is outside the booking window.');
  if (!c.bookingEnabled) throw new DomainError('failed-precondition', 'Bookings are currently paused.');
}
export function generateSlots(day: string, c: BookingSettings): Slot[] {
  validDate(day); const end = minutes(c.closingTime), slots: Slot[] = [];
  for (let m = minutes(c.openingTime); m + c.slotDurationMinutes <= end; m += c.slotDurationMinutes) {
    const startTime = timeText(m), endTime = timeText(m + c.slotDurationMinutes);
    slots.push({slotId: `${day}_${startTime.replace(':', '')}`, visitDate: day, startTime, endTime,
      startAt: midnight(day) + m * 60_000, endAt: midnight(day) + (m+c.slotDurationMinutes)*60_000,
      capacity: c.defaultSlotCapacity, occupancy: 0, blocked: false, blockReason: ''});
  }
  return slots;
}
export function activeHolds(holds: HoldMap, now: number): HoldMap {
  return Object.fromEntries(Object.entries(holds).filter(([, h]) => h.expiresAt > now));
}
export const heldCount = (holds: HoldMap) => Object.values(holds).reduce((sum, h) => sum+h.visitorCount, 0);
export function requireCapacity(slot: Slot, holds: HoldMap, count: number, now: number): void {
  if (slot.blocked || slot.startAt <= now) throw new DomainError('failed-precondition', slot.blocked ? (slot.blockReason || 'This slot is blocked.') : 'This slot has already started.');
  if (count > slot.capacity-slot.occupancy-heldCount(activeHolds(holds, now)))
    throw new DomainError('resource-exhausted', 'This slot no longer has enough places. Please choose another slot.');
}
export const makeToken = () => randomBytes(32).toString('base64url');
export const tokenHash = (value: string) => createHash('sha256').update(value).digest('hex');
export const referenceFor = (day: string) => `KT-${day.replaceAll('-', '')}-${randomBytes(6).toString('hex').toUpperCase()}`;
export const maskPhone = (phone: string) => phone.length < 7 ? 'Verified mobile' : `${phone.slice(0, 3)} ••••• ${phone.slice(-4)}`;
export const publicSlot = (s: Slot, h: HoldMap, now: number, closure?: {closed?: boolean; reason?: string}) => ({...s,
  blocked: s.blocked || closure?.closed === true, blockReason: closure?.closed ? closure.reason || 'Closed for visits' : s.blockReason,
  remaining: Math.max(0, s.capacity-s.occupancy-heldCount(activeHolds(h, now))),
  status: s.startAt <= now ? 'past' : (s.blocked || closure?.closed) ? 'blocked' : s.occupancy+heldCount(activeHolds(h, now)) >= s.capacity ? 'full' : 'available'});
