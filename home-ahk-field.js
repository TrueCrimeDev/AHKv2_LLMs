(() => {
  const canvas = document.getElementById('ahk-field');
  const hero = canvas?.closest('.lab-hero');
  if (!canvas || !hero) return;

  const context = canvas.getContext('2d', { alpha: false });
  if (!context) return;

  const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  const labels = [
    '#Requires AutoHotkey v2.1', 'class AHKEval', 'model.Generate(prompt)',
    'source := response.Code', 'if !script.Parses', 'try Run(source)',
    'catch Error as err', 'for task in suite', 'cases := HiddenTests(task)',
    'Assert.Equal(actual, expected)', 'Map("tasks", 36)', 'Map("cases", 181)',
    'result.TasksPassed', 'result.CasesPassed', 'FileAppend(report, "*")',
    'return benchmark.Score', 'Buffer(64)', 'RegExMatch(output)',
    'Gui().Show()', 'DllCall("QueryPerformanceCounter")'
  ];
  const stages = [
    { label: 'SOURCE .AHK', color: '#EFC04A' },
    { label: 'PARSE', color: '#22D3EE' },
    { label: 'RUNTIME', color: '#5B9FEF' },
    { label: '181 HIDDEN', color: '#A855F7' },
    { label: 'SCORE', color: '#7BC96F' }
  ];
  const pointer = { x: 0, y: 0, active: false };
  const nodes = [];
  const pulses = [];
  const sparks = [];
  let width = 1;
  let height = 1;
  let dpr = 1;
  let frame = 0;
  let visible = true;
  let lastExecution = -Infinity;

  const seededRandom = (seed) => {
    const value = Math.sin(seed * 927.17 + 41.73) * 43758.5453;
    return value - Math.floor(value);
  };

  function populateNodes() {
    nodes.length = 0;
    const count = width < 700 ? 15 : 20;
    for (let index = 0; index < count; index += 1) {
      const stage = index % stages.length;
      nodes.push({
        x: width * (.07 + stage * .215) + (seededRandom(index + 2) - .5) * Math.min(42, width * .035),
        y: height * (.14 + seededRandom(index + 37) * .72),
        phase: seededRandom(index + 81) * Math.PI * 2,
        radius: 2 + seededRandom(index + 15) * 1.8,
        label: labels[index % labels.length],
        stage,
        accent: stages[stage].color
      });
    }
  }

  function resize() {
    const rect = hero.getBoundingClientRect();
    width = Math.max(1, rect.width);
    height = Math.max(1, rect.height);
    dpr = Math.min(window.devicePixelRatio || 1, 1.75);
    canvas.width = Math.round(width * dpr);
    canvas.height = Math.round(height * dpr);
    context.setTransform(dpr, 0, 0, dpr, 0, 0);
    populateNodes();
    if (reducedMotion) draw(0);
  }

  const nodePosition = (node, time) => ({
    x: node.x + (reducedMotion ? 0 : Math.sin(time * .00022 + node.phase) * 11),
    y: node.y + (reducedMotion ? 0 : Math.cos(time * .00018 + node.phase) * 8)
  });

  function spawnExecution(x, y) {
    lastExecution = performance.now();
    pulses.push({ x, y, age: 0 });
    for (let index = 0; index < 16; index += 1) {
      const angle = (Math.PI * 2 * index) / 16 + seededRandom(index + frame) * .16;
      const speed = 1.2 + seededRandom(index + frame + 30) * 2.6;
      sparks.push({
        x, y,
        vx: Math.cos(angle) * speed,
        vy: Math.sin(angle) * speed,
        life: 1,
        color: index % 5 === 0 ? '#EFC04A' : index % 4 === 0 ? '#7BC96F' : '#5B9FEF'
      });
    }
  }

  function drawLanguageMark(time) {
    context.save();
    context.textAlign = 'center';
    context.textBaseline = 'middle';
    context.fillStyle = 'rgba(255,255,255,.026)';
    context.font = `400 ${Math.max(94, Math.min(190, width * .135))}px "Instrument Serif", serif`;
    context.fillText('AutoHotkey', width * .52, height * .53);
    context.fillStyle = 'rgba(239,192,74,.1)';
    context.font = '500 13px "JetBrains Mono", monospace';
    context.fillText('VERSION 2.1  /  EXECUTABLE LANGUAGE BENCHMARK', width * .52, height * .53 + Math.min(116, width * .085));

    context.textBaseline = 'alphabetic';
    context.font = '600 8px "JetBrains Mono", monospace';
    stages.forEach((stage, index) => {
      const x = width * (.07 + index * .215);
      const runAge = time - lastExecution;
      const runStage = runAge >= 0 && runAge < 2100 ? Math.floor((runAge / 2100) * stages.length) : -1;
      context.fillStyle = stage.color;
      context.globalAlpha = index === runStage ? .9 : .24;
      context.textAlign = index === stages.length - 1 ? 'right' : 'left';
      context.fillText(stage.label, x, 42);
    });
    context.globalAlpha = 1;
    context.restore();
  }

  function drawGrid(time) {
    const gap = 64;
    const shift = reducedMotion ? 0 : (time * .006) % gap;
    context.lineWidth = 1;
    context.strokeStyle = 'rgba(255,255,255,.026)';
    context.beginPath();
    for (let x = -gap + shift; x < width + gap; x += gap) {
      context.moveTo(x, 0);
      context.lineTo(x, height);
    }
    for (let y = -gap + shift * .45; y < height + gap; y += gap) {
      context.moveTo(0, y);
      context.lineTo(width, y);
    }
    context.stroke();
  }

  function drawConnections(positions, time) {
    const runAge = time - lastExecution;
    const runProgress = runAge >= 0 && runAge < 2100 ? runAge / 2100 : -1;
    for (let first = 0; first < positions.length; first += 1) {
      for (let second = first + 1; second < positions.length; second += 1) {
        if (nodes[second].stage !== nodes[first].stage + 1) continue;
        const dx = positions[first].x - positions[second].x;
        const dy = positions[first].y - positions[second].y;
        const distance = Math.hypot(dx, dy);
        if (distance > Math.max(290, width * .27)) continue;
        const activeStage = runProgress >= 0 && nodes[first].stage <= runProgress * stages.length;
        const alpha = activeStage ? .48 : Math.max(.025, (1 - Math.abs(dy) / height) * .085);
        context.strokeStyle = activeStage ? stages[nodes[second].stage].color : `rgba(91,159,239,${alpha})`;
        context.globalAlpha = activeStage ? .62 : 1;
        context.lineWidth = 1;
        context.beginPath();
        context.moveTo(positions[first].x, positions[first].y);
        context.lineTo(positions[second].x, positions[second].y);
        context.stroke();

        const packetProgress = (time * .00012 + first * .19) % 1;
        const packetX = positions[first].x + (positions[second].x - positions[first].x) * packetProgress;
        const packetY = positions[first].y + (positions[second].y - positions[first].y) * packetProgress;
        context.globalAlpha = activeStage ? .95 : .22;
        context.fillStyle = stages[nodes[second].stage].color;
        context.beginPath();
        context.arc(packetX, packetY, activeStage ? 2.3 : 1.3, 0, Math.PI * 2);
        context.fill();
        context.globalAlpha = 1;
      }
    }
  }

  function drawPointerRoutes(positions) {
    if (!pointer.active) return;
    positions
      .map((position, index) => ({ position, index, distance: Math.hypot(position.x - pointer.x, position.y - pointer.y) }))
      .filter((item) => item.distance < 240)
      .sort((a, b) => a.distance - b.distance)
      .slice(0, 4)
      .forEach((item) => {
        const alpha = (1 - item.distance / 240) * .68;
        const gradient = context.createLinearGradient(pointer.x, pointer.y, item.position.x, item.position.y);
        gradient.addColorStop(0, `rgba(34,211,238,${alpha})`);
        gradient.addColorStop(1, `rgba(91,159,239,${alpha * .3})`);
        context.strokeStyle = gradient;
        context.lineWidth = 1.2;
        context.beginPath();
        context.moveTo(pointer.x, pointer.y);
        context.lineTo(item.position.x, item.position.y);
        context.stroke();
      });

    context.fillStyle = 'rgba(34,211,238,.85)';
    context.beginPath();
    context.arc(pointer.x, pointer.y, 2.2, 0, Math.PI * 2);
    context.fill();
  }

  function drawNodes(positions) {
    context.textBaseline = 'middle';
    context.font = '500 10px "JetBrains Mono", monospace';
    positions.forEach((position, index) => {
      const node = nodes[index];
      const pointerDistance = pointer.active ? Math.hypot(position.x - pointer.x, position.y - pointer.y) : 999;
      const active = pointerDistance < 180;
      context.shadowBlur = active ? 18 : 9;
      context.shadowColor = node.accent;
      context.fillStyle = node.accent;
      context.globalAlpha = active ? .95 : .48;
      context.beginPath();
      context.arc(position.x, position.y, node.radius + (active ? 1.2 : 0), 0, Math.PI * 2);
      context.fill();
      context.shadowBlur = 0;
      context.globalAlpha = active ? .9 : .22;
      context.fillStyle = '#d0d0d0';
      context.fillText(node.label, position.x + 11, position.y - 1);
      context.globalAlpha = 1;
    });
  }

  function drawEffects() {
    for (let index = pulses.length - 1; index >= 0; index -= 1) {
      const pulse = pulses[index];
      pulse.age += reducedMotion ? .08 : .022;
      context.strokeStyle = `rgba(34,211,238,${Math.max(0, .7 - pulse.age * .7)})`;
      context.lineWidth = 1.5;
      context.beginPath();
      context.arc(pulse.x, pulse.y, 12 + pulse.age * 94, 0, Math.PI * 2);
      context.stroke();
      if (pulse.age >= 1) pulses.splice(index, 1);
    }

    for (let index = sparks.length - 1; index >= 0; index -= 1) {
      const spark = sparks[index];
      spark.x += spark.vx;
      spark.y += spark.vy;
      spark.vx *= .982;
      spark.vy *= .982;
      spark.life -= reducedMotion ? .08 : .025;
      context.globalAlpha = Math.max(0, spark.life);
      context.fillStyle = spark.color;
      context.fillRect(spark.x, spark.y, 2.2, 2.2);
      if (spark.life <= 0) sparks.splice(index, 1);
    }
    context.globalAlpha = 1;
  }

  function draw(time) {
    frame += 1;
    context.setTransform(dpr, 0, 0, dpr, 0, 0);
    context.fillStyle = '#0f0f0f';
    context.fillRect(0, 0, width, height);
    drawGrid(time);
    drawLanguageMark(time);
    const positions = nodes.map((node) => nodePosition(node, time));
    drawConnections(positions, time);
    drawPointerRoutes(positions);
    drawNodes(positions);
    drawEffects();
    if (!reducedMotion && visible) requestAnimationFrame(draw);
  }

  function updatePointer(event) {
    const rect = hero.getBoundingClientRect();
    pointer.x = event.clientX - rect.left;
    pointer.y = event.clientY - rect.top;
    pointer.active = true;
  }

  hero.addEventListener('pointermove', updatePointer, { passive: true });
  hero.addEventListener('pointerleave', () => { pointer.active = false; });
  hero.addEventListener('pointerdown', (event) => {
    if (event.target.closest('a, button')) return;
    updatePointer(event);
    spawnExecution(pointer.x, pointer.y);
    if (reducedMotion) draw(0);
  });

  const observer = new IntersectionObserver(([entry]) => {
    const wasVisible = visible;
    visible = entry.isIntersecting;
    if (!wasVisible && visible && !reducedMotion) requestAnimationFrame(draw);
  }, { threshold: .01 });
  observer.observe(hero);
  new ResizeObserver(resize).observe(hero);
  resize();
  draw(0);
})();
