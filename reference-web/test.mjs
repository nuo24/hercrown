import assert from 'node:assert/strict';
import {defaults,choose,advance,complete,restore} from './dist/state.mjs';
let s=defaults();for(let i=0;i<7;i++){s=advance(s);assert.equal(s.step,i+1)}assert.equal(s.completed,false);s=complete(s);assert.equal(restore(JSON.stringify(s)).completed,true);
s=advance(defaults());assert.equal(s.step,1);assert.equal(s.intention,'');s=advance(s);assert.equal(s.step,2);
s=choose(s,'intention','Find encouragement');s=advance(s);s.step--;assert.equal(s.intention,'Find encouragement');s=advance(s,true);assert.equal(s.intention,'');
s=choose(s,'topics','Peace');s=choose(s,'topics','Hope');assert.deepEqual(s.topics,['Peace','Hope']);s=choose(s,'topics','Peace');assert.deepEqual(s.topics,['Hope']);s.step=4;s=advance(s,true);assert.deepEqual(s.topics,[]);s.step=6;s.reminders=true;s=advance(s,true);assert.equal(s.reminders,false);
assert.equal(complete(defaults(),true).guest,true);assert.equal(restore('bad').step,0);assert.equal(restore('null').step,0);assert.equal(restore('{"step":99}').step,7);
assert.equal(restore('{"step":1,"intention":"Faith"}').step,2);assert.equal(restore('{"step":6,"completed":true}').step,7);assert.equal(restore('{"step":1,"flowVersion":2}').step,1);assert.equal(restore(JSON.stringify(restore('{"step":2}'))).step,3);
console.log('PASS: eight-step flow with introduction, choices, skip/back, completion, recovery and one-time legacy progress migration');
