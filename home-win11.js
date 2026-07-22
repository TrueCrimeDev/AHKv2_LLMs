(() => {
  const desktop = document.querySelector('[data-win-desktop]');
  if (!desktop) return;

  const demoOutput = desktop.querySelector('[data-demo-output]');
  const demoVisual = desktop.querySelector('[data-demo-visual]');
  const demoStatus = desktop.querySelector('[data-demo-status]');
  const demoLabel = desktop.querySelector('[data-demo-label]');
  const demoTitle = desktop.querySelector('[data-demo-title]');
  const demoDescription = desktop.querySelector('[data-demo-description]');
  const demoCode = desktop.querySelector('[data-demo-code]');
  const startButton = desktop.querySelector('[data-start-button]');
  const startMenu = desktop.querySelector('[data-start-menu]');
  const windows = [...desktop.querySelectorAll('[data-window]')];
  let statusTimer;

  const demos = {
    windows: {
      file: 'window-layout.ahk',
      label: 'WINDOW CONTROL',
      title: 'Tile a workspace in one command.',
      description: 'AHK can find, focus, resize, and arrange native Windows applications around the way you work.',
      visualClass: 'demo-windows',
      visual: '<div class="mini-window mini-one"><span></span><p>Research</p></div><div class="mini-window mini-two"><span></span><p>Editor</p></div><div class="mini-window mini-three"><span></span><p>Console</p></div>',
      code: '<span>WinMove</span> 0, 0, A_ScreenWidth / 2, A_ScreenHeight, "A"'
    },
    text: {
      file: 'hotstrings.ahk',
      label: 'TEXT EXPANSION',
      title: 'Turn a short trigger into finished writing.',
      description: 'Hotstrings expand signatures, case notes, templates, or any repeated text inside almost any Windows application.',
      visualClass: 'demo-text',
      visual: '<div class="demo-text-editor"><header>New message</header><p>Thanks for your help.<br><br><mark>;sig → Best,<br>Justin</mark></p></div>',
      code: '<span>Hotstring</span> (":*:;sig", ExpandSignature)'
    },
    clipboard: {
      file: 'clipboard-workflow.ahk',
      label: 'CLIPBOARD WORKFLOWS',
      title: 'Transform and reuse everything you copy.',
      description: 'Watch the clipboard, clean incoming text, keep useful snippets, and paste the right format into the active app.',
      visualClass: 'demo-clipboard',
      visual: '<div class="clipboard-list"><div class="clipboard-item"><span>Raw meeting notes</span><b>captured</b></div><div class="clipboard-item is-picked"><span>Clean Markdown</span><b>selected</b></div><div class="clipboard-item"><span>Plain-text summary</span><b>ready</b></div></div>',
      code: '<span>A_Clipboard</span> := CleanMarkdown(A_Clipboard)'
    },
    files: {
      file: 'download-sorter.ahk',
      label: 'FILE AUTOMATION',
      title: 'Sort a messy folder while you keep working.',
      description: 'AHK can watch directories, rename batches, move files by type, and launch the next step in a desktop workflow.',
      visualClass: 'demo-files',
      visual: '<div class="file-sorter"><div class="file-item"><span>report.pdf</span><b>Documents →</b></div><div class="file-item"><span>capture.png</span><b>Images →</b></div><div class="file-item"><span>results.csv</span><b>Data →</b></div></div>',
      code: '<span>Loop Files</span> Downloads "\\*.*" { SortDownload(A_LoopFileFullPath) }'
    },
    gui: {
      file: 'release-builder.ahk',
      label: 'CUSTOM DESKTOP APPS',
      title: 'Build a real Windows interface in AHK.',
      description: 'Create native tools with inputs, buttons, menus, events, and resizable layouts—without leaving AutoHotkey v2.',
      visualClass: 'demo-gui',
      visual: '<div class="gui-preview"><header><span>Release builder</span><span>×</span></header><label>Project name<i></i></label><label>Output folder<i></i></label><footer><button type="button">Build release</button></footer></div>',
      code: '<span>app</span> := Gui("+Resize", "Release builder")'
    }
  };

  function selectDemo(name, animate = true) {
    const demo = demos[name];
    if (!demo || !demoOutput) return;
    desktop.querySelectorAll('[data-ahk-demo]').forEach((button) => {
      button.classList.toggle('is-active', button.dataset.ahkDemo === name && button.classList.contains('automation-button'));
    });
    document.querySelectorAll('[data-ahk-feature]').forEach((button) => {
      const active = button.dataset.ahkFeature === name;
      button.classList.toggle('is-active', active);
      button.setAttribute('aria-pressed', String(active));
    });
    demoOutput.querySelector('.demo-titlebar span').lastChild.textContent = demo.file;
    demoVisual.className = `demo-visual ${demo.visualClass}`;
    demoVisual.innerHTML = demo.visual;
    demoLabel.textContent = demo.label;
    demoTitle.textContent = demo.title;
    demoDescription.textContent = demo.description;
    demoCode.innerHTML = `<code>${demo.code}</code>`;
    if (!animate) return;
    demoOutput.classList.remove('is-running');
    void demoOutput.offsetWidth;
    demoOutput.classList.add('is-running');
    demoStatus.textContent = 'running';
    clearTimeout(statusTimer);
    statusTimer = setTimeout(() => {
      demoStatus.textContent = 'complete';
      demoOutput.classList.remove('is-running');
    }, 720);
  }

  function focusWindow(windowElement) {
    if (!windowElement) return;
    windows.forEach((item) => item.classList.toggle('is-focused', item === windowElement));
  }

  function openWindow(name) {
    const windowElement = desktop.querySelector(`[data-window="${name}"]`);
    if (!windowElement) return;
    windowElement.classList.remove('is-hidden');
    windowElement.setAttribute('aria-hidden', 'false');
    focusWindow(windowElement);
  }

  function toggleStart(force) {
    const shouldOpen = typeof force === 'boolean' ? force : startMenu.hidden;
    startMenu.hidden = !shouldOpen;
    startButton.setAttribute('aria-expanded', String(shouldOpen));
  }

  desktop.addEventListener('click', (event) => {
    const demoButton = event.target.closest('[data-ahk-demo]');
    const openButton = event.target.closest('[data-open-window]');
    const actionButton = event.target.closest('[data-window-action]');

    if (event.target.closest('[data-start-button]')) {
      toggleStart();
      return;
    }
    if (demoButton) selectDemo(demoButton.dataset.ahkDemo);
    if (openButton) openWindow(openButton.dataset.openWindow);
    if (demoButton || openButton) toggleStart(false);

    if (actionButton) {
      const windowElement = actionButton.closest('[data-window]');
      const action = actionButton.dataset.windowAction;
      if (action === 'maximize') {
        windowElement.classList.toggle('is-maximized');
        focusWindow(windowElement);
      } else {
        windowElement.classList.add('is-hidden');
        windowElement.setAttribute('aria-hidden', 'true');
      }
    }

    const clickedWindow = event.target.closest('[data-window]');
    if (clickedWindow) focusWindow(clickedWindow);
    if (!event.target.closest('[data-start-menu], [data-start-button]')) toggleStart(false);
  });

  desktop.querySelectorAll('[data-drag-handle]').forEach((handle) => {
    let drag = null;
    handle.addEventListener('pointerdown', (event) => {
      if (event.button !== 0 || event.target.closest('button') || window.innerWidth <= 1180) return;
      const windowElement = handle.closest('[data-window]');
      if (windowElement.classList.contains('is-maximized')) return;
      const desktopRect = desktop.getBoundingClientRect();
      const windowRect = windowElement.getBoundingClientRect();
      drag = {
        windowElement,
        startX: event.clientX,
        startY: event.clientY,
        left: windowRect.left - desktopRect.left,
        top: windowRect.top - desktopRect.top
      };
      windowElement.style.width = `${windowRect.width}px`;
      windowElement.style.height = `${windowRect.height}px`;
      focusWindow(windowElement);
      handle.setPointerCapture(event.pointerId);
    });
    handle.addEventListener('pointermove', (event) => {
      if (!drag) return;
      const maxLeft = desktop.clientWidth - drag.windowElement.offsetWidth - 8;
      const maxTop = desktop.clientHeight - drag.windowElement.offsetHeight - 72;
      drag.windowElement.style.left = `${Math.max(8, Math.min(maxLeft, drag.left + event.clientX - drag.startX))}px`;
      drag.windowElement.style.top = `${Math.max(8, Math.min(maxTop, drag.top + event.clientY - drag.startY))}px`;
      drag.windowElement.style.right = 'auto';
      drag.windowElement.style.bottom = 'auto';
    });
    const endDrag = () => { drag = null; };
    handle.addEventListener('pointerup', endDrag);
    handle.addEventListener('pointercancel', endDrag);
  });

  document.querySelectorAll('[data-ahk-feature]').forEach((button) => {
    button.addEventListener('click', () => {
      selectDemo(button.dataset.ahkFeature);
      openWindow('studio');
      desktop.scrollIntoView({
        behavior: window.matchMedia('(prefers-reduced-motion: reduce)').matches ? 'auto' : 'smooth',
        block: 'start'
      });
    });
  });

  function updateClock() {
    const now = new Date();
    const time = now.toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' });
    const date = now.toLocaleDateString([], { month: 'numeric', day: 'numeric', year: 'numeric' });
    desktop.querySelectorAll('[data-taskbar-clock]').forEach((node) => { node.textContent = `${time}\n${date}`; });
    desktop.querySelectorAll('[data-desktop-date]').forEach((node) => {
      node.textContent = now.toLocaleDateString([], { weekday: 'long', month: 'long', day: 'numeric' });
    });
  }

  selectDemo('windows', false);
  updateClock();
  setInterval(updateClock, 30000);
})();
