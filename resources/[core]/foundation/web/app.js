const app=document.getElementById('app');
const list=document.getElementById('character-list');
const form=document.getElementById('create-form');
const notice=document.getElementById('notice');
const heading=document.getElementById('heading');
const subheading=document.getElementById('subheading');
const createButton=document.getElementById('new-character');
const post=(name,data)=>fetch(`https://foundation/${name}`,{method:'POST',headers:{'Content-Type':'application/json; charset=UTF-8'},body:JSON.stringify(data)}).then(r=>r.json());
let characterCount=0;
function message(text){notice.textContent=text||'';}
function showCreate(show){form.classList.toggle('hidden',!show);list.classList.toggle('hidden',show);createButton.classList.toggle('hidden',show);heading.textContent=show?'Create character':'Select character';subheading.textContent=show?'Enter the details for your new citizen.':'Choose who you\'re bringing into the city.';message('');}
function renderCharacters(characters){characterCount=characters.length;list.replaceChildren();characters.forEach(character=>{const row=document.createElement('article');row.className='character';const details=document.createElement('div');const name=document.createElement('strong');name.textContent=`${character.firstname} ${character.lastname}`;const meta=document.createElement('small');meta.textContent=`Born ${character.date_of_birth} · ${character.gender}`;details.append(name,meta);const button=document.createElement('button');button.textContent='Select';button.addEventListener('click',()=>post('selectCharacter',{id:character.id}));row.append(details,button);list.append(row);});createButton.disabled=characterCount>=3;createButton.textContent=characterCount>=3?'Character limit reached':'＋ Create character';}
window.addEventListener('message',event=>{const data=event.data||{};if(data.action==='open'){app.classList.remove('hidden');}if(data.action==='close'){app.classList.add('hidden');}if(data.action==='characters'){renderCharacters(data.characters||[]);if(data.error)message(data.error);}if(data.action==='createResult'&&!data.success)message(data.result);if(data.action==='error')message(data.message);});
createButton.addEventListener('click',()=>showCreate(true));
document.getElementById('cancel-create').addEventListener('click',()=>showCreate(false));
form.addEventListener('submit',event=>{event.preventDefault();const values=Object.fromEntries(new FormData(form).entries());post('createCharacter',values);form.reset();showCreate(false);});
