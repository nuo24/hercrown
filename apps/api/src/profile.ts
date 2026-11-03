// Profile, avatar, preferences and onboarding completion.
import { entitlementFor } from "./billing";
import type { Tracker } from "./events";
import { badRequest, HttpError, oneOf, optionalText, readJson } from "./http";
import { APPEARANCES, FAMILIARITY, FONT_SIZES, INTENTIONS, ONBOARDING_VERSION, ROUTINES, TOPICS } from "./options";
import { resolveVerse } from "./refs";

export interface SessionUser {
  id: string;
  email: string;
  isAnonymous?: boolean | null;
}

interface ProfileRow {
  display_name: string | null;
  bio: string | null;
  avatar_key: string | null;
  updated_at: number;
}

interface PreferencesRow {
  intention: string | null;
  familiarity: string | null;
  topics: string;
  routine: string | null;
  reminders_enabled: number;
  reminder_time: string;
  time_zone: string | null;
  appearance: string;
  gradient: string | null;
  onboarding_version: number | null;
  onboarding_completed_at: number | null;
  font_size: string;
  words_of_jesus_red: number;
  translation: string;
  widget_ref: string | null;
  position_ref: string | null;
  position_updated_at: number | null;
}

const DEFAULT_PREFERENCES: PreferencesRow = {
  intention: null,
  familiarity: null,
  topics: "[]",
  routine: null,
  reminders_enabled: 0,
  reminder_time: "08:00",
  time_zone: null,
  appearance: "dark",
  gradient: null,
  onboarding_version: null,
  onboarding_completed_at: null,
  font_size: "default",
  words_of_jesus_red: 1,
  translation: "kjv",
  widget_ref: null,
  position_ref: null,
  position_updated_at: null,
};

// ── Reads ───────────────────────────────────────────────────────────────────

async function profileRow(env: Env, userId: string) {
  return env.DB.prepare("SELECT display_name, bio, avatar_key, updated_at FROM profiles WHERE user_id = ?1")
    .bind(userId)
    .first<ProfileRow>();
}

export async function preferencesRow(env: Env, userId: string): Promise<PreferencesRow> {
  const row = await env.DB.prepare(
    `SELECT intention, familiarity, topics, routine, reminders_enabled, reminder_time, time_zone, appearance,
            gradient, onboarding_version, onboarding_completed_at, font_size, words_of_jesus_red, translation, widget_ref,
            position_ref, position_updated_at
     FROM preferences WHERE user_id = ?1`,
  ).bind(userId).first<PreferencesRow>();
  return row ?? DEFAULT_PREFERENCES;
}

const profileJson = (row: ProfileRow | null) => ({
  displayName: row?.display_name ?? null,
  bio: row?.bio ?? null,
  // Private: the client fetches it with its bearer token. `v` busts caches when the photo changes.
  avatarUrl: row?.avatar_key ? `/me/avatar?v=${row.updated_at}` : null,
});

const preferencesJson = (row: PreferencesRow) => ({
  intention: row.intention,
  familiarity: row.familiarity,
  topics: JSON.parse(row.topics) as string[],
  routine: row.routine,
  remindersEnabled: row.reminders_enabled === 1,
  reminderTime: row.reminder_time,
  timeZone: row.time_zone,
  appearance: row.appearance,
  gradient: row.gradient ? JSON.parse(row.gradient) : null,
  fontSize: row.font_size,
  wordsOfJesusInRed: row.words_of_jesus_red === 1,
  translation: row.translation,
  widgetRef: row.widget_ref,
  position: row.position_ref ? { ref: row.position_ref, updatedAt: row.position_updated_at } : null,
});

const onboardingJson = (row: PreferencesRow) => ({
  completed: row.onboarding_completed_at !== null,
  completedAt: row.onboarding_completed_at,
  version: row.onboarding_version,
});

/** Everything the app needs at launch in one call. */
export async function getMe(env: Env, user: SessionUser) {
  const [profile, prefs, membership] = await Promise.all([
    profileRow(env, user.id), preferencesRow(env, user.id), entitlementFor(env, user.id),
  ]);
  return Response.json({
    user: { id: user.id, isAnonymous: Boolean(user.isAnonymous), email: user.isAnonymous ? null : user.email },
    profile: profileJson(profile),
    preferences: preferencesJson(prefs),
    onboarding: onboardingJson(prefs),
    membership,
  });
}

// ── Profile ─────────────────────────────────────────────────────────────────

export async function updateProfile(request: Request, env: Env, user: SessionUser) {
  const body = await readJson(request);
  const displayName = optionalText(body, "displayName", 40);
  const bio = optionalText(body, "bio", 180);
  if (body.displayName !== undefined && !displayName) throw badRequest("displayName cannot be empty");

  const current = await profileRow(env, user.id);
  const next = {
    display_name: displayName === undefined ? current?.display_name ?? null : displayName,
    bio: bio === undefined ? current?.bio ?? null : bio,
  };
  await env.DB.prepare(
    `INSERT INTO profiles (user_id, display_name, bio, updated_at) VALUES (?1, ?2, ?3, ?4)
     ON CONFLICT (user_id) DO UPDATE SET display_name = ?2, bio = ?3, updated_at = ?4`,
  ).bind(user.id, next.display_name, next.bio, Date.now()).run();
  return Response.json(profileJson(await profileRow(env, user.id)));
}

// ── Avatar (private R2 object) ──────────────────────────────────────────────

const MAX_AVATAR_BYTES = 10 * 1024 * 1024;

/** Detects the image type from its first bytes; the Content-Type header alone is not trusted. */
function sniffImage(bytes: Uint8Array): { type: string; ext: string } | null {
  if (bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff) return { type: "image/jpeg", ext: "jpg" };
  if (bytes[0] === 0x89 && bytes[1] === 0x50 && bytes[2] === 0x4e && bytes[3] === 0x47) return { type: "image/png", ext: "png" };
  const ascii = (from: number, to: number) => String.fromCharCode(...bytes.subarray(from, to));
  if (ascii(0, 4) === "RIFF" && ascii(8, 12) === "WEBP") return { type: "image/webp", ext: "webp" };
  return null;
}

export async function putAvatar(request: Request, env: Env, user: SessionUser) {
  const declared = Number(request.headers.get("content-length") ?? 0);
  if (declared > MAX_AVATAR_BYTES) throw new HttpError(413, "too_large", "Photo must be 10 MB or smaller");
  const bytes = new Uint8Array(await request.arrayBuffer());
  if (bytes.byteLength === 0) throw badRequest("Photo is empty");
  if (bytes.byteLength > MAX_AVATAR_BYTES) throw new HttpError(413, "too_large", "Photo must be 10 MB or smaller");
  const image = sniffImage(bytes);
  if (!image) throw new HttpError(415, "unsupported_media_type", "Photo must be a JPG, PNG or WebP image");

  const previous = (await profileRow(env, user.id))?.avatar_key;
  const key = `avatars/${user.id}/${crypto.randomUUID()}.${image.ext}`;
  await env.FILES.put(key, bytes, { httpMetadata: { contentType: image.type } });
  await env.DB.prepare(
    `INSERT INTO profiles (user_id, avatar_key, updated_at) VALUES (?1, ?2, ?3)
     ON CONFLICT (user_id) DO UPDATE SET avatar_key = ?2, updated_at = ?3`,
  ).bind(user.id, key, Date.now()).run();
  if (previous) await env.FILES.delete(previous);
  return Response.json(profileJson(await profileRow(env, user.id)));
}

export async function getAvatar(env: Env, user: SessionUser) {
  const key = (await profileRow(env, user.id))?.avatar_key;
  const object = key ? await env.FILES.get(key) : null;
  if (!object) return Response.json({ error: "not_found", message: "No profile photo" }, { status: 404 });
  return new Response(object.body, {
    headers: {
      "content-type": object.httpMetadata?.contentType ?? "application/octet-stream",
      "cache-control": "private, max-age=86400",
      etag: object.httpEtag,
    },
  });
}

export async function deleteAvatar(env: Env, user: SessionUser) {
  const key = (await profileRow(env, user.id))?.avatar_key;
  if (key) {
    await env.DB.prepare("UPDATE profiles SET avatar_key = NULL, updated_at = ?2 WHERE user_id = ?1")
      .bind(user.id, Date.now()).run();
    await env.FILES.delete(key);
  }
  return Response.json(profileJson(await profileRow(env, user.id)));
}

// ── Preferences ─────────────────────────────────────────────────────────────

const HEX = /^#[0-9a-fA-F]{6}$/;
const TIME = /^([01]\d|2[0-3]):[0-5]\d$/;

function isTimeZone(value: string) {
  try {
    new Intl.DateTimeFormat("en-US", { timeZone: value });
    return true;
  } catch {
    return false;
  }
}

/** Shape of reference-web/dist/gradient-theme.js settings. */
function parseGradient(value: unknown): string | null {
  if (value === null) return null;
  const g = value as Record<string, unknown>;
  const pct = (n: unknown) => typeof n === "number" && Number.isFinite(n) && n >= 0 && n <= 100;
  const ok =
    g && typeof g === "object" && !Array.isArray(g) &&
    Array.isArray(g.colors) && g.colors.length === 3 && g.colors.every((c) => typeof c === "string" && HEX.test(c)) &&
    typeof g.third === "boolean" && pct(g.intensity) && pct(g.spread) &&
    typeof g.angle === "number" && Number.isFinite(g.angle) && g.angle >= 0 && g.angle <= 360;
  if (!ok) throw badRequest("gradient must be { colors: [3 hex colors], third: boolean, intensity: 0-100, spread: 0-100, angle: 0-360 }");
  return JSON.stringify({ colors: g.colors, third: g.third, intensity: g.intensity, spread: g.spread, angle: g.angle });
}

/**
 * Partial update: only fields present in the body change; `null` clears an answer.
 * Onboarding completion is not editable here, so Settings can never reset it.
 */
export async function updatePreferences(request: Request, env: Env, user: SessionUser) {
  const body = await readJson(request);
  const next = { ...(await preferencesRow(env, user.id)) };

  const intention = oneOf(body, "intention", INTENTIONS);
  if (intention !== undefined) next.intention = intention;
  const familiarity = oneOf(body, "familiarity", FAMILIARITY);
  if (familiarity !== undefined) next.familiarity = familiarity;
  const routine = oneOf(body, "routine", ROUTINES);
  if (routine !== undefined) next.routine = routine;
  const appearance = oneOf(body, "appearance", APPEARANCES);
  if (appearance) next.appearance = appearance;

  if (body.topics !== undefined) {
    const topics = body.topics;
    if (!Array.isArray(topics) || !topics.every((t) => TOPICS.includes(t))) {
      throw badRequest(`topics must be an array of: ${TOPICS.join(", ")}`);
    }
    next.topics = JSON.stringify(TOPICS.filter((t) => topics.includes(t))); // dedupe, canonical order
  }
  if (body.remindersEnabled !== undefined) {
    if (typeof body.remindersEnabled !== "boolean") throw badRequest("remindersEnabled must be a boolean");
    next.reminders_enabled = body.remindersEnabled ? 1 : 0;
  }
  if (body.reminderTime !== undefined) {
    if (typeof body.reminderTime !== "string" || !TIME.test(body.reminderTime)) throw badRequest("reminderTime must be HH:MM (24-hour)");
    next.reminder_time = body.reminderTime;
  }
  if (body.timeZone !== undefined) {
    if (typeof body.timeZone !== "string" || !isTimeZone(body.timeZone)) throw badRequest("timeZone must be an IANA time zone, e.g. America/Chicago");
    next.time_zone = body.timeZone;
  }
  if (body.gradient !== undefined) next.gradient = parseGradient(body.gradient);
  const fontSize = oneOf(body, "fontSize", FONT_SIZES);
  if (fontSize) next.font_size = fontSize;
  if (body.wordsOfJesusInRed !== undefined) {
    if (typeof body.wordsOfJesusInRed !== "boolean") throw badRequest("wordsOfJesusInRed must be a boolean");
    next.words_of_jesus_red = body.wordsOfJesusInRed ? 1 : 0;
  }
  if (body.translation !== undefined) {
    const known = typeof body.translation === "string"
      ? await env.DB.prepare("SELECT id FROM translations WHERE id = ?1 AND enabled = 1").bind(body.translation).first()
      : null;
    if (!known) throw badRequest("translation must be an available translation id (see /scripture/translations)");
    next.translation = body.translation as string;
  }
  if (body.widgetRef !== undefined) {
    if (body.widgetRef === null) next.widget_ref = null;
    else if (typeof body.widgetRef !== "string") throw badRequest("widgetRef must be a verse reference or null");
    else next.widget_ref = await resolveVerse(env.DB, body.widgetRef);
  }

  await writePreferences(env, user.id, next);
  return Response.json(preferencesJson(next));
}

async function writePreferences(env: Env, userId: string, p: PreferencesRow) {
  await env.DB.prepare(
    `INSERT INTO preferences (user_id, intention, familiarity, topics, routine, reminders_enabled, reminder_time,
       time_zone, appearance, gradient, onboarding_version, onboarding_completed_at, updated_at)
     VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12, ?13)
     ON CONFLICT (user_id) DO UPDATE SET
       intention = ?2, familiarity = ?3, topics = ?4, routine = ?5, reminders_enabled = ?6, reminder_time = ?7,
       time_zone = ?8, appearance = ?9, gradient = ?10, updated_at = ?13`,
  ).bind(
    userId, p.intention, p.familiarity, p.topics, p.routine, p.reminders_enabled, p.reminder_time,
    p.time_zone, p.appearance, p.gradient, p.onboarding_version, p.onboarding_completed_at, Date.now(),
  ).run();
  await env.DB.prepare(
    "UPDATE preferences SET font_size = ?2, words_of_jesus_red = ?3, translation = ?4, widget_ref = ?5 WHERE user_id = ?1",
  ).bind(userId, p.font_size, p.words_of_jesus_red, p.translation, p.widget_ref).run();
}


/**
 * PUT /me/position { ref }: the reader's bookmark (where she left off). A chapter ("JHN.3.1") or verse. Last write wins,
 * but an older position from a slower device never overwrites a newer one (`at`, client ms).
 */
export async function savePosition(request: Request, env: Env, user: SessionUser) {
  const body = await readJson(request);
  if (typeof body.ref !== "string") throw badRequest("ref is required");
  const ref = await resolveVerse(env.DB, body.ref);
  const at = typeof body.at === "number" && Number.isFinite(body.at) ? Math.min(body.at, Date.now()) : Date.now();
  await env.DB.prepare(
    `INSERT INTO preferences (user_id, position_ref, position_updated_at, updated_at) VALUES (?1, ?2, ?3, ?3)
     ON CONFLICT (user_id) DO UPDATE SET position_ref = ?2, position_updated_at = ?3, updated_at = ?3
     WHERE COALESCE(preferences.position_updated_at, 0) <= ?3`,
  ).bind(user.id, ref, at).run();
  const row = await preferencesRow(env, user.id);
  return Response.json({ position: { ref: row.position_ref, updatedAt: row.position_updated_at } });
}

// ── Onboarding ──────────────────────────────────────────────────────────────

/** Marks onboarding complete. Idempotent: the first completion time is kept. There is no "uncomplete". */
export async function completeOnboarding(env: Env, user: SessionUser, tracker?: Tracker) {
  const t = Date.now();
  await env.DB.prepare(
    `INSERT INTO preferences (user_id, onboarding_version, onboarding_completed_at, updated_at) VALUES (?1, ?2, ?3, ?3)
     ON CONFLICT (user_id) DO UPDATE SET
       onboarding_version = ?2,
       onboarding_completed_at = COALESCE(preferences.onboarding_completed_at, ?3),
       updated_at = ?3`,
  ).bind(user.id, ONBOARDING_VERSION, t).run();
  const row = await preferencesRow(env, user.id);
  if (row.onboarding_completed_at === t) {
    // First completion only; the id also makes it count once per person across a guest → account link.
    tracker?.track("onboarding_completed", { version: ONBOARDING_VERSION }, { id: (person) => `onboarding_completed:${person}`, at: t });
  }
  return Response.json(onboardingJson(row));
}
