import {RequestLimiter} from '../src/request_security.js';
import {test, mock} from 'node:test';
import assert from 'node:assert/strict';
import {scryptSync} from 'node:crypto';
import {getFirestore} from 'firebase-admin/firestore';
import {getAuth} from 'firebase-admin/auth';
import {adminLogin} from '../src/index.js';

test('admin password login enforces credentials, role, account state and limits',async()=>{
  const password='test-only-password-123', salt='test-salt';
  let enabled=true, admin=true, disabled=false, limited=false, tokens=0;
  const db=getFirestore(), auth=getAuth();
  mock.method(RequestLimiter.prototype, 'check', async () => {});
  mock.method(db,'doc',(path:string)=>({path,get:async()=>({data:()=>({uid:'test-admin',enabled,salt,hash:scryptSync(password,salt,32).toString('hex')})})}));
  mock.method(db,'runTransaction',async(fn:any)=>fn({get:async()=>({data:()=>({until:Date.now()+60000,count:limited?100:0})}),set:()=>{}}));
  mock.method(auth,'getUser',async()=>({uid:'test-admin',disabled,customClaims:{admin}}));
  mock.method(auth,'createCustomToken',async()=>{tokens++;return 'test-token';});
  const login=(value=password)=>adminLogin.run({app:{appId:'test-app'},data:{username:'test_admin',password:value},rawRequest:{ip:'127.0.0.1'}} as any);
  try {
    assert.deepEqual(await login(),{token:'test-token'});
    await assert.rejects(()=>login('wrong-password'),{code:'unauthenticated'});
    enabled=false;await assert.rejects(()=>login(),{code:'unauthenticated'});enabled=true;
    admin=false;await assert.rejects(()=>login(),{code:'unauthenticated'});admin=true;
    disabled=true;await assert.rejects(()=>login(),{code:'unauthenticated'});disabled=false;
    limited=true;await assert.rejects(()=>login(),{code:'resource-exhausted'});
    assert.equal(tokens,1);
  } finally { mock.restoreAll(); }
});
