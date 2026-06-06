#!/usr/bin/env node
/*
 * run-openrouter-comparison.mjs
 *
 * Generates real, unedited AHK v2 outputs from several LLMs via OpenRouter so
 * they can be compared side-by-side against the Claude Opus 4.8 reference
 * (examples/Opus48_Example.ahk). Every model receives the *identical* user
 * prompt with no system prompt -- "without any prompting" -- so the comparison
 * reflects each model's default AHK v2 instincts.
 *
 * Each model's verbatim reply is written to:
 *   examples/comparison/<model-slug>.txt   (full reply, untouched)
 *   examples/comparison/<model-slug>.ahk   (first ```...``` code block, if any)
 * and a combined record is written to:
 *   examples/comparison/_results.json
 *
 * Usage:
 *   OPENROUTER_API_KEY=sk-or-v1-... node scripts/run-openrouter-comparison.mjs
 *   node scripts/run-openrouter-comparison.mjs --models openai/gpt-4o,deepseek/deepseek-chat
 *   node scripts/run-openrouter-comparison.mjs --dry-run   # print plan, call nothing
 *
 * Requires Node 18+ (global fetch).
 */

import { mkdir, writeFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = join(__dirname, "..");
const OUT_DIR = join(REPO_ROOT, "examples", "comparison");

// The identical task every model gets. Mirrors the scenario in the Opus 4.8
// reference example so the outputs are directly comparable.
const PROMPT = [
  "Write an AutoHotkey v2 script: a clipboard history manager.",
  "",
  "Requirements:",
  "- Keep the last 25 distinct text clips, newest first.",
  "- Win+Shift+V toggles a GUI window listing the clips.",
  "- Double-clicking a list entry pastes it into the previously active window.",
  "- Clean up the clipboard listener when the program exits.",
  "",
  "Return the complete script.",
].join("\n");

// Default lineup. Override with --models a,b,c. These are OpenRouter model IDs;
// the script verifies each is available before calling and skips unknown ones.
const DEFAULT_MODELS = [
  "openai/gpt-4o",
  "google/gemini-2.5-pro",
  "meta-llama/llama-3.3-70b-instruct",
  "deepseek/deepseek-chat",
];

const API_BASE = "https://openrouter.ai/api/v1";

function parseArgs(argv) {
  const args = { models: null, dryRun: false };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--models") args.models = (argv[++i] || "").split(",").map((s) => s.trim()).filter(Boolean);
    else if (a === "--dry-run") args.dryRun = true;
    else if (a === "--help" || a === "-h") args.help = true;
  }
  return args;
}

function slug(modelId) {
  return modelId.replace(/[^a-z0-9]+/gi, "-").toLowerCase();
}

function extractCodeBlock(text) {
  // First fenced block, language tag optional (```ahk, ```autohotkey, ``` ...).
  const m = text.match(/```[a-z0-9_+-]*\s*\n([\s\S]*?)```/i);
  return m ? m[1].replace(/\s+$/, "") + "\n" : null;
}

async function orFetch(path, init = {}) {
  const key = process.env.OPENROUTER_API_KEY;
  if (!key) throw new Error("OPENROUTER_API_KEY is not set in the environment.");
  const res = await fetch(`${API_BASE}${path}`, {
    ...init,
    headers: {
      Authorization: `Bearer ${key}`,
      "Content-Type": "application/json",
      // Optional attribution headers OpenRouter recommends.
      "HTTP-Referer": "https://github.com/TrueCrimeDev/AHKv2_LLMs",
      "X-Title": "AHKv2_LLMs comparison",
      ...(init.headers || {}),
    },
  });
  return res;
}

async function verifyKey() {
  const res = await orFetch("/key");
  if (!res.ok) {
    const body = await res.text().catch(() => "");
    throw new Error(`Key check failed: HTTP ${res.status} ${body.slice(0, 200)}`);
  }
  const data = await res.json();
  return data;
}

async function listAvailableModels() {
  const res = await orFetch("/models");
  if (!res.ok) throw new Error(`Could not list models: HTTP ${res.status}`);
  const data = await res.json();
  return new Set((data.data || []).map((m) => m.id));
}

async function callModel(modelId) {
  const started = Date.now();
  const res = await orFetch("/chat/completions", {
    method: "POST",
    body: JSON.stringify({
      model: modelId,
      // No system prompt -- bare user turn only.
      messages: [{ role: "user", content: PROMPT }],
      temperature: 0.2,
    }),
  });
  const ms = Date.now() - started;
  if (!res.ok) {
    const body = await res.text().catch(() => "");
    return { modelId, ok: false, error: `HTTP ${res.status} ${body.slice(0, 300)}`, ms };
  }
  const data = await res.json();
  const text = data?.choices?.[0]?.message?.content ?? "";
  return {
    modelId,
    ok: true,
    ms,
    usage: data.usage || null,
    finish: data?.choices?.[0]?.finish_reason ?? null,
    text,
  };
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    console.log("Usage: OPENROUTER_API_KEY=sk-or-v1-... node scripts/run-openrouter-comparison.mjs [--models a,b,c] [--dry-run]");
    return;
  }

  const models = args.models && args.models.length ? args.models : DEFAULT_MODELS;

  console.log("Prompt (identical for every model, no system prompt):\n");
  console.log(PROMPT.split("\n").map((l) => "  | " + l).join("\n"));
  console.log("\nModels:", models.join(", "));

  if (args.dryRun) {
    console.log("\n--dry-run: not calling the API.");
    return;
  }

  console.log("\nVerifying OPENROUTER_API_KEY ...");
  const keyInfo = await verifyKey();
  const limit = keyInfo?.data?.limit ?? "n/a";
  const usage = keyInfo?.data?.usage ?? "n/a";
  console.log(`Key OK. usage=${usage} limit=${limit}`);

  console.log("Checking model availability ...");
  let available = new Set();
  try {
    available = await listAvailableModels();
  } catch (e) {
    console.warn("  (could not fetch model list, will attempt all): " + e.message);
  }

  await mkdir(OUT_DIR, { recursive: true });
  const results = [];

  for (const modelId of models) {
    if (available.size && !available.has(modelId)) {
      console.warn(`! Skipping ${modelId} -- not available on this OpenRouter account.`);
      results.push({ modelId, ok: false, error: "not available on account" });
      continue;
    }
    process.stdout.write(`-> ${modelId} ... `);
    let r;
    try {
      r = await callModel(modelId);
    } catch (e) {
      r = { modelId, ok: false, error: e.message };
    }

    if (!r.ok) {
      console.log(`FAILED (${r.error})`);
      results.push({ modelId, ok: false, error: r.error });
      continue;
    }

    const s = slug(modelId);
    await writeFile(join(OUT_DIR, `${s}.txt`), r.text, "utf8");
    const code = extractCodeBlock(r.text);
    if (code) await writeFile(join(OUT_DIR, `${s}.ahk`), code, "utf8");

    console.log(`ok (${r.ms} ms, ${r.text.length} chars${code ? ", code block saved" : ", no code block"})`);
    results.push({
      modelId,
      ok: true,
      ms: r.ms,
      finish: r.finish,
      usage: r.usage,
      chars: r.text.length,
      hasCodeBlock: Boolean(code),
      files: { raw: `examples/comparison/${s}.txt`, ahk: code ? `examples/comparison/${s}.ahk` : null },
    });
  }

  await writeFile(
    join(OUT_DIR, "_results.json"),
    JSON.stringify({ generatedAt: new Date().toISOString(), prompt: PROMPT, results }, null, 2),
    "utf8"
  );

  const okCount = results.filter((r) => r.ok).length;
  console.log(`\nDone. ${okCount}/${results.length} succeeded. Outputs in examples/comparison/`);
  console.log("Next: review the .ahk files, then write the comparison post.");
}

main().catch((e) => {
  console.error("\nFatal:", e.message);
  process.exit(1);
});
