// Entrance-only onboarding choreography. Timers are cancelled whenever the screen changes.
let lastPage=null;
let ticks=[];
const reduced=()=>matchMedia('(prefers-reduced-motion: reduce)').matches;
function cancelTicks(){ticks.forEach(clearTimeout);ticks=[]}
function haptic(style='selection'){
 if(reduced()||document.hidden)return;
 try{
  const native=window.webkit?.messageHandlers?.herCrownHaptics;
  if(native)native.postMessage({style});
  else if(navigator.vibrate)navigator.vibrate(style==='light'?8:5);
 }catch{/* Unsupported haptics must never interrupt onboarding. */}
}
export function resetOnboardingMotion(){cancelTicks();lastPage=null}
export function mountOnboardingMotion(root,step){
 cancelTicks();
 const page=root.querySelector('.screen');
 if(!page){lastPage=null;return}
 // Updating a choice/reminder on this page must not replay its entrance or buzzing.
 if(lastPage===step||reduced()){lastPage=step;return}
 lastPage=step;
 page.classList.add('onboarding-motion');
 page.querySelectorAll('.intro-art img').forEach((image,index)=>{image.style.animationDelay=`${index*140}ms`});
 if(page.classList.contains('welcome')){
  const collage=document.createElement('div');
  collage.className='welcome-motion-art';collage.setAttribute('aria-hidden','true');
  for(let i=0;i<7;i++){const piece=document.createElement('i');piece.className=`welcome-art-piece piece-${i}`;collage.append(piece)}
  page.prepend(collage);
 }
 const heading=page.querySelector('h2');
 const finalHeadline=heading?.innerHTML;
 let characters=0;
 if(heading){
  const reader=document.createElement('span');
  reader.innerHTML=heading.innerHTML.replace(/<br\s*\/?\s*>/gi,' ');
  heading.setAttribute('aria-label',reader.textContent);
  const walker=document.createTreeWalker(heading,NodeFilter.SHOW_TEXT);
  const nodes=[];while(walker.nextNode())nodes.push(walker.currentNode);
  for(const node of nodes){const fragment=document.createDocumentFragment();
   for(const token of node.textContent.split(/(\s+)/)){
    if(!token)continue;
    if(/^\s+$/.test(token)){fragment.append(document.createTextNode(token));continue}
    const word=document.createElement('span');word.className='onboarding-word';word.setAttribute('aria-hidden','true');
    for(const letter of Array.from(token)){
     const span=document.createElement('span');span.className='onboarding-letter';span.textContent=letter;
     span.style.setProperty('--letter',characters++);word.append(span);
    }fragment.append(word);
   }node.replaceWith(fragment);
  }
 }
 const duration=220+characters*32;
 // Retire per-letter layers after typing. WebKit can drop italic glyphs when many
 // completed opacity animations remain composited inside an emphasized run.
 if(heading)ticks.push(setTimeout(()=>{
  if(!page.isConnected)return;
  heading.innerHTML=finalHeadline;
  heading.removeAttribute('aria-label');
 },duration+80));
 page.style.setProperty('--copy-delay',`${duration+80}ms`);
 page.style.setProperty('--action-delay',`${duration+180}ms`);
 page.querySelectorAll('.choice,.chip,.reminder,.notification,.ready blockquote').forEach((el,i)=>{
  el.classList.add('onboarding-enter');el.style.setProperty('--item-delay',`${duration+140+Math.min(i,8)*45}ms`);
 });
 // One small tick per two letters; never a sustained vibration or a tick for every glyph.
 for(let i=0;i<characters;i+=2){ticks.push(setTimeout(()=>{
  if(page.isConnected)haptic();
 },220+i*32))}
}
document.addEventListener('visibilitychange',()=>{if(document.hidden)cancelTicks()});
matchMedia('(prefers-reduced-motion: reduce)').addEventListener('change',cancelTicks);
// Native host registers `herCrownHaptics`; selection -> UISelectionFeedbackGenerator,
// light -> UIImpactFeedbackGenerator(.light). iOS Safari itself has no haptics API.
document.addEventListener('click',event=>{
 if(event.target.closest('.screen [data-action="next"],.screen [data-action="finish"],.screen [data-choice]'))haptic('light');
},true);
