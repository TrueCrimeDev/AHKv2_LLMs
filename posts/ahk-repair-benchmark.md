# AHK-Repair: Terra Fixes What It Can't Write

Every failed AHK-Eval submission is a specimen: real broken code, written by a real model, with a known failure and a hidden test suite that defines "fixed." **AHK-Repair** turns thirty of them into a benchmark. Each item is another model's dead submission — Muse Spark's invented `.Sort()`, Grok's infix `%` parse deaths, Terra's v1-style quote escaping — plus the original task card and the observed failure. The candidate must repair it with the *smallest possible change*: grading runs the original hidden cases through the same alpha.30-fork pipeline as [AHK-Eval](post.html?slug=ahk-eval-benchmark), and a minimality metric penalizes rewrites over surgery.

The 30 items split evenly by failure mode — 10 parse deaths, 10 silent zero-scores, 10 partial-credit bugs — drawn from 26 tasks and 21 source models, frontier and budget alike. Before any money moved, a baseline gate re-verified that all thirty snippets still fail. Eleven models have now run it, most of them from the budget tier. Total spend across all four rounds: **$3.45**.

<div class="bm-wrap"><table class="bm-heat"><thead><tr><th>#</th><th style="text-align:left">repairer</th><th>fixed</th><th>rate</th><th>parse fails</th><th>cost/fix</th></tr></thead><tbody><tr><td class="h-rank">1</td><td class="h-name"><strong>GPT-5.6 Terra</strong></td><td class="h-blue"><strong>18/28</strong></td><td class="h-blue"><strong>64%</strong></td><td class="h-dim">2</td><td class="h-dim">$0.026</td></tr><tr><td class="h-rank">2</td><td class="h-name">GLM-5.2</td><td class="h-blue">15/30</td><td class="h-blue">50%</td><td class="h-emer">1</td><td class="h-dim">$0.030</td></tr><tr><td class="h-rank">3</td><td class="h-name">GPT-5.6 Luna</td><td class="h-blue">14/30</td><td class="h-blue">47%</td><td class="h-dim">2</td><td class="h-dim">$0.023</td></tr><tr><td class="h-rank">4</td><td class="h-name">GLM-5</td><td class="h-blue">12/30</td><td class="h-blue">40%</td><td class="h-dim">4</td><td class="h-dim">$0.039</td></tr><tr><td class="h-rank">5</td><td class="h-name">DeepSeek V4 Pro</td><td class="h-blue">11/30</td><td class="h-blue">37%</td><td class="h-dim">2</td><td class="h-dim">$0.020</td></tr><tr><td class="h-rank">5</td><td class="h-name">Kimi K2.6</td><td class="h-blue">11/30</td><td class="h-blue">37%</td><td class="h-dim">4</td><td class="h-dim">$0.091</td></tr><tr><td class="h-rank">7</td><td class="h-name">Aion-3.0 Mini</td><td class="h-blue">9/30</td><td class="h-blue">30%</td><td class="h-emer">1</td><td class="h-dim">$0.028</td></tr><tr><td class="h-rank">7</td><td class="h-name">Tencent Hy3</td><td class="h-blue">9/30</td><td class="h-blue">30%</td><td class="h-emer">1</td><td class="h-dim">$0.0006</td></tr><tr><td class="h-rank">9</td><td class="h-name">Qwen3 Coder</td><td class="h-blue">7/30</td><td class="h-blue">23%</td><td class="h-dim">4</td><td class="h-dim">$0.003</td></tr><tr><td class="h-rank">10</td><td class="h-name">MiniMax M3</td><td class="h-blue">6/30</td><td class="h-blue">21%</td><td class="h-dim">6</td><td class="h-dim">$0.035</td></tr><tr><td class="h-rank">11</td><td class="h-name">Laguna XS 2.1</td><td class="h-blue">4/30</td><td class="h-blue">13%</td><td class="h-red">15</td><td class="h-dim">$0.006</td></tr></tbody></table></div>

*Terra's two unrun items hit the spend ceiling; rates are per item attempted. Minimality held at 0.85–0.97 across the board — these are edits, not rewrites.*

## The Headline Nobody Predicted

**GPT-5.6 Terra is the board's best repairer.** This is the model [the family post](post.html?slug=gpt-5.6-ahk-eval) profiled as a curiosity: a 120-token median completion, code fired with zero deliberation, two *easy*-tier generation tasks dropped. Handed someone else's broken code and one line of failure evidence, that same terseness becomes a scalpel — 64% of attempted items fixed, at $0.026 a fix.

Generation rank does not predict repair rank. The suite's second data point says the same thing in reverse: **GLM-5.2** repairs at 50% (up from GLM-5's 40%) while its cold AHK-Eval run scored **24/36 — one task *below* GLM-5**, entering the board at rank 20. Zhipu's new checkpoint is a better mechanic and a slightly worse author than its predecessor. Two models, two directions, one conclusion: fixing and writing are different skills, and a one-shot generation board measures only one of them.

## Visible Bugs Get Fixed; Silent Ones Don't

Across all eleven repairers the fix rate falls in a clean gradient by failure mode:

- **parse deaths — 40%.** The error names a line and the line names the idiom (`Missing ending "%"` is always `Mod()`).
- **partial failures — 38%.** Something works; the spec narrows where to look.
- **silent zero-scores — 28%.** The code parses, runs, and lies. No signal but the spec itself.

This is the gradient the [AHK-Contract launch post](post.html?slug=ahk-contract-benchmark) predicted before this data existed: execution feedback rescues loud failures, not quiet ones.

## The Graveyard, and a Family Curse

Seven items survived all eleven repairers — among them `AE_NaturalSort` (of course), Kimi's `AE_Pivot`, and all three GLM-5-sourced bugs, which both GLM generations failed alongside everyone else. The aggregate self-repair signal is real but mild: models fixed 27% of bugs from their own pen against a 31% baseline, and DeepSeek even went two-for-two on its own. The vivid specimen is singular: Terra topped the board and was the *only* model to repair Muse Spark's `AE_GroupByFirstLetter` — while **its own** submission for the very same task sat unfixed in the graveyard, untouched by all eleven repairers, Terra included. Whether that's a blind spot or just a harder bug, the suite now has the instrument to keep asking.

## What the Money Says

The budget tier's whole pitch was cost, and the pitch half-survives. Tencent Hy3 fixes at $0.0006 apiece — three orders of magnitude under Kimi's $0.09 — and Qwen3 at $0.003. But at the top of the board the per-fix economics converge to a band ($0.02–0.04) regardless of list price: OpenAI's terseness cancels its 2–5× per-token rates, and GLM-5.2's reasoning verbosity eats most of its price advantage. Laguna XS is the cautionary tail: 15 of its 30 "repairs" failed to parse — it breaks code faster than it fixes it, at any price.

*Disclosure: Claude Fable 5 built AHK-Repair by mining the AHK-Eval failure corpus, ran all four sweeps under user-approved spend ceilings (two of which triggered mid-run aborts, visible in the attempted counts), and wrote this post. Fixes were graded against the same 181-case hidden suite the original submissions failed, on the pinned v2.1-alpha.30+Console fork.*
