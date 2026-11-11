/* This playground only owns synthetic in-memory data. No system clipboard reads. */
(function (root) {
  const apps = {
    safari: { name: 'Safari', icon: 'assets/app-safari.png' },
    figma: { name: 'Figma', icon: 'assets/app-figma.png' },
    mail: { name: 'Mail', icon: 'assets/app-mail.png' },
    code: { name: 'Visual Studio Code', icon: 'assets/app-code.png' },
    finder: { name: 'Finder', icon: 'assets/app-finder.png' }
  };
  function create() {
    return {
      view: 'desktop', source: 'all', kind: 'all', query: '', selected: 'clip-1', nextNote: 4,
      clips: [
        { id: 'clip-1', app: 'safari', kind: 'text', content: 'Moins de friction.\nPlus de place pour les idées.', pinned: true, time: 'à l’instant' },
        { id: 'clip-2', app: 'figma', kind: 'color', content: '#DFF8EF', pinned: false, time: 'il y a 1 min' },
        { id: 'clip-3', app: 'mail', kind: 'text', content: 'On se retrouve jeudi à 10 h pour découvrir les nouvelles pistes du projet.', pinned: false, time: 'il y a 2 min' },
        { id: 'clip-4', app: 'code', kind: 'text', content: 'const idea = capture();\nconst note = idea.keep();\nnote.add(yourThoughts);', pinned: false, time: 'il y a 4 min' },
        { id: 'clip-5', app: 'safari', kind: 'url', content: 'https://developer.apple.com/design/', title: 'Designing for macOS', pinned: false, time: 'il y a 6 min' },
        { id: 'clip-6', app: 'finder', kind: 'text', content: 'Présentation du projet\nVersion finale • Septembre 2026', pinned: false, time: 'il y a 8 min' },
        { id: 'clip-7', app: 'mail', kind: 'text', content: 'Le prototype est validé. Prochaine étape : préparer la présentation.', pinned: false, time: 'il y a 10 min' }
      ],
      notes: [
        { id: 'note-1', title: 'Une idée à garder', content: 'Moins de friction.\nPlus de place pour les idées.\n\nÀ retenir pour notre projet :\n• Une interface qui s’efface\n• Un raccourci pour chaque geste\n• Le plaisir des petits détails', color: 'yellow', open: true, position: 'left' },
        { id: 'note-2', title: 'Pour demain', content: '• Affiner la première impression\n• Partager les pistes de design\n• Préparer le prototype\n\nUne chose à la fois.\nLes bonnes idées à portée de main.', color: 'mint', open: true, position: 'right' },
        { id: 'note-3', title: 'Le budget du projet', content: 'Budget de lancement\n\nbudget = 1200\ndesign = 450\ndev = 600\n\nReste : 150\nGarder une marge pour la suite.', color: 'blue', open: false, position: 'center' }
      ]
    };
  }
  const normalize = text => text.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase();
  function filter(state, library = false) {
    let list = library && state.source === 'notes' ? state.notes : state.clips;
    return list.filter(item => {
      if (library && state.source === 'pinned' && !item.pinned) return false;
      if (library && apps[state.source] && item.app !== state.source) return false;
      if (!library && state.kind !== 'all' && item.kind !== state.kind) return false;
      return normalize(`${item.content} ${item.title || ''} ${apps[item.app]?.name || ''}`).includes(normalize(state.query.trim()));
    });
  }
  function convert(state, id) {
    const clip = state.clips.find(item => item.id === id);
    if (!clip) return null;
    const existing = state.notes.find(note => note.origin === id);
    if (existing) { existing.open = true; return existing; }
    const note = { id: `note-${state.nextNote++}`, origin: id, title: 'Une idée à garder', content: clip.content + '\n\n', color: 'yellow', open: true, position: 'center' };
    state.notes.push(note);
    return note;
  }
  root.PKDemo = { apps, create, filter, convert };
})(globalThis);
