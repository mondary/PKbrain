/* store3 playground controller — vanilla JS, no dependencies. */
(() => {
  const $ = (selector, root = document) => root.querySelector(selector);
  const $$ = (selector, root = document) => [...root.querySelectorAll(selector)];
  const desktop = $('#desktop');
  const notesLayer = $('#notes-layer');
  const drawerItems = $('#drawer-items');
  const libraryGrid = $('#library-grid');
  const sourceButtons = $('#source-buttons');
  const status = $('#demo-status');
  const reduceMotion = matchMedia('(prefers-reduced-motion: reduce)').matches;
  let state = PKDemo.create();
  let drawerQuery = '';
  let libraryQuery = '';
  let statusTimer = 0;
  let tourStep = -1;
  let tourTimer = 0;

  const showStatus = (text) => {
    status.textContent = text;
    status.classList.add('visible');
    clearTimeout(statusTimer);
    statusTimer = setTimeout(() => status.classList.remove('visible'), 2600);
  };

  const setView = (view) => {
    state.view = view;
    desktop.dataset.view = view;
    $('#drawer').inert = view !== 'drawer';
    $('#library').inert = view !== 'library';
    $('#menu-drawer').setAttribute('aria-expanded', String(view === 'drawer'));
    if (view !== 'desktop') desktop.classList.remove('focus-notes');
  };

  /* ---------- sticky notes ---------- */
  const noteColors = ['yellow', 'mint', 'blue', 'pink'];
  const renderNotes = () => {
    notesLayer.textContent = '';
    state.notes.filter((note) => note.open).forEach((note) => {
      const sticky = document.createElement('article');
      sticky.className = 'sticky';
      sticky.dataset.position = note.position;
      sticky.dataset.color = note.color;
      sticky.dataset.id = note.id;
      sticky.innerHTML = `
        <div class="sticky-top">
          <button type="button" class="sticky-close" aria-label="Fermer la note"><span>×</span></button>
          <input class="sticky-title" value="" aria-label="Titre de la note" maxlength="42">
          <span class="sticky-saved" aria-hidden="true"></span>
        </div>
        <textarea aria-label="Contenu de la note" spellcheck="false"></textarea>
        <div class="sticky-footer">
          <button type="button" data-action="new" title="Nouvelle note">＋</button>
          <button type="button" data-action="delete" title="Mettre à la corbeille">▭</button>
          <span class="note-swatches" role="group" aria-label="Couleur de la note">
            ${noteColors.map((color) => `<button type="button" data-color="${color}" style="--swatch:${{yellow:'#fff3b0',mint:'#dff8ef',blue:'#d8ecff',pink:'#fad7f2'}[color]}" aria-pressed="${note.color === color}" aria-label="Couleur ${color}"></button>`).join('')}
          </span>
          <span style="margin-left:auto;font-size:10px;opacity:.55" aria-hidden="true">⌘ +</span>
        </div>`;
      $('.sticky-title', sticky).value = note.title;
      $('textarea', sticky).value = note.content;
      notesLayer.append(sticky);
    });
  };

  const flagSaved = (sticky) => {
    const flag = $('.sticky-saved', sticky);
    flag.textContent = 'Enregistré ✓';
    clearTimeout(flag._timer);
    flag._timer = setTimeout(() => { flag.textContent = ''; }, 1500);
  };

  notesLayer.addEventListener('input', (event) => {
    const sticky = event.target.closest('.sticky');
    if (!sticky) return;
    const note = state.notes.find((item) => item.id === sticky.dataset.id);
    if (!note) return;
    if (event.target.classList.contains('sticky-title')) note.title = event.target.value;
    else note.content = event.target.value;
    flagSaved(sticky);
  });

  notesLayer.addEventListener('click', (event) => {
    const sticky = event.target.closest('.sticky');
    if (!sticky) return;
    const note = state.notes.find((item) => item.id === sticky.dataset.id);
    if (event.target.closest('.sticky-close')) {
      note.open = false;
      sticky.remove();
      showStatus(`« ${note.title || 'Sans titre'} » rejoint la corbeille — restaurable depuis la liste des notes.`);
      return;
    }
    const action = event.target.closest('[data-action]')?.dataset.action;
    if (action === 'new') return createNote();
    if (action === 'delete') {
      note.open = false;
      sticky.remove();
      showStatus('Note déplacée vers la corbeille.');
      return;
    }
    const swatch = event.target.closest('[data-color]');
    if (swatch) {
      note.color = swatch.dataset.color;
      sticky.dataset.color = note.color;
      $$('.note-swatches button', sticky).forEach((button) => button.setAttribute('aria-pressed', String(button === swatch)));
    }
  });

  const createNote = (content = '') => {
    const note = {
      id: `note-${state.nextNote++}`,
      title: content ? 'Une idée à garder' : 'Nouvelle note',
      content,
      color: noteColors[state.nextNote % noteColors.length],
      open: true,
      position: 'center'
    };
    state.notes.push(note);
    setView('desktop');
    desktop.classList.add('focus-notes');
    renderNotes();
    const sticky = $(`.sticky[data-id="${note.id}"]`);
    sticky.querySelector('textarea').focus();
    return note;
  };

  /* sticky drag — pointer events only, constrained to the notes layer */
  notesLayer.addEventListener('pointerdown', (event) => {
    const bar = event.target.closest('.sticky-top');
    if (!bar || event.target.closest('button, input')) return;
    const sticky = bar.closest('.sticky');
    const layerRect = notesLayer.getBoundingClientRect();
    const rect = sticky.getBoundingClientRect();
    const offset = { x: event.clientX - rect.left, y: event.clientY - rect.top };
    sticky.style.position = 'absolute';
    sticky.style.width = `${rect.width}px`;
    sticky.style.height = `${rect.height}px`;
    sticky.style.left = `${rect.left - layerRect.left}px`;
    sticky.style.top = `${rect.top - layerRect.top}px`;
    sticky.setPointerCapture(event.pointerId);
    const move = (moveEvent) => {
      const x = Math.min(Math.max(moveEvent.clientX - layerRect.left - offset.x, -40), layerRect.width - rect.width + 40);
      const y = Math.min(Math.max(moveEvent.clientY - layerRect.top - offset.y, 0), layerRect.height - 60);
      sticky.style.left = `${x}px`;
      sticky.style.top = `${y}px`;
      sticky.style.transform = 'rotate(0deg)';
    };
    const up = () => {
      sticky.removeEventListener('pointermove', move);
      sticky.removeEventListener('pointerup', up);
    };
    sticky.addEventListener('pointermove', move);
    sticky.addEventListener('pointerup', up);
  });

  /* ---------- drawer + library cards ---------- */
  const kindIcon = { text: '¶', color: '◍', url: '⌁', file: '▤' };
  const clipCard = (clip, { library = false } = {}) => {
    const app = PKDemo.apps[clip.app];
    const card = document.createElement('article');
    card.className = 'clip-card';
    card.dataset.id = clip.id;
    card.tabIndex = 0;
    const body = clip.kind === 'color'
      ? `<div class="clip-color" style="background:${clip.content}">${clip.content}</div>`
      : `<div class="clip-content ${clip.app === 'code' ? 'is-code' : ''}">${clip.kind === 'url' ? `<strong>${clip.title}</strong><span class="clip-url">${clip.content.replace('https://', '')}</span>` : clip.content}</div>`;
    card.innerHTML = `
      <div class="clip-top"><img src="${app.icon}" alt="" width="19" height="19"><span class="clip-app">${app.name}</span><time>${clip.time}</time></div>
      ${body}
      <div class="clip-actions">
        <button type="button" class="pin" aria-pressed="${clip.pinned}" aria-label="Épingler">◇</button>
        <button type="button" class="copy" aria-label="Copier">${kindIcon[clip.kind] || '¶'}</button>
        <button type="button" class="convert">${library ? '▤ Note' : '↗ Note'}</button>
      </div>`;
    if (!library && state.selected === clip.id) card.classList.add('selected');
    return card;
  };

  const renderDrawer = () => {
    state.query = drawerQuery;
    const list = PKDemo.filter(state);
    drawerItems.textContent = '';
    if (!list.length) {
      drawerItems.innerHTML = '<p class="empty">Rien pour ce filtre — essayez « Tout ».</p>';
    } else {
      list.forEach((clip) => drawerItems.append(clipCard(clip)));
      if (!list.some((clip) => clip.id === state.selected)) state.selected = list[0].id;
      drawerItems.querySelector(`[data-id="${state.selected}"]`)?.classList.add('selected');
    }
    $('#drawer-count').textContent = `${list.length} élément${list.length > 1 ? 's' : ''}`;
  };

  const renderLibrary = () => {
    const appCounts = {};
    state.clips.forEach((clip) => { appCounts[clip.app] = (appCounts[clip.app] || 0) + 1; });
    sourceButtons.textContent = '';
    Object.entries(PKDemo.apps).forEach(([key, app]) => {
      if (!appCounts[key]) return;
      const button = document.createElement('button');
      button.type = 'button';
      button.dataset.source = key;
      button.className = 'source-button';
      button.setAttribute('aria-pressed', String(state.source === key));
      button.innerHTML = `<img src="${app.icon}" alt="" width="20" height="20"><span class="source-name">${app.name}</span><small>${appCounts[key]}</small>`;
      sourceButtons.append(button);
    });
    $$('.source-button', library).forEach((button) => {
      button.setAttribute('aria-pressed', String(button.dataset.source === state.source));
    });
    state.query = libraryQuery;
    libraryGrid.textContent = '';
    if (state.source === 'notes') {
      const needle = libraryQuery.trim().toLowerCase();
      const notes = state.notes.filter((note) => (note.title + '\n' + note.content).toLowerCase().includes(needle));
      notes.forEach((note) => libraryGrid.append(noteCard(note)));
    } else {
      const clips = PKDemo.filter(state, true);
      if (state.source === 'all') libraryGrid.append(...state.notes.map((note) => noteCard(note)));
      if (!clips.length && state.source !== 'all') libraryGrid.innerHTML = '<p class="empty">Rien ici pour le moment.</p>';
      clips.forEach((clip) => libraryGrid.append(clipCard(clip, { library: true })));
    }
    const total = libraryGrid.children.length;
    const empty = !!libraryGrid.querySelector('.empty');
    $('#library-count').textContent = `${empty ? 0 : total} élément${total > 1 ? 's' : ''}`;
    const titles = { all: ['Tout votre historique', 'Ce que vous avez copié. Ce que vous voulez garder.'], notes: ['Vos sticky notes', 'Vos idées, vos listes, vos calculs.'], pinned: ['Les épinglés', 'Toujours en haut du tiroir.'] };
    const app = PKDemo.apps[state.source];
    $('#collection-title').textContent = app ? app.name : (titles[state.source] || titles.all)[0];
    $('#collection-subtitle').textContent = app ? `Tout ce qui vient de ${app.name}.` : (titles[state.source] || titles.all)[1];
  };

  const noteCard = (note) => {
    const card = document.createElement('article');
    card.className = 'clip-card note-card';
    card.dataset.note = note.id;
    card.dataset.color = note.color;
    card.innerHTML = `<div class="clip-top"><span class="clip-app">▤ Sticky note</span><time>${note.open ? 'ouverte' : 'fermée'}</time></div><h3></h3><p></p><div class="clip-actions"><button type="button" class="convert" data-open="1">Ouvrir</button></div>`;
    $('h3', card).textContent = note.title;
    $('p', card).textContent = note.content;
    return card;
  };

  const convertClip = (id, { focus = true } = {}) => {
    const clip = state.clips.find((item) => item.id === id);
    const note = PKDemo.convert(state, id);
    renderNotes();
    if (focus) {
      setView('desktop');
      desktop.classList.add('focus-notes');
      $(`.sticky[data-id="${note.id}"]`)?.querySelector('textarea')?.focus();
    }
    showStatus(`« ${clip ? clip.content.split('\n')[0].slice(0, 32) : ''}… » devient une note — à vous de la compléter.`);
    return note;
  };

  drawerItems.addEventListener('click', (event) => {
    const card = event.target.closest('.clip-card');
    if (!card) return;
    state.selected = card.dataset.id;
    if (event.target.closest('.pin')) {
      const clip = state.clips.find((item) => item.id === card.dataset.id);
      clip.pinned = !clip.pinned;
      renderDrawer();
      showStatus(clip.pinned ? 'Épinglé — reste en tête du tiroir.' : 'Détaché.');
      return;
    }
    if (event.target.closest('.convert')) return convertClip(card.dataset.id);
    if (event.target.closest('.copy')) return showStatus('Copié — ⌘V le colle dans la dernière app active.');
    $$('.clip-card', drawerItems).forEach((item) => item.classList.toggle('selected', item === card));
  });

  drawerItems.addEventListener('dblclick', (event) => {
    const card = event.target.closest('.clip-card');
    if (card) convertClip(card.dataset.id);
  });

  libraryGrid.addEventListener('click', (event) => {
    const noteButton = event.target.closest('[data-open]');
    if (noteButton) {
      const note = state.notes.find((item) => item.id === noteButton.closest('[data-note]').dataset.note);
      note.open = true;
      renderNotes();
      setView('desktop');
      desktop.classList.add('focus-notes');
      $(`.sticky[data-id="${note.id}"]`)?.querySelector('textarea')?.focus();
      showStatus(`« ${note.title} » est de retour sur le bureau.`);
      return;
    }
    const card = event.target.closest('.clip-card:not([data-note])');
    if (!card) return;
    if (event.target.closest('.pin')) {
      const clip = state.clips.find((item) => item.id === card.dataset.id);
      clip.pinned = !clip.pinned;
      renderLibrary();
      return;
    }
    if (event.target.closest('.convert')) convertClip(card.dataset.id);
    else if (event.target.closest('.copy')) showStatus('Copié — ⌘V le colle où vous étiez.');
  });

  $('#library-new').addEventListener('click', () => createNote());

  /* ---------- filters & search ---------- */
  $$('.type-filters button').forEach((button) => button.addEventListener('click', () => {
    state.kind = button.dataset.kind;
    $$('.type-filters button').forEach((item) => item.setAttribute('aria-pressed', String(item === button)));
    renderDrawer();
  }));
  $('#drawer-search').addEventListener('input', (event) => { drawerQuery = event.target.value; renderDrawer(); });
  $('#library-search').addEventListener('input', (event) => { libraryQuery = event.target.value; renderLibrary(); });

  const library = $('#library');
  library.addEventListener('click', (event) => {
    const source = event.target.closest('.source-button')?.dataset.source;
    if (!source) return;
    state.source = source;
    $$('.source-button', library).forEach((button) => button.setAttribute('aria-pressed', String(button.dataset.source === source)));
    renderLibrary();
  });

  /* ---------- window chrome, dock, menu ---------- */
  $('#menu-drawer').addEventListener('click', () => setView(state.view === 'drawer' ? 'desktop' : 'drawer'));
  $('#close-drawer').addEventListener('click', () => setView('desktop'));
  $('#expand-library').addEventListener('click', () => { setView('library'); renderLibrary(); });
  $('#close-library').addEventListener('click', () => setView('desktop'));
  $('#minimize-library').addEventListener('click', () => { setView('drawer'); renderDrawer(); });
  $('#maximize-library').addEventListener('click', (event) => {
    library.classList.toggle('expanded');
    event.currentTarget.setAttribute('aria-pressed', String(library.classList.contains('expanded')));
  });

  $$('.dock button').forEach((button) => button.addEventListener('click', () => {
    const view = button.dataset.view;
    if (view === 'drawer') { setView(state.view === 'drawer' ? 'desktop' : 'drawer'); renderDrawer(); }
    if (view === 'library') { setView(state.view === 'library' ? 'desktop' : 'library'); renderLibrary(); }
    if (view === 'notes') {
      if (desktop.classList.contains('focus-notes') && state.view === 'desktop') desktop.classList.remove('focus-notes');
      else { setView('desktop'); desktop.classList.add('focus-notes'); }
    }
    if (view === 'new') createNote();
  }));

  $('#reset-demo').addEventListener('click', () => {
    state = PKDemo.create();
    drawerQuery = libraryQuery = '';
    $('#drawer-search').value = '';
    $('#library-search').value = '';
    stopTour();
    library.classList.remove('expanded');
    setView('desktop');
    desktop.classList.remove('focus-notes');
    state.kind = 'all';
    $$('.type-filters button').forEach((item) => item.setAttribute('aria-pressed', String(item.dataset.kind === 'all')));
    renderAll();
    showStatus('Playground remis à zéro.');
  });

  /* ---------- guided tour ---------- */
  const tour = [
    { title: 'Copiez une idée.', text: 'Elle entre dans votre historique, avec son application d’origine.', run: () => { setView('drawer'); renderDrawer(); } },
    { title: 'Gardez ce qui compte.', text: 'Un extrait mérite mieux que le prochain ⌘V. « ↗ Note » le transforme en sticky.', run: () => { setView('drawer'); state.selected = 'clip-1'; renderDrawer(); } },
    { title: 'Il devient une note.', text: 'La voilà sur le bureau, prête à être complétée.', run: () => convertClip('clip-1') },
    { title: 'Ajoutez vos idées.', text: 'Écrivez, calculez, colorez. L’historique était le début — la note est à vous.', run: () => { const sticky = $('.sticky[data-position=center]'); sticky?.querySelector('textarea')?.focus(); } }
  ];
  const caption = $('#tour-caption');
  const playTourStep = (index) => {
    tourStep = index;
    if (index >= tour.length) return stopTour();
    caption.hidden = false;
    $('#tour-number').textContent = `${String(index + 1).padStart(2, '0')} / ${String(tour.length).padStart(2, '0')}`;
    $('#tour-title').textContent = tour[index].title;
    $('#tour-text').textContent = tour[index].text;
    tour[index].run();
    clearTimeout(tourTimer);
    tourTimer = setTimeout(() => playTourStep(index + 1), 4200);
  };
  function stopTour() {
    tourStep = -1;
    clearTimeout(tourTimer);
    caption.hidden = true;
  }
  $('#start-tour').addEventListener('click', () => playTourStep(0));
  $('#stop-tour').addEventListener('click', stopTour);

  /* ---------- keyboard ---------- */
  document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
      if (tourStep >= 0) return stopTour();
      if (state.view === 'library') return setView('desktop');
      if (state.view === 'drawer') return setView('desktop');
    }
    if (state.view === 'drawer' && !event.target.closest('input, textarea')) {
      state.query = drawerQuery;
      const list = PKDemo.filter(state);
      if (!list.length) return;
      const index = list.findIndex((clip) => clip.id === state.selected);
      if (event.key === 'ArrowRight' || event.key === 'ArrowLeft') {
        event.preventDefault();
        const next = (index + (event.key === 'ArrowRight' ? 1 : -1) + list.length) % list.length;
        state.selected = list[next].id;
        renderDrawer();
        drawerItems.querySelector(`[data-id="${state.selected}"]`)?.scrollIntoView({ block: 'nearest', inline: 'nearest' });
      }
      if (event.key === 'Enter') {
        event.preventDefault();
        if (event.metaKey || event.ctrlKey) convertClip(state.selected);
        else showStatus('Copié — ⌘V le colle dans la dernière app active.');
      }
    }
  });

  /* ---------- page sections wiring ---------- */
  $$('.capture-tabs button').forEach((button) => button.addEventListener('click', () => {
    $$('.capture-tabs button').forEach((item) => {
      const selected = item === button;
      item.setAttribute('aria-selected', String(selected));
      item.tabIndex = selected ? 0 : -1;
    });
    const capture = button.dataset.capture;
    $('#native-drawer').hidden = capture !== 'drawer';
    $('#native-library').hidden = capture !== 'library';
    $('#native-notes').hidden = capture !== 'notes';
    $('#capture-description').textContent = {
      drawer: '⌘⇧V. Votre historique descend depuis la barre des menus. Retrouvez, épinglez, collez ou convertissez en note.',
      library: 'La fenêtre complète : votre collection classée par application, avec vos sticky notes dans le même flux.',
      notes: 'Des fenêtres natives, des couleurs douces, une barre d’outils discrète. Capturées depuis l’app, sans bruit autour.'
    }[capture];
  }));
  $('.capture-tabs').addEventListener('keydown', (event) => {
    if (event.key !== 'ArrowRight' && event.key !== 'ArrowLeft') return;
    const buttons = $$('.capture-tabs button');
    const current = buttons.findIndex((item) => item.getAttribute('aria-selected') === 'true');
    const next = (current + (event.key === 'ArrowRight' ? 1 : -1) + buttons.length) % buttons.length;
    buttons[next].click();
    buttons[next].focus();
  });

  $('#try-capture').addEventListener('click', () => {
    const capture = $('.capture-tabs button[aria-selected=true]').dataset.capture;
    document.getElementById('desktop').scrollIntoView({ behavior: reduceMotion ? 'auto' : 'smooth' });
    if (capture === 'library') { setView('library'); renderLibrary(); }
    else if (capture === 'notes') { setView('desktop'); desktop.classList.add('focus-notes'); }
    else { setView('drawer'); renderDrawer(); }
  });
  $('#try-notes').addEventListener('click', () => {
    document.getElementById('desktop').scrollIntoView({ behavior: reduceMotion ? 'auto' : 'smooth' });
    setView('desktop');
    desktop.classList.add('focus-notes');
  });
  $('#concept-convert').addEventListener('click', () => {
    document.getElementById('desktop').scrollIntoView({ behavior: reduceMotion ? 'auto' : 'smooth' });
    setTimeout(() => convertClip('clip-1'), reduceMotion ? 0 : 450);
  });
  $('#copy-brew').addEventListener('click', async (event) => {
    const command = 'brew install --cask mondary/tap/pkbrain';
    try {
      await navigator.clipboard.writeText(command);
      $('span', event.currentTarget).textContent = 'Copié ✓';
      $('#brew-status').textContent = 'Collez-la dans votre terminal.';
    } catch {
      $('#brew-status').textContent = command;
    }
    setTimeout(() => { $('span', event.currentTarget).textContent = 'Copier'; }, 2200);
  });

  /* ---------- variantes de fond d’écran (?bg=a|b|c) ---------- */
  const wallpapers = { a: 'assets/wallpaper.webp', b: 'assets/wallpaper-b.webp', c: 'assets/wallpaper-c.webp' };
  const applyWallpaper = (key) => {
    const variant = wallpapers[key] ? key : 'b';
    desktop.dataset.bg = variant;
    $('.wallpaper').src = wallpapers[variant];
    document.documentElement.style.setProperty('--capture-wallpaper', `url("${wallpapers[variant]}")`);
    $$('.bg-picker button').forEach((button) => button.setAttribute('aria-pressed', String(button.dataset.bg === variant)));
    const url = new URL(location);
    url.searchParams.set('bg', variant);
    history.replaceState(null, '', url);
  };
  $$('.bg-picker button').forEach((button) => button.addEventListener('click', () => applyWallpaper(button.dataset.bg)));
  applyWallpaper(new URLSearchParams(location.search).get('bg'));

  const renderAll = () => { renderNotes(); renderDrawer(); renderLibrary(); };
  renderAll();
  setView('desktop');
})();
