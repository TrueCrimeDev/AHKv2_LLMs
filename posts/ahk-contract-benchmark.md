# AHK-Contract: 24 Class Contracts, 173 Hidden Tests, and a Benchmark Built to Be Beaten by Agents

[AHK-Eval](post.html?slug=ahk-eval-benchmark) grades one stateless call — arguments in, string out, 36 times. It has ranked twenty-eight endpoints and it still can't see the failure zone its own results keep pointing at: **objects**. Construction protocol, `super` chaining, dispatch order, `this`-binding across callback hops, error-type contracts, lifecycle. Those bugs only exist across method boundaries and over time, and a function suite structurally cannot observe them.

**AHK-Contract** is the companion suite that can. Every task is a class contract: the candidate submits one class (helpers allowed), and 5–8 hidden behavioral tests construct instances, mutate state, detach callbacks, provoke errors, and read the wreckage — headlessly, on the same v2.1-alpha.30+Console fork, graded by the same parse-then-execute discipline as AHK-Eval. 24 tasks, **173 hidden cases**, six categories, and no model has seen any of it yet.

## Six Categories, Four Contracts Each

<div class="bm-wrap"><table class="bm-heat"><thead><tr><th style="text-align:left">category</th><th style="text-align:left">what it catches</th><th style="text-align:left">contracts</th></tr></thead><tbody><tr><td class="h-name">lifecycle</td><td style="text-align:left">no-<code>new</code> construction, <code>super.__New</code> chaining, statics vs instance shadowing, <code>__Delete</code> timing</td><td style="text-align:left">Counter · Employee · Registry · Resource</td></tr><tr><td class="h-name">meta</td><td style="text-align:left"><code>__Get</code>/<code>__Set</code>/<code>__Call</code> arity and routing, computed-property semantics, own-prop materialization silencing meta dispatch</td><td style="text-align:left">Temperature · Proxy · Observable · Cache</td></tr><tr><td class="h-name">protocol</td><td style="text-align:left">fluent <code>this</code> returns, <code>__Enum</code> delegation and hand-written enumerators, subclass-preserving <code>Array</code> methods</td><td style="text-align:left">QueryBuilder · Bag · FluentArray · Range</td></tr><tr><td class="h-name">binding</td><td style="text-align:left"><code>.Bind(this)</code> identity, <code>ObjBindMethod</code> pre-filled args, closure independence, subscription-token removal during emit</td><td style="text-align:left">Scheduler · Dispatcher · CounterFactory · Emitter</td></tr><tr><td class="h-name">errors</td><td style="text-align:left">exact built-in error classes, custom hierarchies, most-specific-class routing, retry-on-type semantics</td><td style="text-align:left">Validator · AppError · ErrorRouter · Retry</td></tr><tr><td class="h-name">alpha</td><td style="text-align:left">typed properties via class refs, <code>Struct</code> overlays, maybe-call <code>(a?)()</code>, initializer-through-<code>__Set</code> routing, read-only class base</td><td style="text-align:left">Point3D · Pipeline · Mixin · PixelBuffer</td></tr></tbody></table></div>

Tiers run 7 easy / 10 mid / 7 hard. Twenty-eight of the 173 cases expect a **thrown error of a named class** — matched by walking the exception's base chain, so a case expecting `AC_AppError` passes when the candidate throws its `AC_NetError` subclass, exactly as `is` would.

## What a Hidden Test Looks Like

Each case body is spliced into the driver as a standalone function — its own locals, its own instance, no shared state with other cases. The task's contract for `AC_Observable` requires that on this interpreter, `__Set` intercepts **every** assignment a candidate instance doesn't own yet — including the class-body initializer that runs before `__New`:

```ahk
AC_Observable.Reset()
o1 := AC_Observable()
o1.Depth := "d1"
return ObjHasOwnProp(o1, "State") "," ObjHasOwnProp(o1, "Tag")
     "," ObjHasOwnProp(o1, "Depth") "|" AC_Observable.LogText()
; expected: 1,1,1|set:State=init,set:Tag=none,set:Depth=d1
```

That single case checks the alpha.30 routing order, the `DefineProp` escape hatch (naive `this.%name% := v` inside `__Set` recurses to death — the run gate's 25-second timeout catches the infinite loop), and own-property materialization, in one string compare.

The grader itself is paranoid by construction. Every protocol line is stamped with a per-run nonce, so a malicious or confused submission that prints `CASE 1 1` spoofs nothing. Statics-bearing tasks spec a `static Reset()` and every body calls it first, so cases stay order-independent — verified by re-grading the whole suite with shuffled case order. And tasks that need harness-side classes (you can't declare a class inside an AHK function body) get disjoint per-case fixtures, so a `Mixin.Graft` in case 1 can't contaminate case 5.

## The Suite Was Adversarially Tested Before Any Model Sees It

Three gates ran before assembly, all free:

- **Reference gate** — a hand-written reference implementation scores 173/173. Twice: once in authored case order, once shuffled.
- **Mutant adequacy** — every task ships two frozen *plausible-wrong* implementations: the Python-habit version, the missing-`super.__New` version, the `a?.()` version that dies at the parse gate. All **48 mutants are killed** by at least one hidden case. A case set that can't tell right from plausibly-wrong doesn't get published.
- **Blind spec-read** — a fresh implementer, seeing only what a candidate sees (signature, spec, one coarse example), wrote an independent implementation for every task. Where a good-faith reading failed a hidden case, the spec was ruled ambiguous and rewritten. This gate caught exactly one real ambiguity (`AC_Retry`'s rethrow-on-exhaustion wording) — which is the point: the benchmark's first adversarial result was against itself.

Expectations for every meta-function and alpha-frontier behavior were transcribed from probe scripts run live on the pinned binary (`2.1-alpha.30+Console`, SHA-256 `06e3ce6e…`) — never from documentation memory. If the fork is rebuilt, the reference gate reruns before any stored grade is trusted.

## Two Arms, One Delta

- **Cold** — the AHK-Eval round-1 protocol verbatim: one bare API message, temperature 0.2, one submission.
- **Agent** — same task card, but the candidate runs as a coding agent in a scratch workspace with the fork binary available and up to eight tool turns. It can write probe scripts, run them, misread the spec, watch the error, and revise. The hidden cases stay hidden either way.

The per-category **cold→agent delta** is the product. Three falsifiable predictions, frozen now, before any run:

1. The **alpha** category shows the largest cold→agent gap — its semantics barely exist in training data, but every one of them is observable in two lines of probe output.
2. Cold losses in **protocol** are dominated by invented members (`.Sort()`, `.Join()`, string methods) — the same borrowed-API fingerprint that decided [the GPT-5.6 family post](post.html?slug=gpt-5.6-ahk-eval).
3. Execution feedback rescues parse deaths and thrown inventions, but **not** silent wrong-value bugs — `binding` identity and `meta` dispatch-order cases stay lost cold *and* agentic for models that don't know the semantics, which is what makes them the load-bearing cases of the suite.

## What Runs First

The cold sweep across the AHK-Eval roster is wired and waiting on a budget ceiling; the agent arm harness comes after, so every agent run lands on a board that already has its cold baseline. Results get their own post — this one is the contract.

*Disclosure: Claude Fable 5 designed and built this benchmark — a three-design judge panel synthesized the harness, 24 authoring agents wrote and probe-validated the tasks against the fork binary, and every reference, mutant, and blind-verification gate above ran to completion before this post was written. The hidden cases stay hidden.*
