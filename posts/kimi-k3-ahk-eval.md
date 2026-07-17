# Kimi K3: Four Tasks Better Than K2.6, and the First Model Through AHK-Contract

Moonshot shipped **Kimi K3** on July 11 — an open-weight multimodal reasoning model, 1M context, $3/M in and $15/M out on OpenRouter. It went through both suites cold: [AHK-Eval](post.html?slug=ahk-eval-benchmark)'s 36 functions and 181 hidden cases, and [AHK-Contract](post.html?slug=ahk-contract-benchmark)'s 24 class contracts and 173 hidden behavioral cases. One bare API call per task, temperature 0.2, one submission, no retries. 60 calls, zero failures, total spend **$1.71**.

Two results. On AHK-Eval it takes **rank 6 at 34/36** — four tasks clear of Kimi K2.6, which sits at rank 12. On AHK-Contract it is the **first model ever to run the suite**, and it scored **23/24**.

That second number is the interesting one, and not in the way the benchmark's authors were hoping.

## AHK-Eval: The Generational Jump Is Real

<div class="bm-wrap"><table class="bm-heat"><thead><tr><th>#</th><th style="text-align:left">Entry</th><th>tasks</th><th>cases</th><th>parse fails</th><th>$/M out</th></tr></thead><tbody><tr><td class="h-rank">1</td><td class="h-name">GPT-5.6 Sol Pro</td><td class="h-blue">35/36</td><td class="h-dim">177/181</td><td class="h-emer">0</td><td class="h-dim">$30</td></tr><tr><td class="h-rank">2</td><td class="h-name">GPT-5.5</td><td class="h-blue">35/36</td><td class="h-dim">176/181</td><td class="h-emer">0</td><td class="h-dim">$30</td></tr><tr><td class="h-rank">3</td><td class="h-name">GPT-5.6 Sol</td><td class="h-blue">34/36</td><td class="h-dim">176/181</td><td class="h-emer">0</td><td class="h-dim">$30</td></tr><tr><td class="h-rank">4</td><td class="h-name">GPT-5.6 Luna Pro</td><td class="h-blue">34/36</td><td class="h-dim">175/181</td><td class="h-emer">0</td><td class="h-dim">$6</td></tr><tr><td class="h-rank">5</td><td class="h-name">Claude Fable 5</td><td class="h-blue">34/36</td><td class="h-dim">172/181</td><td class="h-emer">0</td><td class="h-dim">$50</td></tr><tr><td class="h-rank">6</td><td class="h-name"><strong>Kimi K3</strong></td><td class="h-blue"><strong>34/36</strong></td><td class="h-dim"><strong>171/181</strong></td><td class="h-emer"><strong>0</strong></td><td class="h-dim">$15</td></tr><tr><td class="h-rank">7</td><td class="h-name">GPT-5.6 Luna</td><td class="h-blue">33/36</td><td class="h-dim">169/181</td><td class="h-emer">0</td><td class="h-dim">$6</td></tr><tr><td class="h-rank">12</td><td class="h-name">Kimi K2.6</td><td class="h-blue">30/36</td><td class="h-dim">162/181</td><td class="h-dim">1</td><td class="h-dim">$4</td></tr></tbody></table></div>

K3 clears Opus 4.8 (29/36), Gemini 3.1 Pro (32/36), and Grok 4.5 (31/36). Only the GPT-5.6 Pro tier and GPT-5.5 finish ahead. Zero parse failures — every one of the 36 submissions was valid AHK v2 on the pinned `2.1-alpha.30+Console` fork, which is not a given: K2.6 leaked one, and the bottom of the board is littered with models that emit v1 syntax or invented dialects.

The +4 over K2.6 is the cleanest generational delta the suite has recorded from a single vendor.

### Its Two Losses Aren't Equal

`AE_EndOfMonth` is a real miss. K3 finished it in 505 completion tokens, well inside its budget, and got it wrong. No excuses there.

`AE_NaturalSort` is an artifact, and it's worth being precise about why. The suite caps completions at 8,000 tokens. K3 spent **7,997 of them on reasoning** and had nothing left for an answer:

<div class="bm-wrap"><table class="bm-heat"><thead><tr><th style="text-align:left">task</th><th>completion tokens</th><th>of which reasoning</th><th>result</th></tr></thead><tbody><tr><td class="h-name">AE_Unique</td><td class="h-dim">7,698</td><td class="h-dim">7,586</td><td class="h-emer">5/5 pass</td></tr><tr><td class="h-name">AE_Pivot</td><td class="h-dim">8,000</td><td class="h-dim">7,997</td><td class="h-emer">5/5 pass</td></tr><tr><td class="h-name">AE_NaturalSort</td><td class="h-dim">8,000</td><td class="h-dim">7,997</td><td class="h-dim">0/5 fail</td></tr></tbody></table></div>

When a reasoning model exhausts its budget, `content` comes back empty and the harness falls back to scraping the reasoning trace for a code fence. Two of those three tasks passed anyway — the fallback caught a finished draft mid-thought. `AE_NaturalSort`'s draft wasn't finished.

So K3 is plausibly a 35/36 model wearing a 34/36 score. **The 34 stands**, because every other entry on this board ran under the same 8,000-token cap, and handing K3 more headroom than GPT-5.5 got would buy a rank with a rule change rather than a capability. Truncation is a condition of the suite, not a K3 defect — and at 3 of 36 truncated tasks, K3 is better-behaved than most reasoning models on the board.

## AHK-Contract: 23/24 on the First Try

[AHK-Contract](post.html?slug=ahk-contract-benchmark) launched three weeks ago with 48 killed mutants, a shuffled-order reference gate, a blind spec-read pass, and no model runs at all. It was built on an explicit premise: function suites can't see object semantics, so a class-contract suite would expose a failure zone AHK-Eval structurally cannot — construction protocol, `super` chaining, dispatch order, `this`-binding across callback hops, error-type contracts, lifecycle.

Kimi K3 is the first candidate through it. It solved **23 of 24 contracts, 170 of 173 hidden cases**, zero parse failures.

<div class="bm-wrap"><table class="bm-heat"><thead><tr><th style="text-align:left">category</th><th>tasks</th><th>cases</th></tr></thead><tbody><tr><td class="h-name">lifecycle</td><td class="h-emer">4/4</td><td class="h-dim">28/28</td></tr><tr><td class="h-name">meta</td><td class="h-emer">4/4</td><td class="h-dim">29/29</td></tr><tr><td class="h-name">protocol</td><td class="h-emer">4/4</td><td class="h-dim">31/31</td></tr><tr><td class="h-name">binding</td><td class="h-emer">4/4</td><td class="h-dim">27/27</td></tr><tr><td class="h-name">errors</td><td class="h-emer">4/4</td><td class="h-dim">30/30</td></tr><tr><td class="h-name"><strong>alpha</strong></td><td class="h-blue"><strong>3/4</strong></td><td class="h-dim"><strong>25/28</strong></td></tr></tbody></table></div>

By tier: **easy 7/7, hard 7/7, mid 9/10**. The suite's hard tier — `__Enum` delegation, subscription-token removal during emit, most-specific-class error routing — cost K3 nothing at all.

### This Is a Problem for the Benchmark

AHK-Contract's stated product is the **cold→agent delta**: run a model cold, then run it as an agent with the fork binary and eight tool turns, and measure what execution feedback buys. Three predictions were frozen in advance, one of them being that `binding` identity and `meta` dispatch-order cases "stay lost cold *and* agentic," making them "the load-bearing cases of the suite."

K3 went 4/4 on binding and 4/4 on meta, cold, on the first attempt.

That prediction was hedged — it applies to "models that don't know the semantics," and K3 evidently knows them — so it isn't falsified. But it is squeezed. If a frontier model clears both load-bearing categories cold, those cases don't discriminate at the top of the board, and the delta they were meant to expose has **one task of headroom** left to move. A suite designed to be beaten by agents was very nearly beaten without one.

The honest caveat: **N=1**. One model, one arm, no agent run yet. It's entirely possible K3 is an outlier and the next five candidates scatter across the categories exactly as designed. But the first datapoint says the cold arm is closer to saturation than the design assumed, and that's worth knowing before the roster sweep rather than after.

### The One Contract It Missed

`AC_Pipeline` — alpha category, *mid* tier, 4/7 cases. K3's submission parses clean and its logic reads correct:

```ahk
class AC_Pipeline {
    __New(pre := unset, post := unset) {
        this.hasPre := IsSet(pre)
        this.hasPost := IsSet(post)
        if this.hasPre
            this.pre := pre
        if this.hasPost
            this.post := post
    }

    Run(v) {
        if this.hasPre
            v := this.pre(v)
        v := v * 2
        if this.hasPost
            v := this.post(v)
        return v
    }
}
```

The `IsSet`-at-construction contract is exactly right — that's the part the task was probing, and K3 nailed it. The bug is one line lower. `this.pre(v)` is a **method call**, so AHK passes the instance implicitly as the first argument, and a one-argument hook receives two:

```ahk
this.f(v)   -> THREW: Too many parameters passed to function.
(this.f)(v) -> 101
```

It needed `(this.pre)(v)` or `this.pre.Call(v)`. That single line is the whole 4/7: the three cases that supply a hook throw, the four that don't pass clean. K3 understood the contract and lost the task to AHK's method-call resolution — which is precisely the class of bug a function suite can't see and a contract suite can.

## The Cost Note

The sweep cost $1.71 — $0.95 for 36 eval tasks, $0.76 for 24 contracts. Before running it, the projection said $8.90, built on the assumption that a $15/M reasoning model would saturate its token cap. A $0.30 pilot killed that assumption in four calls: K3's median completion is well under 2,000 tokens, and only 3 of 36 tasks ever approached the ceiling. The estimate was 10× high.

Worth writing down, because the reflex with an expensive reasoning model is to price the worst case and either overpay or not run it. Four calls answered it.

*Pricing pulled live from the OpenRouter model API on the day of the run. Both suites graded on the pinned `2.1-alpha.30+Console` fork, SHA-256 `06e3ce6e…`; AHK-Contract's reference gate was re-verified at 24/24 before K3's submissions were scored.*
