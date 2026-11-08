export const discoveryDesign={
 ps23:{title:'A softer place to land',art:'olive'},
 pr31:{title:'Clothed in quiet strength',art:'intention-heart'},
 mt11:{title:'Lay down what you carry',art:'rest-stones'},
 jr29:{title:'Hope for the unfolding',art:'sunrise'},
 pr3:{title:'Trust the next small step',art:'faith-hands'},
 ps119:{title:'A little light for the way',art:'lantern'},
 ps107:{title:'Notice the ordinary gifts',art:'gratitude-basket'},
 pr17:{title:'Love that stays close',art:'relationship-hands'},
 jm1:{title:'Make room for wisdom',art:'wisdom-pearl'}
};
// Artwork belongs to a passage, never its current row or filter position.
export const illustrationFamilies={
 Peace:['olive','dove','rest-stones'], Identity:['intention-heart','milestone','seedling'],
 Anxiety:['rest-stones','dove','reflection'], Hope:['sunrise','butterfly','anchor'],
 Faith:['faith-hands','anchor','dove'], Purpose:['lantern','purpose-compass','seedling'],
 Gratitude:['gratitude-basket','cosmos','sunrise'], Relationships:['relationship-hands','community','intention-heart'],
 Wisdom:['wisdom-pearl','open-book','lantern']
};
export function passageArtwork(passage){
 const pinned=discoveryDesign[passage.id]?.art;
 if(pinned)return pinned;
 const family=illustrationFamilies[passage.topic]||['open-book','olive','lantern'];
 const hash=[...(passage.ref||passage.id)].reduce((n,c)=>(n*31+c.charCodeAt(0))>>>0,0);
 return family[hash%family.length];
}
// Reorder a browsable feed instead of changing a passage's visual identity.
export function spaceArtwork(items){
 const remaining=[...items],result=[];
 while(remaining.length){const next=remaining.findIndex(v=>v.art!==result.at(-1)?.art);result.push(remaining.splice(next<0?0:next,1)[0])}
 return result;
}
export function discoveryItems(passages,{filter='For you',saved=[],plan,topics=[]}={}){
 let list=filter==='Saved'?passages.filter(v=>saved.includes(v.id)):filter==='Plan'?(plan?.refs||[]).map(id=>passages.find(v=>v.id===id)).filter(Boolean):passages.filter(v=>filter==='For you'||v.topic===filter);
 if(filter==='For you')list=[...list].sort((a,b)=>Number(topics.includes(b.topic))-Number(topics.includes(a.topic)));
 const designed=list.map(v=>({...v,title:discoveryDesign[v.id]?.title||v.ref,art:passageArtwork(v)}));
 return filter==='For you'?spaceArtwork(designed):designed;
}
