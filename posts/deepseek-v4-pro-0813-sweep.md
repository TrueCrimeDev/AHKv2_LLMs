# DeepSeek V4 Pro 0813: A Flawless Mid-Tier and a Reasoning Budget That Runs Out

DeepSeek's **V4 Pro 0813** — the GA checkpoint of V4 Pro, listed on OpenRouter at $0.435/M in, $0.87/M out with a 1M context window, and 2.7× *cheaper* than the undated `deepseek-v4-pro` it replaces — ran all three suites on August 13: [AHK-Eval](post.html?slug=ahk-eval-benchmark) (36 cold one-shot functions, 181 hidden cases), [AHK-Repair](post.html?slug=ahk-repair-benchmark) (30 broken submissions to fix minimally), and [AHK-Contract](post.html?slug=ahk-contract-benchmark) (24 OOP class contracts). Eighty-nine of ninety calls returned code on the first attempt. Total spend: **$0.76**.

It lands **15th of 37** on eval, **7th of 18** on repair, and **3rd of 8** on contract — and the interesting number isn't any of those. It's that the model solved every easy task and every mid task on the board, then lost half the hard tier.

<div class="bm-wrap"><table class="bm-heat"><thead><tr><th style="text-align:left">Suite</th><th>solved</th><th>cases</th><th>parse fails</th><th>rank</th></tr></thead><tbody><tr><td class="h-name">AHK-Eval</td><td class="h-blue">30/36</td><td class="h-dim">155/181</td><td class="h-dim">1</td><td class="h-dim">15/37</td></tr><tr><td class="h-name">AHK-Repair</td><td class="h-blue">14/30</td><td class="h-dim">77/151</td><td class="h-dim">2</td><td class="h-dim">7/18</td></tr><tr><td class="h-name">AHK-Contract</td><td class="h-blue">20/24</td><td class="h-dim">154/173</td><td class="h-dim">1</td><td class="h-dim">3/8</td></tr></tbody></table></div>

## The Cliff

The tier shape is the sharpest the eval board has recorded:

<div class="bm-wrap"><table class="bm-heat"><thead><tr><th style="text-align:left">Tier</th><th>solved</th></tr></thead><tbody><tr><td class="h-name">easy</td><td class="h-emer">12/12</td></tr><tr><td class="h-name">mid</td><td class="h-emer">12/12</td></tr><tr><td class="h-name">hard</td><td class="h-blue">6/12</td></tr></tbody></table></div>

A perfect mid tier is rare — most arms that clear easy 12/12 still drop one or two rungs down. V4 Pro 0813 drops none, and then loses six of twelve hard tasks. By category it swept **strings 6/6 and numbers 6/6**, took 5/6 in algorithms and regex, and fell to 4/6 in both data and datetime.

Against its own predecessor the gain is real and large. The undated `deepseek-v4-pro` scored 22/36 on eval and 11/30 on repair. The 0813 checkpoint is **+8 tasks on eval and +3 on repair, at a third of the token price** — one of the biggest generational steps the suite has measured, and it arrives as a price *cut*.

## One Borrowed Loop

The single eval parse failure is a foreign idiom, the same category that cost [Grok 4.5](post.html?slug=grok-4.5-ahk-eval) two functions. `AE_MergeRanges` died at line 27:

```ahk
for i := 2 to ranges.Length {        ; ==> no such loop form in v2
    r := ranges[i]
```

AHK v2 has no C-style counting `for`. The insertion sort underneath it was correct — the model wrote a working algorithm and reached for a loop header that the language does not have. `Loop ranges.Length - 1` with `i := A_Index + 1` would have shipped it.

The five other eval losses parsed and ran. `AE_Pivot` and `AE_NaturalSort` are the board's standing graveyard, unsolved by most of the roster; `AE_AddBusinessDays` and `AE_ISOWeek` are the datetime pair that pulled that category to 4/6.

## Where the Tokens Went

This is the part that shapes every other number in the post. V4 Pro 0813 is a heavy reasoner, and the undated checkpoint was not — it logged zero reasoning tokens. The 0813 model spends thousands of tokens thinking before it writes a line:

<div class="bm-wrap"><table class="bm-heat"><thead><tr><th style="text-align:left">Suite</th><th>median completion tokens</th><th>calls that hit the cap</th></tr></thead><tbody><tr><td class="h-name">AHK-Eval</td><td class="h-dim">3,564</td><td class="h-dim">6/36</td></tr><tr><td class="h-name">AHK-Repair</td><td class="h-blue">15,312</td><td class="h-amber">14/29</td></tr><tr><td class="h-name">AHK-Contract</td><td class="h-blue">14,842</td><td class="h-amber">8/24</td></tr></tbody></table></div>

The repair median is 15,312 tokens against a 16,000 cap. Half that suite ran out of budget mid-thought. Two calls produced **no code at all** — `AC_Proxy` burned all 20,000 contract tokens reasoning and emitted an empty completion; `Grok_4-3__AE_Unique` did the same at 16,000. Both were graded as parse failures, which is correct as an outcome but misattributes the cause: the model didn't write bad AHK, it never got to the AHK.

This also exposed a defect in the harness worth recording. When a completion comes back with empty content, the generator falls back to the model's reasoning trace — a reasonable habit from the era when reasoning tokens were where the answer hid. For a model that reasons to exhaustion, that fallback writes the *transcript* into the `.ahk` file and logs the call `ok: True`:

```text
= (case-insensitive equal)
== (case-sensitive equal)
!= (case-insensitive not equal)
```

That is the entire contents of one submitted "answer." A runaway-reasoning call should be recorded as a failure, not a success with prose in it. The two affected items are counted as losses here, so the scores are honest, but the log line is misleading and the fallback needs a guard.

## A Caveat on Comparability

To give a reasoner room, this run raised the output caps above the values the historical roster used — 16,000 for eval and repair against the board's 8,000, and 20,000 for contract against 12,000. That decision cuts both ways and readers should weigh it.

On eval it barely matters: 6 of 36 calls touched the ceiling and the median was 3,564. On **repair and contract it matters a great deal** — 14/29 and 8/24 calls were bound by a limit no earlier entry faced, in either direction. Those two scores should be read as *this model under a raised cap*, not as a like-for-like placement against arms that ran at 8,000. The eval figure is close enough to comparable to stand.

The repair suite also stopped one item short of the full thirty when the run hit its spend ceiling, so 14/30 is a floor rather than a final figure.

## What the Money Buys

Seventy-six cents for eighty-nine calls, at roughly seventy seconds each. That is cheap for the eval result and expensive for the time — the same three suites cost [Gemini 3.7 Flash](post.html?slug=gemini-3-7-flash-sweep) twenty-seven cents and about four seconds a call, with better scores on all three.

The honest summary is that DeepSeek shipped a much better model at a much lower price, and then let it think without a leash. A model that solves 24 of 24 easy-and-mid tasks and reasons past its own budget on half the repair suite is not short on capability. It is short on knowing when to stop.

*Disclosure: Claude Opus 5 generated this entry via the OpenRouter API and wrote this post. Every number comes from the same pipeline that graded the rest of the board — parse validation against the v2.1-alpha.30+Console fork, headless execution, and hidden test cases the model never saw. The raised output caps described above apply to this entry only and are flagged wherever they affect a score.*
