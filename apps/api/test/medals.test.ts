import { describe, expect, it } from "vitest";
import { cumulativeMedals, type ChapterRead } from "../src/medals";
const day = (i:number) => new Date(Date.UTC(2026,0,i+1)).toISOString().slice(0,10);
const days = (n:number) => Array.from({length:n},(_,i)=>day(i));
const chapter = (book:string,n:number,d:number):ChapterRead => ({book_id:book,chapter:n,local_day:day(d)});
const stage=(result:ReturnType<typeof cumulativeMedals>,id:string)=>result.find(s=>s.id===id)!;
describe("cumulative concealed medal eligibility",()=>{
 it("counts two days toward every medal without earning or revealing any",()=>{
   const result=cumulativeMedals(days(2),[chapter("GEN",1,0),chapter("GEN",2,1)],day(1));
   expect(result.every(s=>s.days===2&&!s.earned)).toBe(true);
   expect(stage(result,"fruit-0")).toMatchObject({days:2,units:2,earned:false});
   expect(stage(result,"fruit-8")).toMatchObject({days:2,units:2,earned:false});
 });
 it("earns only each reached threshold, without resetting later goals",()=>{
   const refs=Array.from({length:21},(_,i)=>chapter("GEN",i+1,i));
   let r=cumulativeMedals(days(14),refs,day(13));
   expect(stage(r,"fruit-0").earned).toBe(true);
   expect(stage(r,"fruit-1")).toMatchObject({days:14,units:14,earned:false});
   r=cumulativeMedals(days(21),refs,day(20));
   expect(stage(r,"fruit-1")).toMatchObject({days:21,units:21,earned:true});
   expect(stage(r,"fruit-2")).toMatchObject({days:21,units:21,earned:false});
   expect(stage(r,"fruit-8")).toMatchObject({days:21,units:21,earned:false});
 });
 it("requires both days and distinct chapters; rereads never inflate chapter counts",()=>{
   const refs=Array.from({length:14},(_,i)=>chapter("GEN",i+1,0));
   expect(stage(cumulativeMedals(days(13),refs,day(12)),"fruit-0").earned).toBe(false);
   expect(stage(cumulativeMedals(days(14),refs.slice(1),day(13)),"fruit-0").earned).toBe(false);
   expect(stage(cumulativeMedals(days(30),[...refs,...refs,chapter("GEN",1,29)],day(29)),"fruit-1"))
     .toMatchObject({days:21,units:14,earned:false});
 });
 it("counts complete canonical books toward every Armor goal and keeps themed reading separate",()=>{
   const refs=[...Array.from({length:4},(_,i)=>chapter("RUT",i+1,i)),chapter("JUD",1,4),chapter("2JN",1,5)];
   const r=cumulativeMedals(days(30),[...refs,...refs],day(29));
   expect(stage(r,"armor-0").earned).toBe(true);
   expect(stage(r,"armor-1")).toMatchObject({days:30,units:3,earned:true});
   expect(stage(r,"armor-5")).toMatchObject({days:30,units:3,earned:false});
   expect(stage(r,"psalms-1")).toMatchObject({days:30,units:0,earned:false});
   expect(stage(r,"women-0").earned).toBe(true);
   expect(stage(r,"women-1")).toMatchObject({days:30,units:0,earned:false});
 });
 it("ignores duplicate, malformed, future and noncanonical activity",()=>{
   const refs=Array.from({length:50},(_,i)=>chapter("GEN",i+1,0));
   const r=cumulativeMedals([...days(15),...days(15),day(99),"2026-02-30"],
     [...refs,...refs,chapter("BAD",1,14),chapter("RUT",0,14),chapter("RUT",5,14),chapter("RUT",1,99)],day(14));
   expect(stage(r,"fruit-1")).toMatchObject({days:15,units:21,earned:false});
   expect(stage(r,"armor-0")).toMatchObject({days:15,units:1,earned:false});
   expect(stage(r,"promises-0").completedChapterRefs).toEqual(["GEN.6","GEN.7","GEN.8","GEN.9","GEN.12","GEN.15","GEN.17"]);
 });
});
