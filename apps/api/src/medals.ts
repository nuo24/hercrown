// All milestones share verified lifetime activity; each keeps its own full threshold.
import { BOOKS } from "./refs";
import { isValidDay } from "./streak";

type Goal = { id: string; days: number; chapters?: number; books?: number; book?: string; refs?: string[] };
export type ChapterRead = { book_id: string; chapter: number; local_day: string };
const goals: Goal[][] = [
  [14,21,30,45,60,90,120,180,365].map((n,i) => ({id:`fruit-${i}`,days:n,chapters:n})),
  [21,30,45,60,90,180].map((n,i) => ({id:`armor-${i}`,days:n,books:[1,3,5,10,20,40][i]})),
  [30,90,180].map((n,i) => ({id:`psalms-${i}`,days:n,chapters:[30,75,150][i],book:"PSA"})),
  [30,60,90].map((n,i) => ({id:`women-${i}`,days:n,chapters:[4,10,24][i],book:["RUT","EST","LUK"][i]})),
  [{"id": "promises-0", "days": 60, "refs": ["GEN.6", "GEN.7", "GEN.8", "GEN.9", "GEN.12", "GEN.15", "GEN.17", "ISA.40", "ISA.41", "ISA.43", "LAM.3", "ROM.8", "2CO.1", "HEB.6"]}, {"id": "promises-1", "days": 120, "refs": ["HEB.6", "HEB.10", "HEB.11", "HEB.12", "ROM.5", "ROM.8", "ROM.15", "PSA.42", "PSA.62", "PSA.121", "PSA.130", "ISA.25", "ISA.40", "JHN.14", "1PE.1", "REV.21"]}, {"id": "promises-2", "days": 365, "refs": ["PSA.4", "PSA.23", "PSA.29", "PSA.46", "PSA.85", "PSA.131", "ISA.26", "ISA.32", "ISA.54", "MAT.5", "MAT.6", "MAT.11", "JHN.14", "JHN.16", "ROM.12", "ROM.14", "PHP.4", "COL.3", "2TH.3"]}]
];
const canon = new Map(BOOKS.map(b => [b[0], b[3]]));
export function cumulativeMedals(readDays: string[], chapters: ChapterRead[], today: string) {
  const byDay = new Map<string, Set<string>>();
  for (const day of readDays) if (isValidDay(day) && day <= today) byDay.set(day,new Set());
  for (const c of chapters) {
    const total = canon.get(c.book_id);
    if (!total || !Number.isInteger(c.chapter) || c.chapter < 1 || c.chapter > total || !isValidDay(c.local_day) || c.local_day > today) continue;
    if (!byDay.has(c.local_day)) byDay.set(c.local_day,new Set());
    byDay.get(c.local_day)!.add(`${c.book_id}.${c.chapter}`);
  }
  const refs = new Set([...byDay.values()].flatMap(completed => [...completed]));
  const books = BOOKS.filter(b => Array.from({length:b[3]},(_,i) => `${b[0]}.${i+1}`).every(r => refs.has(r))).length;
  return goals.flat().map(goal => {
    const target = goal.books ?? goal.chapters ?? goal.refs!.length;
    const matched = goal.refs?.filter(r => refs.has(r)) ?? [];
    const completed = goal.books ? books : goal.refs ? matched.length
      : [...refs].filter(r => !goal.book || r.startsWith(goal.book+".")).length;
    const days = Math.min(byDay.size, goal.days);
    const units = Math.min(completed, target);
    return {id:goal.id, days, units, completedChapterRefs:matched,
      earned:days === goal.days && units === target};
  });
}
