const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

if (!reduceMotion && 'IntersectionObserver' in window) {
  document.documentElement.classList.add('motion-ready');
  const revealObserver = new IntersectionObserver((entries, observer) => {
    entries.forEach((entry) => {
      if (!entry.isIntersecting) return;
      entry.target.classList.add('is-visible');
      observer.unobserve(entry.target);
    });
  }, { threshold: 0.12, rootMargin: '0px 0px -30px 0px' });
  document.querySelectorAll('.reveal').forEach((element) => revealObserver.observe(element));

  const hero = document.querySelector('.hero');
  let pointerFrame = 0;
  hero.addEventListener('pointermove', (event) => {
    if (event.pointerType === 'touch' || pointerFrame) return;
    pointerFrame = requestAnimationFrame(() => {
      const rect = hero.getBoundingClientRect();
      hero.style.setProperty('--pointer-x', ((event.clientX - rect.left) / rect.width - .5).toFixed(2));
      hero.style.setProperty('--pointer-y', ((event.clientY - rect.top) / rect.height - .5).toFixed(2));
      pointerFrame = 0;
    });
  });
  hero.addEventListener('pointerleave', () => {
    hero.style.setProperty('--pointer-x', 0);
    hero.style.setProperty('--pointer-y', 0);
  });
}

const examples = {
  budget: { title: 'Budget de lancement', rows: [['budget = 1200', '1 200'], ['charges = budget × 0,15', '180'], ['total = budget + charges', '1 380']] },
  units: { title: 'Une idée en mouvement', rows: [['distance = 5 km', '5 km'], ['distance en mètres', '5 000 m'], ['durée = 90 min', '1 h 30']] }
};
const noteRows = [...document.querySelectorAll('#demo-lines > div')];
document.querySelectorAll('.demo-switch').forEach((button) => {
  button.addEventListener('click', () => {
    const example = examples[button.dataset.example];
    document.querySelector('#demo-heading').textContent = example.title;
    noteRows.forEach((row, index) => {
      row.querySelector('span').textContent = example.rows[index][0];
      row.querySelector('strong').textContent = example.rows[index][1];
    });
    document.querySelectorAll('.demo-switch').forEach((item) => {
      const active = item === button;
      item.classList.toggle('is-active', active);
      item.setAttribute('aria-pressed', String(active));
    });
  });
});

const search = document.querySelector('#command-search');
search.setAttribute('role', 'combobox');
search.setAttribute('aria-expanded', 'true');
search.setAttribute('aria-autocomplete', 'list');
const results = [...document.querySelectorAll('.command-result')];
const commandStatus = document.querySelector('#command-status');
let selected = 0;
const normalize = (text) => text.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase();

function updateSelection() {
  const visible = results.filter((result) => !result.hidden);
  selected = Math.min(Math.max(selected, 0), visible.length - 1);
  results.forEach((result) => {
    const active = result === visible[selected];
    result.classList.toggle('is-selected', active);
    result.setAttribute('aria-selected', String(active));
  });
  if (visible[selected]) search.setAttribute('aria-activedescendant', visible[selected].id);
  else search.removeAttribute('aria-activedescendant');
}

search.addEventListener('input', () => {
  const query = normalize(search.value.trim());
  results.forEach((result) => { result.hidden = !normalize(result.dataset.search).includes(query); });
  selected = 0;
  updateSelection();
  commandStatus.textContent = results.some((result) => !result.hidden) ? '↑ ↓ pour naviguer · Entrée pour choisir' : 'Aucun résultat dans cette démonstration';
});

search.addEventListener('keydown', (event) => {
  const visible = results.filter((result) => !result.hidden);
  if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
    event.preventDefault();
    if (!visible.length) return;
    selected = (selected + (event.key === 'ArrowDown' ? 1 : -1) + visible.length) % visible.length;
    updateSelection();
  } else if (event.key === 'Enter' && visible[selected]) {
    event.preventDefault();
    commandStatus.textContent = `Démo : « ${visible[selected].children[1].textContent} » sélectionné`;
  } else if (event.key === 'Escape') {
    search.value = '';
    search.dispatchEvent(new Event('input'));
    search.blur();
  }
});

results.forEach((result) => result.addEventListener('click', () => {
  selected = results.filter((item) => !item.hidden).indexOf(result);
  updateSelection();
  commandStatus.textContent = `Démo : « ${result.children[1].textContent} » sélectionné`;
  search.focus();
}));

function focusPalette() {
  document.querySelector('#palette').scrollIntoView({ behavior: reduceMotion ? 'auto' : 'smooth' });
  search.focus({ preventScroll: true });
}
document.querySelector('#try-palette').addEventListener('click', focusPalette);
document.addEventListener('keydown', (event) => {
  if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === 'k') {
    event.preventDefault();
    focusPalette();
  }
});

document.querySelector('#copy-command').addEventListener('click', async () => {
  const status = document.querySelector('#copy-status');
  try {
    await navigator.clipboard.writeText('brew install --cask mondary/tap/pkbrain');
    status.textContent = 'Commande copiée.';
  } catch {
    status.textContent = 'Copie indisponible : sélectionnez la commande ci-dessus.';
  }
});
