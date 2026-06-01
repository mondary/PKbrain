<script lang="ts">
  type Note={id:string;title:string;body:string;updated:number}
  let notes:Note[]=JSON.parse(localStorage.getItem('stik_notes')||'[]')
  let title=''; let body=''
  function save(){ localStorage.setItem('stik_notes', JSON.stringify(notes)) }
  function add(){ if(!title.trim()&&!body.trim()) return; notes=[{id:crypto.randomUUID(),title:title||'Untitled',body,updated:Date.now()},...notes]; title=''; body=''; save() }
  function del(id:string){ notes=notes.filter(n=>n.id!==id); save() }
</script>
<main>
  <h1>Stik Clone</h1>
  <div class="composer"><input bind:value={title} placeholder="Title"/><textarea bind:value={body} rows="6" placeholder="# Markdown\nwrite..."></textarea><button on:click={add}>Save note</button></div>
  <section>{#each notes as n}<article><h2>{n.title}</h2><pre>{n.body}</pre><button on:click={()=>del(n.id)}>Delete</button></article>{/each}</section>
</main>
<style>
:global(body){margin:0;background:#111318;color:#ebedf1;font-family:ui-monospace,SFMono-Regular,Menlo,monospace}main{max-width:980px;margin:0 auto;padding:20px}.composer{display:grid;gap:8px}input,textarea{background:#171b22;border:1px solid #2f3948;color:#fff;border-radius:8px;padding:10px}button{justify-self:start;background:#273347;border:1px solid #3d4f6b;color:#fff;border-radius:8px;padding:8px 12px}section{display:grid;grid-template-columns:repeat(auto-fill,minmax(260px,1fr));gap:10px;margin-top:14px}article{background:#151a23;border:1px solid #2f3948;border-radius:10px;padding:10px}h2{margin:0 0 8px 0;font-size:16px}pre{white-space:pre-wrap;margin:0 0 8px 0}
</style>
