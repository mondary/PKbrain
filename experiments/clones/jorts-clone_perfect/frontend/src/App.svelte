<script lang="ts">
  type Sticky={id:string;title:string;body:string;color:string}
  const colors=['yellow','pink','mint','blue']
  let title=''; let body=''; let color='yellow'
  let notes:Sticky[]=JSON.parse(localStorage.getItem('jorts_notes')||'[]')
  function save(){ localStorage.setItem('jorts_notes', JSON.stringify(notes)) }
  function add(){ if(!title.trim()&&!body.trim()) return; notes=[{id:crypto.randomUUID(),title:title||'note',body,color},...notes]; title=''; body=''; save() }
  function del(id:string){ notes=notes.filter(n=>n.id!==id); save() }
</script>
<main>
  <h1>Jorts Clone</h1>
  <div class="make"><input bind:value={title} placeholder="Title"/><textarea bind:value={body} rows="3" placeholder="Sticky note"></textarea><select bind:value={color}>{#each colors as c}<option value={c}>{c}</option>{/each}</select><button on:click={add}>Pin</button></div>
  <section>{#each notes as n}<article class="{n.color}"><h3>{n.title}</h3><p>{n.body}</p><button on:click={()=>del(n.id)}>x</button></article>{/each}</section>
</main>
<style>
:global(body){margin:0;background:#f0ece2;color:#1f1c16;font-family:'Marker Felt','Bradley Hand',cursive,system-ui}main{max-width:980px;margin:0 auto;padding:20px}.make{display:grid;grid-template-columns:1fr;gap:8px}input,textarea,select{border:1px solid #b8ac8d;border-radius:8px;padding:10px;background:#fff8e7}button{justify-self:start;border:1px solid #786a4a;background:#e7d2a3;border-radius:8px;padding:8px 10px}section{display:grid;grid-template-columns:repeat(auto-fill,minmax(210px,1fr));gap:14px;margin-top:14px}article{padding:12px;border-radius:8px;min-height:140px;box-shadow:0 8px 14px rgba(0,0,0,.12);transform:rotate(-1deg)}article:nth-child(2n){transform:rotate(1deg)}h3{margin:0 0 8px 0}p{white-space:pre-wrap}.yellow{background:#fff3a6}.pink{background:#ffd2df}.mint{background:#d2f8e8}.blue{background:#cfe5ff}
</style>
