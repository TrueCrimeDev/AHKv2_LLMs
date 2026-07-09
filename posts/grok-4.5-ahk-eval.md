# xAI Grok 4.5: Fourth Place, Undone by Borrowed Operators

xAI's **Grok 4.5** — listed on OpenRouter at $2/M in, $6/M out with a 500k context window, a 60% price step over Grok 4.3 — went through [AHK-Eval](post.html?slug=ahk-eval-benchmark) on July 9: the cold one-shot arm, 36 independent AHK v2 functions, 181 hidden test cases, one API call per task at temperature 0.2, graded by the same parse-then-execute pipeline as the seventeen entries already on the board. All 36 calls returned clean single-function code blocks on the first attempt. Total spend: **$0.32**.

It lands **fourth of eighteen** — the best xAI result the suite has recorded, one task behind Gemini 3.1 Pro and three behind the podium.

<div class="bm-wrap"><table class="bm-heat"><thead><tr><th>#</th><th style="text-align:left">Entry</th><th>tasks</th><th>cases</th><th>parse fails</th></tr></thead><tbody><tr><td class="h-rank">1</td><td class="h-name">GPT-5.5</td><td class="h-blue">35/36</td><td class="h-dim">176/181</td><td class="h-emer">0</td></tr><tr><td class="h-rank">2</td><td class="h-name">Claude Fable 5</td><td class="h-blue">34/36</td><td class="h-dim">172/181</td><td class="h-emer">0</td></tr><tr><td class="h-rank">3</td><td class="h-name">Gemini 3.1 Pro</td><td class="h-blue">32/36</td><td class="h-dim">161/181</td><td class="h-dim">2</td></tr><tr><td class="h-rank">4</td><td class="h-name"><strong>Grok 4.5</strong></td><td class="h-blue"><strong>31/36</strong></td><td class="h-dim"><strong>160/181</strong></td><td class="h-dim"><strong>2</strong></td></tr><tr><td class="h-rank">5</td><td class="h-name">Kimi K2.6</td><td class="h-blue">30/36</td><td class="h-dim">162/181</td><td class="h-dim">1</td></tr><tr><td class="h-rank">6</td><td class="h-name">Opus 4.8</td><td class="h-blue">29/36</td><td class="h-dim">155/181</td><td class="h-emer">0</td></tr><tr><td class="h-rank">7</td><td class="h-name">Grok 4.3</td><td class="h-blue">28/36</td><td class="h-dim">145/181</td><td class="h-dim">1</td></tr></tbody></table></div>

## The Profile

The tier shape is top-heavy in the right way: **easy 12/12, mid 10/12, hard 9/12**. That perfect easy tier is matched by exactly one other cold run on the board — GPT-5.5. The hard-tier 9 ties Kimi K2.6 and trails only Fable 5 (12), GPT-5.5 (11), and Gemini 3.1 Pro (10). By category it swept **strings 6/6 and regex 6/6**, then dropped one task each in data, numbers, and datetime, and two in algorithms.

Against its own family: Grok 4.3's cold run was 28/36, 145 cases, hard tier 7. Grok 4.5 is **+3 tasks, +15 cases, hard tier 9** — a real generational gain, though not a strict superset: 4.3 solved `AE_Duration` and `AE_CsvField`, both of which 4.5 dropped while picking up five tasks elsewhere.

## Five Losses, Three Borrowed Habits

Every point Grok 4.5 left on the table traces to an idiom imported from another language. Not v2 mistakes — *foreign* code.

**Infix `%` — two parse deaths.** `AE_BaseN` and `AE_Duration` never reached the runner:

```ahk
rem := n % b            ; ==> Missing ending "%"
m := (n // 60) % 60     ; same death, same operator
```

AHK v2 spells modulo `Mod(n, b)`; `%` is the dereference sigil, and the parser wants its closing partner. This is the exact operator that cost Hy3 four functions at the parse gate — C-family muscle memory that no amount of otherwise-correct v2 syntax offsets.

**`Array.Sort()` — two runtime zeros.** `AE_Pivot` and `AE_NaturalSort` both parsed, ran, and scored 0/5 on the same invented method:

```ahk
keys.Sort((a, b) => (a > b) - (a < b))   ; v2 arrays ship no .Sort
```

The comparator logic on both tasks was plausible — `AE_NaturalSort` even tokenized digit runs correctly before dying on the call that would have used them. `AE_NaturalSort` stays the board's graveyard: two cold solves in eighteen entries (Kimi K2.6, Claude Fable 5). `AE_Pivot` has four.

**`InStr` argument order — one case short of a solve.** `AE_CsvField` is the best specimen of the run. The quoted-field branch — doubled-quote escapes, embedded commas, the genuinely hard part of RFC 4180 — is flawless, because it walks the string character by character. The unquoted branch does this:

```ahk
next := InStr(line, ",", pos)   ; third arg is CaseSense, not StartingPos
```

The signature is `InStr(Haystack, Needle, CaseSense, StartingPos, Occurrence)` — so the scan restarts at position 1 on every field, and the one hidden case it fails is the simplest input on the card: `AE_CsvField("x,y,z", 3)` returns `y,` instead of `z`. It aced every quote-escape trap and lost the task to plain comma-splitting, 4/5.

## What the Money Buys

At $2/$6 per million, Grok 4.5 costs 60% more than Grok 4.3 and buys three tasks and two rungs on the board. The whole 36-task run cost 32 cents and averaged 1,350 completion tokens per task — about double Grok 4.3's 620, but still no runaway reasoning bloat; answers came back in 4–33 seconds. For a model one fix away from each of five losses, the cheapest upgrade isn't the next checkpoint — it's a rules card that says `Mod()`, no `.Sort()`, and check your `InStr` arguments. [Round 2](post.html?slug=ahk-eval-context-arms) measured exactly what that's worth.

*Disclosure: Claude Fable 5 generated this entry via the OpenRouter API and wrote this post. Every number comes from the same pipeline that graded the other seventeen entries — parse validation against the v2.1-alpha.30+Console fork, headless execution, and 181 hidden test cases the model never saw.*
