import {initializeApp} from 'firebase-admin/app';
import {getFirestore} from 'firebase-admin/firestore';
import {getAuth} from 'firebase-admin/auth';

if(!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST)throw new Error('Seed is emulator-only. Both emulator host variables are required.');
initializeApp({projectId:'demo-keekot-thangal'});
await getFirestore().doc('settings/booking').set({timezone:'Asia/Kolkata',openingTime:'07:00',closingTime:'19:00',slotDurationMinutes:30,
  bookingWindowDays:7,allowSameDayBooking:true,maxVisitorsPerBooking:6,defaultSlotCapacity:12,
  reminderEnabled:true,reminderMinutes:60,bookingEnabled:true,environment:'development',locationUrl:'',contactPhone:'',arrivalMinutes:10});
const auth=getAuth(); const phone='+919999999999';
const admin=await auth.getUserByPhoneNumber(phone).catch(()=>auth.createUser({phoneNumber:phone}));
await auth.setCustomUserClaims(admin.uid,{admin:true,gate:true});
console.log('Development settings seeded: capacity 12, maximum 6 visitors. Local admin: +919999999999. Read its SMS code from the Auth emulator; no fixed OTP is stored.');
