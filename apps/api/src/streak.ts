// Port of reference-web/dist/streak.mjs. Same semantics: local calendar days, duplicates count once,
// invalid and future days are ignored, and a run stays current when the last read day was yesterday.

export interface StreakSummary {
  current: number;
  best: number;
  readToday: boolean;
  week: { day: string; read: boolean }[];
  milestone: number | null; // highest of 7/30/100/365 reached by the current run
}

const MILESTONES = [365, 100, 30, 7];
const DAY_MS = 86_400_000;

/** "YYYY-MM-DD" → days since the epoch, or NaN when malformed or not a real date (e.g. 2026-02-30). */
export function dayOrdinal(day: string): number {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(day)) return NaN;
  const [y, m, d] = day.split("-").map(Number);
  const date = new Date(Date.UTC(y, m - 1, d));
  return date.toISOString().slice(0, 10) === day ? date.getTime() / DAY_MS : NaN;
}

export const isValidDay = (day: string) => Number.isFinite(dayOrdinal(day));

/** The calendar day for an instant in an IANA time zone. */
export function localDayIn(timeZone: string, at = new Date()): string {
  return new Intl.DateTimeFormat("en-CA", { timeZone, year: "numeric", month: "2-digit", day: "2-digit" }).format(at);
}

export function streakSummary(days: string[], today: string): StreakSummary {
  const now = dayOrdinal(today);
  const values = [...new Set(days)].map(dayOrdinal).filter((n) => Number.isFinite(n) && n <= now).sort((a, b) => a - b);
  const set = new Set(values);

  let best = 0, run = 0, previous = -Infinity;
  for (const n of values) {
    run = n === previous + 1 ? run + 1 : 1;
    best = Math.max(best, run);
    previous = n;
  }

  let current = 0;
  for (let n = set.has(now) ? now : now - 1; set.has(n); n--) current++;

  return {
    current,
    best,
    readToday: set.has(now),
    week: Array.from({ length: 7 }, (_, i) => {
      const n = now - 6 + i;
      return { day: new Date(n * DAY_MS).toISOString().slice(0, 10), read: set.has(n) };
    }),
    milestone: MILESTONES.find((m) => current >= m) ?? null,
  };
}
