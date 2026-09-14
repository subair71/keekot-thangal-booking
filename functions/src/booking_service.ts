import {Firestore, FieldValue, Timestamp} from 'firebase-admin/firestore';
import {activeHolds, addDays, BookingSettings, dateKey, DomainError, generateSlots, HoldMap, integer, makeToken, maskPhone, publicSlot, referenceFor, requireCapacity, settingsFrom, Slot, textValue, tokenHash, validDate, validateDay} from './domain.js';

export interface Actor {uid: string; phone: string; admin?: boolean; gate?: boolean}
export class BookingService {
  constructor(readonly db: Firestore, readonly clock = () => Date.now()) {}
  async availability(day: string) {
    validDate(day); const now = this.clock();
    const c = settingsFrom((await this.db.doc('settings/booking').get()).data());
    validateDay(day, c, now);
    const [slots, states, closure] = await Promise.all([
      this.db.collection('visitSlots').where('visitDate', '==', day).get(),
      this.db.collection('slotState').where('visitDate', '==', day).get(), this.db.doc(`closures/${day}`).get()]);
    const byId = new Map(slots.docs.map(d => [d.id, d.data() as Slot]));
    const state = new Map(states.docs.map(d => [d.id, (d.data().holds || {}) as HoldMap]));
    return {serverNow: now, closed: closure.data()?.closed === true, reason: closure.data()?.reason || '',
      slots: generateSlots(day, c).map(s => publicSlot(byId.get(s.slotId) || s, state.get(s.slotId) || {}, now, closure.data()))};
  }
  async createHold(actor: Actor, input: {visitDate: string; slotId: string; visitorCount: number; requestId: string}) {
    validDate(input.visitDate); const holdId = textValue(input.requestId, 20, 100, 'request ID');
    if (!/^[\w-]+$/.test(holdId)) throw new DomainError('invalid-argument', 'Invalid request ID.');
    const holdRef = this.db.doc(`slotHolds/${actor.uid}_${holdId}`), uidRef = this.db.doc(`activeUserHolds/${actor.uid}`);
    return this.db.runTransaction(async tx => {
      const now = this.clock();
      const [config, existing, uidHold] = await tx.getAll(this.db.doc('settings/booking'), holdRef, uidRef);
      const c = settingsFrom(config.data()); validateDay(input.visitDate, c, now);
      integer(input.visitorCount, 1, c.maxVisitorsPerBooking, 'Visitor count');
      if (existing.exists && existing.data()?.status === 'active' && existing.data()!.expiresAt > now) {
        const h=existing.data()!;
        if (h.slotId !== input.slotId || h.visitorCount !== input.visitorCount) throw new DomainError('failed-precondition', 'Request already used for another selection.');
        return {...h, holdId: holdRef.id, serverNow: now};
      }
      if (existing.exists) throw new DomainError('failed-precondition', 'This hold has expired. Select your slot again.');
      if (uidHold.exists && uidHold.data()!.expiresAt > now) throw new DomainError('failed-precondition', 'You already have a held slot. Continue or release it first.');
      const base = generateSlots(input.visitDate, c).find(s => s.slotId === input.slotId);
      if (!base) throw new DomainError('invalid-argument', 'Choose a valid slot.');
      const slotRef = this.db.doc(`visitSlots/${base.slotId}`), stateRef = this.db.doc(`slotState/${base.slotId}`);
      const [slotDoc, stateDoc, closure] = await tx.getAll(slotRef, stateRef, this.db.doc(`closures/${input.visitDate}`));
      if (closure.data()?.closed) throw new DomainError('failed-precondition', 'This day is closed for visits.');
      const slot = slotDoc.exists ? slotDoc.data() as Slot : base;
      const holds = activeHolds(stateDoc.data()?.holds || {}, now);
      requireCapacity(slot, holds, input.visitorCount, now);
      const expiresAt = now + 5*60_000;
      holds[holdRef.id] = {userId: actor.uid, visitorCount: input.visitorCount, expiresAt};
      const hold = {holdId: holdRef.id, userId: actor.uid, slotId: slot.slotId, visitDate: input.visitDate,
        visitorCount: input.visitorCount, expiresAt, status: 'active', startTime: slot.startTime, endTime: slot.endTime};
      tx.set(slotRef, slot);
      tx.set(stateRef, {visitDate: input.visitDate, holds});
      tx.create(holdRef, {...hold, createdAt: FieldValue.serverTimestamp(), purgeAt: Timestamp.fromMillis(expiresAt + 86_400_000)});
      tx.set(uidRef, {holdId: holdRef.id, expiresAt});
      if (!c.scheduleLockedUntil || c.scheduleLockedUntil < input.visitDate) tx.update(config.ref, {scheduleLockedUntil: input.visitDate});
      return {...hold, serverNow: now};
    });
  }
  async releaseHold(actor: Actor, holdId: string) {
    const ref = this.db.doc(`slotHolds/${textValue(holdId, 1, 240, 'hold ID')}`);
    await this.db.runTransaction(async tx => {
      const h=await tx.get(ref); if (!h.exists) return;
      const d=h.data()!; if (d.userId !== actor.uid) throw new DomainError('permission-denied', 'This hold belongs to another visitor.');
      if(d.status !== 'active') return;
      const sr=this.db.doc(`slotState/${d.slotId}`), ur=this.db.doc(`activeUserHolds/${actor.uid}`);
      const [state, user]=await tx.getAll(sr,ur);
      const holds=activeHolds(state.data()?.holds || {},this.clock()); delete holds[holdId];
      tx.set(sr,{visitDate:d.visitDate,holds}); tx.update(ref,{status:'released'});
      if(user.data()?.holdId===holdId)tx.delete(ur);
    }); return {released:true};
  }
  async createBooking(actor: Actor, holdId: string, visitorName: string) {
    textValue(holdId,1,240,'hold ID'); visitorName=textValue(visitorName,2,100,'visitor name');
    const holdRef=this.db.doc(`slotHolds/${holdId}`), bookingRef=this.db.collection('bookings').doc();
    const qrToken=makeToken();
    return this.db.runTransaction(async tx=>{
      const now=this.clock();
      const [h, config]=await tx.getAll(holdRef,this.db.doc('settings/booking'));
      if(!h.exists || h.data()!.userId!==actor.uid) throw new DomainError('not-found','Your hold was not found.');
      const hold=h.data()!;
      if(hold.status==='converted') return {bookingId:hold.bookingId}; // Lost response retries cannot consume twice.
      if(hold.status!=='active' || hold.expiresAt<=now) throw new DomainError('failed-precondition','Your hold has expired. Please choose your slot again.');
      const c=settingsFrom(config.data()); validateDay(hold.visitDate,c,now);
      integer(hold.visitorCount,1,c.maxVisitorsPerBooking,'Visitor count');
      const slotRef=this.db.doc(`visitSlots/${hold.slotId}`), stateRef=this.db.doc(`slotState/${hold.slotId}`), userRef=this.db.doc(`activeUserHolds/${actor.uid}`);
      const [s,state,closure,user]=await tx.getAll(slotRef,stateRef,this.db.doc(`closures/${hold.visitDate}`),userRef);
      if(!s.exists || closure.data()?.closed) throw new DomainError('failed-precondition','This slot is currently closed.');
      const slot=s.data() as Slot, holds=activeHolds(state.data()?.holds || {},now);
      if(!holds[holdId]) throw new DomainError('failed-precondition','Your hold has expired.');
      delete holds[holdId]; requireCapacity(slot,holds,hold.visitorCount,now);
      const bookingReference=referenceFor(hold.visitDate);
      const booking={bookingId:bookingRef.id,bookingReference,userId:actor.uid,visitorName,phoneNumberMasked:maskPhone(actor.phone),
        visitDate:slot.visitDate,slotId:slot.slotId,startTime:slot.startTime,endTime:slot.endTime,startAt:slot.startAt,endAt:slot.endAt,
        timezone:c.timezone,visitorCount:hold.visitorCount,status:'confirmed',qrToken,qrTokenHash:tokenHash(qrToken),
        reminderAt:slot.startAt-c.reminderMinutes*60_000,reminderQueued:false,createdAt:FieldValue.serverTimestamp(),updatedAt:FieldValue.serverTimestamp()};
      tx.create(bookingRef,booking);
      tx.create(this.db.doc(`passTokens/${tokenHash(qrToken)}`),{bookingId:bookingRef.id});
      tx.update(slotRef,{occupancy:slot.occupancy+hold.visitorCount});
      tx.set(stateRef,{visitDate:slot.visitDate,holds});
      tx.update(holdRef,{status:'converted',bookingId:bookingRef.id});
      if(user.data()?.holdId===holdId)tx.delete(userRef);
      return {bookingId:bookingRef.id};
    });
  }
  async cancelBooking(actor: Actor, bookingId: string, reason: string) {
    textValue(bookingId,1,100,'booking ID'); reason=textValue(reason || 'Changed plans',1,200,'reason');
    return this.db.runTransaction(async tx=>{
      const ref=this.db.doc(`bookings/${bookingId}`), booking=await tx.get(ref);
      if(!booking.exists)throw new DomainError('not-found','Booking not found.');
      const b=booking.data()!;
      if(b.userId!==actor.uid && !actor.admin)throw new DomainError('permission-denied','You cannot cancel this booking.');
      if(b.status==='cancelled')return {cancelled:true};
      if(b.status!=='confirmed' || (!actor.admin && b.startAt<=this.clock()))throw new DomainError('failed-precondition','This booking is no longer eligible for cancellation.');
      const sr=this.db.doc(`visitSlots/${b.slotId}`), slot=await tx.get(sr);
      if(!slot.exists || slot.data()!.occupancy<b.visitorCount)throw new DomainError('failed-precondition','Capacity needs administrator review.');
      tx.update(sr,{occupancy:slot.data()!.occupancy-b.visitorCount});
      tx.update(ref,{status:'cancelled',cancelledAt:FieldValue.serverTimestamp(),cancellationReason:reason,updatedAt:FieldValue.serverTimestamp()});
      if(actor.admin)tx.create(this.db.collection('auditLog').doc(),{actor:actor.uid,action:'cancelBooking',bookingId,at:FieldValue.serverTimestamp()});
      return {cancelled:true};
    });
  }
  async validatePass(actor: Actor, qrToken: string, checkIn: boolean) {
    if(!actor.admin && !actor.gate)throw new DomainError('permission-denied','Entry staff access is required.');
    if(typeof qrToken!=='string' || !/^[A-Za-z0-9_-]{43}$/.test(qrToken))return {valid:false};
    return this.db.runTransaction(async tx=>{
      const p=await tx.get(this.db.doc(`passTokens/${tokenHash(qrToken)}`)); if(!p.exists)return {valid:false};
      const [booking,config]=await tx.getAll(this.db.doc(`bookings/${p.data()!.bookingId}`),this.db.doc('settings/booking'));
      if(!booking.exists)return {valid:false};
      const b=booking.data()!, c=settingsFrom(config.data()), now=this.clock();
      const valid=b.status==='confirmed' && now>=b.startAt-c.arrivalMinutes*60_000 && now<b.endAt;
      if(valid && checkIn){
        tx.update(booking.ref,{status:'completed',checkedInAt:FieldValue.serverTimestamp(),updatedAt:FieldValue.serverTimestamp()});
        tx.create(this.db.collection('auditLog').doc(),{actor:actor.uid,action:'checkIn',bookingId:booking.id,at:FieldValue.serverTimestamp()});
      }
      return {valid,bookingReference:b.bookingReference,visitDate:b.visitDate,timeSlot:`${b.startTime}–${b.endTime}`,visitorCount:b.visitorCount,status:valid && checkIn?'completed':b.status};
    });
  }
  async cleanupExpiredHolds() {
    const now=this.clock(); const expired=await this.db.collection('slotHolds').where('status','==','active').where('expiresAt','<=',now).limit(400).get();
    for(const h of expired.docs) await this.db.runTransaction(async tx=>{
      const fresh=await tx.get(h.ref); const d=fresh.data(); if(!d || d.status!=='active' || d.expiresAt>this.clock())return;
      const sr=this.db.doc(`slotState/${d.slotId}`), ur=this.db.doc(`activeUserHolds/${d.userId}`);
      const [s,u]=await tx.getAll(sr,ur);
      tx.set(sr,{visitDate:d.visitDate,holds:activeHolds(s.data()?.holds || {},this.clock())}); tx.update(h.ref,{status:'expired'});
      if(u.data()?.holdId===h.id)tx.delete(ur);
    }); return expired.size;
  }
  async adminUpdateSlots(actor: Actor, input: {visitDate: string; startTime?: string; endTime?: string; blocked: boolean; reason: string; capacity?: number; wholeDay?: boolean}) {
    if(!actor.admin)throw new DomainError('permission-denied','Administrator access is required.');
    validDate(input.visitDate); const reason=textValue(input.reason || 'Administrative closure',1,200,'block reason');
    if(typeof input.blocked!=='boolean')throw new DomainError('invalid-argument','Choose open or blocked.');
    return this.db.runTransaction(async tx=>{
      const config=await tx.get(this.db.doc('settings/booking')), c=settingsFrom(config.data()), now=this.clock();
      if(input.visitDate<dateKey(now) || input.visitDate>addDays(dateKey(now),30))throw new DomainError('invalid-argument','Choose a date within 30 days.');
      const all=generateSlots(input.visitDate,c);
      const selected=input.wholeDay?all:all.filter(s=>s.startTime>=String(input.startTime) && s.endTime<=String(input.endTime));
      if(!selected.length)throw new DomainError('invalid-argument','Select at least one whole slot.');
      if(input.capacity!==undefined)integer(input.capacity,1,500,'Capacity');
      const refs=selected.flatMap(s=>[this.db.doc(`visitSlots/${s.slotId}`),this.db.doc(`slotState/${s.slotId}`)]);
      const docs=await tx.getAll(...refs);
      selected.forEach((base,i)=>{
        const s=docs[i*2].exists?docs[i*2].data() as Slot:base;
        const holds=activeHolds(docs[i*2+1].data()?.holds || {},now);
        if(input.capacity!==undefined && input.capacity<s.occupancy+Object.values(holds).reduce((n,h)=>n+h.visitorCount,0))throw new DomainError('failed-precondition','Capacity cannot be lower than booked and held visitors.');
        tx.set(refs[i*2],{...s,blocked:input.blocked,blockReason:input.blocked?reason:'',capacity:input.capacity ?? s.capacity});
      });
      if(input.wholeDay)tx.set(this.db.doc(`closures/${input.visitDate}`),{visitDate:input.visitDate,closed:input.blocked,reason:input.blocked?reason:''});
      tx.update(config.ref,{scheduleLockedUntil:c.scheduleLockedUntil && c.scheduleLockedUntil>input.visitDate?c.scheduleLockedUntil:input.visitDate});
      tx.create(this.db.collection('auditLog').doc(),{actor:actor.uid,action:'updateSlots',visitDate:input.visitDate,slotCount:selected.length,at:FieldValue.serverTimestamp()});
      return {updated:selected.length};
    });
  }
  async adminUpdateSettings(actor: Actor, input: BookingSettings) {
    if(!actor.admin)throw new DomainError('permission-denied','Administrator access is required.');
    const c=settingsFrom(input);
    const keys: (keyof BookingSettings)[]=['timezone','openingTime','closingTime','slotDurationMinutes','bookingWindowDays','allowSameDayBooking','maxVisitorsPerBooking','defaultSlotCapacity','reminderEnabled','reminderMinutes','bookingEnabled','locationUrl','contactPhone','arrivalMinutes'];
    return this.db.runTransaction(async tx=>{
      const ref=this.db.doc('settings/booking'), prev=await tx.get(ref), p=prev.data();
      if(p && p.scheduleLockedUntil>=dateKey(this.clock()) && ['openingTime','closingTime','slotDurationMinutes','timezone'].some(k=>p[k]!==input[k as keyof BookingSettings]))
        throw new DomainError('failed-precondition',`Hours and duration are locked through ${p!.scheduleLockedUntil}. Change them after the existing schedule has elapsed.`);
      const data=Object.fromEntries(keys.map(k=>[k,c[k]]));
      tx.set(ref,{...data,environment:p?.environment || 'production',updatedAt:FieldValue.serverTimestamp()}, {merge:true});
      tx.create(this.db.collection('auditLog').doc(),{actor:actor.uid,action:'updateSettings',at:FieldValue.serverTimestamp()}); return {updated:true};
    });
  }
}
