import {getAuth} from 'firebase-admin/auth';
import {randomBytes, scryptSync, timingSafeEqual} from 'node:crypto';
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
async function actor(r: CallableRequest, role = 'visitor'): Promise<Actor> {
  if(!r.auth)throw new HttpsError('unauthenticated','Please sign in.');
  const a: Actor={uid:r.auth.uid,phone:String(r.auth.token.phone_number || ''),admin:r.auth.token.admin===true,gate:r.auth.token.gate===true};
  const staff=await db.doc(`khadims/${a.uid}`).get();
  if(staff.exists){
    const d=staff.data()!;
    if(!d.enabled || r.auth.token.khadimVersion!==d.version)throw new HttpsError('permission-denied','Access changed. Please sign in again.');
    a.phone=d.phone; a.permissions=d.permissions; a.admin=false; a.gate=d.permissions.includes('gate');
  }
  if(role!=='visitor' && !a.admin && !(role==='gate' && a.gate) && !a.permissions?.includes(role))
    throw new HttpsError('permission-denied','You do not have access to this area.');
  if(role==='visitor'&&!a.phone)throw new HttpsError('failed-precondition','A verified phone number is required.');
  return a;
}
const enforceAppCheck = !emulator && process.env.ENFORCE_APP_CHECK === 'true';
function callable<T>(fn:(r:CallableRequest)=>Promise<T>) {
  return onCall({enforceAppCheck},async r=>{
    try{return await fn(r);}catch(e){
      if(e instanceof HttpsError)throw e;
      if(e instanceof DomainError)throw new HttpsError(e.code,e.message,{publicMessage:e.message});
      logger.error('Operation failed',{type:e instanceof Error?e.name:'unknown'});
      throw new HttpsError('internal','We could not complete this request. Please try again.');
    }
  });
}
const id=(x:unknown)=>{const value=textValue(x,1,240,'identifier');if(!/^[\w-]+$/.test(value))throw new DomainError('invalid-argument','Invalid identifier.');return value;};
export const getAvailability=callable(async r=>service.availability(validDate(r.data?.visitDate)));
export const getActiveHold=callable(async r=>{
  const a=await actor(r),now=Date.now(); const current=await db.doc(`activeUserHolds/${a.uid}`).get();
  if(!current.exists || current.data()!.expiresAt<=now)return {hold:null};
  const h=await db.doc(`slotHolds/${current.data()!.holdId}`).get();
  if (!h.exists || h.data()!.status!=='active' || h.data()!.expiresAt<=now) return {hold:null};
  const d=h.data()!; return {hold:{holdId:h.id,slotId:d.slotId,visitDate:d.visitDate,startTime:d.startTime,endTime:d.endTime,visitorCount:d.visitorCount,expiresAt:d.expiresAt,serverNow:now}};
});
export const createHold=callable(async r=>service.createHold(await actor(r),r.data));
export const releaseHold=callable(async r=>service.releaseHold(await actor(r),id(r.data?.holdId)));
export const createBooking=callable(async r=>service.createBooking(await actor(r),id(r.data?.holdId),r.data?.visitorName,r.data?.visitorAddress));
export const ensureBookingTokens=callable(async r=>service.ensureBookingTokens(await actor(r),id(r.data?.bookingId)));
export const cancelBooking=callable(async r=>service.cancelBooking(await actor(r),id(r.data?.bookingId),r.data?.reason));
export const validatePass=callable(async r=>service.validatePass(await actor(r,'gate'),r.data?.qrToken,r.data?.checkIn===true));
export const adminUpdateSlot=callable(async r=>service.adminUpdateSlots(await actor(r,'slots'),r.data));
export const adminSetDateHours=callable(async r=>service.adminSetDateHours(await actor(r,'slots'),r.data));
export const adminUpdateSettings=callable(async r=>service.adminUpdateSettings(await actor(r,'settings'),r.data));
export const adminSetBookingStatus=callable(async r=>{
  const a=await actor(r,'bookings'), bookingId=id(r.data?.bookingId), status=r.data?.status;
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
  await actor(r,'dashboard'); const today=dateKey(Date.now());
  const day=db.collection('bookings').where('visitDate','==',today), all=db.collection('bookings');
  const [bookings,visitors,upcoming,cancelled,availability]=await Promise.all([
    day.count().get(),day.where('status','in',['confirmed','completed']).aggregate({visitors:AggregateField.sum('visitorCount')}).get(),
    all.where('status','==','confirmed').where('startAt','>',Date.now()).count().get(),day.where('status','==','cancelled').count().get(),
    service.availability(today).catch(()=>null)]);
  return {bookingsToday:bookings.data().count,visitorsToday:visitors.data().visitors,upcoming:upcoming.data().count,cancelled:cancelled.data().count,
    availableSlots:availability?.slots.filter(s=>s.status==='available').length ?? 0,fullSlots:availability?.slots.filter(s=>s.status==='full').length ?? 0};
});
export const registerDevice=callable(async r=>{
  const a=await actor(r),token=textValue(r.data?.token,30,4096,'notification token'), ref=db.doc(`users/${a.uid}/devices/${tokenHash(token)}`);
  await db.runTransaction(async tx=>{
    const devices=await tx.get(db.collection(`users/${a.uid}/devices`).orderBy('updatedAt','asc'));
    if(!devices.docs.some(d=>d.id===ref.id) && devices.size>=10)tx.delete(devices.docs[0].ref);
    tx.set(ref,{token,updatedAt:FieldValue.serverTimestamp()});
  });return {registered:true};
});
export const unregisterDevice=callable(async r=>{
  const a=await actor(r),token=textValue(r.data?.token,30,4096,'notification token'); await db.doc(`users/${a.uid}/devices/${tokenHash(token)}`).delete(); return {removed:true};
});
export const sendBookingConfirmation=onDocumentWritten('bookings/{bookingId}',async e=>{
  const after=e.data?.after.data(),before=e.data?.before.data();
  if(after && ['confirmed','cancelled'].includes(after.status) && before?.status!==after.status)
    await queueNotice(db,e.params.bookingId,after.status,after);
});
export const sendPushNotification=onDocumentCreated('notifications/{id}',e=>deliverNotice(db,e.params.id));
export const bookingReminderScheduler=onSchedule('every 1 minutes',()=>reminders(db));
export const cleanupExpiredHolds=onSchedule('every 1 minutes',async()=>{await service.cleanupExpiredHolds();});

export {submitContact} from "./contact.js";

const khadimPermissions=['dashboard','bookings','slots','settings','gate'];
function staffPhone(value: unknown): string {
  let phone=String(value ?? '').replace(/[\s()-]/g,'');
  if(/^\d{10}$/.test(phone))phone='+91'+phone;
  if(!/^\+[1-9]\d{6,14}$/.test(phone))throw new HttpsError('invalid-argument','Enter a phone number with country code.');
  return phone;
}
export const adminSaveKhadim=callable(async r=>{
  const admin=await actor(r,'admin');
  const uid=r.data?.uid ? id(r.data.uid) : 'khadim_'+randomBytes(16).toString('hex');
  const name=textValue(r.data?.name,1,100,'name'),phone=staffPhone(r.data?.phone);
  const permissions=r.data?.permissions;
  if(!Array.isArray(permissions)||permissions.some(v=>!khadimPermissions.includes(v)))throw new HttpsError('invalid-argument','Choose valid permissions.');
  const password=String(r.data?.password ?? '');
  if(password && !/^\d{6}$/.test(password))throw new HttpsError('invalid-argument','Password must contain exactly six digits.');
  const salt=randomBytes(16).toString('hex');
  const credentials=password?{salt,hash:scryptSync(password,salt,32).toString('hex')}:null;
  await db.runTransaction(async tx=>{
    const ref=db.doc(`khadims/${uid}`),old=await tx.get(ref);
    const phoneRef=db.doc(`khadimPhones/${phone}`),existing=await tx.get(phoneRef);
    if(r.data?.uid && !old.exists)throw new HttpsError('not-found','Khadim not found.');
    if(!old.exists&&!credentials)throw new HttpsError('invalid-argument','A six-digit password is required.');
    if(existing.exists && existing.data()!.uid!==uid)throw new HttpsError('already-exists','This phone number already has a Khadim account.');
    if(old.exists && old.data()!.phone!==phone)tx.delete(db.doc(`khadimPhones/${old.data()!.phone}`));
    tx.set(phoneRef,{uid});
    tx.set(ref,{name,phone,permissions:[...new Set(permissions)],enabled:r.data?.enabled!==false,version:(old.data()?.version ?? 0)+1,updatedAt:FieldValue.serverTimestamp()});
    if(credentials)tx.set(db.doc(`khadimSecrets/${uid}`),credentials);
    tx.create(db.collection('auditLog').doc(),{actor:admin.uid,action:'saveKhadim',target:uid,at:FieldValue.serverTimestamp()});
  });
  return {uid};
});
export const khadimLogin=callable(async r=>{
  const phone=staffPhone(r.data?.phone),password=String(r.data?.password ?? '');
  const denied=()=>new HttpsError('unauthenticated','Invalid phone number or password.');
  if(!/^\d{6}$/.test(password))throw denied();
  // Both source IP and phone limits apply before the expensive password check.
  const keys=['phone:'+phone,'ip:'+String(r.rawRequest.ip ?? 'unknown')];
  await db.runTransaction(async tx=>{
    const refs=keys.map(k=>db.doc(`khadimLoginLimits/${tokenHash(k)}`));
    const snaps=await Promise.all(refs.map(ref=>tx.get(ref)));
    const now=Date.now();
    for(let i=0;i<refs.length;i++){
      const d=snaps[i].data(),active=d && d.until>now;
      if(active && d.count >= (i===0?5:30))throw new HttpsError('resource-exhausted','Too many attempts. Try again in 15 minutes.');
      tx.set(refs[i],{count:active?d.count+1:1,until:active?d.until:now+15*60*1000});
    }
  });
  const lookup=await db.doc(`khadimPhones/${phone}`).get();
  const uid=lookup.data()?.uid;
  if(!uid)throw denied();
  const [profile,secret]=await Promise.all([db.doc(`khadims/${uid}`).get(),db.doc(`khadimSecrets/${uid}`).get()]);
  const d=profile.data(),c=secret.data();
  if(!d?.enabled||!c||!timingSafeEqual(scryptSync(password,c.salt,32),Buffer.from(c.hash,'hex')))throw denied();
  const token=await getAuth().createCustomToken(uid,{khadimVersion:d.version});
  return {token};
});
