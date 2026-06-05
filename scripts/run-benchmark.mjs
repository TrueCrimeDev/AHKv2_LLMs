#!/usr/bin/env node
/*
 * run-benchmark.mjs
 *
 * An automatic AHK v2 micro-benchmark across LLMs.
 *
 * For each (model x task) pair:
 *   1. Generate: ask the model (via OpenRouter) for an AHK v2 function
 *      `Solve()` that returns the task's value. The prompt is identical for
 *      every model and contains no v2 coaching -- only the harness contract.
 *   2. Wrap: append a one-line driver `FileAppend(String(Solve()), "*")` so the
 *      return value lands on stdout.
 *   3. Execute: POST the script to a CloudAHK server (`/v2/run`) and read
 *      stdout / stderr / exit_code.
 *   4. Grade: compare trimmed stdout to the task's `expected` value.
 *
 * Results are written to bench/results/results.json and a human-readable
 * scorecard at bench/results/scorecard.md.
 *
 * Environment:
 *   OPENROUTER_API_KEY   required for generation (sk-or-v1-...)
 *   AHK_EXEC_URL         CloudAHK base URL, e.g. http://localhost:8000
 *                        If unset, scripts are generated and saved but NOT run
 *                        (grading is skipped and reported as "no-executor").
 *
 * Usage:
 *   node scripts/run-benchmark.mjs
 *   node scripts/run-benchmark.mjs --models openai/gpt-4o,deepseek/deepseek-chat
 *   node scripts/run-benchmark.mjs --gen-only          # never call the executor
 *   node scripts/run-benchmark.mjs --dry-run           # plan only, no API calls
 *
 * Requires Node 18+ (global fetch).
 */

import { mkdir, writeFile, readFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = join(__dirname, "..");
const BENCH_DIR = join(REPO_ROOT, "bench");
const SCRIPTS_OUT = join(BENCH_DIR, "generated");
const RESULTS_DIR = join(BENCH_DIR, "results");

const OR_BASE = "https://openrouter.ai/api/v1";

const DEFAULT_MODELS = [
  "openai/gpt-4o",
  "google/gemini-2.5-pro",
  "meta-llama/llama-3.3-70b-instruct",
  "deepseek/deepseek-chat",
];

function parseArgs(argv) {
  const a = { models: null, dryRun: false, genOnly: false };
  for (let i = 0; i < argv.length; i++) {
    const x = argv[i];
    if (x === "--models") a.models = (argv[++i] || "").split(",").map((s) => s.trim()).filter(Boolean);
    else if (x === "--dry-run") a.dryRun = true;
    else if (x === "--gen-only") a.genOnly = true;
    else if (x === "--help" || x === "-h") a.help = true;
  }
  return a;
}

const slug = (s) => s.replace(/[^a-z0-9]+/gi, "-").toLowerCase();

function buildPrompt(task) {
  // Minimal, identical harness contract. No v2 idiom hints.
  return [
    `Write an AutoHotkey v2 function named Solve() that does the following:`,
    ``,
    task.prompt,
    ``,
    `Solve() must take no arguments and return the value.`,
    `Return only the function definition -- no explanation, no example calls, no markdown.`,
  ].join("\n");
}

function extractCode(text) {
  const fenced = text.match(/```[a-z0-9_+-]*\s*\n([\s\S]*?)```/i);
  return (fenced ? fenced[1] : text).trim();
}

function wrapDriver(code) {
  const hasRequires = /^\s*#Requires\s+AutoHotkey/im.test(code);
  const header = hasRequires ? "" : "#Requires AutoHotkey v2.0\n";
  return `${header}${code}\n\nFileAppend(String(Solve()), "*")\n`;
}

async function orFetch(path, init = {}) {
  const key = process.env.OPENROUTER_API_KEY;
  if (!key) throw new Error("OPENROUTER_API_KEY is not set.");
  return fetch(`${OR_BASE}${path}`, {
    ...init,
    headers: {
      Authorization: `Bearer ${key}`,
      "Content-Type": "application/json",
      "HTTP-Referer": "https://github.com/TrueCrimeDev/AHKv2_LLMs",
      "X-Title": "AHKv2_LLMs benchmark",
      ...(init.headers || {}),
    },
  });
}

async function verifyKey() {
  const res = await orFetch("/key");
  if (!res.ok) throw new Error(`Key check failed: HTTP ${res.status} ${(await res.text()).slice(0, 200)}`);
  return res.json();
}

async function generate(modelId, task) {
  const res = await orFetch("/chat/completions", {
    method: "POST",
    body: JSON.stringify({
      model: modelId,
      messages: [{ role: "user", content: buildPrompt(task) }],
      temperature: 0,
    }),
  });
  if (!res.ok) throw new Error(`gen HTTP ${res.status} ${(await res.text()).slice(0, 200)}`);
  const data = await res.json();
  return data?.choices?.[0]?.message?.content ?? "";
}

async function execViaCloudAhk(execUrl, code) {
  const res = await fetch(`${execUrl.replace(/\/$/, "")}/v2/run`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ code, prepend_requires: true }),
  });
  if (!res.ok) throw new Error(`exec HTTP ${res.status} ${(await res.text()).slice(0, 200)}`);
  return res.json(); // { exit_code, stdout, stderr, ... }
}

function grade(stdout, expected, match) {
  const got = (stdout ?? "").replace(/\r/g, "").trim();
  const want = String(expected).trim();
  return { pass: got === want, got, want };
}

function scorecard(tasks, models, grid) {
  const head = ["| model | " + tasks.map((t) => t.id).join(" | ") + " | score |"];
  const sep = ["|---" + "|:--:".repeat(tasks.length) + "|:--:|"];
  const rows = models.map((m) => {
    let passed = 0;
    const cells = tasks.map((t) => {
      const r = grid[m]?.[t.id];
      if (!r) return "·";
      if (r.status === "pass") { passed++; return "✅"; }
      if (r.status === "fail") return "❌";
      if (r.status === "error") return "⚠️";
      return "·";
    });
    return `| \`${m}\` | ${cells.join(" | ")} | ${passed}/${tasks.length} |`;
  });
  return [
    "# AHK v2 Micro-Benchmark Scorecard",
    "",
    `Generated ${new Date().toISOString()}`,
    "",
    "✅ pass · ❌ wrong value · ⚠️ did not run (syntax/runtime error) · · not attempted",
    "",
    ...head, ...sep, ...rows,
    "",
  ].join("\n");
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    console.log("Usage: OPENROUTER_API_KEY=... [AHK_EXEC_URL=...] node scripts/run-benchmark.mjs [--models a,b] [--gen-only] [--dry-run]");
    return;
  }

  const spec = JSON.parse(await readFile(join(BENCH_DIR, "tasks.json"), "utf8"));
  const tasks = spec.tasks;
  const models = args.models?.length ? args.models : DEFAULT_MODELS;
  const execUrl = args.genOnly ? null : process.env.AHK_EXEC_URL || null;

  console.log(`Tasks: ${tasks.length} | Models: ${models.length}`);
  console.log(`Executor: ${execUrl ? execUrl : "(none -- generation only, grading skipped)"}`);

  if (args.dryRun) {
    console.log("\n--dry-run, sample prompt:\n");
    console.log(buildPrompt(tasks[0]).split("\n").map((l) => "  | " + l).join("\n"));
    return;
  }

  console.log("\nVerifying OPENROUTER_API_KEY ...");
  await verifyKey();
  console.log("Key OK.\n");

  await mkdir(SCRIPTS_OUT, { recursive: true });
  await mkdir(RESULTS_DIR, { recursive: true });

  const grid = {};
  const records = [];

  for (const modelId of models) {
    grid[modelId] = {};
    const ms = slug(modelId);
    for (const task of tasks) {
      process.stdout.write(`-> ${modelId} / ${task.id} ... `);
      const rec = { model: modelId, task: task.id, expected: task.expected };
      let code;
      try {
        const raw = await generate(modelId, task);
        code = extractCode(raw);
        const script = wrapDriver(code);
        await writeFile(join(SCRIPTS_OUT, `${ms}__${task.id}.ahk`), script, "utf8");
        rec.script = `bench/generated/${ms}__${task.id}.ahk`;
      } catch (e) {
        console.log(`GEN ERROR (${e.message})`);
        grid[modelId][task.id] = { status: "error", note: "generation failed" };
        rec.status = "error"; rec.error = e.message; records.push(rec); continue;
      }

      if (!execUrl) {
        console.log("generated (no executor)");
        grid[modelId][task.id] = { status: "skip" };
        rec.status = "no-executor"; records.push(rec); continue;
      }

      try {
        const out = await execViaCloudAhk(execUrl, wrapDriver(code));
        const g = grade(out.stdout, task.expected, spec.match);
        if (out.exit_code !== 0 && !g.pass) {
          console.log(`⚠️ exit ${out.exit_code}`);
          grid[modelId][task.id] = { status: "error", note: `exit ${out.exit_code}` };
          rec.status = "error"; rec.exit_code = out.exit_code; rec.stderr = (out.stderr || "").slice(0, 500);
        } else if (g.pass) {
          console.log("✅");
          grid[modelId][task.id] = { status: "pass" };
          rec.status = "pass"; rec.got = g.got;
        } else {
          console.log(`❌ got "${g.got.slice(0, 40)}" want "${g.want}"`);
          grid[modelId][task.id] = { status: "fail" };
          rec.status = "fail"; rec.got = g.got;
        }
      } catch (e) {
        console.log(`EXEC ERROR (${e.message})`);
        grid[modelId][task.id] = { status: "error", note: "exec failed" };
        rec.status = "error"; rec.error = e.message;
      }
      records.push(rec);
    }
  }

  await writeFile(
    join(RESULTS_DIR, "results.json"),
    JSON.stringify({ generatedAt: new Date().toISOString(), executor: execUrl || null, spec: spec.description, records }, null, 2),
    "utf8"
  );
  const card = scorecard(tasks, models, grid);
  await writeFile(join(RESULTS_DIR, "scorecard.md"), card, "utf8");

  console.log("\n" + card);
  console.log(`\nWrote bench/results/results.json and bench/results/scorecard.md`);
  if (!execUrl) console.log("Set AHK_EXEC_URL to a CloudAHK server and re-run to grade automatically.");
}

main().catch((e) => { console.error("\nFatal:", e.message); process.exit(1); });
