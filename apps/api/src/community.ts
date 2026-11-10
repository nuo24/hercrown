import { badRequest, HttpError, readJson } from './http';
import type { Tracker } from './events';

// Owner-reported aggregate, not donations to the nominees below.
export const GIVING = { totalCents: 735000, currency: 'USD', revenuePercent: 30, reportedAt: '2026-11-08' };
// Independent nominees researched from official program and financial/impact pages.
// Listing is not a partnership or a claim that Her Crown has funded this organization.
export const CAUSES = [
 { id: 'mercy-multiplied', name: 'Mercy Multiplied', category: 'United States · Christian care', photo: 'community-safe', summary: 'A place to heal, grow and begin again.', support: 'Mercy Multiplied is a Christian nonprofit offering a voluntary, free residential program for young women ages 13–32, with Bible study, practical support and individual ministry care. It is not a medical facility.', website: 'https://mercymultiplied.com/programs/residential-program/' },
 { id: 'sharing-the-mission', name: 'Sharing the Mission', category: 'Nigeria · Widows & families', photo: 'community-girls', summary: 'Practical care and encouragement, shared in faith.', support: 'Sharing the Mission supports Nigerian Christian partners, including AMEN and Bege for Gobe, in work with widows, displaced families and children. Projects include meals, supplies, education and community support.', website: 'https://sharingthemission.org/participate/' },
 { id: 'house-of-grace', name: 'House of Grace', category: 'Thailand · Girls’ education', photo: 'community-mothers', summary: 'Room for girls to learn and grow.', support: 'House of Grace Thailand is a Global Servants program supporting girls through education, care and Christian discipleship, helping them prepare for further study, work and community life.', website: 'https://www.globalservants.org/thailand' },
 { id: 'meninadanca', name: 'Meninadança', category: 'Brazil · Safety & opportunity', photo: 'community-church', summary: 'A safe place for friendship, confidence and hope.', support: 'Meninadança’s Pink Houses work with girls living in situations of risk along Brazil’s BR-116 highway. Female teams provide activities, conversation circles and support focused on safety, friendship and opportunity.', website: 'https://meninadanca.org/the-pink-houses/' },
];
export const BALLOT_NOTE = 'Your vote helps guide future giving. Final grants depend on recipient checks and available funds. These independent nominees are not Her Crown partners; the donated total is not attributed to them.';

function round() {
 const now = new Date(); const year = now.getUTCFullYear(), month = now.getUTCMonth();
 return { id: `${year}-${String(month + 1).padStart(2, '0')}-charities-v2`, title: new Intl.DateTimeFormat('en-US', { month: 'long', timeZone: 'UTC' }).format(now) + '’s ballot', closesAt: Date.UTC(year, month + 1, 1), preview: false };
}
export async function getCommunity(env: Env, userId: string) {
 const r = round();
 const row = await env.DB.prepare('SELECT cause_id FROM community_votes WHERE user_id = ?1 AND round_id = ?2').bind(userId, r.id).first<{cause_id: string}>();
 return Response.json({ giving: GIVING, round: r, causes: CAUSES, ballotNote: BALLOT_NOTE, vote: row?.cause_id ?? null });
}
export async function voteCommunity(request: Request, env: Env, userId: string, tracker: Tracker) {
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
