import {test} from 'node:test';
import assert from 'node:assert/strict';
import {activeHolds, BookingSettings, dateKey, generateSlots, makeToken, referenceFor, requireCapacity, settingsFrom, tokenHash, validDate, validateDay} from '../src/domain.js';
export const settings: BookingSettings={timezone:'Asia/Kolkata',openingTime:'07:00',closingTime:'19:00',slotDurationMinutes:30,bookingWindowDays:7,
  allowSameDayBooking:true,maxVisitorsPerBooking:3,defaultSlotCapacity:3,bookingEnabled:true,reminderEnabled:true,reminderMinutes:60,arrivalMinutes:10,
  environment:'development',locationUrl:'',contactPhone:''};
test('7 AM to 7 PM produces exactly 24 complete periods',()=>{
  const slots=generateSlots('2030-01-10',settings); assert.equal(slots.length,24); assert.equal(slots[0].startTime,'07:00'); assert.equal(slots.at(-1)!.endTime,'19:00');
  slots.forEach(s=>assert.equal(s.endAt-s.startAt,30*60_000));
  assert.equal(new Set(slots.map(s=>s.slotId)).size,24);
});
test('India midnight and booking window are independent of server locale',()=>{
  const now=Date.parse('2030-01-09T19:00Z');assert.equal(dateKey(now),'2030-01-10');
  assert.doesNotThrow(()=>validateDay('2030-01-16',settings,now));assert.throws(()=>validateDay('2030-01-17',settings,now));
  assert.throws(()=>validateDay('2030-01-10',{...settings,allowSameDayBooking:false},now));assert.throws(()=>validDate('2030-02-30'));
});
test('expired holds cannot consume capacity',()=>{
  const s=generateSlots('2030-01-10',settings)[0], now=s.startAt-60_000;
  const holds={a:{userId:'a',visitorCount:3,expiresAt:now}};
  assert.deepEqual(activeHolds(holds,now),{});assert.doesNotThrow(()=>requireCapacity(s,holds,3,now));
  assert.throws(()=>requireCapacity(s,{a:{...holds.a,expiresAt:now+1}},1,now));
});
test('blocked, past, and overcapacity bookings fail',()=>{
  const s=generateSlots('2030-01-10',settings)[0];
  assert.throws(()=>requireCapacity({...s,blocked:true},{},1,s.startAt-1000));
  assert.throws(()=>requireCapacity(s,{},1,s.startAt));assert.throws(()=>requireCapacity(s,{},4,s.startAt-1000));
});
test('configuration rejects partial periods and unsafe links',()=>{
  assert.throws(()=>settingsFrom({...settings,closingTime:'19:10'}));assert.throws(()=>settingsFrom({...settings,defaultSlotCapacity:0}));
  assert.throws(()=>settingsFrom({...settings,locationUrl:'javascript:alert(1)'}));
});
test('references and QR tokens are independent cryptographic values',()=>{
  const refs=new Set(Array.from({length:1000},()=>referenceFor('2030-01-10')));assert.equal(refs.size,1000);
  const token=makeToken();assert.equal(token.length,43);assert.equal(tokenHash(token).length,64);assert.notEqual(token,makeToken());
  assert.match([...refs][0],/^KT-20300110-[A-F0-9]{12}$/);
});
