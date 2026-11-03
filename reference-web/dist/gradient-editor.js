(()=>{
 const panel=document.querySelector('#gradient-editor'),api=window.BibleGradient;
 const form=panel.querySelector('form');
 function fill(){const s=api.get();s.colors.forEach((c,i)=>form.elements['color'+i].value=c);form.elements.third.checked=s.third;for(const n of ['intensity','spread','angle'])form.elements[n].value=s[n];labels()}
 function labels(){for(const n of ['intensity','spread','angle'])panel.querySelector(`[data-value="${n}"]`).textContent=form.elements[n].value+(n==='angle'?'°':'%');form.elements.color2.disabled=!form.elements.third.checked}
 function update(){const s={colors:[0,1,2].map(i=>form.elements['color'+i].value),third:form.elements.third.checked,intensity:+form.elements.intensity.value,spread:+form.elements.spread.value,angle:+form.elements.angle.value};api.apply(s,true);frame.contentWindow.dispatchEvent(new CustomEvent('bible-gradient-change',{detail:s}));labels()}
 form.addEventListener('input',update);form.addEventListener('submit',e=>e.preventDefault());
 panel.querySelector('#gradient-reset').onclick=()=>{api.apply(api.defaults,true);fill();update()};
 panel.querySelector('#gradient-copy').onclick=async()=>{const status=panel.querySelector('[role=status]');try{await navigator.clipboard.writeText(api.css());status.textContent='CSS copied'}catch{status.textContent='Copy unavailable in this browser'}};
 frame.addEventListener('load',()=>frame.contentWindow.dispatchEvent(new CustomEvent('bible-gradient-change',{detail:api.get()})));
 fill();
})();
