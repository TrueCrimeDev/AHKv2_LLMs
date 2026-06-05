# AHK v2 Micro-Benchmark

An **automatic, judgment-free** benchmark of how well LLMs write AutoHotkey v2.

## The idea

Instead of eyeballing whole programs, each task is a tiny problem whose answer
is a **single deterministic value**. Every model is asked for the same thing:

> Write an AutoHotkey v2 function named `Solve()` that returns *&lt;value&gt;*.

The harness then:

1. **Generates** the function from each model via OpenRouter (identical prompt,
   no v2 coaching, `temperature: 0`).
2. **Wraps** it with a one-line driver: `FileAppend(String(Solve()), "*")` so the
   return value is printed to stdout.
3. **Executes** the script through [CloudAHK](../cloudahk/) (`POST /v2/run`),
   capturing `stdout`, `stderr`, and `exit_code`.
4. **Grades** by comparing trimmed `stdout` to the task's `expected` value.

A model can land in three states per task:

| Symbol | Meaning |
| :----: | :------ |
| ✅ | stdout matched the expected value |
| ❌ | ran, but produced the wrong value |
| ⚠️ | failed to run at all (v2 syntax/runtime error) — often a v1-ism |

That ⚠️ column is the interesting one: it catches object-literal-instead-of-`Map()`,
v1 command syntax, bad `:=` vs `=`, legacy `%var%`, etc., because those make the
script fail to execute rather than just return a wrong number.

## Running it

```bash
# generation only (saves scripts, no grading)
OPENROUTER_API_KEY=sk-or-v1-... node scripts/run-benchmark.mjs --gen-only

# full run with automatic grading via a CloudAHK server
OPENROUTER_API_KEY=sk-or-v1-... AHK_EXEC_URL=http://localhost:8000 \
  node scripts/run-benchmark.mjs

# pick your own lineup
node scripts/run-benchmark.mjs --models openai/gpt-4o,deepseek/deepseek-chat
```

## Outputs

- `bench/generated/<model>__<task>.ahk` — the exact script that was run.
- `bench/results/results.json` — full per-cell record (stdout, stderr, status).
- `bench/results/scorecard.md` — the model × task matrix with a score column.

## Tasks

See [`tasks.json`](./tasks.json). Each entry has an `id`, the `prompt` text,
the `expected` value, and a `probes` note describing which v2 idiom it targets.
Add a task by appending an object with a deterministic single-value answer.
