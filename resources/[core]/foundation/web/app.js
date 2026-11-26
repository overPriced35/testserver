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
const faceControls=document.getElementById('face-controls');
const inventoryPanel=document.getElementById('inventory-panel');
const inventoryGrid=document.getElementById('inventory-grid');
const inventoryWeight=document.getElementById('inventory-weight');
const post=(name,data)=>fetch('https://foundation/'+name,{method:'POST',headers:{'Content-Type':'application/json; charset=UTF-8'},body:JSON.stringify(data)}).then(r=>r.json());
let characterCount=0;
const componentNames=['Face','Mask','Hair','Torso','Legs','Bag','Shoes','Accessories','Undershirt','Body armor','Decals','Top'];
const propNames=['Hats','Glasses','Ears','Watches','Bracelets','Accessory 5','Accessory 6','Accessory 7'];
const faceNames=['Nose width','Nose peak height','Nose peak length','Nose bone height','Nose peak lowering','Nose bone twist','Eyebrow height','Eyebrow depth','Cheekbone height','Cheekbone width','Cheek width','Eye opening','Lip thickness','Jaw width','Jaw shape','Chin height','Chin length','Chin width','Chin cleft','Neck width'];
function message(text){notice.textContent=text||'';}
function showCreate(show){editor.classList.add('hidden');form.classList.toggle('hidden',!show);list.classList.toggle('hidden',show);createButton.classList.toggle('hidden',show);heading.textContent=show?'Create character':'Select character';subheading.textContent=show?'Enter the details for your new citizen.':'Choose who you are bringing into the city.';message('');}
function renderCharacters(characters){characterCount=characters.length;list.replaceChildren();characters.forEach(character=>{const row=document.createElement('article');row.className='character';const details=document.createElement('div');const name=document.createElement('strong');name.textContent=character.firstname+' '+character.lastname;const meta=document.createElement('small');meta.textContent='Born '+character.date_of_birth+' · '+character.gender;details.append(name,meta);const button=document.createElement('button');button.textContent='Select';button.addEventListener('click',()=>post('selectCharacter',{id:character.id}));row.append(details,button);list.append(row);});createButton.disabled=characterCount>=3;createButton.textContent=characterCount>=3?'Character limit reached':'＋ Create character';}
function renderInventory(inventory){
 inventoryGrid.replaceChildren();
 const items=inventory?.items||[];
 const bySlot=new Map(items.map(item=>[item.slot,item]));
 inventoryWeight.textContent=(inventory?.weight??0).toLocaleString()+' / '+(inventory?.maxWeight??0).toLocaleString()+' g · '+items.length+' occupied slots';
 for(let slot=1;slot<=(inventory?.slots||30);slot++){
  const item=bySlot.get(slot);const card=document.createElement('article');card.className='inventory-slot'+(item?' filled':'');
  const number=document.createElement('small');number.textContent='SLOT '+String(slot).padStart(2,'0');card.append(number);
  if(item){
   const name=document.createElement('strong');name.textContent=item.label||item.name;
   const count=document.createElement('span');count.textContent='× '+item.count;
   const weight=document.createElement('small');weight.textContent=(item.unitWeight*item.count).toLocaleString()+' g';
   card.append(name,count,weight);
   if(item.usable){const use=document.createElement('button');use.textContent='Use';use.addEventListener('click',()=>post('useInventoryItem',{slot}));card.append(use);}
  }else{const empty=document.createElement('span');empty.className='empty-slot';empty.textContent='Empty';card.append(empty);}
  inventoryGrid.append(card);
 }
}
function numberInput(value,min=0){const input=document.createElement('input');input.type='number';input.min=String(min);input.value=String(value??0);input.className='editor-number';return input;}
function buildEditor(appearance){
 componentControls.replaceChildren();propControls.replaceChildren();faceControls.replaceChildren();
 const components=appearance?.components||[];const props=appearance?.props||[];const features=appearance?.faceFeatures||[];
 for(let id=0;id<12;id++){const current=components.find(x=>x.component===id)||{drawable:0,texture:0};const row=document.createElement('div');row.className='editor-row';const name=document.createElement('label');name.textContent=componentNames[id];const drawable=numberInput(current.drawable);const texture=numberInput(current.texture);const apply=document.createElement('button');apply.textContent='Apply';apply.addEventListener('click',async()=>{const result=await post('previewComponent',{component:id,drawable:Number(drawable.value),texture:Number(texture.value)});message(result.ok?'Clothing preview updated.':result.error);});row.append(name,drawable,texture,apply);componentControls.append(row);}
 for(let id=0;id<8;id++){const current=props.find(x=>x.prop===id)||{drawable:-1,texture:0};const row=document.createElement('div');row.className='editor-row';const name=document.createElement('label');name.textContent=propNames[id];const drawable=numberInput(current.drawable,-1);const texture=numberInput(current.texture);const apply=document.createElement('button');apply.textContent='Apply';apply.addEventListener('click',async()=>{const result=await post('previewProp',{prop:id,drawable:Number(drawable.value),texture:Number(texture.value)});message(result.ok?'Accessory preview updated.':result.error);});row.append(name,drawable,texture,apply);propControls.append(row);}
 for(let id=0;id<20;id++){const current=features.find(x=>x.feature===id)||{value:0};const row=document.createElement('label');row.className='face-row';const title=document.createElement('span');title.textContent=faceNames[id];const value=document.createElement('input');value.type='range';value.min='-1';value.max='1';value.step='0.05';value.value=String(current.value);value.addEventListener('input',()=>post('previewFaceFeature',{feature:id,value:Number(value.value)}));row.append(title,value);faceControls.append(row);}
 const blend=appearance?.headBlend||{};
 document.getElementById('shape-first').value=blend.shapeFirst??0;
 document.getElementById('shape-second').value=blend.shapeSecond??0;
 document.getElementById('skin-first').value=blend.skinFirst??0;
 document.getElementById('skin-second').value=blend.skinSecond??0;
 document.getElementById('shape-mix').value=blend.shapeMix??0.5;
 document.getElementById('skin-mix').value=blend.skinMix??0.5;
 document.getElementById('hair-color').value=appearance?.hair?.color??0;
 document.getElementById('hair-highlight').value=appearance?.hair?.highlight??0;
 document.getElementById('eye-color').value=appearance?.eyeColor??0;
}
window.addEventListener('message',event=>{const data=event.data||{};if(data.action==='open'){app.classList.remove('hidden');inventoryPanel.classList.add('hidden');}if(data.action==='close')app.classList.add('hidden');if(data.action==='characters'){inventoryPanel.classList.add('hidden');editor.classList.add('hidden');renderCharacters(data.characters||[]);if(data.error)message(data.error);}if(data.action==='createResult'&&!data.success)message(data.result);if(data.action==='error')message(data.message);if(data.action==='inventoryLoading'){form.classList.add('hidden');list.classList.add('hidden');createButton.classList.add('hidden');editor.classList.add('hidden');inventoryPanel.classList.remove('hidden');heading.textContent='Inventory';subheading.textContent='Your carried items.';inventoryWeight.textContent='Loading inventory…';}
if(data.action==='inventoryData'){if(data.error)message(data.error);else renderInventory(data.inventory);}
if(data.action==='inventoryResult'){message(data.success?'Item used.':(data.error||'Could not use item.'));}
if(data.action==='appearanceEditor'){inventoryPanel.classList.add('hidden');form.classList.add('hidden');list.classList.add('hidden');createButton.classList.add('hidden');editor.classList.remove('hidden');heading.textContent='Appearance';subheading.textContent='Customize your character.';buildEditor(data.appearance||{});message('');}});
createButton.addEventListener('click',()=>showCreate(true));
document.getElementById('cancel-create').addEventListener('click',()=>showCreate(false));
form.addEventListener('submit',event=>{event.preventDefault();const values=Object.fromEntries(new FormData(form).entries());post('createCharacter',values);form.reset();showCreate(false);});
document.getElementById('apply-heritage').addEventListener('click',async()=>{const data={shapeFirst:Number(document.getElementById('shape-first').value),shapeSecond:Number(document.getElementById('shape-second').value),skinFirst:Number(document.getElementById('skin-first').value),skinSecond:Number(document.getElementById('skin-second').value),shapeMix:Number(document.getElementById('shape-mix').value),skinMix:Number(document.getElementById('skin-mix').value)};const result=await post('previewHeadBlend',data);message(result.ok?'Heritage preview updated.':result.error);});
document.getElementById('apply-hair').addEventListener('click',async()=>{const result=await post('previewHair',{color:Number(document.getElementById('hair-color').value),highlight:Number(document.getElementById('hair-highlight').value)});message(result.ok?'Hair colors updated.':result.error);});
document.getElementById('apply-eyes').addEventListener('click',async()=>{const result=await post('previewEyeColor',{color:Number(document.getElementById('eye-color').value)});message(result.ok?'Eye color updated.':result.error);});
document.getElementById('save-appearance').addEventListener('click',async()=>{const result=await post('saveAppearance',{});message(result.ok?'Appearance saved.':'Could not save appearance.');});
document.getElementById('close-appearance').addEventListener('click',()=>post('close',{}));
document.getElementById('close-inventory').addEventListener('click',()=>post('close',{}));
window.addEventListener('keydown',event=>{if(event.key==='Escape'&&(!editor.classList.contains('hidden')||!inventoryPanel.classList.contains('hidden')))post('close',{});});
