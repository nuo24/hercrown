import {localDay} from './streak.mjs';
const DAY=86400000;
function ordinal(value){if(typeof value!=='string'||!/^\d{4}-\d{2}-\d{2}$/.test(value))return NaN;const [y,m,d]=value.split('-').map(Number),n=Date.UTC(y,m-1,d);return new Date(n).toISOString().slice(0,10)===value?n/DAY:NaN}
const iso=n=>new Date(n*DAY).toISOString().slice(0,10);
const fmt=(n,options)=>new Date(n*DAY).toLocaleDateString('en-US',{timeZone:'UTC',...options});
export function readingActivity(days=[],months=6,today=localDay()){
 const end=ordinal(today);if(!Number.isFinite(end))throw new Error('Invalid activity end date');
 if(![6,12].includes(months))throw new Error('Activity range must be 6 or 12 months');
 const date=new Date(end*DAY),y=date.getUTCFullYear(),m=date.getUTCMonth()-months;
 const target=new Date(Date.UTC(y,m,1)),last=new Date(Date.UTC(target.getUTCFullYear(),target.getUTCMonth()+1,0)).getUTCDate();
 const start=Date.UTC(target.getUTCFullYear(),target.getUTCMonth(),Math.min(date.getUTCDate(),last))/DAY+1;
 const monday=start-((new Date(start*DAY).getUTCDay()+6)%7),lastSunday=end+(6-((new Date(end*DAY).getUTCDay()+6)%7));
 const valid=new Set((Array.isArray(days)?days:[]).map(ordinal).filter(n=>Number.isFinite(n)&&n>=start&&n<=end));
 const weeks=[];let best=0,run=0;
 for(let n=start;n<=end;n++){run=valid.has(n)?run+1:0;best=Math.max(best,run)}
 for(let n=monday;n<=lastSunday;n+=7){weeks.push(Array.from({length:7},(_,i)=>{const value=n+i;return{day:iso(value),inside:value>=start&&value<=end,read:valid.has(value),today:value===end}}))}
 return{start:iso(start),end:today,totalDays:end-start+1,readDays:valid.size,best,percent:Math.round(valid.size/(end-start+1)*100),weeks};
}
export function renderStreakActivity(days,range,weekHTML,today=localDay()){
 const tabs=`<div class="rhythm-ranges" role="group" aria-label="Reading activity period">${[['week','Week'],['6','6 months']].map(([id,label])=>`<button type="button" data-nr="streak-range" data-range="${id}" aria-pressed="${range===id}" class="${range===id?'selected':''}">${label}</button>`).join('')}</div>`;
 if(range==='week')return tabs+weekHTML;
 const activity=readingActivity(days,Number(range),today),start=ordinal(activity.start),end=ordinal(activity.end);
 const panels=range==='12'?[activity.weeks.slice(0,26),activity.weeks.slice(26)]:[activity.weeks];
 const calendars=panels.map(weeks=>{let previousMonth='';const labels=weeks.map((week,index)=>{const first=week.find(x=>x.inside),month=first?first.day.slice(0,7):'';const label=month&&month!==previousMonth?fmt(ordinal(first.day),{month:'short'}):'';previousMonth=month;return `<span class="${index>weeks.length-4?'near-edge':''}">${label}</span>`}).join('');
 const grid=weeks.map(week=>`<div class="activity-week">${week.map(day=>`<span class="activity-cell ${!day.inside?'outside':day.read?'read':'unread'} ${day.today?'today':''}" ${day.inside?`title="${fmt(ordinal(day.day),{weekday:'short',month:'short',day:'numeric',year:'numeric'})}: ${day.read?'Reading complete':'No reading recorded'}"`:''}></span>`).join('')}</div>`).join('');
 return `<div class="activity-calendar"><div class="activity-weekdays" aria-hidden="true">${['M','','W','','F','',''].map(x=>`<span>${x}</span>`).join('')}</div><div class="activity-grid" style="--weeks:${weeks.length}" role="img" aria-label="${activity.readDays} reading days in the selected period. Filled squares mean a reading day; empty squares mean no reading recorded."><div class="activity-months" aria-hidden="true">${labels}</div><div class="activity-map" aria-hidden="true">${grid}</div></div></div>`}).join('');
 return `${tabs}<section class="rhythm-activity" aria-label="${range==='12'?'One year':'Six months'} of reading activity"><div class="activity-period"><span>${fmt(start,{month:'short',day:'numeric',year:'numeric'})} – ${fmt(end,{month:'short',day:'numeric',year:'numeric'})}</span></div><div class="activity-panels">${calendars}</div><div class="activity-legend"><span><i></i>No reading recorded</span><span><i class="read"></i>Read</span></div><p class="activity-scroll-hint">Each square is one day.</p><div class="activity-stats"><div><strong>${activity.readDays}</strong><span>Reading days</span></div><div><strong>${activity.best}</strong><span>Best streak in period</span></div><div><strong>${activity.percent}%</strong><span>Days with reading</span></div></div>${activity.readDays?'':'<p class="activity-empty">No reading days recorded in this period yet.</p>'}</section>`;
}
