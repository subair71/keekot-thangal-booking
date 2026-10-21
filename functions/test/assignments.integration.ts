import {test,after} from 'node:test';
import assert from 'node:assert/strict';
import {initializeApp,deleteApp} from 'firebase-admin/app';
import {getFirestore} from 'firebase-admin/firestore';
import {AssignmentService} from '../src/assignments.js';
if(!process.env.FIRESTORE_EMULATOR_HOST)throw new Error('Emulator required');
const app=initializeApp({projectId:'demo-keekot-thangal'},'assignments'),db=getFirestore(app),service=new AssignmentService(db);
const day='2030-01-12',at=(t:string)=>Date.parse(`${day}T${t}:00+05:30`);
after(async()=>{await db.terminate();await deleteApp(app);});
test('assignment lifecycle, concurrency and conflict protection',async t=>{
 const base={userId:'demo-visitor',visitorName:'DEMO Visitor',visitDate:day,startAt:at('10:00'),endAt:at('10:30'),status:'confirmed'};
 for(const uid of ['assignment-a','assignment-b'])await db.doc(`khadims/${uid}`).set({name:`DEMO ${uid}`,enabled:true});
 for(const id of ['assignment-one','assignment-two'])await db.doc(`bookings/${id}`).set(base);
 await t.test('missing schedule and out of hours are rejected',async()=>{
  await assert.rejects(()=>service.change('admin','assignment-one','assignment-a','',0));
  await service.saveSchedule('admin','assignment-a',day,{hours:[{start:'11:00',end:'12:00'}]});
  await assert.rejects(()=>service.change('admin','assignment-one','assignment-a','',0));
 });
 for(const uid of ['assignment-a','assignment-b'])await service.saveSchedule('admin',uid,day,{hours:[{start:'09:00',end:'17:00'}]});
 let winner='';
 await t.test('concurrent admins cannot reserve the same capacity',async()=>{
  const ids=['assignment-one','assignment-two'];
  const results=await Promise.allSettled(ids.map(id=>service.change('admin',id,'assignment-a','',0)));
  assert.equal(results.filter(r=>r.status==='fulfilled').length,1);winner=ids[results.findIndex(r=>r.status==='fulfilled')];
 });
 await t.test('stale retries and reasonless reassignment are rejected',async()=>{
  await assert.rejects(()=>service.change('admin',winner,'assignment-b','',0));
  await assert.rejects(()=>service.change('admin',winner,'assignment-b','',1));
 });
 await t.test('schedule conflicts require acknowledgement and remain assigned',async()=>{
  await assert.rejects(()=>service.saveSchedule('assignment-a','assignment-a',day,{available:false},true));
  const result=await service.saveSchedule('assignment-a','assignment-a',day,{available:false,acknowledgeConflicts:true},true);
  assert.deepEqual(result.conflicts,[winner]);
  const b=(await db.doc(`bookings/${winner}`).get()).data()!;
  assert.equal(b.assignment.khadimId,'assignment-a');assert.equal(b.assignment.conflict,true);
 });
 await t.test('reassignment, removal and audit history',async()=>{
  await service.change('admin',winner,'assignment-b','Cover unavailable colleague',1);
  await service.change('admin',winner,null,'Visitor requested removal',2);
  assert.equal((await db.doc(`bookings/${winner}`).get()).data()!.assignment.status,'unassigned');
  assert.equal((await db.collection('assignmentHistory').where('bookingId','==',winner).get()).size,3);
 });
 await t.test('cancelled bookings do not reserve capacity',async()=>{
  await service.change('admin',winner,'assignment-b','',3);
  await db.doc(`bookings/${winner}`).update({status:'cancelled'});
  const other=winner==='assignment-one'?'assignment-two':'assignment-one';
  await service.change('admin',other,'assignment-b','',0);
  await assert.rejects(()=>service.change('admin',winner,'assignment-b','',4));
 });
 await t.test('only assignee can start; transitions and changed times are checked',async()=>{
  const now=Date.now();
  await db.doc('bookings/assignment-live').set({...base,startAt:now-1000,endAt:now+60000,assignment:{khadimId:'assignment-b',status:'assigned',revision:1,scheduledStart:now-1000,scheduledEnd:now+60000}});
  await assert.rejects(()=>service.transition('assignment-a','assignment-live','inProgress'));
  await assert.rejects(()=>service.transition('assignment-b','assignment-live','completed'));
  await service.transition('assignment-b','assignment-live','inProgress');
  await service.transition('assignment-b','assignment-live','completed');
  await service.transition('assignment-b','assignment-live','completed');
  await assert.rejects(()=>service.transition('assignment-b','assignment-live','inProgress'));
  await db.doc('bookings/assignment-moved').set({...base,assignment:{khadimId:'assignment-b',status:'assigned',revision:1,scheduledStart:0,scheduledEnd:1}});
  await assert.rejects(()=>service.transition('assignment-b','assignment-moved','inProgress'),/Visit time changed/);
 });
 await t.test('date changes are revalidated without silently switching khadims',async()=>{
  await db.doc('bookings/assignment-reschedule').set({...base,startAt:at('15:00'),endAt:at('15:30'),assignment:{khadimId:'assignment-b',status:'assigned',revision:1,scheduledStart:at('14:00'),scheduledEnd:at('14:30')}});
  await service.reconcile('assignment-reschedule');
  let b=(await db.doc('bookings/assignment-reschedule').get()).data()!;
  assert.equal(b.assignment.conflict,false);assert.equal(b.assignment.scheduledStart,at('15:00'));
  await db.doc('bookings/assignment-reschedule').update({startAt:at('18:00'),endAt:at('18:30')});
  await service.reconcile('assignment-reschedule');b=(await db.doc('bookings/assignment-reschedule').get()).data()!;
  assert.equal(b.assignment.conflict,true);assert.equal(b.assignment.khadimId,'assignment-b');
 });

});
