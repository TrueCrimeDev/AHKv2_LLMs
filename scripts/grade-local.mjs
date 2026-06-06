#!/usr/bin/env node
/*
 * grade-local.mjs
 *
 * Grades already-generated benchmark scripts (bench/generated/*.ahk) by running
 * each through a local AutoHotkey v2 interpreter under Wine + a virtual display,
 * with no further OpenRouter calls. Compares trimmed stdout to the expected
 * value in bench/tasks.json and writes bench/results/scorecard.md + results.json.
 *
 * Prereqgs (provided by scripts/setup-ahk-executor.sh):
 *   - wine on PATH, AutoHotkey64.exe at $AHK_EXE (default /tmp/ahk/AutoHotkey64.exe)
 *   - a running X server; export DISPLAY (e.g. :99) and WINEPREFIX
 *
 * AHK is invoked with /ErrorStdOut so load/runtime errors go to stderr and the
 * process exits, instead of popping a blocking dialog. A per-script timeout is
 * the backstop for anything that still hangs.
 *
 * Usage:
 *   DISPLAY=:99 WINEPREFIX=/root/.wine-ahk node scripts/grade-local.mjs
 */

import { readFile, readdir, writeFile, mkdir } from "node:fs/promises";
import { writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { tmpdir } from "node:os";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const ERR_TOKEN = "__AHK_ERROR__";

// Re-wrap a generated script: strip the harness driver line and replace it with
// a try/catch version so a runtime exception (e.g. calling a non-existent
// Array.Sort()) prints an error token and exits cleanly, instead of popping a
// blocking dialog under the virtual display. /ErrorStdOut still handles
// load-time (syntax) errors. Returns a path to a temp script to run.
function prepareScript(src) {
  const body = src.replace(/\n*FileAppend\(String\(Solve\(\)\),\s*"\*"\)\s*/g, "\n");
  const wrapped =
    body.trimEnd() +
    `\n\ntry {\n    FileAppend(String(Solve()), "*")\n} catch as e {\n    FileAppend("${ERR_TOKEN}" . e.Message, "*")\n}\n`;
  const tmp = join(tmpdir(), `ahkgrade_${Math.random().toString(36).slice(2)}.ahk`);
  writeFileSync(tmp, wrapped, "utf8");
  return tmp;
}

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, "..");
const BENCH = join(ROOT, "bench");
const GEN = join(BENCH, "generated");
const RESULTS = join(BENCH, "results");
const AHK_EXE = process.env.AHK_EXE || "/tmp/ahk/AutoHotkey64.exe";
const TIMEOUT_MS = Number(process.env.AHK_TIMEOUT_MS || 12000);

const slug = (s) => s.replace(/[^a-z0-9]+/gi, "-").toLowerCase();
const winPath = (p) => "Z:" + p.replace(/\//g, "\\");

function runAhk(file) {
  const r = spawnSync("wine", [AHK_EXE, "/ErrorStdOut", winPath(file)], {
    encoding: "utf8",
    timeout: TIMEOUT_MS,
    env: process.env,
    killSignal: "SIGKILL",
  });
  return {
    timedOut: r.error && r.error.code === "ETIMEDOUT",
    code: r.status,
    stdout: (r.stdout || "").replace(/X connection to :\d+ broken.*$/s, ""),
    stderr: r.stderr || "",
  };
}

function classify(res, expected) {
  if (res.timedOut) return { status: "error", note: "timeout" };
  const out = res.stdout.replace(/\r/g, "").trim();
  const want = String(expected).trim();
  // Runtime exception caught by the try-wrapper.
  if (out.startsWith(ERR_TOKEN)) {
    return { status: "error", note: ("runtime: " + out.slice(ERR_TOKEN.length)).slice(0, 160) };
  }
  if (out === want) return { status: "pass", got: out };
  // No usable stdout + error text/nonzero exit => load-time (syntax) failure.
  const errText = res.stderr.replace(/^\s*[0-9a-f]{4}:(err|fixme):.*$/gim, "").trim();
  if (out === "" && (res.code !== 0 || errText)) {
    return { status: "error", got: out, note: ("load: " + (errText.split("\n").pop() || `exit ${res.code}`)).slice(0, 160) };
  }
  return { status: "fail", got: out };
}

function buildScorecard(tasks, models, grid) {
  const head = "| model | " + tasks.map((t) => t.id).join(" | ") + " | score |";
  const sep = "|---" + "|:--:".repeat(tasks.length) + "|:--:|";
  const sym = { pass: "✅", fail: "❌", error: "⚠️" };
  const rows = models.map((m) => {
    let p = 0;
    const cells = tasks.map((t) => {
      const r = grid[m]?.[t.id];
      if (r?.status === "pass") p++;
      return sym[r?.status] || "·";
    });
    return `| \`${m}\` | ${cells.join(" | ")} | **${p}/${tasks.length}** |`;
  });
  return [
    "# AHK v2 Micro-Benchmark Scorecard",
    "",
    `Generated ${new Date().toISOString()} · executor: AutoHotkey64.exe via Wine`,
    "",
    "✅ pass · ❌ ran but wrong value · ⚠️ did not run (syntax/runtime error or timeout)",
    "",
    head, sep, ...rows, "",
  ].join("\n");
}

async function main() {
  const spec = JSON.parse(await readFile(join(BENCH, "tasks.json"), "utf8"));
  const tasks = spec.tasks;
  const files = (await readdir(GEN)).filter((f) => f.endsWith(".ahk"));
  if (!files.length) { console.error("No generated scripts in bench/generated/. Run the benchmark first."); process.exit(1); }

  // Discover models from filenames (slug before "__").
  const models = [...new Set(files.map((f) => f.split("__")[0]))].sort();
  const taskById = new Map(tasks.map((t) => [t.id, t]));
  const slugToModel = {}; // best-effort label
  const grid = {};
  const records = [];

  for (const f of files) {
    const [mslug, rest] = f.split("__");
    const taskId = rest.replace(/\.ahk$/, "");
    const task = taskById.get(taskId);
    if (!task) continue;
    grid[mslug] ??= {};
    process.stdout.write(`-> ${mslug} / ${taskId} ... `);
    const src = await readFile(join(GEN, f), "utf8");
    const tmp = prepareScript(src);
    const res = runAhk(tmp);
    try { (await import("node:fs")).unlinkSync(tmp); } catch {}
    const c = classify(res, task.expected);
    grid[mslug][taskId] = c;
    const sym = { pass: "✅", fail: "❌", error: "⚠️" }[c.status];
    console.log(`${sym} ${c.status === "pass" ? "" : `got "${(c.got ?? "").slice(0, 30)}" want "${task.expected}"${c.note ? ` [${c.note}]` : ""}`}`);
    records.push({ model: mslug, task: taskId, expected: task.expected, ...c });
  }

  await mkdir(RESULTS, { recursive: true });
  await writeFile(join(RESULTS, "results.json"),
    JSON.stringify({ gradedAt: new Date().toISOString(), executor: "wine+ahk64", records }, null, 2), "utf8");
  const card = buildScorecard(tasks, models, grid);
  await writeFile(join(RESULTS, "scorecard.md"), card, "utf8");
  console.log("\n" + card);

  // Aggregate by status for a quick console summary.
  const tally = {};
  for (const r of records) tally[r.status] = (tally[r.status] || 0) + 1;
  console.log("Totals:", JSON.stringify(tally), "\nWrote bench/results/scorecard.md");
}

main().catch((e) => { console.error("Fatal:", e.message); process.exit(1); });
