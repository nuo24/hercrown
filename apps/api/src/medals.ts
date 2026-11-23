// Replay verified reading chronologically. Each collection has one active stage;
// a completion day belongs entirely to that stage, never to the next one.
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
export function sequentialMedals(readDays: string[], chapters: ChapterRead[], today: string) {
  const byDay = new Map<string, Set<string>>();
  for (const day of readDays) if (isValidDay(day) && day <= today) byDay.set(day,new Set());
  for (const c of chapters) {
    const total = canon.get(c.book_id);
    if (!total || !Number.isInteger(c.chapter) || c.chapter < 1 || c.chapter > total || !isValidDay(c.local_day) || c.local_day > today) continue;
    if (!byDay.has(c.local_day)) byDay.set(c.local_day,new Set());
    byDay.get(c.local_day)!.add(`${c.book_id}.${c.chapter}`);
  }
  const timeline = [...byDay].sort(([a],[b]) => a.localeCompare(b));
  return goals.flatMap(collection => {
    const stages = collection.map(g => ({id:g.id,days:0,units:0,completedChapterRefs:[] as string[],earned:false}));
    let index=0, days=0;
    let refs = new Set<string>();
    for (const [,completed] of timeline) {
      if (index >= collection.length) break;
      const goal=collection[index], state=stages[index];
      days++;
      for (const ref of completed) refs.add(ref);
      let units: number;
      if (goal.books) {
        units = BOOKS.filter(b => Array.from({length:b[3]},(_,i) => `${b[0]}.${i+1}`).every(r => refs.has(r))).length;
      } else if (goal.refs) units=goal.refs.filter(r => refs.has(r)).length;
      else units=[...refs].filter(r => !goal.book || r.startsWith(goal.book+".")).length;
      state.days=Math.min(days,goal.days);
      state.units=Math.min(units,goal.books ?? goal.chapters ?? goal.refs!.length);
      state.completedChapterRefs=goal.refs?.filter(r => refs.has(r)) ?? [];
      state.earned=state.days===goal.days && state.units===(goal.books ?? goal.chapters ?? goal.refs!.length);
      if (state.earned) { index++; days=0; refs=new Set(); }
    }
    return stages;
  });
}
