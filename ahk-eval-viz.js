(function () {
  'use strict';

  const escapeHtml = (value) => String(value ?? '').replace(/[&<>"']/g, (char) => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#039;'
  })[char]);

  const mean = (values) => values.reduce((sum, value) => sum + value, 0) / values.length;

  function sectionHeading(text) {
    return [...document.querySelectorAll('#content > h2')]
      .find((heading) => heading.textContent.trim() === text);
  }

  function firstWrapBeforeNextHeading(heading) {
    let node = heading?.nextElementSibling;
    while (node && node.tagName !== 'H2') {
      if (node.matches('.bm-wrap')) return node;
      node = node.nextElementSibling;
    }
    return null;
  }

  function detailsFor(element, summary, note) {
    const details = document.createElement('details');
    details.className = 'eval-data-details';
    const label = document.createElement('summary');
    label.innerHTML = `<span>${escapeHtml(summary)}</span><small>${escapeHtml(note)}</small>`;
    details.append(label, element);
    return details;
  }

  function buildPipeline(board) {
    const section = document.createElement('section');
    section.className = 'eval-viz eval-pipeline';
    section.setAttribute('aria-labelledby', 'eval-pipeline-title');
    section.innerHTML = `
      <div class="eval-viz-head">
        <div>
          <span class="eval-kicker">How the score is made</span>
          <h2 id="eval-pipeline-title">One task. Three gates. No partial victory.</h2>
        </div>
        <p>A model solves a task only when its function clears every hidden case.</p>
      </div>
      <div class="eval-flow" role="list" aria-label="AHK-Eval grading process">
        <div class="eval-flow-step" role="listitem">
          <b>01</b><span>Generate</span>
          <strong>${board.tasks} separate functions</strong>
          <p>Fresh context and the same one-shot prompt for every task.</p>
        </div>
        <div class="eval-flow-arrow" aria-hidden="true">→</div>
        <div class="eval-flow-step" role="listitem">
          <b>02</b><span>Execute</span>
          <strong>Parse → run → compare</strong>
          <p>A real AHK v2 runtime checks syntax before the answer is tested.</p>
        </div>
        <div class="eval-flow-arrow" aria-hidden="true">→</div>
        <div class="eval-flow-step" role="listitem">
          <b>03</b><span>Grade</span>
          <strong>${board.cases} hidden cases</strong>
          <p>Every case must pass to count the task as solved.</p>
        </div>
      </div>`;
    return section;
  }

  function buildLeaderboard(board) {
    const rows = [...board.rows].sort((a, b) => a.rank - b.rank);
    const top = rows.slice(0, 12);
    const leader = top[0];
    const underTen = rows
      .filter((row) => row.price_out > 0 && row.price_out <= 10)
      .sort((a, b) => b.solved - a.solved || b.cases - a.cases)[0];
    const comparable = rows.filter((row) => Number.isFinite(row.rules) && Number.isFinite(row.repair));
    const stages = [
      { label: 'Cold prompt', value: mean(comparable.map((row) => row.solved)), className: 'cold' },
      { label: '+ rules card', value: mean(comparable.map((row) => row.rules)), className: 'rules' },
      { label: '+ one repair', value: mean(comparable.map((row) => row.repair)), className: 'repair' },
    ];
    const repairLift = stages[2].value - stages[0].value;
    const repairWins = comparable.filter((row) => row.repair > row.solved).length;

    const section = document.createElement('section');
    section.className = 'eval-viz eval-board';
    section.setAttribute('aria-label', 'Live AHK-Eval leaderboard and harness comparison');
    section.innerHTML = `
      <div class="eval-stat-row" aria-label="Current benchmark summary">
        <div><span>Current leader</span><strong>${escapeHtml(leader.display)}</strong><small>${leader.solved}/${board.tasks} tasks · ${leader.cases}/${board.cases} cases</small></div>
        <div><span>Strongest ≤ $10/M output</span><strong>${escapeHtml(underTen.display)}</strong><small>${underTen.solved}/${board.tasks} tasks · $${underTen.price_out.toFixed(2)}/M</small></div>
        <div><span>Live board</span><strong>${rows.length} entries</strong><small>Updated ${escapeHtml(board.generated)}</small></div>
      </div>

      <div class="eval-chart-head">
        <div>
          <span class="eval-kicker">Cold score · top 12</span>
          <h3>Tasks solved out of ${board.tasks}</h3>
        </div>
        <span class="eval-chart-key"><i></i> full-task passes <b>cases show partial credit</b></span>
      </div>
      <div class="eval-leader-chart" role="list" aria-label="Top twelve models ranked by tasks solved">
        ${top.map((row) => `
          <a class="eval-leader-row" role="listitem" href="leaderboard.html" aria-label="Rank ${row.rank}, ${escapeHtml(row.display)}, ${row.solved} of ${board.tasks} tasks and ${row.cases} of ${board.cases} hidden cases">
            <span class="eval-rank">${String(row.rank).padStart(2, '0')}</span>
            <span class="eval-model"><b>${escapeHtml(row.display)}</b><small>${escapeHtml(row.provider)}</small></span>
            <span class="eval-score-track" role="progressbar" aria-valuemin="0" aria-valuemax="${board.tasks}" aria-valuenow="${row.solved}"><i style="width:${(row.solved / board.tasks) * 100}%"></i></span>
            <strong class="eval-score">${row.solved}<small>/${board.tasks}</small></strong>
            <span class="eval-cases">${row.cases}/${board.cases}</span>
          </a>`).join('')}
      </div>
      <a class="eval-full-board" href="leaderboard.html">Open all ${rows.length} entries, pricing, and harness arms <span aria-hidden="true">→</span></a>

      <div class="eval-harness">
        <div class="eval-chart-head">
          <div>
            <span class="eval-kicker">Same ${comparable.length} models · same ${board.tasks} tasks</span>
            <h3>Execution feedback is the part that moves the score.</h3>
          </div>
          <p>A rules card barely changes the field. One repair round adds <strong>+${repairLift.toFixed(1)} tasks</strong> on average and improves ${repairWins} of ${comparable.length} models.</p>
        </div>
        <div class="eval-stage-chart" role="img" aria-label="Average tasks solved: ${stages.map((stage) => `${stage.label} ${stage.value.toFixed(1)}`).join(', ')} out of ${board.tasks}">
          ${stages.map((stage, index) => `
            <div class="eval-stage-row ${stage.className}">
              <span>${stage.label}</span>
              <div class="eval-stage-track"><i style="width:${(stage.value / board.tasks) * 100}%"></i></div>
              <strong>${stage.value.toFixed(1)}<small>/${board.tasks}</small></strong>
              <em>${index === 0 ? 'baseline' : `${stage.value - stages[0].value >= 0 ? '+' : ''}${(stage.value - stages[0].value).toFixed(1)}`}</em>
            </div>`).join('')}
        </div>
        <div class="eval-harness-note"><b>Cold</b> = answer once. <b>Rules</b> = add an AHK v2 pitfalls card. <b>Repair</b> = return the failing test output and allow one correction.</div>
      </div>`;

    return section;
  }

  function buildCategoryChart(tableWrap) {
    const table = tableWrap?.querySelector('table');
    if (!table) return null;
    const labels = [...table.querySelectorAll('thead th')].slice(1).map((cell) => cell.textContent.trim());
    const rows = [...table.querySelectorAll('tbody tr')];
    const categories = labels.map((label, index) => {
      const values = rows.map((row) => {
        const text = row.cells[index + 1]?.textContent.trim() || '0/6';
        return Number(text.split('/')[0]);
      });
      return { label, average: mean(values) };
    }).sort((a, b) => b.average - a.average);

    const section = document.createElement('section');
    section.className = 'eval-viz eval-category';
    section.setAttribute('aria-label', 'Average tasks solved by category in the original cohort');
    section.innerHTML = `
      <div class="eval-chart-head">
        <div>
          <span class="eval-kicker">Original cohort · average per model</span>
          <h3>Language-specific data work separates the field.</h3>
        </div>
        <p>Every category contains six tasks. Longer bars mean the category was easier for the cohort.</p>
      </div>
      <div class="eval-category-chart" role="img" aria-label="${categories.map((category) => `${category.label} ${category.average.toFixed(1)} of 6`).join(', ')}">
        ${categories.map((category, index) => `
          <div class="eval-category-row">
            <span><b>${index + 1}</b>${escapeHtml(category.label)}</span>
            <div class="eval-category-track"><i style="width:${(category.average / 6) * 100}%"></i></div>
            <strong>${category.average.toFixed(1)}<small>/6</small></strong>
          </div>`).join('')}
      </div>`;
    return section;
  }

  function buildDifficultyChart(tableWrap) {
    const table = tableWrap?.querySelector('table');
    if (!table) return null;
    const rows = [...table.querySelectorAll('tbody tr')].map((row) => {
      const cells = row.cells;
      const labelText = cells[0]?.textContent.trim() || '';
      const difficulty = labelText.match(/\b(easy|mid|hard)$/i)?.[1]?.toLowerCase() || '';
      const task = labelText.replace(/\s+(easy|mid|hard)$/i, '');
      const scoreText = cells[cells.length - 1]?.textContent.trim() || '0/13';
      const [solved, total] = scoreText.split('/').map(Number);
      return { task, difficulty, solved, total };
    });
    const hardest = rows.sort((a, b) => a.solved - b.solved || a.task.localeCompare(b.task)).slice(0, 7);

    const section = document.createElement('section');
    section.className = 'eval-viz eval-hardest';
    section.setAttribute('aria-label', 'Hardest tasks in the original benchmark cohort');
    section.innerHTML = `
      <div class="eval-chart-head">
        <div>
          <span class="eval-kicker">Lowest full-pass rates</span>
          <h3>The hardest tasks were not always labeled “hard.”</h3>
        </div>
        <p>NaturalSort required algorithmic care. ExtractDigits was “easy,” but an AHK v2 string-comparison trap cut its solve rate in half.</p>
      </div>
      <div class="eval-hardest-chart" role="img" aria-label="${hardest.map((item) => `${item.task}, ${item.solved} of ${item.total} models`).join('; ')}">
        ${hardest.map((item) => `
          <div class="eval-hardest-row">
            <span class="eval-task"><b>${escapeHtml(item.task)}</b><small class="${item.difficulty}">${escapeHtml(item.difficulty)}</small></span>
            <div class="eval-hardest-track"><i style="width:${(item.solved / item.total) * 100}%"></i></div>
            <strong>${item.solved}<small>/${item.total}</small></strong>
          </div>`).join('')}
      </div>`;
    return section;
  }

  async function enhanceAhkEvalArticle() {
    const content = document.getElementById('content');
    const container = document.querySelector('.article-container');
    if (!content || !container) return;

    container.classList.add('eval-mode');
    content.classList.add('eval-enhanced');
    const duplicateTitle = content.querySelector(':scope > h1:first-child');
    if (duplicateTitle) duplicateTitle.remove();

    const response = await fetch('posts/ahk-eval/board.json');
    if (!response.ok) throw new Error('Live AHK-Eval board unavailable');
    const board = await response.json();

    const leaderboardHeading = sectionHeading('The Leaderboard') || sectionHeading('The Live Leaderboard');
    if (leaderboardHeading) {
      leaderboardHeading.textContent = 'The Live Leaderboard';
      const intro = leaderboardHeading.nextElementSibling;
      if (intro?.tagName === 'P') {
        intro.textContent = `The live board now tracks ${board.rows.length} completed runs. The narrative below explains the original 13-model cohort that established the benchmark.`;
      }
      const originalTable = firstWrapBeforeNextHeading(leaderboardHeading);
      const boardSection = buildLeaderboard(board);
      const anchor = originalTable || intro || leaderboardHeading;
      anchor.replaceWith(boardSection);
      if (originalTable) {
        boardSection.append(detailsFor(
          originalTable,
          'Original 13-model leaderboard',
          'The fixed cohort discussed in the article below'
        ));
      }
      leaderboardHeading.before(buildPipeline(board));
    }

    const categoryHeading = sectionHeading('Tasks Solved by Category');
    const categoryWrap = firstWrapBeforeNextHeading(categoryHeading);
    const categoryChart = buildCategoryChart(categoryWrap);
    if (categoryChart && categoryWrap) {
      categoryWrap.replaceWith(categoryChart);
      categoryChart.append(detailsFor(categoryWrap, 'Compare every model by category', '13 models × 6 categories'));
    }

    const gridHeading = sectionHeading('Who Solved What');
    const gridIntro = gridHeading?.nextElementSibling;
    if (gridIntro?.tagName === 'P') {
      gridIntro.textContent = 'Start with the seven lowest solve rates below. Open the complete matrix only when you need task-by-task detail.';
    }
    const gridWrap = firstWrapBeforeNextHeading(gridHeading);
    const difficultyChart = buildDifficultyChart(gridWrap);
    if (difficultyChart && gridWrap) {
      gridWrap.replaceWith(difficultyChart);
      difficultyChart.append(detailsFor(gridWrap, 'Explore the complete task matrix', '36 tasks × 13 models · full and partial passes'));
    }
  }

  window.enhanceAhkEvalArticle = enhanceAhkEvalArticle;
})();
