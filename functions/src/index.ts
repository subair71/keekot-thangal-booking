import {initializeApp} from 'firebase-admin/app';
import {getFirestore, FieldValue, AggregateField} from 'firebase-admin/firestore';
import {onCall, HttpsError, CallableRequest} from 'firebase-functions/v2/https';
import {onDocumentCreated, onDocumentWritten} from 'firebase-functions/v2/firestore';
import {onSchedule} from 'firebase-functions/v2/scheduler';
import {setGlobalOptions} from 'firebase-functions/v2';
import {logger} from 'firebase-functions';
import {Actor, BookingService} from './booking_service.js';
import {dateKey, DomainError, textValue, tokenHash, validDate} from './domain.js';
import {deliverNotice, queueNotice, reminders} from './notifications.js';

initializeApp(); const db=getFirestore(), service=new BookingService(db);
setGlobalOptions({region:'asia-south1',maxInstances:20,memory:'256MiB',timeoutSeconds:60});
const emulator=process.env.FUNCTIONS_EMULATOR==='true';
function actor(r: CallableRequest, role: 'visitor'|'admin'|'gate'='visitor'): Actor {
  if(!r.auth)throw new HttpsError('unauthenticated','Please verify your mobile number.');
  const a={uid:r.auth.uid,phone:String(r.auth.token.phone_number || ''),admin:r.auth.token.admin===true,gate:r.auth.token.gate===true};
  if(role==='admin'&&!a.admin || role==='gate'&&!a.admin&&!a.gate)throw new HttpsError('permission-denied','You do not have access to this area.');
  if(role==='visitor'&&!a.phone)throw new HttpsError('failed-precondition','A verified phone number is required.'); return a;
}
function callable<T>(fn:(r:CallableRequest)=>Promise<T>) {
  return onCall({enforceAppCheck:!emulator},async r=>{
    try{return await fn(r);}catch(e){
      if(e instanceof HttpsError)throw e;
      if(e instanceof DomainError)throw new HttpsError(e.code,e.message,{publicMessage:e.message});
      logger.error('Operation failed',{type:e instanceof Error?e.name:'unknown'});
      throw new HttpsError('internal','We could not complete this request. Please try again.');
    }
  });
}
const id=(x:unknown)=>{const value=textValue(x,1,240,'identifier');if(!/^[\w-]+$/.test(value))throw new DomainError('invalid-argument','Invalid identifier.');return value;};
export const getAvailability=callable(r=>service.availability(validDate(r.data?.visitDate)));
export const getActiveHold=callable(async r=>{
  const a=actor(r),now=Date.now(); const current=await db.doc(`activeUserHolds/${a.uid}`).get();
  if(!current.exists || current.data()!.expiresAt<=now)return {hold:null};
  const h=await db.doc(`slotHolds/${current.data()!.holdId}`).get();
  if (!h.exists || h.data()!.status!=='active' || h.data()!.expiresAt<=now) return {hold:null};
  const d=h.data()!; return {hold:{holdId:h.id,slotId:d.slotId,visitDate:d.visitDate,startTime:d.startTime,endTime:d.endTime,visitorCount:d.visitorCount,expiresAt:d.expiresAt,serverNow:now}};
});
export const createHold=callable(r=>service.createHold(actor(r),r.data));
export const releaseHold=callable(r=>service.releaseHold(actor(r),id(r.data?.holdId)));
export const createBooking=callable(r=>service.createBooking(actor(r),id(r.data?.holdId),r.data?.visitorName));
export const cancelBooking=callable(r=>service.cancelBooking(actor(r),id(r.data?.bookingId),r.data?.reason));
export const validatePass=callable(r=>service.validatePass(actor(r,'gate'),r.data?.qrToken,r.data?.checkIn===true));
export const adminUpdateSlot=callable(r=>service.adminUpdateSlots(actor(r,'admin'),r.data));
export const adminUpdateSettings=callable(r=>service.adminUpdateSettings(actor(r,'admin'),r.data));
export const adminSetBookingStatus=callable(async r=>{
  const a=actor(r,'admin'), bookingId=id(r.data?.bookingId), status=r.data?.status;
  if(!['completed','noShow'].includes(status))throw new HttpsError('invalid-argument','Choose a valid status.');
  await db.runTransaction(async tx=>{
    const ref=db.doc(`bookings/${bookingId}`), b=await tx.get(ref);
    if(!b.exists)throw new HttpsError('not-found','Booking not found.');
    if(b.data()!.status===status)return;
    if(!['confirmed','expired'].includes(b.data()!.status))throw new HttpsError('failed-precondition','This booking cannot be updated.');
    if(Date.now()<(status==='noShow'?b.data()!.endAt:b.data()!.startAt))throw new HttpsError('failed-precondition',status==='noShow'?'Wait until the visit has ended.':'The visit has not started.');
    tx.update(ref,{status,updatedAt:FieldValue.serverTimestamp()});
    tx.create(db.collection('auditLog').doc(),{actor:a.uid,action:status,bookingId,at:FieldValue.serverTimestamp()});
  });return {updated:true};
});
export const adminDashboard=callable(async r=>{
  actor(r,'admin'); const today=dateKey(Date.now());
  const day=db.collection('bookings').where('visitDate','==',today), all=db.collection('bookings');
  const [bookings,visitors,upcoming,cancelled,availability]=await Promise.all([
    day.count().get(),day.where('status','in',['confirmed','completed']).aggregate({visitors:AggregateField.sum('visitorCount')}).get(),
    all.where('status','==','confirmed').where('startAt','>',Date.now()).count().get(),day.where('status','==','cancelled').count().get(),
    service.availability(today).catch(()=>null)]);
  return {bookingsToday:bookings.data().count,visitorsToday:visitors.data().visitors,upcoming:upcoming.data().count,cancelled:cancelled.data().count,
    availableSlots:availability?.slots.filter(s=>s.status==='available').length ?? 0,fullSlots:availability?.slots.filter(s=>s.status==='full').length ?? 0};
});
export const registerDevice=callable(async r=>{
  const a=actor(r),token=textValue(r.data?.token,30,4096,'notification token'), ref=db.doc(`users/${a.uid}/devices/${tokenHash(token)}`);
  await db.runTransaction(async tx=>{
    const devices=await tx.get(db.collection(`users/${a.uid}/devices`).orderBy('updatedAt','asc'));
    if(!devices.docs.some(d=>d.id===ref.id) && devices.size>=10)tx.delete(devices.docs[0].ref);
    tx.set(ref,{token,updatedAt:FieldValue.serverTimestamp()});
  });return {registered:true};
});
export const unregisterDevice=callable(async r=>{
  const a=actor(r),token=textValue(r.data?.token,30,4096,'notification token'); await db.doc(`users/${a.uid}/devices/${tokenHash(token)}`).delete(); return {removed:true};
});
export const sendBookingConfirmation=onDocumentWritten('bookings/{bookingId}',async e=>{
  const after=e.data?.after.data(),before=e.data?.before.data();
  if(after && ['confirmed','cancelled'].includes(after.status) && before?.status!==after.status)
    await queueNotice(db,e.params.bookingId,after.status,after);
});
export const sendPushNotification=onDocumentCreated('notifications/{id}',e=>deliverNotice(db,e.params.id));
export const bookingReminderScheduler=onSchedule('every 1 minutes',()=>reminders(db));
export const cleanupExpiredHolds=onSchedule('every 1 minutes',async()=>{await service.cleanupExpiredHolds();});
