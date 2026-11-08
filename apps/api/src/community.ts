import { badRequest, HttpError, readJson } from './http';
import type { Tracker } from './events';

// Owner confirmed these giving figures on November 8. The gallery remains a staging ballot
// until recipient identities and grants are approved; no prototype votes are imported.
export const GIVING = { totalCents: 735000, currency: 'USD', revenuePercent: 30, reportedAt: '2026-11-08' };
export const CAUSES = [
 { id: 'safe', name: 'Her Safe Place', category: 'Safety & a fresh start', photo: 'community-safe', summary: 'A safe place to land. A chance to begin again.', support: 'Emergency accommodation, practical essentials, and one-to-one support as women rebuild their lives.' },
 { id: 'girls', name: 'Open Doors for Girls', category: 'Education & opportunity', photo: 'community-girls', summary: 'Help a girl stay in school and see a bigger future.', support: 'School supplies, transport assistance, and mentoring that helps girls keep learning.' },
 { id: 'mothers', name: 'The Motherhood Fund', category: 'Care for mothers', photo: 'community-mothers', summary: 'Care for the woman who cares for everyone.', support: 'Baby essentials, meals, and a network of local support.' },
 { id: 'church', name: 'Grace Church Pantry', category: 'Local church outreach', photo: 'community-church', summary: 'Practical care for women and families in the neighborhood.', support: 'Community meals, essential groceries, and women’s support gatherings led by local volunteers.' },
];
function round() {
 const now = new Date(); const year = now.getUTCFullYear(), month = now.getUTCMonth();
 return { id: `${year}-${String(month + 1).padStart(2, '0')}`, title: new Intl.DateTimeFormat('en-US', { month: 'long', timeZone: 'UTC' }).format(now) + '’s ballot', closesAt: Date.UTC(year, month + 1, 1), preview: true };
}
export async function getCommunity(env: Env, userId: string) {
 const r = round();
 const row = await env.DB.prepare('SELECT cause_id FROM community_votes WHERE user_id = ?1 AND round_id = ?2').bind(userId, r.id).first<{cause_id: string}>();
 return Response.json({ giving: GIVING, round: env.APP_ENV === 'production' ? null : r, causes: env.APP_ENV === 'production' ? [] : CAUSES, vote: row?.cause_id ?? null });
}
export async function voteCommunity(request: Request, env: Env, userId: string, tracker: Tracker) {
 if (env.APP_ENV === 'production') throw new HttpError(409, 'ballot_unavailable', 'This ballot is not open yet.');
 const body = await readJson(request); const r = round();
 if (body.roundId !== r.id) throw new HttpError(409, 'round_changed', 'The ballot has changed. Refresh and choose again.');
 if (!CAUSES.some(c => c.id === body.causeId)) throw badRequest('Choose a cause from this ballot');
 const changed = await env.DB.prepare(`INSERT INTO community_votes(user_id,round_id,cause_id,updated_at) VALUES(?1,?2,?3,?4)
 ON CONFLICT(user_id,round_id) DO UPDATE SET cause_id=excluded.cause_id,updated_at=excluded.updated_at WHERE cause_id <> excluded.cause_id RETURNING cause_id`).bind(userId,r.id,body.causeId,Date.now()).first();
 if (changed) tracker.track('community_vote_saved', { cause_id: String(body.causeId), round_id: r.id });
 return Response.json({ vote: body.causeId, roundId: r.id });
}
export async function listSuggestions(env: Env, userId: string) {
 const { results } = await env.DB.prepare('SELECT id,name,type,city,website,reason,status FROM community_suggestions WHERE user_id = ?1 ORDER BY created_at DESC LIMIT 100').bind(userId).all();
 return Response.json({ suggestions: results });
}
export async function saveSuggestion(request: Request, env: Env, userId: string, tracker: Tracker, id?: string) {
 const body = await readJson(request);
 const field = (key: string, max: number, min = 0) => {
  const v = body[key] ?? ''; if (typeof v !== 'string' || v.length > max || v.trim().length < min || /[\x00-\x08\x0e-\x1f]/.test(v)) throw badRequest(`Check ${key}`); return v.trim();
 };
 const name = field('name',90,2), type = field('type',30), city = field('city',90), website = field('website',500), reason = field('reason',500,10);
 if (!['Charity','Local church','Community project'].includes(type)) throw badRequest('Choose a cause type');
 if (website) { try { const u = new URL(website); if (!['http:','https:'].includes(u.protocol) || u.username || u.password) throw 0; } catch { throw badRequest('Enter a full http or https website'); } }
 const now = Date.now();
 if (id) {
  const result = await env.DB.prepare(`UPDATE community_suggestions SET name=?1,type=?2,city=?3,website=?4,reason=?5,updated_at=?6 WHERE id=?7 AND user_id=?8 AND status='submitted' RETURNING id`).bind(name,type,city,website,reason,now,id,userId).first();
  if (!result) throw new HttpError(404,'not_found','This suggestion is unavailable or already in review.');
 } else {
  const recent = await env.DB.prepare('SELECT COUNT(*) AS n FROM community_suggestions WHERE user_id=?1 AND created_at>?2').bind(userId,now-86400000).first<{n:number}>();
  if ((recent?.n ?? 0) >= 5) throw new HttpError(429,'suggestion_limit','You can suggest another cause tomorrow.');
  const duplicate = await env.DB.prepare('SELECT id FROM community_suggestions WHERE user_id=?1 AND lower(name)=lower(?2) AND lower(city)=lower(?3) AND created_at>?4').bind(userId,name,city,now-86400000).first<{id:string}>();
  if (duplicate) return Response.json({ id: duplicate.id });
  const key = new TextEncoder().encode(JSON.stringify([userId,new Date(now).toISOString().slice(0,10),name.toLowerCase(),city.toLowerCase()]));
  id = Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',key)),v=>v.toString(16).padStart(2,'0')).join('');
  const inserted = await env.DB.prepare(`INSERT OR IGNORE INTO community_suggestions(id,user_id,name,type,city,website,reason,created_at,updated_at)
    SELECT ?1,?2,?3,?4,?5,?6,?7,?8,?8 WHERE (SELECT COUNT(*) FROM community_suggestions WHERE user_id=?2 AND created_at>?9) < 5 RETURNING id`).bind(id,userId,name,type,city,website,reason,now,now-86400000).first();
  if (!inserted) {
   const prior = await env.DB.prepare('SELECT id FROM community_suggestions WHERE id=?1 AND user_id=?2').bind(id,userId).first();
   if (!prior) throw new HttpError(429,'suggestion_limit','You can suggest another cause tomorrow.');
   return Response.json({id});
  }
 }
 tracker.track('community_cause_suggested', {}); // Personal nomination fields never go to analytics.
 return Response.json({ id });
}
