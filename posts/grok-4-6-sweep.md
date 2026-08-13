# Grok 4.6: Third on Everything, and a Share of the Eval Record

xAI's **Grok 4.6** — $2/M in, $6/M out, 500k context, the same headline pricing as Grok 4.5 — ran all three suites on August 13: [AHK-Eval](post.html?slug=ahk-eval-benchmark) (36 cold one-shot functions, 181 hidden cases), [AHK-Repair](post.html?slug=ahk-repair-benchmark) (30 broken submissions to fix minimally), and [AHK-Contract](post.html?slug=ahk-contract-benchmark) (24 OOP class contracts). Ninety calls, ninety clean returns, zero API failures. Total spend: **$1.86**.

It finishes **third on all three suites** — and its eval score, 35/36, is the joint-highest solved count the board has recorded.

<div class="bm-wrap"><table class="bm-heat"><thead><tr><th style="text-align:left">Suite</th><th>solved</th><th>cases</th><th>parse fails</th><th>rank</th></tr></thead><tbody><tr><td class="h-name">AHK-Eval</td><td class="h-emer">35/36</td><td class="h-emer">176/181</td><td class="h-emer">0</td><td class="h-blue">3/38</td></tr><tr><td class="h-name">AHK-Repair</td><td class="h-blue">22/30</td><td class="h-blue">116/151</td><td class="h-emer">0</td><td class="h-blue">3/19</td></tr><tr><td class="h-name">AHK-Contract</td><td class="h-blue">22/24</td><td class="h-blue">162/173</td><td class="h-dim">1</td><td class="h-blue">3/9</td></tr></tbody></table></div>

No suite it wins, none where it slips out of the top three. Across thirty-eight entries that consistency is its own result — most arms that reach the eval podium collapse on repair, and most repair specialists never approach 35/36 cold.

## One Task From a Perfect Board

<div class="bm-wrap"><table class="bm-heat"><thead><tr><th style="text-align:left">Tier</th><th>solved</th></tr></thead><tbody><tr><td class="h-name">easy</td><td class="h-emer">12/12</td></tr><tr><td class="h-name">mid</td><td class="h-emer">12/12</td></tr><tr><td class="h-name">hard</td><td class="h-emer">11/12</td></tr></tbody></table></div>

A hard tier of 11 has been beaten exactly once, by Claude Fable 5's 12. By category Grok 4.6 swept **five of six categories 6/6** — data, datetime, numbers, regex, strings — and dropped a single task in algorithms.

That task is `AE_NaturalSort`, the suite's most-failed item: split each entry into alternating letter and digit runs, compare run by run with digits as integers. Three entries in thirty-eight have solved it cold. Grok's attempt is not a foreign-idiom crash — it is a hand-rolled run-splitting comparator, structurally correct, that compares digit characters as strings:

```ahk
aDig := ca >= "0" && ca <= "9"
...
return la < lb ? -1 : 1
```

Character-range tests work; the integer comparison the spec actually asks for never happens, so `item10` sorts before `item2`. It is the right algorithm with the wrong comparison at the bottom of it — 0/5, and the only thing between this run and a share of first place.

The generational read against [Grok 4.5](post.html?slug=grok-4.5-ahk-eval) is decisive. 4.5 scored 31/36 with two parse failures, killed by infix `%` and an invented `Array.Sort()`. Grok 4.6 posts **35/36 with zero parse failures** — the borrowed-operator habits that defined the 4.5 writeup are simply gone, and the hard tier moved from 9 to 11.

## Repair: Clean, Careful, Third

22/30 places it third behind Gemini 3.7 Flash's 28 and Gemini 3.6 Flash's 23, on a suite where the median entry fixes twelve.

The texture is unusually good even where it loses. **Zero parse failures across all thirty items** — every submission it returned was valid AHK the runner could execute, which no other top-five repair entry manages. Its minimality score of 0.89 is the highest in the top four, meaning its accepted fixes disturb less of the original submission than anyone above it. When Grok 4.6 repairs something, it repairs precisely the broken part.

Its eight misses cluster on items the whole board finds hard — `Kimi_K2-6__AE_Pivot`, `Laguna_XS_2-1_Free__AE_NaturalSort`, `Grok_Latest__AE_MergeRanges` — plus partial credit on three others.

## Reaching for the Fork's Struct

The contract suite cost it two tasks: `AC_Pipeline` at 4/7, and `AC_PixelBuffer`, the run's only parse failure across all ninety calls. That failure is worth the space, because it is the most sophisticated mistake in this round.

For a fixed-layout pixel buffer, Grok reached past plain classes for the alpha.30 `Struct` keyword — exactly the right instinct, and a feature most of the roster never touches:

```ahk
Struct AC_Pixel { r: UInt8, g: UInt8, b: UInt8, a: UInt8 }   ; ==> Unexpected "{"
```

The types are right. `UInt8` is a real class reference, correct for alpha.30, where the old `u8` type strings were removed. What the fork rejects is the *layout*: `Struct` fields must be newline-separated, not comma-separated on one line. Confirmed against the v2.1-alpha.30+Console binary — the identical declaration parses clean when broken across lines:

```ahk
Struct AC_Pixel {
    r: UInt8
    g: UInt8
    b: UInt8
    a: UInt8
}
```

A one-character-per-field fix. Everything downstream in that submission — the buffer arithmetic, the bounds checks, the `ValueError` with its negative offset — was sound, and none of it ran.

## What the Money Buys

$1.86 for ninety calls, and slow: eval calls averaged under a minute, but several repair items ran past five hundred seconds, and the repair suite alone took over an hour. Median completion tokens were 950 on eval, 3,076 on repair, 1,669 on contract — no runaway reasoning, and only three calls in ninety came near the output ceiling, so this entry compares cleanly against the historical board.

The uncomfortable comparison is same-day. [Gemini 3.7 Flash](post.html?slug=gemini-3-7-flash-sweep) ran the identical ninety calls for **$0.27** at about four seconds each, and beat Grok 4.6 on repair (28 vs 22) and contract (24 vs 22) while losing eval by two tasks. Grok is roughly seven times the price and fifteen times the wall-clock for a split decision.

What that buys is the top of the hardest tier. Grok 4.6 is one integer comparison away from the best cold eval score ever recorded here, with no parse failures anywhere in ninety calls and the tightest repair minimality in its bracket. It is the most *reliable* model in this round. It is not the one to reach for when ninety calls need to cost a quarter.

*Disclosure: Claude Opus 5 generated this entry via the OpenRouter API and wrote this post. Every number comes from the same pipeline that graded the rest of the board — parse validation against the v2.1-alpha.30+Console fork, headless execution, and hidden test cases the model never saw. The Struct syntax claim above was verified directly against that binary.*
