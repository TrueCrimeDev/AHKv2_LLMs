# How to Benchmark LLMs on AHK v2: Ten Rules From Nine Experiments

Since June this blog has graded LLM-written AutoHotkey v2 nine different ways: a GUI that has to open, a toolkit of text transforms, 36 functions behind hidden tests, four harness arms, 24 class contracts, a repair suite, a rare-feature probe, a classifier that tried to replace the grader, and a grading graph that audited the grader itself. Each one was built because the one before it measured something wrong.

This post collects what survived. The short version: **run the code on a pinned interpreter against hidden cases, split the work into many small independent tasks, prove the suite before any model sees it, aim at v2 semantics rather than algorithms, measure the harness separately from the model, and never trust a single board.** Each rule below comes with the number that forced it.

## How the Method Got Here

<div class="bm-wrap"><table class="bm-heat"><thead><tr><th style="text-align:left">experiment</th><th style="text-align:left">shape</th><th style="text-align:left">what it taught</th></tr></thead><tbody><tr><td class="h-name"><a href="post.html?slug=llm-clipboard-benchmark">Clipboard formatter</a></td><td style="text-align:left">one GUI spec, 77 models, parse + run + checklist score</td><td style="text-align:left">65% parsed, 41% ran, and a 95 code score crashed on launch</td></tr><tr><td class="h-name"><a href="post.html?slug=llm-toolkit-benchmark">Clipboard Toolkit</a></td><td style="text-align:left">12 transforms in one file, 27 hidden cases</td><td style="text-align:left">functional cases spread the field, but one parse error zeroed a whole file</td></tr><tr><td class="h-name"><a href="post.html?slug=ahk-eval-benchmark">AHK-Eval</a></td><td style="text-align:left">36 functions, one call each, 181 hidden cases</td><td style="text-align:left">parse failures fell to 2% and the spread moved to v2 semantics</td></tr><tr><td class="h-name"><a href="post.html?slug=ahk-eval-context-arms">Rounds 2</a> &amp; <a href="post.html?slug=ahk-eval-round-3">3</a></td><td style="text-align:left">the same tasks under card, feedback, self-test and Claude Code arms</td><td style="text-align:left">the loop is worth an order of magnitude more than the docs</td></tr><tr><td class="h-name"><a href="post.html?slug=ahk-contract-benchmark">AHK-Contract</a></td><td style="text-align:left">24 class contracts, 173 cases, mutant-gated</td><td style="text-align:left">object bugs only exist across method calls and over time</td></tr><tr><td class="h-name"><a href="post.html?slug=ahk-repair-benchmark">AHK-Repair</a></td><td style="text-align:left">30 real dead submissions, minimal-edit fixes</td><td style="text-align:left">fixing and writing rank models differently</td></tr><tr><td class="h-name">Esoteric probe</td><td style="text-align:left">13 rare-feature tasks across 42 models</td><td style="text-align:left">knowing the common subset is not knowing the language</td></tr><tr><td class="h-name"><a href="post.html?slug=jev-decisions-judge">Jev</a></td><td style="text-align:left">a classifier predicting the grade of 2,952 scripts</td><td style="text-align:left">a judge that reads cannot replace one that runs</td></tr><tr><td class="h-name"><a href="post.html?slug=ahk-harness-graph">The grading graph</a></td><td style="text-align:left">four gated tiers over 159 scripts</td><td style="text-align:left">47 scripts loaded, ran clean and did nothing</td></tr></tbody></table></div>

## 1. Run It. Reading Is Not Grading.

The first board ranked 74 code-emitting models on whether their script parsed, whether it opened a window, and a 0–100 checklist score. Parse passed **65%**; only **41%** ran. Hermes 4 405B tied for the best code score in the folder at 95 and ranked 31st, because its most elegant line called `IsMap()`, a function AHK v2 does not have. Eight of the eighteen scripts that parsed and then crashed were perfectly formed calls to APIs that don't exist. A parser cannot see that. A checklist cannot see it. Neither can a model reading the code: [Jev](post.html?slug=jev-decisions-judge) labeled **199 of 211** zero-pass AHK-Eval scripts `all_pass`, and a leaderboard built from its probabilities correlated with the real one at ρ = 0.33.

Even "it runs" is not enough. The [grading graph](post.html?slug=ahk-harness-graph) found that **46 of 159** clipboard-editor submissions assign `Clipboard := text`, the v1 variable. In v2 that line creates an ordinary local, so the script loads, runs, exits zero and copies nothing. The only thing that proves a program correct is an assertion on what it actually produced.

So every serious board here uses the same three gates, in order: **does it parse** (`/validate`), **does it run**, and **does it return the exact right answer on every hidden case**.

## 2. Many Small Tasks, One Call Each

The Toolkit asked for twelve functions in one file. Kimi K2.6 interleaved its reasoning prose into the code, the file failed to parse, and twelve good functions scored zero. Asked for one small function at a time on [AHK-Eval](post.html?slug=ahk-eval-benchmark), the same model scored **30/36** with the third-most hidden cases in the field.

That is the HumanEval/MBPP pattern, and it changed what the benchmark measures. The GUI board lost 35% of submissions at the loader; AHK-Eval loses **2%** (17 of 432). Once packaging stops deciding the score, the difficulty tiers start doing their job: field solve rates fall **78% easy, 74% mid, 61% hard**, which is what a calibrated suite should show. Granularity also reshuffles rankings. Sonnet 4.6 won the Toolkit; Opus 4.8 beats it by four tasks on Eval. One shape of task is never enough to rank a model.

## 3. A Coarse Example in Public, the Traps in Hidden Cases

The model gets a signature, a spec and **one happy-path example**. The 5–8 hidden cases carry the edges. A task counts as solved only at full marks; the total of hidden cases passed is the partial credit and the tiebreak. That tiebreak has decided the top of the board: GPT-5.6 Sol Pro took rank 1 from GPT-5.5 at 35/36 apiece, **177 cases to 176**.

Compare outputs the way the language would, not the way a string diff would. AHK-Eval normalizes line endings before comparing. The expression-evaluator grader built for an upcoming suite compares numbers with a `1e-9` tolerance so `4` and `4.0` agree. Error cases never assert on message text. AHK-Contract's 28 must-throw cases match the required error class by walking the exception's base chain, so a case expecting `AC_AppError` passes when the candidate throws its `AC_NetError` subclass, exactly as `is` would.

## 4. Prove the Suite Before Any Model Sees It

A benchmark that hasn't been tested is just a second untested program. AHK-Contract ran four free gates before a single paid call:

- **Reference gate.** A hand-written reference passes every case. AHK-Eval went further: a Python oracle computed the expected outputs independently and the AHK reference matched them, **181/181**.
- **Shuffled-order gate.** Re-grade with every task's cases in a different order, to catch hidden coupling between cases.
- **Mutant adequacy.** Each task ships two frozen plausible-wrong implementations: the Python-habit version, the missing-`super.__New` version, the `a?.()` version that dies at the parse gate. All **48 mutants** must fail at least one case. A case set that can't tell right from plausibly wrong doesn't get published.
- **Blind spec-read.** A fresh implementer sees only what a candidate sees and writes the class in good faith. If that fails a hidden case, the spec is ambiguous and gets rewritten. It caught `AC_Retry`'s rethrow-on-exhaustion wording.

[AHK-Repair](post.html?slug=ahk-repair-benchmark) adds the mirror image: before any money moved, a baseline gate re-verified that all thirty broken snippets still fail.

Then pin everything. Expectations for meta-functions and alpha behavior are transcribed from probe scripts run live on the pinned binary (`2.1-alpha.30+Console`, SHA-256 `06e3ce6e…`), never from documentation memory. If the fork is rebuilt, the reference gate reruns before any stored grade is trusted.

The gates exist because the authors fall in too. AHK-Eval's own reference implementations hit the `ExtractDigits` trap twice before verification flushed it out, and the grader for a still-unreleased expression-evaluator suite threw on its first line, `calc := Calc()`, the case-insensitive shadowing trap its own prompt warns about.

## 5. Build the Grader as if the Candidate Is Hostile

Generated code is untrusted input, and some of it is confused enough to look malicious. The driver wraps each submission, calls it with the hidden inputs and reports one line per case. This is the AHK-Eval core loop:

```ahk
for c in cases {
    ok := false
    try {
        got := AE_Task(c[1]*)
        ok := (__aeNorm(got) == __aeNorm(c[2]))
    } catch {
        ok := false
    }
    Print("CASE {} {}", A_Index, ok ? 1 : 0)
}
```

AHK-Contract hardens that skeleton in six ways worth copying:

- **A per-run nonce on every protocol line**, so a submission that prints `CASE 1 1` spoofs nothing.
- **One function per case**, so every case has its own locals and its own instance. Classes with statics spec a `static Reset()` that every case calls first.
- **Two timeouts**: 30 seconds to validate, 25 to run. A naive `this.%name% := v` inside `__Set` recurses forever; the run timeout turns that into a failed case instead of a hung grader.
- **Exit-code classification**: 10 for an uncaught error, 11 for a critical fault, 12 for a parse failure.
- **Crash-prone cases ordered last**, with partial salvage: if the summary line never arrives, the case lines that did arrive still count.
- **A lint on the case bodies themselves**: no `A_TickCount`, `A_Now`, `Random` or timers, and no local name that collides case-insensitively with a class or built-in.

## 6. Aim at v2, Not at Algorithms

The tasks that separate models are not hard algorithms. They are tasks with an obvious path in another language that fails in this one:

- **Relational operators throw on non-numeric strings.** `ExtractDigits` is a one-line `RegExReplace(s, "\D")`; half the field wrote `A_LoopField >= "0"` instead and threw on the first letter. An easy-tier task, solved by **6 of 13** models cold.
- **`while` re-binds `A_Index`**, shadowing the outer `Loop`'s, which cost Fable 5 a textbook `ToRoman`.
- **Identifiers are case-insensitive**, so `main := Main()` fails. It is tied for the largest named cause of load failures in the grading graph's corpus.
- **Borrowed standard libraries.** `StrJoin()`, `Array.Sort()`, `.ToLower()`, `StrReverse`, `Asc`, infix `%` for modulo, a C-style counting `for`. Each one parses or reads cleanly and kills the task at runtime.

Two more patterns held across every board. Map aggregation discriminates harder than algorithms: `GroupByFirstLetter` and `Pivot` went 3/12 on AHK-Eval, worse than every algorithm task except `NaturalSort`. And code-specialist models trail generalists. Qwen3 Coder finished 12th of 13 on Eval, and both of Mistral's coding models failed to parse on the GUI board.

## 7. Measure the Harness as Its Own Variable

Nobody writes AHK in one cold API call, so a cold score only describes half the system. Rounds 2 and 3 re-ran the same 36 tasks and 181 hidden cases under four harness arms, with every arm a fresh generation and the hidden cases outside every loop:

<div class="bm-wrap"><table class="bm-heat"><thead><tr><th style="text-align:left">arm</th><th style="text-align:left">what the model gets</th><th>field mean (of 36)</th><th>Δ vs cold</th></tr></thead><tbody><tr><td class="h-name">cold</td><td style="text-align:left">one bare message, no system prompt</td><td class="h-amber">25.6</td><td class="h-dim">—</td></tr><tr><td class="h-name">+card</td><td style="text-align:left">a 44-line rules file as the system prompt</td><td class="h-amber">26.0</td><td class="h-amber">+0.4</td></tr><tr><td class="h-name">+feedback</td><td style="text-align:left">the public example's error text and one repair round</td><td class="h-blue">28.9</td><td class="h-blue">+3.3</td></tr><tr><td class="h-name">+self-tests</td><td style="text-align:left">writes up to 6 of its own tests, two repair rounds</td><td class="h-emer">31.0</td><td class="h-emer">+5.4</td></tr><tr><td class="h-name">+Claude Code</td><td style="text-align:left">a headless agent with the real interpreter</td><td class="h-emer">Opus 4.8 29 → 36, Sonnet 4.6 25 → 35</td><td class="h-emer">+7 / +10</td></tr></tbody></table></div>

The rules card was a coin flip: it cost Kimi K2.6 four tasks and Grok 4.3 three. One error message lifted every one of the thirteen models. Inside Claude Code, Sonnet 4.6 matched cold GPT-5.5 for about eleven cents a task.

Two caveats keep the arms honest:

- **A single public probe misses bugs it doesn't trigger.** GPT-5.5's `Pivot` passed the example, so the repair round never fired, and then failed 3 of 5 hidden cases.
- **Self-tests amplify the model's reading of the spec, including a wrong one.** GPT-5.1 regressed from 25 to 24 under self-tests. Re-run with its own test inputs but reference-computed expected values, it scored 26: 15 of its 214 tests (7%) carried a wrong expected value, and those 15 were the whole story.

## 8. One Board Measures One Skill

Writing a function, writing a class, fixing someone else's code and knowing the language's corners are different skills, and the boards rank them differently.

GPT-5.6 Terra is a terse model that drops easy generation tasks, yet it is the best repairer on AHK-Repair at **64%**. GLM-5.2 repairs better than GLM-5 (50% vs 40%) while scoring one task *worse* on Eval. Repair also exposes what execution feedback cannot fix: parse deaths get repaired 40% of the time, partial failures 38%, and silent wrong-value bugs only **28%**. The rare-feature probe tracks Eval overall (ρ = 0.86 across 37 complete models) but splits off the models that only know the common subset. Inkling scores 0.64 on Eval and 0.32 on the probe.

A board also has a shelf life. GPT-6 Astra posted the first cold **36/36** on AHK-Eval, and Contract has three perfect entries: Astra, Gemini 3.7 Flash and Opus 5.5. When the top of a board fills up, it stops ranking the top, and it needs a harder companion.

## 9. Freeze the Protocol, Disclose Every Deviation

The cold protocol is fixed: one API message per task, `temperature 0.2`, `max_tokens 8000`, fenced-code extraction with directives stripped, and a fallback to the `reasoning` field when a model returns `content: null` (four models in the Toolkit run hid their whole program there). Every exception gets written down in the post that contains it:

- **APIs that reject `temperature`.** Fable 5, Opus 5.5 and GPT-6 Astra ran at default sampling.
- **The token cap.** Muse Spark's `NaturalSort` hit the 8,000-token cap exactly and was cut off eleven lines into the function.
- **Refusals.** A safety classifier blocked 16 of Opus 5.5's 103 calls before the model wrote a token, and an unchanged retry recovered five. Blocked calls are scored as missing, never re-run on a fallback model, because a fallback answer would be another model's code scored under this one's name.
- **Spend ceilings.** Two AHK-Repair sweeps aborted at their ceiling and show it in the attempted counts.
- **Conflicts of interest.** When the model that built a suite also sits it, it runs the identical protocol with fresh contexts, and the post says so.

Track cost per task too. The per-fix price on Repair spans three orders of magnitude, from $0.0006 to $0.09, and the board's top five converge on a $0.02–0.04 band regardless of list price.

## 10. Audit the Instruments

Every measuring tool on this blog has been wrong at least once, in a specific and reproducible way.

- **Screenshots.** PowerShell is DPI-unaware, so on a 125% display every capture of a DPI-aware window was measured at 80% of its real size, and the right and bottom 20% were silently cropped. That included the previously published rank-1 shot. The fix measures the same window at 793×572 instead of 634×458.
- **Parsers and linters.** The bundled tree-sitter grammar fails on a brace-less `catch` body after a closing brace, which the interpreter accepts. 36 of 159 scripts hit it, so their findings are now demoted and marked `partial`. Two gaps in the analyser, classes not counted as callable and the error classes missing from its built-in table, inflated `undefined-call` to 602 findings; fixing them left 57.
- **Judges.** Jev's low end is trustworthy (all 39 scripts it rated below 0.1 really failed), so it works as a cheap reject filter in front of the interpreter. Its high end is not: running best-of-N candidates in Jev's order of confidence took 1.83 interpreter runs to find a pass, against 1.41 for a random shuffle.

Treat every static signal as a lead, and the interpreter's result as the only verdict.

## What Is Still Missing

- **Repeated sampling.** Every arm is one sample per task, and the posts themselves call ±1 task noise. Several samples per task (pass@k) would make close rankings trustworthy, and that matters most where ties are decided by a single hidden case.
- **The agent arm on AHK-Contract.** The suite's headline metric is the cold-to-agent delta per category, with three falsifiable predictions frozen before any run. Only cold results exist so far.

## The Checklist

If you are building the next AHK v2 benchmark, this is the recipe the data supports:

1. Pin the interpreter and record its hash. Rerun the reference gate on any rebuild.
2. Write small, independent tasks, one API call each, with an obvious wrong path in some other language.
3. Publish a signature, a spec and one coarse example. Hide 5–8 cases that carry the traps.
4. Pass the reference, shuffled-order, mutant and blind spec-read gates before spending anything.
5. Isolate every case in its own function, stamp the output with a nonce, and time out both validate and run.
6. Grade parse, then run, then exact output. Count full marks as solved and the case total as tiebreak.
7. Report by tier and category, with tokens and cost per task.
8. Run cold as the baseline, then add feedback and agent arms as separate fresh generations, with the hidden cases outside every loop.
9. Pair the generation board with at least one other skill: classes, repair or rare features.
10. Disclose every protocol deviation, and audit your own tools before you trust a surprising number.

*Disclosure: Claude Opus 5.5 compiled this post from the series' published posts and the grader source in the bench folder. No new model runs were made. Every number is quoted from the post linked beside it, apart from the rare-feature probe figures, which come from that probe's roster report, and the expression-evaluator details, which come from its unreleased task post.*
