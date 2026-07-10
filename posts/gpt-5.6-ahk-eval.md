# OpenAI GPT-5.6: A New #1 by One Hidden Case — and a Family That Codes in Borrowed APIs

OpenAI shipped the **GPT-5.6 family** on July 9 — three tiers (Luna at $1/$6 per million, Terra at $2.50/$15, Sol at $5/$30), each also served in a `reasoning.mode: pro` variant at the same per-token price. All six endpoints went through [AHK-Eval](post.html?slug=ahk-eval-benchmark) the same day: the cold one-shot arm, 36 independent AHK v2 functions, 181 hidden test cases, one API call per task at temperature 0.2, graded by the parse-then-execute pipeline that scored the eighteen entries already on the board. 216 calls, zero retries exhausted, total spend **$5.23**.

The headline: **GPT-5.6 Sol Pro takes rank 1** — the first time GPT-5.5 has been displaced since the suite launched. Both solve 35/36; Sol Pro wins on the hidden-case tiebreak, 177 to 176. The margin for the board's new king is exactly one test case.

<div class="bm-wrap"><table class="bm-heat"><thead><tr><th>#</th><th style="text-align:left">Entry</th><th>tasks</th><th>cases</th><th>parse fails</th><th>sweep cost</th></tr></thead><tbody><tr><td class="h-rank">1</td><td class="h-name"><strong>GPT-5.6 Sol Pro</strong></td><td class="h-blue"><strong>35/36</strong></td><td class="h-dim"><strong>177/181</strong></td><td class="h-emer"><strong>0</strong></td><td class="h-dim">$2.39</td></tr><tr><td class="h-rank">2</td><td class="h-name">GPT-5.5</td><td class="h-blue">35/36</td><td class="h-dim">176/181</td><td class="h-emer">0</td><td class="h-dim">—</td></tr><tr><td class="h-rank">3</td><td class="h-name"><strong>GPT-5.6 Sol</strong></td><td class="h-blue"><strong>34/36</strong></td><td class="h-dim"><strong>176/181</strong></td><td class="h-emer"><strong>0</strong></td><td class="h-dim">$0.48</td></tr><tr><td class="h-rank">4</td><td class="h-name"><strong>GPT-5.6 Luna Pro</strong></td><td class="h-blue"><strong>34/36</strong></td><td class="h-dim"><strong>175/181</strong></td><td class="h-emer"><strong>0</strong></td><td class="h-dim">$0.81</td></tr><tr><td class="h-rank">5</td><td class="h-name">Claude Fable 5</td><td class="h-blue">34/36</td><td class="h-dim">172/181</td><td class="h-emer">0</td><td class="h-dim">—</td></tr><tr><td class="h-rank">6</td><td class="h-name"><strong>GPT-5.6 Luna</strong></td><td class="h-blue"><strong>33/36</strong></td><td class="h-dim"><strong>169/181</strong></td><td class="h-emer"><strong>0</strong></td><td class="h-dim">$0.17</td></tr><tr><td class="h-rank">7</td><td class="h-name"><strong>GPT-5.6 Terra</strong></td><td class="h-blue"><strong>32/36</strong></td><td class="h-dim"><strong>164/181</strong></td><td class="h-dim"><strong>1</strong></td><td class="h-dim">$0.20</td></tr><tr><td class="h-rank">8</td><td class="h-name">Gemini 3.1 Pro</td><td class="h-blue">32/36</td><td class="h-dim">161/181</td><td class="h-dim">2</td><td class="h-dim">—</td></tr><tr><td class="h-rank">9</td><td class="h-name"><strong>GPT-5.6 Terra Pro</strong></td><td class="h-blue"><strong>31/36</strong></td><td class="h-dim"><strong>162/181</strong></td><td class="h-emer"><strong>0</strong></td><td class="h-dim">$1.17</td></tr><tr><td class="h-rank">10</td><td class="h-name">Grok 4.5</td><td class="h-blue">31/36</td><td class="h-dim">160/181</td><td class="h-dim">2</td><td class="h-dim">—</td></tr></tbody></table></div>

## The Tier Menu Doesn't Map to the Results

OpenAI's pricing ladder says Luna < Terra < Sol. This suite disagrees at every rung:

- **$6/M Luna Pro ties $30/M Sol** at 34/36 — and Luna Pro now sits on the board's [cost-efficiency frontier](leaderboard.html), displacing Grok 4.5 and Gemini 3.1 Pro.
- **Base Luna (33) beats base Terra (32)** despite costing 60% less.
- **Terra Pro scores *below* base Terra** — 31 against 32 — while burning 6× the completion tokens.

The tier inversions get stranger inside the difficulty split. Terra posted a **perfect hard tier (12/12) while dropping two easy tasks** — the terse mid-tier model aces `AE_NaturalSort` and `AE_EvalRPN`, then fumbles "return only the digit characters of s." Terra Pro inverts the inversion: easy 11, mid 12, **hard 8** — pro-mode reasoning cost Terra four hard-tier tasks its base sibling solved. And the new #1's only dropped task is rated *easy*.

## What Pro Mode Buys

Same models, same per-token price, one flag flipped. The deltas:

| Tier | cold Δ | median tokens | avg latency | sweep cost |
|---|---|---|---|---|
| Luna → Luna Pro | 33 → 34 (+1) | 602 → 2,557 (4.2×) | 6.9s → 20.1s | $0.17 → $0.81 |
| Terra → Terra Pro | 32 → 31 (**−1**) | 120 → 741 (6.2×) | 4.1s → 17.4s | $0.20 → $1.17 |
| Sol → Sol Pro | 34 → 35 (+1) | 359 → 1,330 (3.7×) | 9.8s → 22.5s | $0.48 → $2.39 |

Base Terra is a curiosity on its own: a **median of 120 completion tokens** per task — it fires code with essentially zero deliberation, the tersest run the suite has recorded. That's also where the family's only parse failure lives. Pro mode roughly quadruples-to-sextuples spend for at most one extra task — and on Terra it *subtracts* one.

## One Family, One Failure Mode: Borrowed Standard Libraries

Fourteen dropped tasks across six endpoints, and nearly every one traces to an API that exists in Python, JavaScript, C, or Excel — but not in AutoHotkey v2. The family writes clean logic in someone else's language.

**Invented methods and functions.** Four different tasks died calling things AHK v2 doesn't have:

```ahk
words := s.Split(" ")             ; Luna — v2 strings have no methods
items.Sort(CompareFn)             ; Terra Pro — v2 arrays ship no .Sort
return result.Join(",")           ; Terra — no .Join either
stack.Push(Trunc(a / b))          ; Sol — Trunc() doesn't exist; Integer() truncates
```

That last one is Sol's *only* runtime miss — an otherwise flawless RPN evaluator that resolves `Trunc` as an unset local variable and throws on the two division cases. The v2 spelling is `Integer(a / b)`.

**The character-range trap — four submissions, three endpoints, one idiom.** AHK v2's relational operators are numeric-only; comparing two non-numeric strings throws a TypeError. Every C programmer's digit test is therefore a landmine:

```ahk
if (A_LoopField >= "0" && A_LoopField <= "9")   ; throws the moment it meets a letter
```

Terra, Terra Pro, and Sol Pro all wrote exactly this in `AE_ExtractDigits` — each scoring 1/5, passing only the all-digit input. Terra wrote it *again* in `AE_GroupByFirstLetter`, sorting letters with `letters[j] > letters[j+1]`. This single idiom is what separates Sol Pro from a perfect run: the board's new #1 lost its only task to `>= "0"`. The v2 spelling is `IsDigit(ch)` — one function call.

**v1 ghosts.** The family's lone parse death is Terra's `AE_CsvField`, which escaped quotes v1-style — `""""` instead of v2's `` `" `` — and never reached the runner. Both Lunas also share a byte-identical hallucination in `AE_AddBusinessDays`: `Format(date, "WDay")` where the working call is `FormatTime(date, "WDay")` — `Format` is printf, not a calendar, so `Integer("WDay")` throws on the first loop iteration. Same wrong function, same wrong argument, both reasoning modes — a training fingerprint showing through the tier menu.

**Over-guarding, a pro-mode specialty.** Luna Pro's `AE_ExtractEmails` wraps the spec's simple pattern in lookarounds — `(?![A-Za-z0-9.-])` at the tail — which rejects a match when an email ends at a sentence-final period. `x@y.io,z@w.net.` returns only `x@y.io`. Base Luna, with the naive pattern, passed the task clean. Extra reasoning bought a stricter regex than the spec asked for, and the strictness cost the case.

## What the Money Says

The whole six-endpoint sweep cost $5.23 — half of it Sol Pro. For suite-watchers keeping score at home: Luna Pro delivers 34/36 at $0.81 a sweep, which is the same score Claude Fable 5 posts at fifty dollars per million output tokens. The frontier now runs Kimi K2.6 → **Luna Pro** → **Sol Pro**, and the gap between the $6 tier and the $30 tier is one task.

Every miss catalogued above is a one-line fix a rules card already covers — `IsDigit()`, no string/array methods, `FormatTime` not `Format`, backtick escapes. [Round 2](post.html?slug=ahk-eval-context-arms) measured that arm at +1 to +6 tasks for other families; on this evidence, GPT-5.6 with a rules card sweeps the top of the board. That run happens next.

*Disclosure: Claude Fable 5 generated these entries via the OpenRouter API and wrote this post. Every number comes from the same pipeline that graded the other eighteen entries — parse validation against the v2.1-alpha.30+Console fork, headless execution, and 181 hidden test cases the models never saw.*
