<script lang="ts">
  import { onMount } from 'svelte'
  import {
    GetState,
    TogglePause,
    TogglePin,
    DeleteClip,
    ClearUnpinned,
    CopyClip,
    AddToShelf,
    RemoveFromShelf,
    ClearShelf,
    CopyShelf,
    CreateNote,
    UpdateNote,
    DeleteNote,
    TogglePinNote
  } from '../wailsjs/go/main/App'

  type ClipItem = { id: string; text: string; pinned: boolean; source: string; createdAt: number }
  type NoteItem = { id: string; title: string; body: string; color: string; pinned: boolean; createdAt: number; updatedAt: number }
  type AppState = { paused: boolean; items: ClipItem[]; shelf: ClipItem[]; notes: NoteItem[] }

  let state: AppState = { paused: false, items: [], shelf: [], notes: [] }
  let query = ''
  let drawerOpen = true
  let activePanel: 'shelf' | 'notes' = 'shelf'
  let noteTitle = ''
  let noteBody = ''
  let noteColor = 'yellow'

  async function refresh() { state = await GetState() }
  async function pauseResume() { state = await TogglePause() }
  async function togglePin(id: string) { await TogglePin(id); await refresh() }
  async function remove(id: string) { state = await DeleteClip(id) }
  async function clearUnpinned() { state = await ClearUnpinned() }
  async function copy(id: string) { await CopyClip(id) }
  async function addToShelf(id: string) { await AddToShelf(id); await refresh() }
  async function removeFromShelf(id: string) { state = await RemoveFromShelf(id) }
  async function clearShelf() { state = await ClearShelf() }
  async function copyShelf() { await CopyShelf() }

  async function createNote() {
    if (!noteTitle.trim() && !noteBody.trim()) return
    state = await CreateNote(noteTitle, noteBody, noteColor)
    noteTitle = ''
    noteBody = ''
  }

  async function deleteNote(id: string) { state = await DeleteNote(id) }
  async function togglePinNote(id: string) { await TogglePinNote(id); await refresh() }
  async function onNoteTitleChange(n: NoteItem, e: Event) {
    const v = (e.currentTarget as HTMLInputElement).value
    state = await UpdateNote(n.id, v, n.body, n.color)
  }
  async function onNoteBodyChange(n: NoteItem, e: Event) {
    const v = (e.currentTarget as HTMLTextAreaElement).value
    state = await UpdateNote(n.id, n.title, v, n.color)
  }
  function clipPreview(text: string): string { return text.length > 150 ? `${text.slice(0, 150)}...` : text }

  $: filtered = state.items.filter((item) => item.text.toLowerCase().includes(query.toLowerCase()))

  onMount(async () => {
    await refresh()
    const id = setInterval(refresh, 1800)
    return () => clearInterval(id)
  })
</script>

<main>
  <section class="history-pane">
    <header>
      <div><h1>PKbrain</h1><small>clipboard + notes</small></div>
      <div class="actions">
        <button on:click={pauseResume}>{state.paused ? 'Resume' : 'Pause'}</button>
        <button on:click={clearUnpinned}>Clear unpinned</button>
        <button on:click={() => (drawerOpen = !drawerOpen)}>{drawerOpen ? 'Hide panel' : 'Show panel'}</button>
      </div>
    </header>

    <input type="text" bind:value={query} placeholder="Search clipboard history" class="search" />

    <section class="list">
      {#if filtered.length === 0}
        <p class="empty">No clips yet. Copy text to start.</p>
      {:else}
        {#each filtered as item}
          <article class="clip {item.pinned ? 'pinned' : ''}">
            <p>{clipPreview(item.text)}</p>
            <footer>
              <button on:click={() => copy(item.id)}>Copy</button>
              <button on:click={() => addToShelf(item.id)}>Shelf</button>
              <button on:click={() => togglePin(item.id)}>{item.pinned ? 'Unpin' : 'Pin'}</button>
              <button on:click={() => remove(item.id)}>Delete</button>
            </footer>
          </article>
        {/each}
      {/if}
    </section>
  </section>

  <aside class="drawer {drawerOpen ? 'open' : 'closed'}">
    <div class="drawer-top">
      <div class="tabs">
        <button class:active={activePanel === 'shelf'} on:click={() => (activePanel = 'shelf')}>Shelf</button>
        <button class:active={activePanel === 'notes'} on:click={() => (activePanel = 'notes')}>Notes</button>
      </div>

      {#if activePanel === 'shelf'}
        <div class="actions"><button on:click={copyShelf}>Copy all</button><button on:click={clearShelf}>Clear</button></div>
      {/if}
    </div>

    {#if activePanel === 'shelf'}
      <div class="shelf-list">
        {#if state.shelf.length === 0}
          <p class="empty">Shelf empty</p>
        {:else}
          {#each state.shelf as item, index}
            <article class="shelf-item"><strong>#{index + 1}</strong><p>{clipPreview(item.text)}</p><button on:click={() => removeFromShelf(item.id)}>Remove</button></article>
          {/each}
        {/if}
      </div>
    {:else}
      <div class="notes-wrap">
        <div class="note-create">
          <input bind:value={noteTitle} placeholder="Note title" />
          <textarea bind:value={noteBody} placeholder="Quick thought..." rows="4"></textarea>
          <div class="create-row">
            <select bind:value={noteColor}>
              <option value="yellow">Yellow</option>
              <option value="pink">Pink</option>
              <option value="blue">Blue</option>
              <option value="green">Green</option>
              <option value="orange">Orange</option>
              <option value="purple">Purple</option>
            </select>
            <button on:click={createNote}>Add note</button>
          </div>
        </div>

        <div class="notes-grid">
          {#each state.notes as n}
            <article class="note-card color-{n.color}">
              <input value={n.title} on:change={(e) => onNoteTitleChange(n, e)} />
              <textarea rows="5" on:change={(e) => onNoteBodyChange(n, e)}>{n.body}</textarea>
              <div class="note-actions">
                <button on:click={() => togglePinNote(n.id)}>{n.pinned ? 'Unpin' : 'Pin'}</button>
                <button on:click={() => deleteNote(n.id)}>Delete</button>
              </div>
            </article>
          {/each}
          {#if state.notes.length === 0}
            <p class="empty">No notes yet</p>
          {/if}
        </div>
      </div>
    {/if}
  </aside>
</main>

<style>
  :global(body) { margin: 0; background: radial-gradient(circle at 10% -10%, #3f4c69 0%, #0d1118 44%, #0a0d12 100%); color: #edf1f8; font-family: Inter, ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, sans-serif; }
  main { height: 100vh; display: grid; grid-template-columns: 1fr auto; overflow: hidden; }
  .history-pane { padding: 20px; overflow: auto; }
  header { display: flex; justify-content: space-between; align-items: flex-end; gap: 10px; }
  h1, h2 { margin: 0; }
  small { color: #9ca7bc; }
  .actions { display: flex; gap: 8px; }
  .search { width: 100%; margin: 14px 0; padding: 12px; border-radius: 12px; background: #161d28; border: 1px solid #2f3a4f; color: #edf1f8; box-sizing: border-box; }
  .list { display: grid; gap: 10px; }
  .clip { border: 1px solid #2f3a4f; background: linear-gradient(180deg, #1a2230 0%, #141a25 100%); border-radius: 14px; padding: 12px; }
  .clip.pinned { border-color: #ffcf5a; }
  .clip p { margin: 0; white-space: pre-wrap; word-break: break-word; }
  footer { margin-top: 10px; display: flex; gap: 8px; flex-wrap: wrap; }
  button { background: #242f43; border: 1px solid #34425b; color: #eff4ff; border-radius: 9px; padding: 8px 10px; cursor: pointer; }
  button:hover { background: #2f3b54; }
  .drawer { width: 440px; border-left: 1px solid #2f3a4f; background: linear-gradient(180deg, #131a25 0%, #0f141d 100%); transition: transform 180ms ease; display: flex; flex-direction: column; }
  .drawer.closed { transform: translateX(100%); }
  .drawer.open { transform: translateX(0); }
  .drawer-top { padding: 16px; border-bottom: 1px solid #2f3a4f; display: flex; justify-content: space-between; align-items: center; gap: 8px; }
  .tabs { display: flex; gap: 6px; }
  .tabs button.active { background: #395382; }
  .shelf-list { padding: 12px; display: grid; gap: 8px; overflow: auto; }
  .shelf-item { border: 1px solid #334158; background: #171f2c; border-radius: 10px; padding: 10px; display: grid; gap: 8px; }
  .shelf-item p { margin: 0; white-space: pre-wrap; word-break: break-word; }

  .notes-wrap { display: grid; grid-template-rows: auto 1fr; overflow: hidden; }
  .note-create { padding: 12px; border-bottom: 1px solid #2f3a4f; display: grid; gap: 8px; }
  .note-create input, .note-create textarea, .note-create select, .note-card input, .note-card textarea {
    background: rgba(255,255,255,.45);
    border: 1px solid rgba(0,0,0,.18);
    border-radius: 8px;
    padding: 8px;
    color: #1d1f23;
    font: inherit;
    box-sizing: border-box;
    width: 100%;
  }
  .create-row { display: flex; gap: 8px; }
  .notes-grid { overflow: auto; padding: 12px; display: grid; gap: 10px; }
  .note-card {
    border-radius: 10px;
    padding: 10px;
    border: 1px solid rgba(0,0,0,.12);
    box-shadow: 0 3px 8px rgba(0,0,0,.2);
    transform: rotate(-0.3deg);
    display: grid;
    gap: 8px;
  }
  .note-card:nth-child(2n) { transform: rotate(0.4deg); }
  .note-card:nth-child(3n) { transform: rotate(-0.6deg); }
  .note-actions { display: flex; gap: 8px; }

  .color-yellow { background: #fff0a8; }
  .color-pink { background: #ffd0de; }
  .color-blue { background: #cfe7ff; }
  .color-green { background: #d7f7cc; }
  .color-orange { background: #ffdcb6; }
  .color-purple { background: #ead8ff; }

  .empty { color: #8c99b0; }
  @media (max-width: 980px) { main { grid-template-columns: 1fr; } .drawer { position: fixed; right: 0; top: 0; bottom: 0; z-index: 9; } }
</style>
