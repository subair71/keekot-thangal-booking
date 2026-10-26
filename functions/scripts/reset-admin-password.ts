import {initializeApp, applicationDefault} from 'firebase-admin/app';
import {getAuth} from 'firebase-admin/auth';
import {getFirestore} from 'firebase-admin/firestore';
import {randomBytes, scryptSync} from 'node:crypto';

const [projectId,username]=process.argv.slice(2);
if(!projectId||!username||!/^[a-z0-9_]{3,64}$/.test(username))throw new Error('Usage: npm run reset-admin-password -- PROJECT_ID USERNAME (password via stdin; authorized ADC required)');
let input='';
for await(const chunk of process.stdin){input+=chunk;if(input.length>258)throw new Error('Password too long');}
const password=input.replace(/\r?\n$/, '');
if(password.length<12||password.length>256)throw new Error('Password must contain 12–256 characters');
initializeApp({projectId,credential:applicationDefault()});
const auth=getAuth(),db=getFirestore(),ref=db.doc(`adminCredentials/${username}`);
const snap=await ref.get();
if(!snap.exists)throw new Error(`Username "${username}" does not exist; no changes made`);
const data=snap.data();
const uid=data?.uid;
if(!uid||typeof uid!=='string')throw new Error(`Document for "${username}" does not contain a valid uid`);
let user;
try {
  user=await auth.getUser(uid);
} catch(err:any) {
  if(err?.code==='auth/user-not-found') {
    user=await auth.createUser({uid,displayName:username});
  } else {
    throw err;
  }
}
await auth.setCustomUserClaims(user.uid,{admin:true});
const salt=randomBytes(32).toString('hex');
const hash=scryptSync(password,salt,32).toString('hex');
await ref.set({uid:user.uid,enabled:true,salt,hash},{merge:true});
await auth.revokeRefreshTokens(user.uid);
console.log('Administrator password reset successfully.');
