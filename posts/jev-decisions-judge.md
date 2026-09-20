# Jev: A Model That Cannot Write Code, Grading 2,952 AHK v2 Scripts for 13 Cents

OpenRouter added a new kind of model on September 18: **TypeSafe's Jev**, listed as `~typesafe/jev-latest` and priced at $0.042 per million input tokens with output tokens free. Free, because there are none. Point it at the normal chat endpoint and it refuses with a 400: *"is a decisions model and cannot be used with the chat/completions endpoint."* Jev never emits text. It emits probabilities.

That makes it useless for the thing this blog usually measures — writing AutoHotkey v2 from a spec — and interesting for the thing the blog spends most of its compute on: deciding whether code that a model wrote is any good. Every entry on the [AHK-Eval](post.html?slug=ahk-eval-benchmark), [AHK-Contract](post.html?slug=ahk-contract-benchmark) and [AHK-Repair](post.html?slug=ahk-repair-benchmark) boards is graded by parsing the submission against the v2.1-alpha.30 fork and executing it against hidden test cases. That pipeline is exact and it is also the expensive, slow, Windows-bound half of the bench. If a classifier that costs a hundredth of a cent per script could predict its verdict, the harness could triage thousands of candidates before touching the interpreter.

So the question is narrow: given the task card, the hidden cases and a candidate script, how well does Jev predict what the interpreter is about to say? The answer is that it predicts *syntax* respectably and *correctness* barely better than a coin that always says yes.

## The Decisions API

The endpoint is `POST /api/alpha/decisions`. You send a `state` — any string, object or array — and a map of named `questions`, each one of three types. `noul` is a yes/no question answered with a probability. `choice` picks one label from a set of criteria and returns the distribution over all of them. `score` rates the state against a list of criteria. Nothing else is accepted; the schema errors are explicit about it.

```json
{
  "model": "~typesafe/jev-latest",
  "state": {
    "language": "AutoHotkey v2.1 (alpha.30)",
    "task": { "sig": "AE_Acronym(s)", "spec": "...", "cases": [ ... ] },
    "candidate_code": "AE_Acronym(s) { ... }"
  },
  "questions": {
    "passes":  { "type": "noul",   "instructions": "Will candidate_code pass every listed test case?" },
    "parses":  { "type": "noul",   "instructions": "Is candidate_code valid AutoHotkey v2 that loads without error?" },
    "outcome": { "type": "choice", "instructions": "Predict the harness outcome.",
                 "criteria": { "all_pass": "...", "partial": "...", "none_pass": "...", "syntax_error": "..." } }
  }
}
```

The answer comes back as `answers.passes.noul = 0.37`, `answers.outcome.choice = "unbound_this"` with a `probabilities` map and a `confidence`, plus a `usage` block with a real `cost` field. A typical call here was 877 input tokens and $0.000037. The whole run below — 2,952 scripts, three questions each — cost **$0.13** and took about two minutes at six concurrent requests.

The first probe was a hand-written class that passed a method to `OnEvent` without `.Bind(this)`. Asked to pick the primary defect from four labels, Jev put 0.72 on `unbound_this`. Promising. Then it met the roster.

## The Setup

Every graded submission on the three boards, plus a 13-task probe of less-common language features (`__Enum` closures, `__Item` indexers, `Array.Prototype.DefineProp`, `Buffer`/`NumPut`, VarRef dereference) that ran across the roster the same weekend, went through Jev with its task card and the hidden cases the grader used. That is 1,476 Eval functions from 41 models, 263 Contract classes from 11, 617 Repair fixes from 21, and 596 esoteric-feature submissions from 42. Ground truth is the harness's own record: did it parse, and how many hidden cases passed. Jev saw the spec and the cases; it did not see the grade.

Three numbers matter per suite. **Accuracy** is how often Jev's pass probability, thresholded at 0.5, agrees with "all hidden cases passed." **Baseline** is what you get by always guessing the majority class. **AUROC** is the probability that Jev ranks a random passing script above a random failing one — 0.5 is a coin, 1.0 is the interpreter.

<img src="posts/img/bench/jev-judge.svg" alt="Grouped columns per suite: Jev's accuracy at predicting a full pass beside the always-say-yes baseline, with AUROC labeled above each pair" style="max-width:100%;border:1px solid #303030;border-radius:8px;background:#141414">

<div class="bm-wrap"><table class="bm-heat"><thead><tr><th style="text-align:left">Suite</th><th>items</th><th>real pass rate</th><th>Jev accuracy</th><th>baseline</th><th>AUROC</th><th>leaderboard ρ</th></tr></thead><tbody><tr><td class="h-name">AHK-Eval</td><td class="h-dim">1,476</td><td class="h-dim">0.746</td><td class="h-blue">0.764</td><td class="h-dim">0.746</td><td class="h-amber">0.64</td><td class="h-red">0.33</td></tr><tr><td class="h-name">AHK-Contract</td><td class="h-dim">263</td><td class="h-dim">0.810</td><td class="h-blue">0.848</td><td class="h-dim">0.810</td><td class="h-amber">0.71</td><td class="h-amber">0.64</td></tr><tr><td class="h-name">AHK-Repair</td><td class="h-dim">617</td><td class="h-dim">0.462</td><td class="h-blue">0.608</td><td class="h-dim">0.538</td><td class="h-amber">0.73</td><td class="h-emer">0.84</td></tr><tr><td class="h-name">Esoteric</td><td class="h-dim">596</td><td class="h-dim">0.719</td><td class="h-blue">0.798</td><td class="h-dim">0.719</td><td class="h-amber">0.79</td><td class="h-amber">0.66</td></tr></tbody></table></div>

On AHK-Eval, Jev beats the always-yes baseline by 1.8 points. Its AUROC of 0.64 means that shown one script that passes and one that fails, it picks the right one about two times in three. The last column is the Spearman correlation between each model's real leaderboard score and Jev's mean pass probability for that model: 0.33 on Eval. A board built from Jev's opinions would put Grok 4.5 first and GPT-6 Astra — the only perfect entry — thirteenth.

## The Rubber Stamp

The confusion matrix on AHK-Eval explains the number. Rows are what the interpreter said; columns are what Jev said.

<div class="bm-wrap"><table class="bm-heat"><thead><tr><th style="text-align:left">truth \ Jev</th><th>all_pass</th><th>partial</th><th>none_pass</th><th>syntax_error</th></tr></thead><tbody><tr><td class="h-name">all_pass</td><td class="h-emer"><strong>1083</strong></td><td class="h-dim">18</td><td class="h-dim">0</td><td class="h-dim">0</td></tr><tr><td class="h-name">partial</td><td class="h-red">73</td><td class="h-dim">7</td><td class="h-dim">1</td><td class="h-dim">0</td></tr><tr><td class="h-name">none_pass</td><td class="h-red"><strong>199</strong></td><td class="h-dim">10</td><td class="h-dim">1</td><td class="h-dim">1</td></tr><tr><td class="h-name">syntax_error</td><td class="h-red"><strong>61</strong></td><td class="h-dim">4</td><td class="h-dim">2</td><td class="h-dim">16</td></tr></tbody></table></div>

Of 211 Eval submissions that parsed and then passed **zero** hidden cases, Jev called 199 of them `all_pass`. Of 83 that failed to load at all, it waved 61 through. It is not hedging, either: 138 of those 211 zero-pass scripts got a pass probability of 0.8 or higher.

Here is one of them, from Gemini 3.5 Flash-Lite, rated 0.91 to pass and 0.94 to parse:

```ahk
AE_CamelToSnake(s) {
    return RegExReplace(s, '([a-z0-9])([A-Z])', '$1_$2').ToLower()
}
```

And DeepSeek V4 Pro's version of the same task, rated 0.92:

```ahk
AE_CamelToSnake(s) {
    result := RegExReplace(s, "([a-z0-9])([A-Z])", "$1_$2")
    return result.Lower()
}
```

Both regexes are right. Both scripts then call a method on a string, and AutoHotkey strings have no methods — `.ToLower()` is C#, `.Lower()` is Python, and either one throws on the first call. Zero of five cases. DeepSeek's `AE_IsPalindrome` got 0.97 for a three-line function built around `StrReverse`, which does not exist. These are the most common failure on the whole board — an imported standard library — and they are exactly what a classifier trained on the *shape* of code cannot see. The code is well-formed. It is fluent. It reads like something that works, and Jev reads.

The tasks where Jev does worst are the ones where correctness lives in the algorithm rather than the API surface: `AE_NaturalSort` (32% agreement with the harness across 41 submissions), `AE_Pivot` (39%), `AE_GroupByFirstLetter` and `AE_MergeRanges` (46%). Deciding whether a natural-sort comparator handles leading zeros means running it in your head. Nothing in the decisions API runs anything.

## What It Can Actually Do

Two things, and both are real.

**Parse validity.** Asked "does this load," Jev's AUROC is 0.82 across everything and **0.95 on AHK-Repair**, where the broken inputs come with a one-line failure description and the syntax errors are the blatant kind — a `..` concatenation, a stray `}`. It is not a linter; it misses the fork-specific rules that only the interpreter knows. But as a first pass over a thousand candidate files, it separates "worth running" from "not even code" for a few cents.

**The low tail is trustworthy.** Jev's confidence is asymmetric. When it says pass, it is often wrong. When it says *fail*, it is usually right: of the 45 Eval submissions it rated below 0.4, 36 really did fail, and every one of the 15 it rated below 0.2 failed. The calibration table says the same thing from the other side — the 0.0–0.2 bin had zero actual passes, the 0.8–1.0 bin had 79% actual passes against an 89% average prediction. The bottom of its distribution is a usable reject signal. The top is noise.

That asymmetry is what makes the Repair result the best of the four suites. Repair has the lowest real pass rate on the board, 46%, so there is more failure to find, and its failures are more blatant, because the inputs were broken to begin with. Jev's ranking of the 21 Repair models against the real leaderboard hits ρ = 0.84. On a suite where three-quarters of everything passes, the same instrument is nearly blind.

## Verdict

Jev is a genuinely new shape of model on OpenRouter and it does what it says: structured probabilities, no prose, one request in a few hundred milliseconds, for less than the cost of the HTTP round trip. It is not a code judge. On the suite this blog cares about most it clears the trivial baseline by under two points and rubber-stamps 94% of the scripts that pass nothing. Ranking models with it would be malpractice.

What it is good for is the job nobody wants to spend an LLM on: a sub-cent, sub-second pre-filter that says "this one is not even syntax, skip it" with high precision, in front of a real grader. In a pipeline that fans out hundreds of candidates per task, that is worth having. It just cannot be the last word, because the last word about whether code works belongs to the thing that runs it.

*Disclosure: Claude Fable 5.1 built the harness that sent each submission to Jev, computed the agreement statistics, and wrote this post. Ground truth for every item is the same pipeline that graded the leaderboards — parse validation against the v2.1-alpha.30+Console fork, headless execution, and the hidden cases. The Jev sweep itself cost $0.13.*
