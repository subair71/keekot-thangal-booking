import {test,after} from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {initializeApp,deleteApp} from 'firebase-admin/app';
import {getFirestore, Timestamp} from 'firebase-admin/firestore';
import {initializeTestEnvironment,assertFails,assertSucceeds} from '@firebase/rules-unit-testing';
import {doc,getDoc,setDoc,collection,query,where,getDocs} from 'firebase/firestore';
import {BookingService} from '../src/booking_service.js';
import {BookingSettings, generateSlots} from '../src/domain.js';
import {queueNotice} from '../src/notifications.js';

if(!process.env.FIRESTORE_EMULATOR_HOST)throw new Error('Integration tests require a Firestore emulator.');
const projectId='demo-keekot-thangal', app=initializeApp({projectId}), db=getFirestore(app);
let now=Date.parse('2030-01-10T00:00:00Z'); const service=new BookingService(db,()=>now), day='2030-01-10';
const settings:BookingSettings={timezone:'Asia/Kolkata',openingTime:'07:00',closingTime:'19:00',slotDurationMinutes:30,bookingWindowDays:7,allowSameDayBooking:true,
  maxVisitorsPerBooking:3,defaultSlotCapacity:3,bookingEnabled:true,reminderEnabled:true,reminderMinutes:60,arrivalMinutes:10,environment:'development',locationUrl:'',contactPhone:''};
const actor=(i:number)=>({uid:`test-${i}`,phone:`+9199${String(i).padStart(8,'0')}`});
const hold=(i:number,slot=0,count=1)=>service.createHold(actor(i),{visitDate:day,slotId:generateSlots(day,settings)[slot].slotId,visitorCount:count,requestId:`request-${String(i).padStart(24,'0')}-${slot}`});
after(async()=>{await db.terminate();await deleteApp(app);});
test('Firestore transactions and rules',async t=>{
  await db.doc('settings/booking').set(settings);
  await t.test('date hours enforce availability, holds, reset and booking protection',async()=>{
    const date='2030-01-16', admin={...actor(800),admin:true};
    await assert.rejects(()=>service.adminSetDateHours(actor(801),{visitDate:date,openingTime:'08:00',closingTime:'17:00'}));
    await service.adminSetDateHours(admin,{visitDate:date,openingTime:'08:00',closingTime:'17:00'});
    const available=await service.availability(date);
    assert.equal(available.slots.length,18);assert.equal(available.slots[0].startTime,'08:00');assert.equal(available.slots.at(-1)!.endTime,'17:00');
    await assert.rejects(()=>service.createHold(actor(802),{visitDate:date,slotId:`${date}_0700`,visitorCount:1,requestId:'date-hours-invalid-request-802'}));
    const h=await service.createHold(actor(803),{visitDate:date,slotId:`${date}_0800`,visitorCount:1,requestId:'date-hours-valid-request-803'});
    await assert.rejects(()=>service.adminSetDateHours(admin,{visitDate:date,openingTime:'09:00',closingTime:'17:00'}));
    const b=await service.createBooking(actor(803),h.holdId,'Date Hours Visitor');
    await assert.rejects(()=>service.adminSetDateHours(admin,{visitDate:date,openingTime:'09:00',closingTime:'17:00'}));
    await service.cancelBooking(admin,b.bookingId,'Testing schedule change');
    await service.adminSetDateHours(admin,{visitDate:date,openingTime:'09:00',closingTime:'17:00'});
    await service.adminSetDateHours(admin,{visitDate:date,reset:true});
    assert.equal((await service.availability(date)).slots.length,24);
    assert.equal((await service.availability(day)).slots.length,24);
  });
  await t.test('daily phone limit is atomic across accounts and slots; admins bypass it',async()=>{
    const date='2030-01-15', phone='+919876543210';
    const actors=[901,902,903].map(i=>({...actor(i),phone}));
    const holds=await Promise.all(actors.map((a,i)=>service.createHold(a,{visitDate:date,slotId:`${date}_${['0700','0730','0800'][i]}`,visitorCount:1,requestId:`phone-limit-request-${a.uid}`})));
    const results=await Promise.allSettled(actors.map((a,i)=>service.createBooking(a,holds[i].holdId,'Limit Visitor')));
    assert.equal(results.filter(r=>r.status==='fulfilled').length,2);
    assert.equal(results.filter(r=>r.status==='rejected').length,1);
    const winner=results.findIndex(r=>r.status==='fulfilled');
    const result=results[winner];assert.equal(result.status,'fulfilled');
    if(result.status!=='fulfilled')throw new Error('Missing booking');
    assert.equal((await service.createBooking(actors[winner],holds[winner].holdId,'Retry Visitor')).bookingId,result.value.bookingId);
    await service.cancelBooking(actors[winner],result.value.bookingId,'Changed plans');
    await assert.rejects(()=>service.createHold({...actor(904),phone},{visitDate:date,slotId:`${date}_0830`,visitorCount:1,requestId:'phone-limit-fourth-request'}),/maximum of 2/);
    const failed=results.findIndex(r=>r.status==='rejected');
    await service.createBooking({...actors[failed],admin:true},holds[failed].holdId,'Admin Visitor');
    const admin={...actor(905),phone,admin:true};
    const extra=await service.createHold(admin,{visitDate:date,slotId:`${date}_0900`,visitorCount:1,requestId:'phone-limit-admin-extra-request'});
    await service.createBooking(admin,extra.holdId,'Admin Extra');
    const nextDate='2030-01-14';
    const next=await service.createHold(actors[0],{visitDate:nextDate,slotId:`${nextDate}_0700`,visitorCount:1,requestId:'phone-limit-other-date-request'});
    await service.createBooking(actors[0],next.holdId,'Other Date Visitor');
    const legacy=actor(906);
    for(let i=0;i<2;i++)await db.doc(`bookings/limit-legacy-${i}`).set({userId:legacy.uid,visitDate:date,status:'confirmed'});
    await assert.rejects(()=>service.createHold(legacy,{visitDate:date,slotId:`${date}_0930`,visitorCount:1,requestId:'phone-limit-legacy-request'}),/maximum of 2/);
  });
  let bookingId='',owner=actor(0),holdId='';
  await t.test('12 simultaneous requests cannot exceed 3 places',async()=>{
    const results=await Promise.allSettled(Array.from({length:12},(_,i)=>hold(i)));
    const successful=results.flatMap((r,i)=>r.status==='fulfilled'?[{h:r.value,a:actor(i)}]:[]);
    assert.equal(successful.length,3); const first=successful[0];owner=first.a;holdId=first.h.holdId;
    const bookings=await Promise.all(successful.map(x=>service.createBooking(x.a,x.h.holdId,'Test Visitor','  12 Test Street, Chavakkad  ')));bookingId=bookings[0].bookingId;
    const slot=await db.doc(`visitSlots/${day}_0700`).get();assert.equal(slot.data()!.occupancy,3);
    const records=await Promise.all(bookings.map(b=>db.doc(`bookings/${b.bookingId}`).get()));
    assert.deepEqual(records.map(b=>b.data()!.tokenStart).sort((a,b)=>a-b),[1,2,3]);
    assert.ok(records.every(b=>b.data()!.tokenStart===b.data()!.tokenEnd));
  });
  await t.test('address is trimmed and stored with the booking',async()=>{
    assert.equal((await db.doc(`bookings/${bookingId}`).get()).data()!.visitorAddress,'12 Test Street, Chavakkad');
    await assert.rejects(()=>service.createBooking(owner,holdId,'Test Visitor','   '));
    await assert.rejects(()=>service.createBooking(owner,holdId,'Test Visitor','x'.repeat(501)));
  });
  await t.test('confirmation retry returns same booking without another increment',async()=>{
    assert.equal((await service.createBooking(owner,holdId,'Test Visitor')).bookingId,bookingId);
    assert.equal((await db.doc(`visitSlots/${day}_0700`).get()).data()!.occupancy,3);
    assert.equal((await db.doc(`slotTokenCounters/${day}_0700`).get()).data()!.nextToken,4);
  });
  await t.test('cross-user cancellation fails; simultaneous retries restore capacity once',async()=>{
    await assert.rejects(()=>service.cancelBooking(actor(999),bookingId,'Test'));
    await Promise.all([service.cancelBooking(owner,bookingId,'Changed plans'),service.cancelBooking(owner,bookingId,'Retry')]);
    assert.equal((await db.doc(`visitSlots/${day}_0700`).get()).data()!.occupancy,2);
  });
  await t.test('cancelled tokens are not reused',async()=>{
    const h=await hold(30);const r=await service.createBooking(actor(30),h.holdId,'Later Visitor');
    const b=(await db.doc(`bookings/${r.bookingId}`).get()).data()!;
    assert.equal(b.tokenStart,4);assert.equal(b.tokenEnd,4);
  });
  await t.test('groups get consecutive individual tokens; every slot starts at one',async()=>{
    const h=await hold(31,5,2);const r=await service.createBooking(actor(31),h.holdId,'Group Visitor');
    const b=(await db.doc(`bookings/${r.bookingId}`).get()).data()!;
    assert.equal(b.tokenStart,1);assert.equal(b.tokenEnd,2);
    const next=await hold(32,5,1);const r2=await service.createBooking(actor(32),next.holdId,'Next Visitor');
    assert.equal((await db.doc(`bookings/${r2.bookingId}`).get()).data()!.tokenStart,3);
    const tomorrow='2030-01-11';const another=await service.createHold(actor(33),{visitDate:tomorrow,slotId:`${tomorrow}_0700`,visitorCount:1,requestId:'tomorrow-request-1234567890'});
    const r3=await service.createBooking(actor(33),another.holdId,'Tomorrow Visitor');
    assert.equal((await db.doc(`bookings/${r3.bookingId}`).get()).data()!.tokenStart,1);
  });
  await t.test('legacy bookings backfill by booking time safely alongside new confirmations',async()=>{
    const slotId=`${day}_1000`;
    await db.doc('bookings/legacy-later').set({userId:actor(34).uid,slotId,visitorCount:1,status:'cancelled',createdAt:Timestamp.fromMillis(2000)});
    await db.doc('bookings/legacy-first').set({userId:actor(34).uid,slotId,visitorCount:2,status:'cancelled',createdAt:Timestamp.fromMillis(1000)});
    await assert.rejects(()=>service.ensureBookingTokens(actor(999),'legacy-first'));
    const h=await hold(35,6);
    const [tokens,r]=await Promise.all([service.ensureBookingTokens(actor(34),'legacy-first'),service.createBooking(actor(35),h.holdId,'New Visitor')]);
    assert.deepEqual(tokens,{tokenStart:1,tokenEnd:2});
    assert.deepEqual(await service.ensureBookingTokens(actor(34),'legacy-later'),{tokenStart:3,tokenEnd:3});
    assert.equal((await db.doc(`bookings/${r.bookingId}`).get()).data()!.tokenStart,4);
    assert.deepEqual(await service.ensureBookingTokens(actor(34),'legacy-first'),tokens);
  });
  await t.test('expired hold disappears without scheduler and cannot confirm',async()=>{
    const h=await hold(20,1,3);now+=301_000;
    const a=await service.availability(day);assert.equal(a.slots[1].remaining,3);
    await assert.rejects(()=>service.createBooking(actor(20),h.holdId,'Test Visitor'));
  });
  await t.test('a delayed confirmation event cannot notify a cancelled booking',async()=>{
    const stale=(await db.doc(`bookings/${bookingId}`).get()).data()!;
    await queueNotice(db,bookingId,'confirmed',{...stale,status:'confirmed'});
    assert.equal((await db.doc(`notifications/${bookingId}_confirmed`).get()).exists,false);
    await queueNotice(db,bookingId,'cancelled',stale);
    assert.equal((await db.doc(`notifications/${bookingId}_cancelled`).get()).exists,true);
  });
  await t.test('day closure is rechecked at confirmation',async()=>{
    const h=await hold(21,2);
    await db.doc(`closures/${day}`).set({closed:true,reason:'Test closure'});
    await assert.rejects(()=>service.createBooking(actor(21),h.holdId,'Test Visitor'));
    await db.doc(`closures/${day}`).delete();await service.releaseHold(actor(21),h.holdId);
  });
  await t.test('capacity reductions cannot undercut bookings or live holds',async()=>{
    const h=await hold(23,3,3);
    await assert.rejects(()=>service.adminUpdateSlots({...actor(100),admin:true},{visitDate:day,startTime:'08:30',endTime:'09:00',blocked:false,reason:'Test',capacity:2}));
    await service.releaseHold(actor(23),h.holdId);
  });
  await t.test('secure pass requires staff, time window, and prevents repeated entry',async()=>{
    const h=await hold(24,4);const result=await service.createBooking(actor(24),h.holdId,'Gate Visitor');
    const b=(await db.doc(`bookings/${result.bookingId}`).get()).data()!;
    await assert.rejects(()=>service.validatePass(actor(1),b.qrToken,true));
    assert.equal((await service.validatePass({...actor(100),gate:true},b.qrToken,false)).valid,false);
    now=b.startAt+1000; assert.equal((await service.validatePass({...actor(100),gate:true},b.qrToken,true)).valid,true);
    assert.equal((await service.validatePass({...actor(100),gate:true},b.qrToken,true)).valid,false);
  });
  await t.test('Firestore rules isolate owners and reject all client capacity mutations',async()=>{
    const env=await initializeTestEnvironment({projectId,firestore:{rules:await readFile('../firestore.rules','utf8'),host:'127.0.0.1',port:8080}});
    try{
      const own=env.authenticatedContext(owner.uid).firestore(),other=env.authenticatedContext('other').firestore(),admin=env.authenticatedContext('admin',{admin:true}).firestore();
      await assertSucceeds(getDoc(doc(own,'bookings',bookingId)));await assertFails(getDoc(doc(other,'bookings',bookingId)));
      await assertSucceeds(getDocs(query(collection(own,'bookings'),where('userId','==',owner.uid))));
      await assertFails(getDocs(collection(own,'bookings')));await assertFails(setDoc(doc(own,'bookings','fake'),{userId:owner.uid,status:'confirmed'}));
      await assertFails(setDoc(doc(admin,'visitSlots','anything'),{capacity:99}));
      await assertFails(setDoc(doc(own,'users',owner.uid),{admin:true}));
      await assertFails(setDoc(doc(own,'slotTokenCounters',`${day}_0700`),{nextToken:1}));
      await assertFails(setDoc(doc(own,'phoneDailyBookings','fake'),{count:0}));
      await assertFails(getDoc(doc(own,'phoneDailyBookings','fake')));
      await assertFails(getDoc(doc(own,'slotTokenCounters',`${day}_0700`)));
      await assertFails(getDoc(doc(own,'slotState',`${day}_0700`)));await assertFails(setDoc(doc(own,'users',owner.uid,'devices','fake'),{token:'fake'}));
      await assertSucceeds(getDoc(doc(env.unauthenticatedContext().firestore(),'settings','booking')));
    }finally{await env.cleanup();}
  });
});
