import {test,after} from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {initializeApp,deleteApp} from 'firebase-admin/app';
import {getFirestore, Timestamp} from 'firebase-admin/firestore';
import {initializeTestEnvironment,assertFails,assertSucceeds} from '@firebase/rules-unit-testing';
import {doc,getDoc,setDoc,collection,query,where,getDocs,onSnapshot} from 'firebase/firestore';
import {BookingService} from '../src/booking_service.js';
import {BookingSettings, generateSlots, makeToken, tokenHash} from '../src/domain.js';
import {queueNotice,deliverNotice} from '../src/notifications.js';

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
    await service.createBooking({...actors[failed],admin:true},holds[failed].holdId,'Admin Visitor',undefined,phone);
    const admin={...actor(905),phone,admin:true};
    const extra=await service.createHold(admin,{visitDate:date,slotId:`${date}_0900`,visitorCount:1,requestId:'phone-limit-admin-extra-request'});
    await service.createBooking(admin,extra.holdId,'Admin Extra',undefined,phone);
    const nextDate='2030-01-14';
    const next=await service.createHold(actors[0],{visitDate:nextDate,slotId:`${nextDate}_0700`,visitorCount:1,requestId:'phone-limit-other-date-request'});
    await service.createBooking(actors[0],next.holdId,'Other Date Visitor');
    const legacy=actor(906);
    for(let i=0;i<2;i++)await db.doc(`bookings/limit-legacy-${i}`).set({userId:legacy.uid,visitDate:date,status:'confirmed'});
    await assert.rejects(()=>service.createHold(legacy,{visitDate:date,slotId:`${date}_0930`,visitorCount:1,requestId:'phone-limit-legacy-request'}),/maximum of 2/);
  });
  await t.test('staff book for different visitors with atomic phone limits, creator ownership and safe retries',async()=>{
    const date='2030-01-12', visitorPhone='+442079460958';
    const staff=[1001,1002,1003].map(i=>({...actor(i),khadim:true,permissions:['bookings'],name:`Staff ${i}`}));
    const request=(a:typeof staff[0],slot:string,key:string)=>service.createHold(a,{visitDate:date,slotId:`${date}_${slot}`,visitorCount:1,requestId:`staff-visitor-request-${key}`});
    const held=await Promise.all(staff.map((a,i)=>request(a,['0700','0730','0800'][i],`${i}`)));
    const results=await Promise.allSettled(staff.map((a,i)=>service.createBooking(a,held[i].holdId,'Called Visitor','12 Visitor Street','+44 20 7946 0958')));
    assert.equal(results.filter(r=>r.status==='fulfilled').length,2);
    assert.equal(results.filter(r=>r.status==='rejected').length,1);
    const first=results.findIndex(r=>r.status==='fulfilled'), result=results[first];
    if(result.status!=='fulfilled')throw new Error('Expected a booking');
    const b=(await db.doc(`bookings/${result.value.bookingId}`).get()).data()!;
    assert.equal(b.visitorPhone,visitorPhone);assert.equal(b.visitorPhoneVerified,false);
    assert.equal(b.phoneNumberMasked,'+44 ••••• 0958');assert.equal(b.userId,staff[first].uid);
    assert.equal(b.bookedByUid,staff[first].uid);assert.equal(b.bookedByRole,'khadim');
    assert.equal(b.bookedByName,staff[first].name);assert.equal(b.visitorAddress,'12 Visitor Street');
    const notice=(await db.doc(`notifications/${b.bookingId}_confirmed`).get()).data()!;
    assert.equal(notice.userId,staff[first].uid);assert.equal(notice.recipientRole,'booker');
    assert.equal((await service.createBooking(staff[first],held[first].holdId,'Retry','12 Visitor Street',visitorPhone)).bookingId,b.bookingId);
    await assert.rejects(()=>service.createHold({...actor(1004),phone:visitorPhone},{visitDate:date,slotId:`${date}_0830`,visitorCount:1,requestId:'self-after-staff-limit-request'}),/maximum of 2/);
    await service.cancelBooking(staff[first],b.bookingId,'Cancelled assisted visit');
    const failed=results.findIndex(r=>r.status==='rejected');
    await assert.rejects(()=>service.createBooking(staff[failed],held[failed].holdId,'Still Limited',undefined,visitorPhone),/maximum of 2/);
    await service.createBooking({...staff[failed],admin:true,phone:''},held[failed].holdId,'Admin Guest',undefined,visitorPhone);
    // One Khadim can serve more than two distinct visitor numbers; their own
    // phone counter and profile must never be changed by assisted bookings.
    for(let i=0;i<3;i++) {
      const next=await request(staff[first],['0900','0930','1000'][i],`distinct-${i}`);
      await service.createBooking(staff[first],next.holdId,'Different Guest',undefined,`+1202555012${i}`);
    }
    const invalid=await request(staff[first],'1030','invalid');
    await assert.rejects(()=>service.createBooking(staff[first],invalid.holdId,'Missing Phone'),/visitor phone number/);
    await assert.rejects(()=>service.createBooking(staff[first],invalid.holdId,'Bad Phone',undefined,'123'),/visitor phone number/);
    await assert.rejects(()=>service.createBooking({...actor(1005)},invalid.holdId,'Spoofed',undefined,visitorPhone),/Only authorized staff/);
    await assert.rejects(()=>request({...staff[first],permissions:['gate']},'1100','unauthorized'),/Booking permission/);
    await service.releaseHold(staff[first],invalid.holdId);
    const admin={...actor(1006),phone:'',admin:true};
    const adminHold=await service.createHold(admin,{visitDate:date,slotId:`${date}_1130`,visitorCount:1,requestId:'admin-without-phone-request'});
    const adminBooking=await service.createBooking(admin,adminHold.holdId,'Admin Guest',undefined,visitorPhone);
    assert.equal((await db.doc(`bookings/${adminBooking.bookingId}`).get()).data()!.bookedByRole,'admin');
    assert.equal((await db.doc(`users/${staff[first].uid}`).get()).exists,false);
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
    const notice=(await db.doc(`notifications/${bookingId}_confirmed`).get()).data()!;
    assert.equal(notice.userId,owner.uid);assert.equal(notice.delivery,'pending');
    await queueNotice(db,bookingId,'confirmed',(await db.doc(`bookings/${bookingId}`).get()).data()!);
    assert.equal((await db.collection('notifications').where('bookingId','==',bookingId).where('kind','==','confirmed').get()).size,1);
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
    const notice=await db.doc(`notifications/${bookingId}_confirmed`).get();
    assert.equal(notice.exists,true); // Created atomically with the original booking.
    await queueNotice(db,bookingId,'confirmed',stale);
    assert.equal((await db.doc(`notifications/${bookingId}_confirmed`).get()).data()!.createdAt.toMillis(),notice.data()!.createdAt.toMillis());
    await deliverNotice(db,`${bookingId}_confirmed`);
    assert.equal((await db.doc(`notifications/${bookingId}_confirmed`).get()).data()!.delivery,'superseded');
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
    const staff={...actor(100),gate:true};
    await assert.rejects(()=>service.validatePass(actor(1),b.qrToken,true));
    assert.equal((await service.validatePass(staff,'bad-qr',true)).reason,'invalid_pass');
    assert.equal((await service.validatePass(staff,'x'.repeat(43),true)).reason,'invalid_pass');
    assert.equal((await service.validatePass(staff,b.qrToken,false)).reason,'too_early');
    now=b.endAt;
    assert.equal((await service.validatePass(staff,b.qrToken,true)).reason,'expired');
    now=b.startAt+1000;
    assert.equal((await service.validatePass(staff,b.qrToken,false)).valid,true);
    assert.equal((await db.doc(`bookings/${result.bookingId}`).get()).data()!.status,'confirmed');
    const scans=await Promise.all([service.validatePass(staff,b.qrToken,true),service.validatePass({...actor(101),admin:true},b.qrToken,true)]);
    assert.equal(scans.filter(r=>r.valid).length,1);
    assert.equal(scans.filter(r=>r.reason==='already_used').length,1);
    const saved=(await db.doc(`bookings/${result.bookingId}`).get()).data()!;
    assert.equal(saved.status,'completed');
    assert.ok(saved.checkedInAt);
    assert.ok(['test-100','test-101'].includes(saved.checkedInBy));
    assert.equal((await service.validatePass(staff,b.qrToken,true)).reason,'already_used');
    const cancelled=(await db.doc(`bookings/${bookingId}`).get()).data()!;
    assert.equal((await service.validatePass(staff,cancelled.qrToken,true)).reason,'cancelled');
  });
  await t.test('assigned Khadim scans use current assignment and account permissions',async t=>{
    const previousNow=now,startAt=Date.parse('2030-01-10T05:00:00Z'),endAt=startAt+30*60_000;
    const khadim={uid:'scan-assignee',phone:'+919777777777',khadim:true,khadimVersion:1,permissions:[] as string[]};
    const profile=db.doc(`khadims/${khadim.uid}`);
    const resetProfile=()=>profile.set({enabled:true,version:1,permissions:[]});
    const pass=async(name:string,legacy=false)=>{
      const qrToken=makeToken(),ref=db.doc(`bookings/scan-${name}`),slotId=`scan-slot-${name}`;
      const assignment={khadimId:khadim.uid,status:'assigned',revision:1,conflict:false,scheduledStart:startAt,scheduledEnd:endAt};
      await ref.set({bookingId:ref.id,bookingReference:`SCAN-${name}`,userId:'scan-visitor',visitDate:day,slotId,
        startTime:'10:30',endTime:'11:00',startAt,endAt,visitorCount:1,status:'confirmed',qrToken,assignment,
        ...(legacy?{}:{tokenStart:1,tokenEnd:1})});
      await db.doc(`passTokens/${tokenHash(qrToken)}`).set({bookingId:ref.id});
      return {qrToken,ref,slotId,assignment};
    };
    try {
      now=startAt+1000;
      await t.test('assignee without gate can validate, migrate legacy numbers and admit only once',async()=>{
        await resetProfile();
        const p=await pass('legacy',true);
        const checked=await service.validatePass(khadim,p.qrToken,false);
        assert.equal(checked.valid,true);assert.equal(checked.tokenStart,1);assert.equal(checked.tokenEnd,1);
        assert.equal((await p.ref.get()).data()!.status,'confirmed');
        assert.equal((await db.doc(`slotTokenCounters/${p.slotId}`).get()).data()!.nextToken,2);
        assert.equal((await service.validatePass(khadim,p.qrToken,true)).status,'completed');
        const saved=(await p.ref.get()).data()!;
        assert.equal(saved.checkedInBy,khadim.uid);assert.ok(saved.checkedInAt);
        assert.equal(saved.assignment.status,'assigned'); // Attendance does not finish the Khadim's service.
        assert.equal((await service.validatePass(khadim,p.qrToken,true)).reason,'already_used');
      });
      await t.test('wrong, removed, conflicted and stale assignments cannot disclose or mutate a pass',async()=>{
        await resetProfile();
        const p=await pass('denied',true);
        const denied=()=>assert.rejects(()=>service.validatePass(khadim,p.qrToken,true));
        await p.ref.update({'assignment.khadimId':'replacement-khadim'});
        await assert.rejects(()=>service.validatePass({...khadim,gate:true},p.qrToken,true),{code:'permission-denied'});
        for(const status of ['unassigned','cancelled','completed']){
          await p.ref.update({assignment:{...p.assignment,status}});await denied();
        }
        await p.ref.update({assignment:{...p.assignment,conflict:true}});await denied();
        await p.ref.update({assignment:{...p.assignment,scheduledStart:startAt-60_000}});await denied();
        const saved=(await p.ref.get()).data()!;
        assert.equal(saved.status,'confirmed');assert.equal(saved.checkedInAt,undefined);
        assert.equal(saved.tokenStart,undefined);
        assert.equal((await db.doc(`slotTokenCounters/${p.slotId}`).get()).exists,false);
      });
      await t.test('disabled, deleted and version-changed profiles are rejected; gate access comes from current profile',async()=>{
        await resetProfile();
        const p=await pass('revoked');
        await profile.update({enabled:false});
        await assert.rejects(()=>service.validatePass(khadim,p.qrToken,true),{code:'permission-denied'});
        await profile.update({enabled:true,version:2});
        await assert.rejects(()=>service.validatePass(khadim,p.qrToken,true),{code:'permission-denied'});
        await profile.delete();
        await assert.rejects(()=>service.validatePass(khadim,p.qrToken,true),{code:'permission-denied'});
        assert.equal((await p.ref.get()).data()!.status,'confirmed');
        await resetProfile();
        await p.ref.update({assignment:{...p.assignment,khadimId:'other-khadim'}});
        await profile.update({permissions:['gate']});
        assert.equal((await service.validatePass(khadim,p.qrToken,false)).valid,true);
        await profile.update({permissions:[]});
        await assert.rejects(()=>service.validatePass({...khadim,gate:true},p.qrToken,true),{code:'permission-denied'});
      });
      await t.test('assigned scans retain arrival, cancellation and concurrent-entry protections',async()=>{
        await resetProfile();
        const p=await pass('timing');
        await p.ref.update({'assignment.status':'inProgress'});
        now=startAt-settings.arrivalMinutes*60_000-1;
        assert.equal((await service.validatePass(khadim,p.qrToken,true)).reason,'too_early');
        now=endAt;
        assert.equal((await service.validatePass(khadim,p.qrToken,true)).reason,'expired');
        now=startAt+1000;
        await p.ref.update({status:'cancelled'});
        assert.equal((await service.validatePass(khadim,p.qrToken,true)).reason,'cancelled');
        await p.ref.update({status:'confirmed'});
        const scans=await Promise.all([service.validatePass(khadim,p.qrToken,true),service.validatePass({...actor(3100),admin:true},p.qrToken,true)]);
        assert.equal(scans.filter(r=>r.valid).length,1);
        assert.equal(scans.filter(r=>r.reason==='already_used').length,1);
        const saved=(await p.ref.get()).data()!;
        assert.ok([khadim.uid,'test-3100'].includes(saved.checkedInBy));
        assert.equal(saved.assignment.status,'inProgress');
        const audit=await db.collection('auditLog').where('bookingId','==',p.ref.id).get();
        assert.equal(audit.docs.filter(d=>d.data().action==='checkIn').length,1);
      });
    } finally {now=previousNow;}
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
      await db.doc('khadims/limited-staff').set({name:'Test Khadim',phone:'+919888888888',enabled:true,version:1,permissions:['bookings']});
      await db.doc('khadimSecrets/limited-staff').set({hash:'private',salt:'private'});
      const staff=env.authenticatedContext('limited-staff',{khadimVersion:1}).firestore();
      await db.doc('bookings/staff-created').set({userId:'limited-staff',bookedByUid:'limited-staff',bookedByRole:'khadim',visitorPhone:'+919555555555'});
      await assertSucceeds(getDoc(doc(staff,'bookings','staff-created')));
      const matchingPhone=env.authenticatedContext('guest-account',{phone_number:'+919555555555'}).firestore();
      await assertFails(getDoc(doc(matchingPhone,'bookings','staff-created')));
      await assertFails(setDoc(doc(staff,'bookings','staff-created'),{visitorPhone:'+919000000000'},{merge:true}));
      await assertFails(getDocs(collection(staff,'bookings')));
      await db.doc('bookings/staff-assigned').set({userId:'someone',assignment:{khadimId:'limited-staff'}});
      await assertSucceeds(getDocs(query(collection(staff,'bookings'),where('assignment.khadimId','==','limited-staff'))));
      await assertFails(getDoc(doc(staff,'bookings',bookingId)));
      await assertSucceeds(getDoc(doc(staff,'khadims','limited-staff')));
      await assertFails(getDocs(collection(staff,'khadims')));
      await assertFails(getDoc(doc(staff,'khadimSecrets','limited-staff')));
      await assertFails(getDoc(doc(admin,'khadimSecrets','limited-staff')));
      await assertFails(setDoc(doc(staff,'khadims','limited-staff'),{permissions:['settings'],enabled:true,version:1}));
      await db.doc('khadims/limited-staff').update({version:2});
      await assertFails(getDoc(doc(staff,'bookings','staff-created')));
      await assertFails(getDocs(collection(staff,'bookings')));
      const refreshed=env.authenticatedContext('limited-staff',{khadimVersion:2}).firestore();
      await assertSucceeds(getDocs(query(collection(refreshed,'bookings'),where('assignment.khadimId','==','limited-staff'))));
      await db.doc('khadims/limited-staff').update({enabled:false});
      await assertFails(getDoc(doc(refreshed,'bookings','staff-created')));
      await assertFails(getDocs(collection(refreshed,'bookings')));
      await db.doc('khadims/limited-staff').update({enabled:true,permissions:['gate']});
      await db.doc('bookings/staff-assigned').update({userId:owner.uid});
      const streams=[own,admin,refreshed].map(client=>new Promise<void>((resolve,reject)=>{
        const timer=setTimeout(()=>{unsubscribe();reject(new Error('Realtime assignment update timed out'));},10000);
        const unsubscribe=onSnapshot(doc(client,'bookings','staff-assigned'),snapshot=>{
          if(snapshot.data()?.assignment?.status==='inProgress'){clearTimeout(timer);unsubscribe();resolve();}
        },error=>{clearTimeout(timer);reject(error);});
      }));
      await db.doc('bookings/staff-assigned').update({'assignment.status':'inProgress'});
      await Promise.all(streams);

      await assertFails(getDocs(collection(refreshed,'bookings')));

    }finally{await env.cleanup();}
  });
});
