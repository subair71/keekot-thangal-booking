import {initializeApp, applicationDefault} from 'firebase-admin/app';
import {getAuth} from 'firebase-admin/auth';
import {getFirestore} from 'firebase-admin/firestore';
import {randomBytes, scryptSync} from 'node:crypto';

const [projectId,username]=process.argv.slice(2);
if(!projectId||!username||!/^[a-z0-9_]{3,64}$/.test(username))throw new Error('Usage: npm run admin-account -- PROJECT_ID USERNAME (password via stdin; authorized ADC required)');
let input='';
for await(const chunk of process.stdin){input+=chunk;if(input.length>258)throw new Error('Password too long');}
const password=input.replace(/\r?\n$/, '');
if(password.length<12||password.length>256)throw new Error('Password must contain 12–256 characters');
initializeApp({projectId,credential:applicationDefault()});
const auth=getAuth(),db=getFirestore(),ref=db.doc(`adminCredentials/${username}`);
if((await ref.get()).exists)throw new Error('Username already exists; no changes made');
const user=await auth.createUser({displayName:username});
try {
  await auth.setCustomUserClaims(user.uid,{admin:true});
  const salt=randomBytes(32).toString('hex');
  await ref.create({uid:user.uid,enabled:true,salt,hash:scryptSync(password,salt,32).toString('hex')});
} catch(error) {
  await auth.deleteUser(user.uid);
  throw error;
}
console.log('Administrator created successfully.');
