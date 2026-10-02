// site.js - shared header behavior: Ctrl+K search over posts and pages, mobile menu.
(function () {
  'use strict';

  const PAGES = [
    { kind: 'Page', title: 'Benchmarks', text: 'Every AHK v2 benchmark suite and how it is graded', href: 'benchmarks.html' },
    { kind: 'Page', title: 'AHK-Eval Leaderboard', text: '36 tasks, 181 hidden cases, every model ranked', href: 'leaderboard.html' },
    { kind: 'Page', title: 'Clipboard Leaderboard', text: 'The GUI clipboard-formatter board', href: 'clipboard-leaderboard.html' },
    { kind: 'Page', title: 'Prompts', text: 'The exact benchmark prompts', href: 'prompts.html' },
    { kind: 'Page', title: 'Wiki', text: 'AHK v2 reference notes', href: 'wiki.html' },
    { kind: 'Page', title: 'Inheritance', text: 'Classes, prototypes and inheritance in AHK v2', href: 'inheritance.html' },
    { kind: 'Page', title: 'Console', text: 'The v2.1-alpha.30+Console fork', href: 'console.html' },
    { kind: 'Page', title: 'Playground', text: 'Run AHK v2 code in the browser via CloudAHK', href: 'playground.html' }
  ];
  const MAX_RESULTS = 8;

  const ICON_SEARCH = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"><circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/></svg>';

  let overlay = null;
  let input = null;
  let list = null;
  let entries = null;
  let matches = [];
  let selected = 0;
  let lastFocus = null;

  function loadEntries() {
    if (entries) return Promise.resolve(entries);
    return fetch('posts/posts.json')
      .then(r => {
        if (!r.ok) throw new Error('posts.json ' + r.status);
        return r.json();
      })
      .then(posts => {
        const postEntries = posts.map(p => ({
          kind: 'Post · ' + p.date,
          title: p.title,
          text: p.preview || p.description || '',
          tags: (p.tags || []).join(' '),
          href: 'post.html?slug=' + encodeURIComponent(p.slug),
          date: p.date
        }));
        postEntries.sort((a, b) => (a.date < b.date ? 1 : -1));
        entries = postEntries.concat(PAGES);
        return entries;
      })
      .catch(err => {
        console.error('Search index failed to load:', err);
        entries = PAGES.slice();
        return entries;
      });
  }

  function score(entry, terms) {
    const title = entry.title.toLowerCase();
    const hay = (entry.title + ' ' + entry.text + ' ' + (entry.tags || '')).toLowerCase();
    let total = 0;
    for (const t of terms) {
      if (!hay.includes(t)) return 0;
      total += title.includes(t) ? 3 : 1;
    }
    return total;
  }

  function render() {
    list.textContent = '';
    if (!matches.length) {
      const empty = document.createElement('li');
      empty.className = 'search-empty';
      empty.textContent = entries ? 'No matches.' : 'Loading…';
      list.appendChild(empty);
      return;
    }
    matches.forEach((m, i) => {
      const li = document.createElement('li');
      li.className = 'search-result';
      li.id = 'search-result-' + i;
      li.setAttribute('role', 'option');
      li.setAttribute('aria-selected', i === selected ? 'true' : 'false');
      const a = document.createElement('a');
      a.href = m.href;
      const kind = document.createElement('span');
      kind.className = 'search-result-kind';
      kind.textContent = m.kind;
      const title = document.createElement('span');
      title.className = 'search-result-title';
      title.textContent = m.title;
      const text = document.createElement('span');
      text.className = 'search-result-text';
      text.textContent = m.text;
      a.append(kind, title, text);
      a.addEventListener('mousemove', () => select(i));
      li.appendChild(a);
      list.appendChild(li);
    });
    input.setAttribute('aria-activedescendant', 'search-result-' + selected);
  }

  function update() {
    const q = input.value.trim().toLowerCase();
    const terms = q.split(/\s+/).filter(Boolean);
    const pool = entries || [];
    if (!terms.length) {
      matches = pool.slice(0, MAX_RESULTS);
    } else {
      matches = pool
        .map(e => ({ e, s: score(e, terms) }))
        .filter(x => x.s > 0)
        .sort((a, b) => b.s - a.s)
        .slice(0, MAX_RESULTS)
        .map(x => x.e);
    }
    selected = 0;
    render();
  }

  function select(i) {
    if (i === selected || !matches.length) return;
    selected = (i + matches.length) % matches.length;
    list.querySelectorAll('.search-result').forEach((el, n) => {
      el.setAttribute('aria-selected', n === selected ? 'true' : 'false');
    });
    const el = list.children[selected];
    if (el) el.scrollIntoView({ block: 'nearest' });
    input.setAttribute('aria-activedescendant', 'search-result-' + selected);
  }

  function build() {
    overlay = document.createElement('div');
    overlay.className = 'search-overlay';
    overlay.hidden = true;
    overlay.innerHTML =
      '<div class="search-panel" role="dialog" aria-modal="true" aria-label="Search">' +
        '<div class="search-field">' + ICON_SEARCH +
          '<input type="search" placeholder="Search posts and pages" autocomplete="off" spellcheck="false" role="combobox" aria-expanded="true" aria-controls="search-results">' +
          '<kbd>Esc</kbd>' +
        '</div>' +
        '<ul class="search-results" id="search-results" role="listbox"></ul>' +
        '<div class="search-footer"><span><kbd>↑</kbd><kbd>↓</kbd>navigate</span><span><kbd>↵</kbd>open</span></div>' +
      '</div>';
    document.body.appendChild(overlay);
    input = overlay.querySelector('input');
    list = overlay.querySelector('.search-results');

    overlay.addEventListener('mousedown', e => {
      if (e.target === overlay) close();
    });
    input.addEventListener('input', update);
    input.addEventListener('keydown', e => {
      if (e.key === 'ArrowDown') { e.preventDefault(); select(selected + 1); }
      else if (e.key === 'ArrowUp') { e.preventDefault(); select(selected - 1); }
      else if (e.key === 'Enter') {
        const m = matches[selected];
        if (m) { e.preventDefault(); window.location.href = m.href; }
      }
      else if (e.key === 'Escape') { e.preventDefault(); close(); }
    });
  }

  function open() {
    if (!overlay) build();
    lastFocus = document.activeElement;
    overlay.hidden = false;
    document.documentElement.style.overflow = 'hidden';
    input.value = '';
    matches = [];
    render();
    input.focus();
    loadEntries().then(update);
  }

  function close() {
    if (!overlay || overlay.hidden) return;
    overlay.hidden = true;
    document.documentElement.style.overflow = '';
    if (lastFocus && lastFocus.focus) lastFocus.focus();
  }

  function isTyping(el) {
    return el && (el.isContentEditable || /^(INPUT|TEXTAREA|SELECT)$/.test(el.tagName));
  }

  document.addEventListener('keydown', e => {
    const k = e.key.toLowerCase();
    if ((e.ctrlKey || e.metaKey) && k === 'k') {
      e.preventDefault();
      if (overlay && !overlay.hidden) close(); else open();
    } else if (k === '/' && !isTyping(document.activeElement) && (!overlay || overlay.hidden)) {
      e.preventDefault();
      open();
    }
  });

  function initHeader() {
    document.querySelectorAll('[data-search-open]').forEach(btn => btn.addEventListener('click', open));

    const header = document.querySelector('.site-header');
    const toggle = document.querySelector('[data-menu-toggle]');
    if (header && toggle) {
      toggle.addEventListener('click', () => {
        const isOpen = header.classList.toggle('menu-open');
        toggle.setAttribute('aria-expanded', isOpen ? 'true' : 'false');
      });
      header.querySelectorAll('.nav-link').forEach(a => a.addEventListener('click', () => {
        header.classList.remove('menu-open');
        toggle.setAttribute('aria-expanded', 'false');
      }));
    }

    const key = document.querySelector('.search-key');
    if (key && /Mac|iPhone|iPad/.test(navigator.platform || '')) key.textContent = '⌘ K';
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', initHeader);
  else initHeader();
})();
