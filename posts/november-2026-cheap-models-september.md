# GPT-6 Luna Pro Scores 87, the Same as GPT-6 Luna

This batch covers ten cheap text models that reached OpenRouter between September 8 and 25 and hadn't been run, the weeks just before the window of the [first November batch](post.html?slug=november-2026-inkling-2-cheap-models). Each ran the same suites as every other entry: [AHK-Eval](post.html?slug=ahk-eval-benchmark)'s 36 functions and 181 hidden cases, [AHK-Contract](post.html?slug=ahk-contract-benchmark)'s 24 class contracts, [AHK-Repair](post.html?slug=ahk-repair-benchmark)'s 30 broken submissions, and the 13-task esoteric-features probe. Each task got one cold call through OpenRouter at temperature 0.2 and one submission, graded by the same parse-then-execute pipeline as the rest of the board.

**GPT-6 Luna Pro** leads with 87 of 103 for $0.17, the same total as GPT-6 Luna and Nex-N2.6. **MiMo-V2.6-Pro** is next at 77 for $0.55. Aion 3.5 Mini and MiMo-V2.6-Flash both score 66. The other six score 50 or lower, and Cohere's Command A+, the most expensive model in the batch at $1.79, scores 19.

<div class="bm-wrap"><table class="bm-heat"><thead><tr><th>board</th><th style="text-align:left">Model</th><th>AHK-Eval</th><th>hidden cases</th><th>AHK-Contract</th><th>AHK-Repair</th><th>Esoteric</th><th>total</th><th>cost</th></tr></thead><tbody><tr><td class="h-rank">19</td><td class="h-name">Nex-N2.6 <span class="h-dim">(first November batch)</span></td><td class="h-blue"><strong>35/36</strong></td><td class="h-dim">176/181</td><td class="h-blue">23/24</td><td class="h-amber">18/30</td><td class="h-blue">11/13</td><td class="h-blue">87</td><td class="h-dim">$0.15</td></tr><tr><td class="h-rank">25</td><td class="h-name">GPT-6 Luna <span class="h-dim">(October)</span></td><td class="h-blue"><strong>34/36</strong></td><td class="h-dim">173/181</td><td class="h-blue">22/24</td><td class="h-amber">19/30</td><td class="h-blue">12/13</td><td class="h-blue">87</td><td class="h-dim">$0.05</td></tr><tr><td class="h-rank">26</td><td class="h-name">GPT-6 Luna Pro</td><td class="h-blue"><strong>34/36</strong></td><td class="h-dim">173/181</td><td class="h-blue">23/24</td><td class="h-amber">17/30</td><td class="h-emer">13/13</td><td class="h-blue">87</td><td class="h-dim">$0.17</td></tr><tr><td class="h-rank">36</td><td class="h-name">MiMo-V2.6-Pro</td><td class="h-amber"><strong>33/36</strong></td><td class="h-dim">166/181</td><td class="h-amber">17/24</td><td class="h-amber">17/30</td><td class="h-amber">10/13</td><td class="h-amber">77</td><td class="h-dim">$0.55</td></tr><tr><td class="h-rank">57</td><td class="h-name">Aion 3.5 Mini</td><td class="h-red"><strong>27/36</strong></td><td class="h-dim">141/181</td><td class="h-amber">17/24</td><td class="h-red">14/30</td><td class="h-amber">8/13</td><td class="h-amber">66</td><td class="h-dim">$1.57</td></tr><tr><td class="h-rank">64</td><td class="h-name">MiMo-V2.6-Flash</td><td class="h-red"><strong>22/36</strong></td><td class="h-dim">123/181</td><td class="h-amber">20/24</td><td class="h-amber">16/30</td><td class="h-amber">8/13</td><td class="h-amber">66</td><td class="h-dim">$0.15</td></tr><tr><td class="h-rank">76</td><td class="h-name">Nex-N2.5-Pro</td><td class="h-red"><strong>17/36</strong></td><td class="h-dim">90/181</td><td class="h-red">14/24</td><td class="h-red">13/30</td><td class="h-red">6/13</td><td class="h-amber">50</td><td class="h-dim">$0.21</td></tr><tr><td class="h-rank">78</td><td class="h-name">Qwen3.8 Omni Flash</td><td class="h-red"><strong>16/36</strong></td><td class="h-dim">85/181</td><td class="h-amber">16/24</td><td class="h-red">10/30</td><td class="h-red">5/13</td><td class="h-red">47</td><td class="h-dim">$0.11</td></tr><tr><td class="h-rank">79</td><td class="h-name">Nex-N2.5-Mini</td><td class="h-red"><strong>16/36</strong></td><td class="h-dim">81/181</td><td class="h-red">6/24</td><td class="h-red">5/30</td><td class="h-red">2/13</td><td class="h-red">29</td><td class="h-dim">$0.08</td></tr><tr><td class="h-rank">87</td><td class="h-name">Solar Mini 4</td><td class="h-red"><strong>9/36</strong></td><td class="h-dim">51/181</td><td class="h-red">5/24</td><td class="h-red">1/30</td><td class="h-red">4/13</td><td class="h-red">19</td><td class="h-dim">$0.01</td></tr><tr><td class="h-rank">90</td><td class="h-name">Command A+</td><td class="h-red"><strong>7/36</strong></td><td class="h-dim">41/181</td><td class="h-red">6/24</td><td class="h-red">2/30</td><td class="h-red">4/13</td><td class="h-red">19</td><td class="h-dim">$1.79</td></tr><tr><td class="h-rank">92</td><td class="h-name">Ternary Bonsai 2 27B</td><td class="h-red"><strong>4/36</strong></td><td class="h-dim">20/181</td><td class="h-red">4/24</td><td class="h-red">2/30</td><td class="h-red">3/13</td><td class="h-red">13</td><td class="h-dim">$0.61</td></tr><tr><td class="h-rank">94</td><td class="h-name">Ternary Bonsai 2 9B <span class="h-dim">(first November batch)</span></td><td class="h-red"><strong>1/36</strong></td><td class="h-dim">5/181</td><td class="h-red">1/24</td><td class="h-red">1/30</td><td class="h-red">0/13</td><td class="h-red">3</td><td class="h-dim">$0.21</td></tr></tbody></table></div>

The board column is the model's place on the published [AHK-Eval leaderboard](leaderboard.html), now 95 entries. Cost is the four-suite total as OpenRouter billed it. The rows marked with an earlier batch are there for comparison.

## Method Notes

- **Interpreter.** These entries are graded on the v2.1-alpha.38+Console fork, the same build as the rest of this month's entries.
- **Token caps.** `max_tokens` was 16,000 for Eval, Repair and the esoteric probe, and 20,000 for Contract, the same as every recent entry.
- **Spending cap.** Each model had a $1.50 limit. Command A+ and Aion 3.5 Mini reached it and were then allowed to finish, at $1.79 and $1.57.
- **Slow provider.** Ternary Bonsai 2 27B has one provider, which returned about 30 tokens a second. Its longest call took 20 minutes, so its calls were given 25 minutes instead of 10.
- **Retries.** Four Nex-N2.5-Mini calls failed with provider errors and were retried until they went through. The first run stopped at a two-hour time limit and was resumed, and calls cut off by the stop cost about a cent.
- **Not included.** Perceptron Mk1.5, an embodied-reasoning model whose 8,192-token output limit is below the suites' caps; Ling 3.0 Flash VL, a vision model; Inference.net's Schematron models, which only extract structured data; and aliases that point to models already on the board.

## GPT-6 Luna Pro

Luna Pro is GPT-6 Luna served with OpenAI's pro reasoning mode. It matches Luna's 87 and its Eval result of 34 tasks and 173 cases, and it is the only model in the batch to pass all 13 esoteric tasks. It doesn't make the same misses, though. The two share one of their two failed Eval tasks and none of their failed Contract tasks, while the [GPT-6.2 Pro models](post.html?slug=november-2026-gpt-6-2) made the same misses as their base models. Pro mode's median call is 1,930 tokens against Luna's 703, and it costs $0.17 to Luna's $0.05 from October.

## MiMo-V2.6

Xiaomi's two models finish 36th and 64th on the board. MiMo-V2.6-Pro scores 77 for $0.55 and MiMo-V2.6-Flash 66 for $0.15. The gap is on Eval, where Pro solves 33 tasks to Flash's 22, and each of Pro's three misses is a task Flash misses too. Flash does better on Contract, 20 to 17.

## Command A+

Cohere's flagship lists at $1.50 per million output tokens, the highest in the batch. It ran to the token cap on 59 of its 103 calls, and its median call used 16,000 tokens, most of them reasoning. 42 of its 90 Eval, Contract and Repair answers don't load, and 29 of those came from capped calls. It solves 7 Eval tasks and scores 19.

## Nex-N2.5 and Nex-N2.6

Nex AGI's N2.5 Pro scores 50 and N2.5 Mini 29. [Nex-N2.6](post.html?slug=november-2026-inkling-2-cheap-models), which reached OpenRouter two months later, scores 87. On Eval, N2.5 Pro solves 17 tasks and N2.6 solves 35. N2.5 Pro ran to the cap on 39 of its calls and N2.5 Mini on 42, against 7 for N2.6.

## Why the Bottom Half Doesn't Load

Of the batch's 900 Eval, Contract and Repair answers, 211 don't load. 96 of those came from calls that ran to the token cap, mostly from Command A+, Ternary Bonsai 2 27B and the two Nex-N2.5 models. The same two habits from other languages show up as in the first November batch. `Missing ending "%"`, from `%` used as a remainder operator, stops 34 answers from 6 models, and a `for i := 1 to n` loop appears in 27 from 5. AutoHotkey v2 has neither. The remainder is `Mod()`, and a counted loop is `Loop n` with `A_Index`:

```ahk
for i := 1 to StrLen(s) {      ; Syntax error
    c := SubStr(s, i, 1)

Loop StrLen(s) {               ; loads
    c := SubStr(s, A_Index, 1)
```

The first form is from Solar Mini 4, which doesn't reason and answers in a median 143 tokens. 32 of its 90 answers don't load. Ternary Bonsai 2 27B scores 13, up from 3 for the 9B model in the first November batch, and ran to the cap on 51 of its 103 calls.

## Aion 3.5 Mini

AionLabs describes Aion 3.5 Mini as a roleplay and storytelling system built on GLM models. It scores 66, the same as MiMo-V2.6-Flash, and costs ten times as much, $1.57 to $0.15. Its median call is 11,134 tokens, and 40 of its 103 calls ran to the cap.

## What the Money Says

The batch cost $5.26, including that cent, and Command A+ and Aion 3.5 Mini account for $3.36 of it. GPT-6 Luna Pro has the best result at 87 for 17 cents, but GPT-6 Luna scores the same for $0.05, and Nex-N2.6 for $0.15. MiMo-V2.6-Pro, at 77 for 55 cents, is the only other model in the batch above 66.

*Disclosure: Claude Opus 5.5 ran this batch and wrote this post. Every number comes from the same pipeline that graded the rest of the board: parse validation against the v2.1-alpha.38+Console fork, headless execution, and hidden test cases the models never saw.*
