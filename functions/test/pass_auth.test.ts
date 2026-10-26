import {test, mock} from 'node:test';
import assert from 'node:assert/strict';
import {getFirestore} from 'firebase-admin/firestore';
import {BookingService} from '../src/booking_service.js';
import {validatePass} from '../src/index.js';

test('pass callable admits current Khadims without gate access and ignores spoofed request roles', async () => {
  let staff: Record<string, unknown> | undefined;
  const db=getFirestore();
  mock.method(db,'doc',(path: string)=>{
    assert.equal(path,'khadims/real-scanner');
    return {get:async()=>({exists:staff!==undefined,data:()=>staff})};
  });
  mock.method(BookingService.prototype,'validatePass',async(actor,qrToken,checkIn)=>({valid:true,actor,qrToken,checkIn}));
  const run=(token:Record<string,unknown>)=>validatePass.run({
    auth:{uid:'real-scanner',token},
    data:{qrToken:'q'.repeat(43),checkIn:true,uid:'other-khadim',admin:true,gate:true,khadim:true,khadimVersion:999},
  } as any);
  try {
    await assert.rejects(()=>validatePass.run({data:{}} as any),{code:'unauthenticated'});
    await assert.rejects(()=>run({phone_number:'+919111111111'}),{code:'permission-denied'});
    const admin=await run({admin:true}) as any;
    assert.equal(admin.actor.admin,true);
    const gate=await run({gate:true}) as any;
    assert.equal(gate.actor.gate,true); // A gate-only account need not have a visitor phone.
    staff={enabled:true,version:2,phone:'+919111111111',name:'Assigned Khadim',permissions:[]};
    const assigned=await run({khadimVersion:2,admin:true,gate:true}) as any;
    assert.equal(assigned.actor.uid,'real-scanner');
    assert.equal(assigned.actor.khadim,true);
    assert.equal(assigned.actor.khadimVersion,2);
    assert.equal(assigned.actor.admin,false);
    assert.equal(assigned.actor.gate,false);
    assert.equal(assigned.checkIn,true);
    await assert.rejects(()=>run({khadimVersion:1}),{code:'permission-denied'});
    staff.permissions=['gate'];
    assert.equal((await run({khadimVersion:2}) as any).actor.gate,true);
    staff.enabled=false;
    await assert.rejects(()=>run({khadimVersion:2}),{code:'permission-denied'});
    staff=undefined;
    await assert.rejects(()=>run({khadimVersion:2}),{code:'permission-denied'});
  } finally {mock.restoreAll();}
});
