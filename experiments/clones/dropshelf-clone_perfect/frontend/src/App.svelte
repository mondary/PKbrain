<script lang="ts">
  type Card = { id: string; text: string }
  let input = ''
  let shelf: Card[] = JSON.parse(localStorage.getItem('dropshelf_stack') || '[]')
  function save(){ localStorage.setItem('dropshelf_stack', JSON.stringify(shelf)) }
  function push(){ const t=input.trim(); if(!t) return; shelf=[...shelf,{id:crypto.randomUUID(),text:t}]; input=''; save() }
  function remove(id:string){ shelf=shelf.filter(s=>s.id!==id); save() }
  function clear(){ shelf=[]; save() }
  async function copyAll(){ await navigator.clipboard.writeText(shelf.map(s=>s.text).join('\n')); }
</script>
<main>
  <h1>DropShelf Clone</h1>
  <div class="top"><input bind:value={input} placeholder="Drop text"/><button on:click={push}>Drop</button><button on:click={copyAll}>Copy Stack</button><button on:click={clear}>Clear</button></div>
  <section>{#each shelf as s, i}<article><strong>{i+1}</strong><p>{s.text}</p><button on:click={()=>remove(s.id)}>Remove</button></article>{/each}</section>
</main>
<style>
:global(body){margin:0;background:#0f0d14;color:#f4ecff;font-family:Inter,system-ui}main{max-width:880px;margin:0 auto;padding:20px}.top{display:grid;grid-template-columns:1fr auto auto auto;gap:8px}input{background:#1f1827;border:1px solid #4d3f60;color:#fff;border-radius:10px;padding:10px}button{background:#332845;border:1px solid #5d4d74;color:#fff;border-radius:9px;padding:8px 10px}section{display:grid;gap:10px;margin-top:14px}article{background:#1a1522;border:1px solid #433755;border-radius:12px;padding:10px;display:grid;gap:8px}p{margin:0;white-space:pre-wrap}
</style>
