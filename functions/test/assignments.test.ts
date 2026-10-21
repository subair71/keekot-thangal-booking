import {test} from 'node:test';
import assert from 'node:assert/strict';
import {eligibility,scheduleInput,Visit} from '../src/assignments.js';
const day='2030-01-10';
const at=(t:string)=>Date.parse(`${day}T${t}:00+05:30`);
const visit=(a='10:00',b='10:30'):Visit=>({startAt:at(a),endAt:at(b),status:'confirmed',assignment:{status:'assigned'}});
const schedule=scheduleInput({hours:[{start:'09:00',end:'17:00'}],breaks:[{start:'12:00',end:'13:00'}]});
test('no schedule is off duty; hours and breaks cover the entire visit',()=>{
 assert.equal(eligibility(undefined,visit(),[],day).state,'Off duty');
 assert.equal(eligibility(schedule,visit(),[],day).eligible,true);
 assert.equal(eligibility(schedule,visit('08:50','09:10'),[],day).eligible,false);
 assert.equal(eligibility(schedule,visit('11:50','12:10'),[],day).state,'Unavailable');
 assert.equal(eligibility({...schedule,available:false},visit(),[],day).eligible,false);
});
test('capacity uses maximum overlapping active workload with half-open boundaries',()=>{
 assert.equal(eligibility(schedule,visit(),[visit()],day).state,'Busy');
 assert.equal(eligibility(schedule,visit(),[visit('09:30','10:00')],day).eligible,true);
 assert.equal(eligibility({...schedule,capacity:2},visit(),[visit('10:00','10:15'),visit('10:15','10:30')],day).eligible,true);
 assert.equal(eligibility(schedule,visit(),[{...visit(),status:'cancelled'}],day).eligible,true);
 assert.equal(eligibility(schedule,visit(),[{...visit(),assignment:{status:'completed'}}],day).eligible,true);
});
test('schedule validation rejects reversed windows and unsafe capacities',()=>{
 assert.throws(()=>scheduleInput({hours:[{start:'10:00',end:'09:00'}]}));
 assert.throws(()=>scheduleInput({hours:[],capacity:0}));
 assert.throws(()=>scheduleInput({hours:[{start:'24:00',end:'25:00'}]}));
});
