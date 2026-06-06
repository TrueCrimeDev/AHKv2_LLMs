# AHK v2 Micro-Benchmark — Results

First full run of the [benchmark](./README.md): every model received the
identical bare prompt for each task (no v2 coaching), generated an AHK v2
`Solve()` function via OpenRouter, and the result was executed on the **real
AutoHotkey v2 interpreter** (AutoHotkey64.exe via Wine + Xvfb) and graded by
comparing stdout to a golden value.

- **Date:** 2026-06-05
- **Tasks:** 21 (10 Tier 1 + 11 Tier 2)
- **Models:** 5 current flagships, via OpenRouter
- **Grading:** fully automatic, no human judgment

## Scorecard

✅ pass · ❌ ran but wrong value · ⚠️ did not run (syntax/runtime error or timeout)

| model | score |
|---|:--:|
| `google/gemini-3.1-pro-preview` | **21/21** |
| `openai/gpt-5.5` | **19/21** |
| `x-ai/grok-4.20` | **19/21** |
| `deepseek/deepseek-v4-pro` | **18/21** |
| `meta-llama/llama-4-maverick` | **12/21** |

(Per-task matrix is regenerated into `bench/results/scorecard.md` on each run.)

## Real AHK v2 mistakes the benchmark surfaced

These are genuine failures confirmed by reading the code and re-running — not
harness artifacts:

- **Case-insensitive identifier collision** — GPT-5.5 named a local `stack`
  while its class was `Stack`. AHK v2 identifiers are case-insensitive, so the
  local shadows the class and `Stack()` no longer resolves. Renaming the local
  is the only fix. (Cost it both `class-stack` and `inheritance`.)
- **`catch e` instead of `catch as e`** — a v1-ism; v2 requires the `as`
  keyword. Hit DeepSeek V4 Pro and Grok 4.20 on `try-catch-message`.
- **Hallucinated stdlib** — `arr.Sort()` and `Integer.BitCount()` (no such
  methods in v2), and `Map.Values` (not a property).
- **`A_Random`** — not a v2 built-in variable (v2 uses the `Random()` function).
- **`DateDiff` parameter misuse** — wrong argument shape.
- **Reversed `DateDiff`** — correct magnitude, wrong sign (`-155` vs `155`).
- **Infinite-loop `RegExMatch`** — not advancing the match position (timeout).

## Notes / methodology

- One iteration was needed on the harness itself: the first prompt said "return
  only the function definition", which pushed models to define classes *inside*
  `Solve()` — illegal in v2. The prompt now permits top-level classes/helpers,
  which removed the only systematic harness artifact. The numbers above are from
  the corrected run.
- Execution backend is local (Wine + AHK64 + Xvfb); see
  `scripts/setup-ahk-executor.sh`. Runtime errors are caught via a try-wrapper
  so they fail fast instead of blocking on a dialog.
- Approx. OpenRouter spend for the full run + iterations: ~$1.25.
