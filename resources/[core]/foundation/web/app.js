const app=document.getElementById('app');
const list=document.getElementById('character-list');
const form=document.getElementById('create-form');
const notice=document.getElementById('notice');
const heading=document.getElementById('heading');
const subheading=document.getElementById('subheading');
const createButton=document.getElementById('new-character');
const editor=document.getElementById('appearance-editor');
const componentControls=document.getElementById('component-controls');
const propControls=document.getElementById('prop-controls');
const post=(name,data)=>fetch('https://foundation/'+name,{method:'POST',headers:{'Content-Type':'application/json; charset=UTF-8'},body:JSON.stringify(data)}).then(r=>r.json());
let characterCount=0;
const componentNames=['Face','Mask','Hair','Torso','Legs','Bag','Shoes','Accessories','Undershirt','Body armor','Decals','Top'];
const propNames=['Hats','Glasses','Ears','Watches','Bracelets','Accessory 5','Accessory 6','Accessory 7'];
function message(text){notice.textContent=text||'';}
function showCreate(show){editor.classList.add('hidden');form.classList.toggle('hidden',!show);list.classList.toggle('hidden',show);createButton.classList.toggle('hidden',show);heading.textContent=show?'Create character':'Select character';subheading.textContent=show?'Enter the details for your new citizen.':'Choose who you are bringing into the city.';message('');}
function renderCharacters(characters){characterCount=characters.length;list.replaceChildren();characters.forEach(character=>{const row=document.createElement('article');row.className='character';const details=document.createElement('div');const name=document.createElement('strong');name.textContent=character.firstname+' '+character.lastname;const meta=document.createElement('small');meta.textContent='Born '+character.date_of_birth+' · '+character.gender;details.append(name,meta);const button=document.createElement('button');button.textContent='Select';button.addEventListener('click',()=>post('selectCharacter',{id:character.id}));row.append(details,button);list.append(row);});createButton.disabled=characterCount>=3;createButton.textContent=characterCount>=3?'Character limit reached':'＋ Create character';}
function numberInput(value,min=0){const input=document.createElement('input');input.type='number';input.min=String(min);input.value=String(value??0);input.className='editor-number';return input;}
function buildEditor(appearance){
 componentControls.replaceChildren();propControls.replaceChildren();
 const components=appearance?.components||[];const props=appearance?.props||[];
 for(let id=0;id<12;id++){const current=components.find(x=>x.component===id)||{drawable:0,texture:0};const row=document.createElement('div');row.className='editor-row';const name=document.createElement('label');name.textContent=componentNames[id];const drawable=numberInput(current.drawable);const texture=numberInput(current.texture);const apply=document.createElement('button');apply.textContent='Apply';apply.addEventListener('click',async()=>{const result=await post('previewComponent',{component:id,drawable:Number(drawable.value),texture:Number(texture.value)});message(result.ok?'Clothing preview updated.':result.error);});row.append(name,drawable,texture,apply);componentControls.append(row);}
 for(let id=0;id<8;id++){const current=props.find(x=>x.prop===id)||{drawable:-1,texture:0};const row=document.createElement('div');row.className='editor-row';const name=document.createElement('label');name.textContent=propNames[id];const drawable=numberInput(current.drawable,-1);const texture=numberInput(current.texture);const apply=document.createElement('button');apply.textContent='Apply';apply.addEventListener('click',async()=>{const result=await post('previewProp',{prop:id,drawable:Number(drawable.value),texture:Number(texture.value)});message(result.ok?'Accessory preview updated.':result.error);});row.append(name,drawable,texture,apply);propControls.append(row);}
}
window.addEventListener('message',event=>{const data=event.data||{};if(data.action==='open')app.classList.remove('hidden');if(data.action==='close')app.classList.add('hidden');if(data.action==='characters'){editor.classList.add('hidden');renderCharacters(data.characters||[]);if(data.error)message(data.error);}if(data.action==='createResult'&&!data.success)message(data.result);if(data.action==='error')message(data.message);if(data.action==='appearanceEditor'){form.classList.add('hidden');list.classList.add('hidden');createButton.classList.add('hidden');editor.classList.remove('hidden');heading.textContent='Appearance';subheading.textContent='Customize your current outfit.';buildEditor(data.appearance||{});message('');}});
createButton.addEventListener('click',()=>showCreate(true));
document.getElementById('cancel-create').addEventListener('click',()=>showCreate(false));
form.addEventListener('submit',event=>{event.preventDefault();const values=Object.fromEntries(new FormData(form).entries());post('createCharacter',values);form.reset();showCreate(false);});
document.getElementById('save-appearance').addEventListener('click',async()=>{const result=await post('saveAppearance',{});message(result.ok?'Appearance saved.':'Could not save appearance.');});
document.getElementById('close-appearance').addEventListener('click',()=>post('close',{}));
window.addEventListener('keydown',event=>{if(event.key==='Escape'&&!editor.classList.contains('hidden'))post('close',{});});
