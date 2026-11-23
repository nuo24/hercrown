import { describe, expect, it } from "vitest";
import { sequentialMedals, type ChapterRead } from "../src/medals";
const day = (i:number) => new Date(Date.UTC(2026,0,i+1)).toISOString().slice(0,10);
const days = (n:number,start=0) => Array.from({length:n},(_,i)=>day(i+start));
const chapter = (book:string,n:number,d:number):ChapterRead => ({book_id:book,chapter:n,local_day:day(d)});
const stage=(result:ReturnType<typeof sequentialMedals>,id:string)=>result.find(s=>s.id===id)!;
describe("sequential medal stages",()=>{
 it("one chapter starts only the first goal in every collection",()=>{
   const result=sequentialMedals([day(0)],[chapter("GEN",1,0)],day(0));
   for(const prefix of ["fruit","armor","psalms","women","promises"]){
     expect(stage(result,`${prefix}-0`).days).toBe(1);
     expect(result.filter(s=>s.id.startsWith(prefix)&&s.id!==`${prefix}-0`).every(s=>s.days===0&&s.units===0&&!s.earned)).toBe(true);
   }
 });
 it("14 days/chapters earn Love; Joy requires 21 fresh days/chapters, without rollover",()=>{
   const first=Array.from({length:14},(_,i)=>chapter("GEN",i+1,i));
   // Extra reading on the award day must not spill into Joy.
   first.push(chapter("GEN",50,13));
   let r=sequentialMedals(days(14),first,day(13));
   expect(stage(r,"fruit-0").earned).toBe(true);
   expect(stage(r,"fruit-1")).toMatchObject({days:0,units:0,earned:false});
   const second=Array.from({length:21},(_,i)=>chapter("GEN",i+1,i+14)); // genuine rereading qualifies in a fresh stage
   r=sequentialMedals(days(34),[...first,...second],day(33));
   expect(stage(r,"fruit-1")).toMatchObject({days:20,units:20,earned:false});
   r=sequentialMedals(days(35),[...first,...second,...second],day(34));
   expect(stage(r,"fruit-1")).toMatchObject({days:21,units:21,earned:true});
   expect(stage(r,"fruit-2")).toMatchObject({days:0,units:0,earned:false});
 });
 it("Armor needs complete books reread in its own stage, not totals carried from Belt",()=>{
   const ruth=Array.from({length:4},(_,i)=>chapter("RUT",i+1,i));
   let r=sequentialMedals(days(22),ruth,day(21));
   expect(stage(r,"armor-0").earned).toBe(true);
   expect(stage(r,"armor-1")).toMatchObject({days:1,units:0,earned:false});
   const reread=[...Array.from({length:4},(_,i)=>chapter("RUT",i+1,21+i)),chapter("JUD",1,25),chapter("2JN",1,26)];
   r=sequentialMedals(days(51),[...ruth,...reread],day(50));
   expect(stage(r,"armor-1")).toMatchObject({days:30,units:3,earned:true});
   expect(stage(r,"armor-2")).toMatchObject({days:0,units:0,earned:false});
 });
 it("does not bank pre-stage chapters, duplicates, invalid books/chapters or future activity",()=>{
   const refs=Array.from({length:50},(_,i)=>chapter("GEN",i+1,0));
   const r=sequentialMedals([...days(15),day(99)], [...refs,...refs,chapter("BAD",1,14),chapter("RUT",0,14),chapter("RUT",5,14),chapter("RUT",1,99)],day(14));
   expect(stage(r,"fruit-0").earned).toBe(true);
   expect(stage(r,"fruit-1")).toMatchObject({days:1,units:0,earned:false});
   expect(stage(r,"armor-0")).toMatchObject({days:15,units:1,earned:false});
 });
});
