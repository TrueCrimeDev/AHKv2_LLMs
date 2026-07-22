import assert from 'node:assert/strict';
import { access, readFile } from 'node:fs/promises';
import { join } from 'node:path';
import test from 'node:test';
import vm from 'node:vm';

const root = process.cwd();

test('homepage leads with the benchmark lab and includes accessible navigation', async () => {
  const [html, desktopScript] = await Promise.all([
    readFile(join(root, 'dist', 'client', 'index.html'), 'utf8'),
    readFile(join(root, 'dist', 'client', 'home-win11.js'), 'utf8'),
  ]);
  assert.match(html, /AutoHotkey v2 makes Windows/);
  assert.match(html, /<main id="main-content"/);
  assert.match(html, /aria-label="Main navigation"/);
  assert.match(html, /data-filter="benchmark"/);
  assert.match(html, /#Requires AutoHotkey v2\.1/);
  assert.match(html, /data-win-desktop/);
  assert.match(html, /data-start-menu/);
  assert.match(html, /public\/windows11-dark-reference\.png/);
  assert.match(html, /data-ahk-feature="windows"/);
  assert.match(html, /data-ahk-feature="gui"/);
  assert.match(html, /public\/fluent-icons\/window_multiple_24_regular\.svg/);
  assert.match(html, /home-win11\.js/);
  assert.match(desktopScript, /Hotstring/);
  assert.match(desktopScript, /A_Clipboard/);
  assert.match(desktopScript, /Loop Files/);
  assert.match(desktopScript, /data-drag-handle/);
  assert.match(desktopScript, /data-window-action/);
  assert.match(desktopScript, /data-ahk-feature/);
  assert.match(desktopScript, /scrollIntoView/);
  assert.doesNotMatch(html, /Codex is building|codex-preview/);
  new vm.Script(desktopScript);

  const inlineScripts = [...html.matchAll(/<script>([\s\S]*?)<\/script>/g)];
  assert.ok(inlineScripts.length > 0);
  for (const [, source] of inlineScripts) new vm.Script(source);
});

test('research data and article paths are internally consistent', async () => {
  const posts = JSON.parse(await readFile(join(root, 'posts', 'posts.json'), 'utf8'));
  const board = JSON.parse(await readFile(join(root, 'posts', 'ahk-eval', 'board.json'), 'utf8'));

  assert.ok(posts.length >= 20);
  assert.equal(board.tasks, 36);
  assert.equal(board.cases, 181);
  assert.ok(board.rows.length >= 20);

  for (const post of posts) {
    await access(join(root, post.path));
  }
});

test('deployment output contains the worker, assets, and benchmark data', async () => {
  await Promise.all([
    access(join(root, 'dist', 'server', 'index.js')),
    access(join(root, 'dist', 'client', 'style.css')),
    access(join(root, 'dist', 'client', 'windows11-dark-reference.png')),
    access(join(root, 'dist', 'client', 'fluent-icons', 'window_multiple_24_regular.svg')),
    access(join(root, 'dist', 'client', 'posts', 'posts.json')),
    access(join(root, 'dist', 'client', 'posts', 'ahk-eval', 'board.json')),
  ]);

  const worker = await readFile(join(root, 'dist', 'server', 'index.js'), 'utf8');
  assert.match(worker, /HTML_ASSET_VERSION = '[0-9a-f]{12}'/);
  assert.match(worker, /url\.pathname \+ '\.html'/);
});

test('AHK-Eval explainer ships its live visualization layer', async () => {
  const [postShell, script, stylesheet] = await Promise.all([
    readFile(join(root, 'dist', 'client', 'post.html'), 'utf8'),
    readFile(join(root, 'dist', 'client', 'ahk-eval-viz.js'), 'utf8'),
    readFile(join(root, 'dist', 'client', 'ahk-eval-viz.css'), 'utf8'),
  ]);

  assert.match(postShell, /enhanceAhkEvalArticle/);
  assert.match(script, /One task\. Three gates\. No partial victory/);
  assert.match(script, /Execution feedback is the part that moves the score/);
  assert.match(script, /Explore the complete task matrix/);
  assert.match(stylesheet, /\.eval-leader-chart/);
  new vm.Script(script);
});

test('shared UI and benchmark visuals follow the dark design system', async () => {
  const [shared, evalStyles, home] = await Promise.all([
    readFile(join(root, 'dist', 'client', 'style.css'), 'utf8'),
    readFile(join(root, 'dist', 'client', 'ahk-eval-viz.css'), 'utf8'),
    readFile(join(root, 'dist', 'client', 'index.html'), 'utf8'),
  ]);

  for (const token of ['#0f0f0f', '#141414', '#121212', '#303030', '#232323', '#5B9FEF', '#7BC96F', '#F59E42', '#DC3545', '#A855F7', '#22D3EE']) {
    assert.match(shared + evalStyles, new RegExp(token, 'i'));
  }
  assert.match(evalStyles, /\.eval-board[\s\S]*?border:\s*0;[\s\S]*?border-radius:\s*12px;[\s\S]*?box-shadow:\s*inset 0 0 0 1px/);
  assert.match(evalStyles, /\.eval-full-board[^}]*background:\s*var\(--eval-primary\)[^}]*color:\s*#ffffff[^}]*border-radius:\s*8px/);
  assert.doesNotMatch(evalStyles, /#ff9f43/i);
  assert.match(home, /family=Instrument\+Serif/);
  assert.match(home, /family=Inter/);
  assert.match(home, /family=JetBrains\+Mono/);
});

test('leaderboard leads with AHK cost, then SWE-bench, then model data', async () => {
  const html = await readFile(join(root, 'dist', 'client', 'leaderboard.html'), 'utf8');
  const ahkChart = html.indexOf('id="ahkcost"');
  const sweChart = html.indexOf('id="swe"');
  const dataTable = html.indexOf('id="board"');

  assert.ok(ahkChart > 0 && ahkChart < sweChart && sweChart < dataTable);
  assert.match(html, /data-secondary-label/);
  assert.match(html, /tabindex="0" role="img"/);
  assert.match(html, /function placeTip\(dot\)/);
  assert.match(html, /tip-grid/);
  assert.match(html, /aria-labelledby="ahk-chart-title ahk-svg-desc"/);
  assert.match(html, /aria-labelledby="swe-chart-title swe-svg-desc"/);
  assert.doesNotMatch(html, /<title id="(?:ahk|swe)-svg-title">/);

  const scripts = [...html.matchAll(/<script>([\s\S]*?)<\/script>/g)];
  assert.ok(scripts.length > 0);
  for (const [, source] of scripts) new vm.Script(source);
});

test('benchmark cards use concise previews and prominent provider indicators', async () => {
  const [html, postsText] = await Promise.all([
    readFile(join(root, 'dist', 'client', 'benchmarks.html'), 'utf8'),
    readFile(join(root, 'dist', 'client', 'posts', 'posts.json'), 'utf8'),
  ]);
  const posts = JSON.parse(postsText);
  const gpt = posts.find(post => post.slug === 'gpt-5.6-ahk-eval');

  assert.ok(gpt);
  assert.equal(gpt.preview_title, 'GPT-5.6 Takes #1 by One Hidden Case');
  assert.ok(gpt.preview.length <= 120);
  assert.match(html, /class="provider-badge"/);
  assert.match(html, /label: 'OpenAI'/);
  assert.match(html, /post\.preview_title \|\| post\.title/);
  assert.match(html, /post\.preview/);
  assert.match(html, /genericTags/);

  const scripts = [...html.matchAll(/<script>([\s\S]*?)<\/script>/g)];
  assert.ok(scripts.length > 0);
  for (const [, source] of scripts) new vm.Script(source);
});
