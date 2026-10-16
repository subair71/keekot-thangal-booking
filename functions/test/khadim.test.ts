import {test} from 'node:test';
import assert from 'node:assert/strict';
import {Firestore} from 'firebase-admin/firestore';
import {BookingService} from '../src/booking_service.js';
import {BookingSettings} from '../src/domain.js';

const service=new BookingService({} as Firestore);
test('bookings access does not grant settings, slots or gate privileges',async()=>{
  const staff={uid:'staff',phone:'+919876543210',permissions:['bookings']};
  await assert.rejects(()=>service.adminUpdateSettings(staff,{} as BookingSettings),/Administrator access/);
  await assert.rejects(()=>service.adminSetDateHours(staff,{visitDate:'2030-01-10',reset:true}),/Administrator access/);
  await assert.rejects(()=>service.adminUpdateSlots(staff,{visitDate:'2030-01-10',blocked:true,reason:'test'}),/Administrator access/);
  await assert.rejects(()=>service.validatePass(staff,'x',true),/Entry staff access/);
});
test('slots access does not grant general settings or gate privileges',async()=>{
  const staff={uid:'staff',phone:'+919876543210',permissions:['slots']};
  await assert.rejects(()=>service.adminUpdateSettings(staff,{} as BookingSettings),/Administrator access/);
  await assert.rejects(()=>service.validatePass(staff,'x',true),/Entry staff access/);
});
