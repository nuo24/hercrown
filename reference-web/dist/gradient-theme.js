(()=>{
 const key='bible-gradient-v1';
 const defaults={colors:['#e4eddf','#e0edf5','#eadff0'],third:false,intensity:100,spread:49,angle:165};
 let settings;try{settings={...defaults,...JSON.parse(localStorage.getItem(key)||'{}')}}catch{settings={...defaults}}
 const rgba=(hex,a)=>{const n=parseInt(hex.slice(1),16);return `rgba(${n>>16},${n>>8&255},${n&255},${a})`};
 function gradient(s,dark=false){const a=s.intensity/100*(dark?.20:1),spread=s.spread;return `radial-gradient(ellipse at 0% 14%,${rgba(s.colors[0],a)} 0%,transparent ${spread}%),radial-gradient(ellipse at 100% 74%,${rgba(s.colors[1],a)} 0%,transparent ${spread}%)${s.third?`,radial-gradient(ellipse at 52% 100%,${rgba(s.colors[2],a*.8)} 0%,transparent ${spread}%)`:''},linear-gradient(${s.angle}deg,${dark?'#101314,#121619':'#fff,#f5f8f7'})`}
 function apply(s,persist=false){settings={...defaults,...s,colors:s.colors.slice(0,3)};for(const [name,dark] of [['--bible-gradient-light',false],['--bible-gradient-dark',true]])document.documentElement.style.setProperty(name,gradient(settings,dark));if(persist)localStorage.setItem(key,JSON.stringify(settings));return settings}
 window.BibleGradient={defaults,get:()=>structuredClone(settings),apply,css:()=>`background: ${gradient(settings)};`};
 addEventListener('bible-gradient-change',e=>apply(e.detail));addEventListener('storage',e=>{if(e.key===key){try{apply(JSON.parse(e.newValue)||defaults)}catch{}}});apply(settings);
})();
