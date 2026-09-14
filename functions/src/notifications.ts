import {Firestore, FieldValue} from 'firebase-admin/firestore';
import {getMessaging} from 'firebase-admin/messaging';
import {settingsFrom} from './domain.js';

export async function queueNotice(db: Firestore, bookingId: string, kind: string, b: FirebaseFirestore.DocumentData) {
  const title=kind==='confirmed'?'Booking confirmed':kind==='cancelled'?'Booking cancelled':'Visit reminder';
  const time=new Intl.DateTimeFormat('en-IN',{hour:'numeric',minute:'2-digit',timeZone:'Asia/Kolkata'}).format(b.startAt);
  const date=new Intl.DateTimeFormat('en-IN',{day:'numeric',month:'short',timeZone:'Asia/Kolkata'}).format(b.startAt);
  const body=kind==='cancelled'?'Your visit has been cancelled. Your places have been released.':`Your Keekot Thangal visit ${kind==='reminder'?'begins':'is confirmed'} at ${time} on ${date}.`;
  const ref=db.doc(`notifications/${bookingId}_${kind}`);
  await db.runTransaction(async tx=>{
    const [existing,booking]=await tx.getAll(ref,db.doc(`bookings/${bookingId}`));
    if(existing.exists || !booking.exists)return;
    const current=booking.data()!;
    if(kind==='cancelled'?current.status!=='cancelled':current.status!=='confirmed')return;
    if(kind==='reminder' && current.startAt<=Date.now())return;
    tx.create(ref,{userId:b.userId,bookingId,kind,title,body,read:false,delivery:'pending',attempts:0,nextAttemptAt:Date.now(),createdAt:FieldValue.serverTimestamp()});
  });
}
export async function deliverNotice(db: Firestore, id: string) {
  const ref=db.doc(`notifications/${id}`);
  const notice=await db.runTransaction(async tx=>{
    const d=(await tx.get(ref)).data(); const now=Date.now();
    if(!d || ['sent','no-device','failed','superseded'].includes(d.delivery) || d.nextAttemptAt>now)return null;
    const b=(await tx.get(db.doc(`bookings/${d.bookingId}`))).data();
    if(!b || (d.kind==='cancelled'?b.status!=='cancelled':b.status!=='confirmed') || (d.kind==='reminder' && b.startAt<=now)) {
      tx.update(ref,{delivery:'superseded'});return null;
    }
    tx.update(ref,{delivery:'pending',nextAttemptAt:now+120_000,attempts:d.attempts+1}); return d;
  });
  if(!notice)return;
  try {
    const tokens=await db.collection(`users/${notice.userId}/devices`).orderBy('updatedAt','desc').limit(10).get();
    if(tokens.empty){await ref.update({delivery:'no-device'});return;}
    const result=await getMessaging().sendEachForMulticast({tokens:tokens.docs.map(t=>t.data().token),
      notification:{title:notice.title,body:notice.body},data:{bookingId:notice.bookingId,notificationId:id},
      webpush:{notification:{tag:id,icon:'/icons/Icon-192.png'},fcmOptions:{link:process.env.APP_ORIGIN?`${process.env.APP_ORIGIN}/booking/${notice.bookingId}`:undefined}}});
    let retry=false;
    for(const [i,r] of result.responses.entries())if(!r.success){
      if(['messaging/registration-token-not-registered','messaging/invalid-registration-token'].includes(r.error?.code || ''))await tokens.docs[i].ref.delete(); else retry=true;
    }
    await ref.update({delivery:retry?(notice.attempts>=4?'failed':'pending'):'sent',nextAttemptAt:Date.now()+300_000});
  } catch {await ref.update({delivery:notice.attempts>=4?'failed':'pending',nextAttemptAt:Date.now()+300_000});}
}
export async function reminders(db: Firestore) {
  const config=(await db.doc('settings/booking').get()).data(); if(!config)return;
  const c=settingsFrom(config), now=Date.now();
  const upcoming=await db.collection('bookings').where('status','==','confirmed').where('reminderQueued','==',false).where('reminderAt','<=',now).limit(300).get();
  for(const b of upcoming.docs){
    if(c.reminderEnabled && b.data().startAt>now)await queueNotice(db,b.id,'reminder',b.data());
    await b.ref.update({reminderQueued:true});
  }
  const expired=await db.collection('bookings').where('status','==','confirmed').where('endAt','<=',now).limit(300).get();
  for(const doc of expired.docs)await db.runTransaction(async tx=>{
    const fresh=await tx.get(doc.ref);if(fresh.data()?.status==='confirmed')tx.update(doc.ref,{status:'expired',updatedAt:FieldValue.serverTimestamp()});
  });
  const pending=await db.collection('notifications').where('delivery','==','pending').where('nextAttemptAt','<=',now).limit(100).get();
  await Promise.all(pending.docs.map(d=>deliverNotice(db,d.id)));
}
