export function localDay(date=new Date()){return `${date.getFullYear()}-${String(date.getMonth()+1).padStart(2,'0')}-${String(date.getDate()).padStart(2,'0')}`}
const ordinal=day=>{if(!/^\d{4}-\d{2}-\d{2}$/.test(day))return NaN;const [y,m,d]=day.split('-').map(Number);const date=new Date(Date.UTC(y,m-1,d));return date.toISOString().slice(0,10)===day?date.getTime()/86400000:NaN};
export function streakSummary(days=[],today=localDay()){
 const now=ordinal(today),values=[...new Set(Array.isArray(days)?days:[])].map(ordinal).filter(n=>Number.isFinite(n)&&n<=now).sort((a,b)=>a-b),set=new Set(values);
 let best=0,run=0,previous=-Infinity;for(const n of values){run=n===previous+1?run+1:1;best=Math.max(best,run);previous=n}
 let current=0,start=set.has(now)?now:now-1;while(set.has(start)){current++;start--}
 return {current,best,readToday:set.has(now),week:Array.from({length:7},(_,i)=>{const n=now-6+i;return {day:new Date(n*86400000).toISOString().slice(0,10),read:set.has(n)}})}
}
export function recordDay(days,today=localDay()){return [...new Set([...(Array.isArray(days)?days:[]),today])].filter(d=>Number.isFinite(ordinal(d))).sort()}
