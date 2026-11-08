let timers=[],lastPage=null;
let settle=()=>{};
const reduced=()=>matchMedia('(prefers-reduced-motion: reduce)').matches;
function later(fn,ms){timers.push(setTimeout(fn,ms))}
function clear(){timers.forEach(clearTimeout);timers=[];lastPage?.getAnimations({subtree:true}).forEach(a=>a.cancel());}
function haptic(){if(document.hidden||reduced())return;try{window.webkit?.messageHandlers?.herCrownHaptics?.postMessage({style:'selection'})}catch{}}
export function resetOnboardingMotion(){clear();lastPage=null}
export function mountOnboardingMotion(root,step){
const page=root.querySelector('.screen');if(!page)return;
if(page===lastPage)return;clear();lastPage=page;
const lead=page.querySelector('.question-lead'),body=page.querySelector('.question-body');
if(reduced()){lead?.remove();return}
page.classList.add('onboarding-motion');
page.querySelectorAll('.intro-art img').forEach((image,index)=>image.style.animationDelay=`${index*140}ms`);
if(page.classList.contains('welcome')){const collage=document.createElement('div');collage.className='welcome-motion-art';collage.setAttribute('aria-hidden','true');for(let i=0;i<7;i++){const part=document.createElement('i');part.className=`welcome-art-piece piece-${i}`;collage.append(part)}page.prepend(collage)}
function type(el,start,speed=48){if(!el)return start;const original=el.innerHTML;const label=document.createElement('span');label.innerHTML=original.replace(/<br\s*\/?\s*>/gi,' ');el.setAttribute('aria-label',label.textContent);let count=0;const walker=document.createTreeWalker(el,NodeFilter.SHOW_TEXT),nodes=[];while(walker.nextNode())nodes.push(walker.currentNode);
for(const node of nodes){const frag=document.createDocumentFragment();for(const token of node.textContent.split(/(\s+)/)){if(!token)continue;if(/^\s+$/.test(token)){frag.append(document.createTextNode(token));continue}const word=document.createElement('span');word.className='onboarding-word';word.setAttribute('aria-hidden','true');for(const char of Array.from(token)){const span=document.createElement('span');span.textContent=char;span.style.visibility='hidden';const i=count++;later(()=>{if(page.isConnected){span.style.visibility='visible';if(i%4===0)haptic()}},start+i*speed);word.append(span)}frag.append(word)}node.replaceWith(frag)}const end=start+count*speed;later(()=>{if(page.isConnected){el.innerHTML=original;el.removeAttribute('aria-label')}},end+60);return end;}
const actions=page.querySelector('.actions');
const gated=!!body||!!lead||step===1||step===13;
const answers=Array.from(page.querySelectorAll('.question-body>.sub,.choices,.chips,.input-dock,.limit,.reminder,.reminder-preview'));
function showAnswers(visible){for(const el of answers){el.style.visibility=visible?'visible':'hidden';el.inert=!visible;el.setAttribute('aria-hidden',String(!visible));}}
showAnswers(false);
function gate(locked){if(!actions)return;actions.style.visibility=locked?'hidden':'visible';actions.inert=locked;actions.setAttribute('aria-hidden',String(locked));}
function finish(){showAnswers(true);page.querySelectorAll('[inert]').forEach(e=>e.inert=false);page.querySelectorAll('[style*="visibility"]').forEach(e=>e.style.visibility='visible');lead?.remove();if(body){body.inert=false;body.style.visibility='visible';body.style.opacity='1';body.style.transform='none';}gate(false);}
settle=finish;
if(gated)gate(true);
let start=220;
if(lead){
 body.style.visibility='hidden';body.inert=true;
 const leadEnd=type(lead,start);
 const exit=leadEnd+650;
 later(()=>{if(page.isConnected)lead.animate([{opacity:1,transform:'translateY(0)'},{opacity:0,transform:'translateY(-12px)'}],{duration:240,easing:'ease-out',fill:'forwards'})},exit);
 start=exit+260;
 later(()=>{if(!page.isConnected)return;lead.remove();body.style.visibility='visible';body.inert=false;body.animate([{opacity:0,transform:'translateY(10px)'},{opacity:1,transform:'translateY(0)'}],{duration:280,easing:'cubic-bezier(.22,1,.36,1)'})},start);
}
const end=type(page.querySelector('h2'),start);
later(()=>{if(!page.isConnected)return;showAnswers(true);for(const el of answers)el.animate([{opacity:0},{opacity:1}],{duration:220,easing:'ease-out'});},end+80);
let completed=end+100;
const bridge=page.querySelector('.cost-bridge');
if(bridge){
 const bridgeStart=end+1200;
 if(page.classList.contains('scroll-intro')){
  later(()=>{if(!page.isConnected)return;
   const illustration=page.querySelector('.intro-art'),heading=page.querySelector('h2');
   for(const el of [illustration,heading])el?.animate([{opacity:1,transform:'translateY(0)'},{opacity:0,transform:'translateY(-20px)'}],{duration:700,easing:'cubic-bezier(.22,1,.36,1)',fill:'forwards'});
   const content=page.querySelector('.intro-content').getBoundingClientRect();
   const target=content.top+Math.min(80,content.height*.16);
   const moment=page.querySelector('.christ-moment')||bridge;
   const distance=target-moment.getBoundingClientRect().top;
   moment.animate([{transform:'translateY(0)'},{transform:`translateY(${distance}px)`}],{duration:850,easing:'cubic-bezier(.22,1,.36,1)',fill:'forwards'});
  },bridgeStart);
 }
 const bridgeEnd=type(bridge,bridgeStart+1000);
 const christArt=page.querySelector('.christ-art');
 if(christArt)later(()=>{if(page.isConnected)christArt.animate([{opacity:0,transform:'translateY(8px) scale(.9)'},{opacity:1,transform:'translateY(0) scale(1)'}],{duration:320,easing:'cubic-bezier(.22,1,.36,1)',fill:'forwards'})},bridgeEnd+60);
 completed=bridgeEnd+(christArt?380:160);
}
if(step===13){const prayer=page.querySelector('.personal-prayer');completed=type(prayer,end+400,38)+180;const recite=page.querySelector('.recite');if(recite){recite.style.visibility='hidden';recite.inert=true;later(()=>{if(page.isConnected){recite.style.visibility='visible';recite.inert=false}},completed);}}
if(gated)later(()=>{if(page.isConnected)gate(false)},completed);
page.style.setProperty('--copy-delay',`${end+80}ms`);page.style.setProperty('--action-delay','0ms');
}
document.addEventListener('visibilitychange',()=>{if(document.hidden){clear();settle()}});
matchMedia('(prefers-reduced-motion: reduce)').addEventListener('change',()=>{clear();settle()});
