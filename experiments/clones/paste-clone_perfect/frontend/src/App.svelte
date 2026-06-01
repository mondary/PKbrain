<script lang="ts">
  type Clip = { id: string; text: string; pinned: boolean }
  let query = ''
  let clips: Clip[] = JSON.parse(localStorage.getItem('paste_clips') || '[]')
  let value = ''
  function add() {
    const t = value.trim(); if (!t) return
    clips = [{ id: crypto.randomUUID(), text: t, pinned: false }, ...clips].slice(0, 200)
    value = ''
    save()
  }
  function save() { localStorage.setItem('paste_clips', JSON.stringify(clips)) }
  function del(id: string) { clips = clips.filter(c => c.id !== id); save() }
  function pin(id: string) { clips = clips.map(c => c.id===id ? { ...c, pinned: !c.pinned } : c); save() }
  async function copy(text: string) { await navigator.clipboard.writeText(text) }
  $: filtered = clips
    .filter(c => c.text.toLowerCase().includes(query.toLowerCase()))
    .sort((a,b)=> Number(b.pinned)-Number(a.pinned))
</script>
<main>
  <aside class="drawer">
    <h1>Paste Clone</h1>
    <input bind:value={query} placeholder="Search" class="search" />
    <div class="quick"><input bind:value={value} placeholder="Quick add" /><button on:click={add}>Add</button></div>
    <div class="list">{#each filtered as c}<article class="item {c.pinned?'p':''}"><p>{c.text}</p><footer><button on:click={() => copy(c.text)}>Copy</button><button on:click={() => pin(c.id)}>{c.pinned?'Unpin':'Pin'}</button><button on:click={() => del(c.id)}>Del</button></footer></article>{/each}</div>
  </aside>
</main>
<style>
:global(body){margin:0;background:#0b0f16;color:#e9eef8;font-family:Inter,system-ui}main{height:100vh;display:flex;justify-content:flex-end}.drawer{width:420px;height:100vh;background:#121826;border-left:1px solid #2f3a50;padding:14px;box-sizing:border-box}.search,input{width:100%;box-sizing:border-box;background:#1a2233;border:1px solid #33425e;color:#fff;border-radius:10px;padding:10px}.quick{display:grid;grid-template-columns:1fr auto;gap:8px;margin:8px 0}.list{display:grid;gap:8px;max-height:calc(100vh - 150px);overflow:auto}.item{background:#182234;border:1px solid #2f3e59;padding:10px;border-radius:10px}.item.p{border-color:#ffcd58}p{margin:0;white-space:pre-wrap}footer{display:flex;gap:6px;margin-top:8px}button{background:#27344d;border:1px solid #3a4d70;color:#fff;border-radius:8px;padding:6px 8px}
</style>
