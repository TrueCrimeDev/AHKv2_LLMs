# AHK-Eval Round 2: What a Coding Harness Is Actually Worth

[Round 1](post.html?slug=ahk-eval-benchmark) measured thirteen models **cold** — one bare API message per task, no system prompt, no tools. That's a clean measurement and an unrealistic one: nobody writes AHK that way. Real work happens inside a harness — rules files auto-loaded into context, and a runtime that throws your errors back at you.

So round 2 re-runs the same 36 tasks, same hidden 181 test cases, same grading driver, same fork — with two harness arms:

- **+card** — a **44-line rules file** attached as the system prompt. Not written for this benchmark: it's the byte-for-byte syntax card a working AHK setup auto-loads for every `.ahk` edit (`:=` not `=`, `Map()` not object literals, fat-arrow single-line only, no `.Keys()` on Map...). Frozen before the run.
- **+card+feedback** — the same card, plus one **repair round**: each submission is executed against the task's *public example only*. If it fails to parse, throws, or returns the wrong value, the model gets the actual error text and one chance to fix it. The 181 hidden cases never enter the loop.

Every arm is a fresh generation — no arm sees another arm's code. One repair maximum. Grading identical to round 1.

## The Leaderboard, Three Ways

<div class="bm-wrap"><table class="bm-heat"><thead><tr><th style="text-align:left">Model</th><th>cold</th><th>+card</th><th>+card+feedback</th><th>Δ card</th><th>Δ feedback</th></tr></thead><tbody><tr><td class="h-name">Fable 5</td><td class="h-emer">34</td><td class="h-emer">35</td><td class="h-emer">36/36</td><td class="h-emer">+1</td><td class="h-emer">+2</td></tr><tr><td class="h-name">GPT-5.5</td><td class="h-emer">35</td><td class="h-emer">35</td><td class="h-emer">35</td><td class="h-dim">0</td><td class="h-dim">0</td></tr><tr><td class="h-name">Gemini 3.1 Pro</td><td class="h-emer">32</td><td class="h-emer">32</td><td class="h-emer">35</td><td class="h-dim">0</td><td class="h-emer">+3</td></tr><tr><td class="h-name">Opus 4.8</td><td class="h-emer">29</td><td class="h-emer">29</td><td class="h-emer">34</td><td class="h-dim">0</td><td class="h-emer">+5</td></tr><tr><td class="h-name">Kimi K2.6</td><td class="h-emer">30</td><td class="h-amber">26</td><td class="h-emer">32</td><td class="h-red">−4</td><td class="h-emer">+2</td></tr><tr><td class="h-name">Grok 4.3</td><td class="h-emer">28</td><td class="h-amber">25</td><td class="h-emer">31</td><td class="h-red">−3</td><td class="h-emer">+3</td></tr><tr><td class="h-name">MiniMax M3</td><td class="h-amber">26</td><td class="h-amber">24</td><td class="h-emer">30</td><td class="h-red">−2</td><td class="h-emer">+4</td></tr><tr><td class="h-name">Sonnet 4.6</td><td class="h-amber">25</td><td class="h-amber">27</td><td class="h-emer">29</td><td class="h-emer">+2</td><td class="h-emer">+4</td></tr><tr><td class="h-name">GLM-5</td><td class="h-amber">25</td><td class="h-amber">27</td><td class="h-emer">29</td><td class="h-emer">+2</td><td class="h-emer">+4</td></tr><tr><td class="h-name">DeepSeek V4 Pro</td><td class="h-amber">22</td><td class="h-amber">26</td><td class="h-amber">27</td><td class="h-emer">+4</td><td class="h-emer">+5</td></tr><tr><td class="h-name">GPT-5.1</td><td class="h-amber">22</td><td class="h-amber">25</td><td class="h-amber">25</td><td class="h-emer">+3</td><td class="h-emer">+3</td></tr><tr><td class="h-name">Qwen3 Coder</td><td class="h-amber">16</td><td class="h-amber">15</td><td class="h-amber">18</td><td class="h-red">−1</td><td class="h-emer">+2</td></tr><tr><td class="h-name">Mistral Large 3</td><td class="h-red">9</td><td class="h-red">12</td><td class="h-red">15</td><td class="h-emer">+3</td><td class="h-emer">+6</td></tr></tbody></table></div>

Field means: the rules card is worth **+0.38 tasks**. One round of execution feedback is worth **+3.31**.

## The Rules Card Is a Coin Flip

The documentation arm scattered: +4 for DeepSeek, −4 for Kimi, roughly zero across the top of the board. The bottom half — models that fumble basic v2 syntax — gained a little. Several strong models got *worse*: Kimi K2.6 dropped four tasks, Grok three. More context appears to mean more opportunity to over-comply, over-explain, or wander off the output format — Kimi's round-1 "packaging problem" came back with reinforcements.

The sharpest version of this finding is the field's signature trap. `ExtractDigits` — killed by `A_LoopField >= "0"` throwing on letters — went **6 solves cold, 5 with the card**. Handing models a syntax rules file didn't touch the trap (the card, honestly, doesn't mention it — real rules files encode style, not exhaustive semantics). Documentation in context is not inoculation.

## Feedback Lifts Every Single Model

The repair arm is a different phenomenon: **all thirteen models improved over cold**, from +2 to +6. No exceptions, including the models the card had hurt.

The mechanism is visible in the plumbing: 123 of 468 first drafts failed the public probe; one error message later, 46 of them passed it outright — and the fixes carried to the hidden cases. The tasks that moved most are exactly the semantics traps:

- `ExtractDigits` 6 → **11** (the error text says `Expected a Number but got a String` — models fix it instantly)
- `Duration` 8 → **12**, `WordWrap` 9 → **12**, `ToRoman` 10 → **13**, `CamelToSnake` 6 → **10**
- Even `NaturalSort`, round 1's wall, doubled: 2 → **4** — GPT-5.5 finally cracked it with a failing example in hand

Algorithm walls erode slower than trap walls (`Pivot` 4 → 5, `MergeRanges` 7 → 8): a stack trace tells you *that* you're wrong, not *how* to think.

## The Conflict-of-Interest Entry Goes Perfect

Same disclosure as round 1: Fable 5 built this benchmark and also sat it, over the bare Anthropic API with the same arms as everyone else, fresh contexts, hidden cases never in the loop.

In the feedback arm it scored **36/36 — 181 of 181 hidden cases**. The first perfect run in the suite's history. And the single repair event that got it there is the best data point in this post: with the rules card *in its system prompt*, Fable's fresh draft of `ExtractDigits` wrote the relational-operator trap **again** — third documented time across these benchmarks — and threw on the first letter. One line of error text later, the fix was `RegExReplace(s, "\D")`, and every hidden case passed.

Round 1 concluded: *"Knowing about a trap in one context does not inoculate the next cold context."* Round 2 finishes the sentence: neither does documentation sitting in that context. **A stack trace does.**

## The Blind Spot

The feedback arm's one structural limit showed up at the top of the board. GPT-5.5's `Pivot` draft **passed the public example** — so the repair round never fired — and then failed 3 of 5 hidden cases. Probe-based feedback only helps when the bug shows on the probe; a single public example is a coarse probe. That's the argument for the next iteration: let the model write and run *its own* test cases, the way a real agentic harness would. (**[Round 3](post.html?slug=ahk-eval-round-3) ran exactly that** — GPT-5.5's `Pivot` fell to its own tests, and the field gained +5.4.)

And the arms are independent samples, not a pipeline — each is a fresh generation, so ±1-task moves are within sampling noise, and a handful of tasks regressed under feedback (`EvalRPN` 11 → 9: repair can overcorrect a function that was already close).

## Takeaway

If you're building an AHK coding setup — or judging "model + harness" claims — this is the ordering the data supports: **execution feedback ≫ static context**. A 44-line rules card moved the field a third of a task and hurt as many strong models as it helped. One round of run-the-code-and-read-the-error moved the field three-plus tasks and helped all thirteen models. It's the same conclusion the [clipboard board's Full Harness run](post.html?slug=fable-5-clipboard-sweep) reached from the other direction: the value of a harness isn't the documents it stuffs into context — it's the loop.

*Method notes: v2.1-alpha.30+Console fork for all parsing and execution, identical driver and hidden cases as round 1; OpenRouter at `temperature 0.2` (Fable 5 via the Anthropic API at default sampling); `max_tokens 8000`; one repair round maximum, fed only the public example's parse error, exception message, or got-vs-expected values; a repair that un-parsed a parsing draft was discarded. All 3 × 468 generations were fresh — no arm saw another arm's output. Fable 5 wrote the harness arms and this post; every number comes from the same automated pipeline that graded round 1.*

## Appendix: The Rules Card

The +card arms' system prompt, verbatim — the auto-loading syntax rules file from a working AHK v2 setup. Note what it does and doesn't cover: style and API-shape rules, but neither of round 1's headline traps (relational operators throwing on strings, `A_Index` re-binding in `while`).

```markdown
# AHK v2 Syntax Rules

- `:=` for all assignment. Never bare `=`.
- `ClassName()` to instantiate. Never `new ClassName`.
- `Map()` for key-value data. Never object literals `{}` for data storage.
- Assign Map entries individually: `m["key"] := "val"`. Never pass pairs to constructor.
- Arrays are 1-indexed. Never index at 0.
- Fat arrow `=>` for single expressions only. Never `=> { }` with braces.
- Event handlers: extract to method + `.Bind(this)`. Never inline multi-line callbacks.
- Semicolons for comments. Never `//` C-style comments.
- Backtick for escapes inside strings. Never backslash.
- `ComObject()` not `ComObjCreate()`.
- `&var` for ByRef.
- Map has no `.Keys()` method -- iterate with `for key in mapObj`.
- Never empty `catch` blocks. Every `catch` must handle or re-throw.
- Declare variables explicitly and early within scope.
- Verify a method/property exists on the class before calling it. AHK v2 has its own API -- never assume methods from other languages exist.

## Version baseline

- The canonical interpreter is the **v2.1-alpha.30+Console fork**. `A_AhkVersion` reports `2.1-alpha.30+Console`.
- New scripts should declare `#Requires AutoHotkey v2.1-alpha.30`.
- Alpha.30 typed-property and call-syntax rules are mandatory in new code:
  - Maybe-call/index: `(a?)()` and `(a?)[]` — never `a?.()` / `a?.[]`.
  - Typed properties: class refs only — `Int8` / `Int16` / `Int32` / `Int64` / `UInt8` / `UInt16` / `UInt32` / `Float32` / `Float64` / `IntPtr`. No `i32` / `u32` / `uptr` strings, no typeless `buf: 32`. No `UInt64` class — use `Int64` and handle the sign yourself.
  - `DllCall` / `ComCall` / `CallbackCreate` accept `"Void"` return when the result is uninteresting.
  - Parenthesise `!a ?? b` and `b + a ?? c` — bare forms are rejected at load time.

## Fork-only built-ins (always available)

- `Print(Fmt, Values*)` — variadic stdout println; with 2+ args it dispatches to `Format` internally.
- `SyntaxError` — exception class extending `Error`.

## Fork-only built-ins (gated)

- `Eval(expr)` — runtime expression evaluator, enabled with `#EnableEval`. Throws `SyntaxError` on bad input, `UnsetError` on missing identifiers.
```
