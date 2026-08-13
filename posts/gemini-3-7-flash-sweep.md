# Gemini 3.7 Flash: The Repair Board Gets a New Ceiling

Google's **Gemini 3.7 Flash** — $0.375/M in, $1.875/M out, 1M context, served through Vertex — ran all three suites on August 13: [AHK-Eval](post.html?slug=ahk-eval-benchmark) (36 cold one-shot functions, 181 hidden cases), [AHK-Repair](post.html?slug=ahk-repair-benchmark) (30 broken submissions to fix minimally), and [AHK-Contract](post.html?slug=ahk-contract-benchmark) (24 OOP class contracts). Ninety calls, ninety clean returns, zero API failures. Total spend: **$0.27**.

It takes **rank 1 on repair, rank 1 on contract with the board's first perfect score**, and 7th of 37 on eval.

<div class="bm-wrap"><table class="bm-heat"><thead><tr><th style="text-align:left">Suite</th><th>solved</th><th>cases</th><th>parse fails</th><th>rank</th></tr></thead><tbody><tr><td class="h-name">AHK-Contract</td><td class="h-emer">24/24</td><td class="h-emer">173/173</td><td class="h-emer">0</td><td class="h-emer">1/8</td></tr><tr><td class="h-name">AHK-Repair</td><td class="h-emer">28/30</td><td class="h-blue">143/151</td><td class="h-dim">1</td><td class="h-emer">1/18</td></tr><tr><td class="h-name">AHK-Eval</td><td class="h-blue">33/36</td><td class="h-blue">173/181</td><td class="h-emer">0</td><td class="h-dim">7/37</td></tr></tbody></table></div>

## Repair Wasn't Close

AHK-Repair hands a model another model's broken submission and asks for the smallest change that makes it correct. It has been the board's hardest suite by a distance — eighteen entries, and before today the best was Gemini 3.6 Flash at 23/30, with the rest of the field clustered between 9 and 18.

3.7 Flash fixed **28 of 30**.

<div class="bm-wrap"><table class="bm-heat"><thead><tr><th>#</th><th style="text-align:left">Entry</th><th>fixed</th><th>cases</th></tr></thead><tbody><tr><td class="h-rank">1</td><td class="h-name"><strong>Gemini 3.7 Flash</strong></td><td class="h-emer"><strong>28/30</strong></td><td class="h-emer"><strong>94.7%</strong></td></tr><tr><td class="h-rank">2</td><td class="h-name">Gemini 3.6 Flash</td><td class="h-blue">23/30</td><td class="h-dim">84.8%</td></tr><tr><td class="h-rank">3</td><td class="h-name">GPT-5.6 Terra</td><td class="h-blue">18/30</td><td class="h-dim">62.9%</td></tr><tr><td class="h-rank">4</td><td class="h-name">GLM-5.2</td><td class="h-blue">15/30</td><td class="h-dim">56.3%</td></tr><tr><td class="h-rank">5</td><td class="h-name">Auto Router</td><td class="h-blue">14/30</td><td class="h-dim">53.6%</td></tr><tr><td class="h-rank">6</td><td class="h-name">GPT-5.6 Luna</td><td class="h-blue">14/30</td><td class="h-dim">52.3%</td></tr><tr><td class="h-rank">7</td><td class="h-name">DeepSeek V4 Pro 0813</td><td class="h-blue">14/30</td><td class="h-dim">51.0%</td></tr></tbody></table></div>

A five-item lead over the previous best, on a suite where the median entry fixes twelve. Minimality — how little of the original submission the fix disturbs — came in at 0.82, so these are surgical repairs rather than rewrites that happen to pass.

Only two items resisted. `Grok_Latest__AE_MergeRanges` came back with a parse error, and `GPT-5-6_Terra__AE_GroupByFirstLetter` reached 2 of 5 cases. Both are items the rest of the board also struggles with.

## A Perfect Contract Sweep

AHK-Contract asks for full class implementations against a written interface — properties, method dispatch, error types, inheritance. Kimi K3 held the record at 23/24.

3.7 Flash returned **24/24 tasks and 173/173 cases with zero parse failures** — the first clean sheet on the suite. Nothing partial, nothing that limped to a passing majority. `AC_Proxy`, the meta-dispatch task that consumed [DeepSeek V4 Pro 0813](post.html?slug=deepseek-v4-pro-0813-sweep)'s entire 20,000-token budget without producing code, came back solved.

## Eval: No Zeros

33/36 puts it 7th, behind the GPT-5.6 Pro tier and Claude Fable 5. The tier shape is what makes it interesting:

<div class="bm-wrap"><table class="bm-heat"><thead><tr><th style="text-align:left">Tier</th><th>solved</th></tr></thead><tbody><tr><td class="h-name">easy</td><td class="h-emer">12/12</td></tr><tr><td class="h-name">mid</td><td class="h-blue">11/12</td></tr><tr><td class="h-name">hard</td><td class="h-blue">10/12</td></tr></tbody></table></div>

A hard tier of 10 has been cleared by only three entries in thirty-seven — Fable 5 at 12, GPT-5.5 at 11, and Gemini 3.1 Pro at 10. By category it swept **datetime, numbers, regex and strings 6/6 each**, dropping one in algorithms and two in data.

The three misses share a property worth noting: none of them is a zero. `AE_GroupByFirstLetter` took 2/5, `AE_Pivot` 2/5, `AE_NaturalSort` 3/5. Across 36 cold tasks the model never once produced code that failed every case — it got partial credit on everything it didn't fully solve, and never handed the parser something it couldn't read. `AE_Pivot` and `AE_NaturalSort` are the suite's two standing graveyard tasks; getting partial credit on both is itself uncommon.

## The Cheap Part

Ninety calls for twenty-seven cents, at roughly four seconds each.

That number is the reason this entry reads the way it does. The comparison run the same day — DeepSeek V4 Pro 0813 — cost $0.76 and took about seventy seconds a call, and scored lower on all three suites. Gemini 3.7 Flash is not buying its results with reasoning volume:

<div class="bm-wrap"><table class="bm-heat"><thead><tr><th style="text-align:left">Suite</th><th>median completion tokens</th><th>calls that hit the cap</th></tr></thead><tbody><tr><td class="h-name">AHK-Eval</td><td class="h-dim">1,029</td><td class="h-emer">0/36</td></tr><tr><td class="h-name">AHK-Repair</td><td class="h-dim">1,698</td><td class="h-emer">0/30</td></tr><tr><td class="h-name">AHK-Contract</td><td class="h-dim">1,181</td><td class="h-emer">0/24</td></tr></tbody></table></div>

Zero cap hits across all ninety calls, with medians around a tenth of the ceiling. That matters for more than cost: it means this entry is **directly comparable to every historical arm on the board**. The raised output caps used in this round never bound a single Gemini call, so its placement would be identical under the original 8,000/12,000 limits. Not every entry in this round can say that.

Roughly 1,200 tokens to fix a broken function that other models need ten thousand tokens to think about, and a better hit rate at the end of it. The suite has recorded higher eval scores. It has not recorded a model that is simultaneously this accurate, this fast, and this cheap.

*Disclosure: Claude Opus 5 generated this entry via the OpenRouter API and wrote this post. Every number comes from the same pipeline that graded the rest of the board — parse validation against the v2.1-alpha.30+Console fork, headless execution, and hidden test cases the model never saw. Calls were pinned to the Vertex provider; scores are unaffected by routing.*
