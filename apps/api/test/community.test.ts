import { env } from 'cloudflare:workers';
import { expect, it } from 'vitest';
import { api, signInGuest } from './helpers';
import { getCommunity, voteCommunity } from '../src/community';
import type { Tracker } from '../src/events';
const payload = { name:'A local pantry',type:'Local church',city:'Philadelphia',website:'https://example.org',reason:'Helping women find practical care close to home.' };
it('requires a session and returns owner figures with the researched shortlist, no sample vote counts',async()=>{
 expect((await api('/me/community')).status).toBe(401);
 const {token}=await signInGuest(); const b=await(await api('/me/community',{token})).json<any>();
 expect(b.giving).toMatchObject({totalCents:735000,revenuePercent:30});
 expect(b.causes.map((c:any)=>c.name)).toEqual(['Mercy Multiplied','Sharing the Mission','House of Grace','Meninadança']);
 expect(b.vote).toBeNull(); expect(b.causes.every((c:any)=>c.votes===undefined)).toBe(true);
});
it('uses a server round, idempotently keeps one vote, and allows changing it',async()=>{
 const {token,userId}=await signInGuest(); const b=await(await api('/me/community',{token})).json<any>();
 const vote=(causeId:string,roundId=b.round.id)=>api('/me/community/vote',{token,method:'PUT',body:JSON.stringify({causeId,roundId})});
 expect((await vote('mercy-multiplied','2020-01')).status).toBe(409); expect((await vote('invented')).status).toBe(400);
 await Promise.all([vote('mercy-multiplied'),vote('mercy-multiplied')]); await vote('sharing-the-mission');
 const rows=await env.DB.prepare('SELECT cause_id FROM community_votes WHERE user_id=?1').bind(userId).all();
 expect(rows.results).toEqual([{cause_id:'sharing-the-mission'}]);
});
it('opens a real production preference ballot without importing legacy fixture choices',async()=>{
 const {userId}=await signInGuest(); const production={...env,APP_ENV:'production'} as Env;
 const current=new Date().toISOString().slice(0,7);
 await env.DB.prepare('INSERT INTO community_votes VALUES(?1,?2,?3,?4)').bind(userId,current,'safe',Date.now()).run();
 const b=await(await getCommunity(production,userId)).json<any>();
 expect(b.causes.map((c:any)=>c.id)).toEqual(['mercy-multiplied','sharing-the-mission','house-of-grace','meninadanca']);
 expect(b.round.id).toBe(current+'-charities-v2'); expect(b.round.preview).toBe(false); expect(b.vote).toBeNull();
 expect(b.ballotNote).toContain('not Her Crown partners');
 const tracker={track:()=>{}} as unknown as Tracker;
 const request=(causeId:string)=>new Request('https://example.org',{method:'PUT',headers:{'content-type':'application/json'},body:JSON.stringify({roundId:b.round.id,causeId})});
 await expect(voteCommunity(request('safe'),production,userId,tracker)).rejects.toMatchObject({status:400});
 expect((await voteCommunity(request('sharing-the-mission'),production,userId,tracker)).status).toBe(200);
 expect((await(await getCommunity(production,userId)).json<any>()).vote).toBe('sharing-the-mission');
});
it('validates suggestions, deduplicates retries, and prevents cross-account reads/edits',async()=>{
 const a=await signInGuest(), b=await signInGuest();
 const post=(body:any)=>api('/me/community/suggestions',{token:a.token,method:'POST',body:JSON.stringify(body)});
 expect((await post({...payload,website:'javascript:alert(1)'})).status).toBe(400);
 const first=await(await post(payload)).json<any>(); const retry=await(await post(payload)).json<any>(); expect(retry.id).toBe(first.id);
 expect((await(await api('/me/community/suggestions',{token:b.token})).json<any>()).suggestions).toEqual([]);
 expect((await api('/me/community/suggestions/'+first.id,{token:b.token,method:'PATCH',body:JSON.stringify(payload)})).status).toBe(404);
 expect((await api('/me/community/suggestions/'+first.id,{token:a.token,method:'PATCH',body:JSON.stringify({...payload,city:'New York'})})).status).toBe(200);
 expect((await(await api('/me/community/suggestions',{token:a.token})).json<any>()).suggestions[0].city).toBe('New York');
});
it('preserves votes, private suggestions and prayer quotas when a guest links an account',async()=>{
 const {moveUserData}=await import('../src/users');
 const a=await signInGuest(),b=await signInGuest(); const round=(await(await api('/me/community',{token:a.token})).json<any>()).round;
 await api('/me/community/vote',{token:a.token,method:'PUT',body:JSON.stringify({roundId:round.id,causeId:'mercy-multiplied'})});
 await api('/me/community/suggestions',{token:a.token,method:'POST',body:JSON.stringify(payload)});
 await env.DB.prepare('INSERT INTO onboarding_prayer_limits(user_id,day,attempts) VALUES(?1,?2,2)').bind(a.userId,'2026-11-08').run();
 await moveUserData(env,a.userId,b.userId);
 expect((await(await api('/me/community',{token:b.token})).json<any>()).vote).toBe('mercy-multiplied');
 expect((await(await api('/me/community/suggestions',{token:b.token})).json<any>()).suggestions).toHaveLength(1);
 expect(await env.DB.prepare('SELECT attempts FROM onboarding_prayer_limits WHERE user_id=?1').bind(b.userId).first()).toEqual({attempts:2});
});
it('deduplicates simultaneous nomination retries and atomically caps submissions',async()=>{
 const {token,userId}=await signInGuest();
 const send=(name:string)=>api('/me/community/suggestions',{token,method:'POST',body:JSON.stringify({...payload,name})});
 const same=await Promise.all([send('Same cause'),send('Same cause')]); expect(same.every(r=>r.ok)).toBe(true);
 expect((await env.DB.prepare('SELECT COUNT(*) AS n FROM community_suggestions WHERE user_id=?1').bind(userId).first<{n:number}>())?.n).toBe(1);
 await Promise.all(Array.from({length:8},(_,i)=>send('Different cause '+i)));
 expect((await env.DB.prepare('SELECT COUNT(*) AS n FROM community_suggestions WHERE user_id=?1').bind(userId).first<{n:number}>())?.n).toBe(5);
});
