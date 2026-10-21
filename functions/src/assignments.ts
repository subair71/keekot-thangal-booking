import {Firestore, FieldValue} from 'firebase-admin/firestore';
import {noticeData} from './notifications.js';
import {DomainError, validDate} from './domain.js';

export type Window = {start: string; end: string};
export type Schedule = {hours: Window[]; breaks: Window[]; unavailable: Window[]; available: boolean; capacity: number};
export type Visit = {startAt: number; endAt: number; status: string; checkedInAt?: unknown; assignment?: {khadimId?: string; status?: string}};
const fail=(message:string):never=>{throw new DomainError('failed-precondition',message);};
export function minutes(value: string): number {
  if(!/^([01]\d|2[0-3]):[0-5]\d$/.test(value))throw new DomainError('invalid-argument','Use HH:mm time.');
  const [h,m]=value.split(':').map(Number);return h*60+m;
}
export function scheduleInput(data: any): Schedule {
  const ranges=(value:unknown):Window[]=>{
    if(!Array.isArray(value)||value.length>24)throw new DomainError('invalid-argument','Provide up to 24 time ranges.');
    return value.map(w=>{if(!w||typeof w.start!=='string'||typeof w.end!=='string'||minutes(w.start)>=minutes(w.end))throw new DomainError('invalid-argument','A range must end after it starts.');return {start:w.start,end:w.end};});
  };
  const capacity=data.capacity ?? 1;
  if(!Number.isInteger(capacity)||capacity<1||capacity>50)throw new DomainError('invalid-argument','Capacity must be 1–50.');
  return {hours:ranges(data.hours),breaks:ranges(data.breaks ?? []),unavailable:ranges(data.unavailable ?? []),available:data.available!==false,capacity};
}
export function eligibility(schedule: Schedule|undefined, visit: Visit, others: Visit[], day: string) {
  const active=others.filter(b=>(b.status==='confirmed'||(b.status==='completed'&&b.checkedInAt)) && ['assigned','inProgress'].includes(b.assignment?.status ?? '') && b.startAt<visit.endAt && b.endAt>visit.startAt);
  // Maximum simultaneous workload, not the total number of visits in the interval.
  const events=active.flatMap(b=>[[Math.max(b.startAt,visit.startAt),1],[Math.min(b.endAt,visit.endAt),-1]]);
  events.sort((a,b)=>a[0]-b[0]||a[1]-b[1]);let count=0,workload=0;
  for(const [,delta] of events){count+=delta;workload=Math.max(workload,count);}
  const result=(reason:string,state:string)=>({eligible:!reason,reason,state,workload,capacity:schedule?.capacity ?? 1});
  if(!schedule)return result('No working schedule configured','Off duty');
  const epoch=(time:string)=>Date.parse(`${day}T${time}:00+05:30`);
  if(!schedule.hours.some(w=>epoch(w.start)<=visit.startAt&&epoch(w.end)>=visit.endAt))return result('Outside working hours','Off duty');
  if(!schedule.available)return result('Marked unavailable','Unavailable');
  if([...schedule.breaks,...schedule.unavailable].some(w=>epoch(w.start)<visit.endAt&&epoch(w.end)>visit.startAt))return result('Break or unavailable period','Unavailable');
  if(workload>=schedule.capacity)return result('Capacity is full','Busy');
  return result('','Available');
}

export class AssignmentService {
  constructor(private db:Firestore){}
  async candidates(bookingId:string) {
    const b=await this.db.doc(`bookings/${bookingId}`).get();if(!b.exists)fail('Booking not found.');
    const visit=b.data()!;
    const [staff,bookings]=await Promise.all([this.db.collection('khadims').get(),this.db.collection('bookings').where('visitDate','==',visit.visitDate).get()]);
    return {candidates:await Promise.all(staff.docs.map(async k=>{
      const schedule=await this.db.doc(`khadimSchedules/${k.id}_${visit.visitDate}`).get();
      const others=bookings.docs.filter(d=>d.id!==bookingId&&d.data().assignment?.khadimId===k.id).map(d=>d.data() as Visit);
      const check=eligibility(schedule.data() as Schedule|undefined,visit as Visit,others,visit.visitDate);
      return {uid:k.id,name:k.data().name,...check,...(!k.data().enabled?{eligible:false,reason:'Account disabled',state:'Unavailable'}:{})};
    }))};
  }
  async change(actor:string, bookingId:string, khadimId:string|null, reason:string, expectedRevision:number) {
    return this.db.runTransaction(async tx=>{
      const lock=this.db.doc('assignmentLocks/global');await tx.get(lock);
      const ref=this.db.doc(`bookings/${bookingId}`),snap=await tx.get(ref);
      if(!snap.exists)fail('Booking not found.');const b=snap.data()!,old=b.assignment;
      if((old?.revision ?? 0)!==expectedRevision)fail('Assignment changed. Refresh and try again.');
      if(b.status!=='confirmed'&&!(b.status==='completed'&&b.checkedInAt))fail('Only active bookings can be assigned.');
      if(old?.status==='completed')fail('A completed visit cannot be reassigned.');
      if(old?.khadimId===(khadimId ?? undefined)&&!old?.conflict&&old?.scheduledStart===b.startAt&&old?.scheduledEnd===b.endAt)return {updated:false};
      if(old?.khadimId && reason.trim().length<3)fail('A reason is required for reassignment or removal.');
      let name:string|null=null;
      if(khadimId){
        const staff=await tx.get(this.db.doc(`khadims/${khadimId}`));
        if(!staff.exists||!staff.data()!.enabled)fail('Khadim account is unavailable.');
        const schedule=await tx.get(this.db.doc(`khadimSchedules/${khadimId}_${b.visitDate}`));
        const bookings=await tx.get(this.db.collection('bookings').where('visitDate','==',b.visitDate));
        const others=bookings.docs.filter(d=>d.id!==bookingId&&d.data().assignment?.khadimId===khadimId).map(d=>d.data() as Visit);
        const check=eligibility(schedule.data() as Schedule|undefined,b as Visit,others,b.visitDate);
        if(!check.eligible)fail(check.reason);name=staff.data()!.name;
      }
      const assignment={khadimId,displayName:name,status:khadimId?'assigned':'unassigned',revision:expectedRevision+1,conflict:false,scheduledStart:b.startAt,scheduledEnd:b.endAt};
      tx.update(ref,{assignment,updatedAt:FieldValue.serverTimestamp()});
      tx.set(this.db.doc(`notifications/${bookingId}_assignment_${assignment.revision}`),{...noticeData(bookingId,'assignment',b),title:'Visit assignment updated',body:khadimId?`Your assigned khadim is ${name}.`:'Khadim assignment pending.'});
      tx.set(lock,{version:FieldValue.increment(1)});
      tx.create(this.db.collection('assignmentHistory').doc(),{bookingId,actor,action:khadimId?(old?.khadimId?'reassigned':'assigned'):'removed',before:old ?? null,after:assignment,reason:reason.trim().slice(0,500),at:FieldValue.serverTimestamp()});
      return {updated:true};
    });
  }
  async saveSchedule(actor:string,uid:string,day:string,data:any,self=false){
    validDate(day);
    return this.db.runTransaction(async tx=>{
      const lock=this.db.doc('assignmentLocks/global');await tx.get(lock);
      const ref=this.db.doc(`khadimSchedules/${uid}_${day}`),old=await tx.get(ref);
      const staff=await tx.get(this.db.doc(`khadims/${uid}`));if(!staff.exists||!staff.data()!.enabled)fail('Khadim account is unavailable.');
      if(self&&!old.exists)fail('Ask an administrator to configure your schedule first.');
      if(self&&typeof data.available!=='boolean')fail('Choose available or unavailable.');
      const schedule=self?{...old.data()!,available:data.available} as Schedule:scheduleInput(data);
      const bookings=await tx.get(this.db.collection('bookings').where('visitDate','==',day));
      const active=bookings.docs.filter(d=>d.data().assignment?.khadimId===uid&&(d.data().status==='confirmed'||(d.data().status==='completed'&&d.data().checkedInAt))&&['assigned','inProgress'].includes(d.data().assignment.status));
      const conflicts=active.filter(d=>!eligibility(schedule,d.data() as Visit,active.filter(o=>o.id!==d.id).map(o=>o.data() as Visit),day).eligible).map(d=>d.id);
      if(conflicts.length&&!data.acknowledgeConflicts)fail(`${conflicts.length} assigned visit(s) would be affected. Confirm the warning to save.`);
      for(const b of active)tx.update(b.ref,{'assignment.conflict':conflicts.includes(b.id)});
      tx.set(ref,{...schedule,khadimId:uid,visitDate:day,updatedBy:actor,updatedAt:FieldValue.serverTimestamp()});
      tx.set(lock,{version:FieldValue.increment(1)});
      tx.create(this.db.collection('assignmentHistory').doc(),{actor,action:'scheduleUpdated',khadimId:uid,visitDate:day,conflicts,at:FieldValue.serverTimestamp()});
      return {updated:true,conflicts};
    });
  }
  async reconcile(bookingId:string){
    await this.db.runTransaction(async tx=>{
      const lock=this.db.doc('assignmentLocks/global');await tx.get(lock);
      const ref=this.db.doc(`bookings/${bookingId}`),snapshot=await tx.get(ref),b=snapshot.data(),a=b?.assignment;
      if(!b||!a?.khadimId)return;
      if(b.status==='cancelled'&&a.status!=='cancelled'){
        tx.update(ref,{'assignment.status':'cancelled','assignment.revision':FieldValue.increment(1)});
        tx.set(lock,{version:FieldValue.increment(1)});
        tx.create(this.db.collection('assignmentHistory').doc(),{bookingId,actor:'system',action:'bookingCancelled',at:FieldValue.serverTimestamp()});return;
      }
      if(a.scheduledStart===b.startAt&&a.scheduledEnd===b.endAt)return;
      if(a.conflict||!['assigned','inProgress'].includes(a.status))return;
      const schedule=await tx.get(this.db.doc(`khadimSchedules/${a.khadimId}_${b.visitDate}`));
      const staff=await tx.get(this.db.doc(`khadims/${a.khadimId}`));
      const bookings=await tx.get(this.db.collection('bookings').where('visitDate','==',b.visitDate));
      const others=bookings.docs.filter(d=>d.id!==bookingId&&d.data().assignment?.khadimId===a.khadimId).map(d=>d.data() as Visit);
      const check=eligibility(schedule.data() as Schedule|undefined,b as Visit,others,b.visitDate);
      const conflict=!check.eligible||!staff.data()?.enabled;
      tx.update(ref,{'assignment.conflict':conflict,'assignment.revision':FieldValue.increment(1),...(!conflict?{'assignment.scheduledStart':b.startAt,'assignment.scheduledEnd':b.endAt}:{})});
      tx.set(lock,{version:FieldValue.increment(1)});
      tx.create(this.db.collection('assignmentHistory').doc(),{bookingId,actor:'system',action:conflict?'visitTimeConflict':'visitTimeRevalidated',at:FieldValue.serverTimestamp()});
    });
  }
  async transition(actor:string,bookingId:string,status:string){
    return this.db.runTransaction(async tx=>{
      const lock=this.db.doc('assignmentLocks/global');await tx.get(lock);
      const ref=this.db.doc(`bookings/${bookingId}`),snap=await tx.get(ref);const b=snap.data();
      if(!b||b.assignment?.khadimId!==actor)throw new DomainError('permission-denied','This visit is not assigned to you.');
      if(b.status==='cancelled'||(status==='inProgress'&&b.status!=='confirmed'&&!(b.status==='completed'&&b.checkedInAt)))fail('Booking is no longer active.');
      if(b.assignment.status===status)return {updated:false};
      if(!((b.assignment.status==='assigned'&&status==='inProgress')||(b.assignment.status==='inProgress'&&status==='completed')))fail('Invalid visit status transition.');
      if(b.assignment.scheduledStart!==b.startAt||b.assignment.scheduledEnd!==b.endAt)fail('Visit time changed. Ask an administrator to review.');
      if(b.assignment.conflict)fail('Ask an administrator to resolve the assignment conflict.');
      if(status==='inProgress'&&(Date.now()<b.startAt||Date.now()>=b.endAt))fail('Start the visit within its scheduled time.');
      tx.update(ref,{'assignment.status':status,'assignment.revision':FieldValue.increment(1),updatedAt:FieldValue.serverTimestamp()});
      tx.set(this.db.doc(`notifications/${bookingId}_assignment_${b.assignment.revision+1}`),{...noticeData(bookingId,'assignment',b),title:'Visit status updated',body:status==='completed'?'Your visit is completed.':'Your visit is in progress.'});
      tx.set(lock,{version:FieldValue.increment(1)});
      tx.create(this.db.collection('assignmentHistory').doc(),{actor,bookingId,action:status,at:FieldValue.serverTimestamp()});return {updated:true};
    });
  }
}
