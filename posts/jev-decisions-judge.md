# Jev: A Model That Cannot Write Code, Grading 2,952 AHK v2 Scripts for 13 Cents

OpenRouter added a new kind of model on September 18: **TypeSafe's Jev**, listed as `~typesafe/jev-latest` and priced at $0.042 per million input tokens with output tokens free. Free, because there are none. Point it at the normal chat endpoint and it refuses with a 400: *"is a decisions model and cannot be used with the chat/completions endpoint."* Jev never emits text. It emits probabilities.

That makes it useless for the thing this blog usually measures — writing AutoHotkey v2 from a spec — and interesting for the thing the blog spends most of its compute on: deciding whether code that a model wrote is any good. Every entry on the [AHK-Eval](post.html?slug=ahk-eval-benchmark), [AHK-Contract](post.html?slug=ahk-contract-benchmark) and [AHK-Repair](post.html?slug=ahk-repair-benchmark) boards is graded by parsing the submission against the v2.1-alpha.30 fork and executing it against hidden test cases. That pipeline is exact and it is also the expensive, slow, Windows-bound half of the bench. If a classifier that costs a hundredth of a cent per script could predict its verdict, the harness could triage thousands of candidates before touching the interpreter.

So the question is narrow: given the task card, the hidden cases and a candidate script, how well does Jev predict what the interpreter is about to say? The short answer is that it predicts *syntax* respectably, predicts *correctness* barely better than a coin that always says yes, and has one genuinely useful property that took a calibration chart to find. The long answer is the rest of this post, including how to call it from AHK v2 itself.

## What a Decisions Model Is

The endpoint is `POST https://openrouter.ai/api/alpha/decisions`, same bearer key as everything else on OpenRouter. There is no documentation page yet; the schema is discoverable by sending it nothing and reading the validation errors. An empty body gets you three complaints: `model` must be a string, `state` must be a string, record or array, `questions` must be a record. Send a question with no type and the error lists the only three it accepts: `noul`, `choice`, `score`. Send each type bare and it tells you what else it needs. Ten minutes of 400s is the whole API reference.

The shape that comes out of that:

- **`state`** is whatever you want judged. A string, an object, an array — the code, the spec, the test cases, all of it.
- **`noul`** is a yes/no question. It takes `instructions` and returns a single probability.
- **`choice`** takes `instructions` and a `criteria` map of label → description. It returns the chosen label, a probability for every label, and a confidence.
- **`score`** takes `instructions` and a `criteria` list. It returns an overall score, a probability per criterion, and a confidence.

<img src="posts/img/bench/jev-flow.svg" alt="Diagram: a JSON request with a state object and three questions on the left, Jev in the middle, and three answer cards on the right showing a 0.42 yes/no probability, a choice distribution with unbound_this at 0.73, and a score of 0.45 with three criterion bars" style="max-width:100%;border:1px solid #303030;border-radius:8px;background:#141414">

The diagram is a real call. The state was a small class that passes its button handler to `OnEvent` without `.Bind(this)` — the single most common bug in beginner AHK v2 OOP. Asked to pick the defect from four labels, Jev put 0.73 on `unbound_this`. Asked whether the click would run clean, it said 0.42. Asked to score quality against three criteria, it gave 0.57 to "uses proper v2 OOP", 0.41 to "callbacks bound correctly", and 0.02 to "has error handling". All three answers are defensible, and the call cost $0.000022 for 516 input tokens and 90 output tokens. That is the promising first impression. The roster is where it gets complicated.

## Calling It From AHK v2

Because the endpoint is plain JSON over HTTPS, an AHK v2 script can talk to it with `WinHttp` and no library at all on the fork, which has a native `JSON` class. On a stock build you `#Include` any JSON library that exposes `Stringify` and `Parse`, and nothing else changes. The client is a class with one method and three static builders for the question shapes:

```ahk
class JevClient {
    static Endpoint := "https://openrouter.ai/api/alpha/decisions"

    __New(apiKey, model := "~typesafe/jev-latest") {
        this.apiKey := apiKey
        this.model := model
    }

    Ask(state, questions) {
        body := Map()
        body["model"] := this.model
        body["state"] := state
        body["questions"] := questions
        http := ComObject("WinHttp.WinHttpRequest.5.1")
        http.Open("POST", JevClient.Endpoint, false)
        http.SetRequestHeader("Authorization", "Bearer " this.apiKey)
        http.SetRequestHeader("Content-Type", "application/json")
        http.Send(JSON.Stringify(body))
        if http.Status != 200
            throw Error("Jev returned HTTP " http.Status, -1, SubStr(http.ResponseText, 1, 300))
        return JSON.Parse(http.ResponseText)
    }

    static Noul(instructions) {
        q := Map()
        q["type"] := "noul"
        q["instructions"] := instructions
        return q
    }

    static Choice(instructions, criteria) {
        q := Map()
        q["type"] := "choice"
        q["instructions"] := instructions
        q["criteria"] := criteria
        return q
    }
}
```

Building a request is three Maps. The criteria for a `choice` question is itself a Map of label to description, which `JSON.Stringify` serializes as an object:

```ahk
defects := Map()
defects["none"] := "No defect"
defects["unbound_this"] := "Method passed as a callback without .Bind(this)"
defects["v1_syntax"] := "Uses AutoHotkey v1 syntax"
defects["missing_persistent"] := "Script exits immediately"

questions := Map()
questions["runs_clean"] := JevClient.Noul("Will clicking the button run without a runtime error?")
questions["defect"] := JevClient.Choice("Pick the primary defect in this code.", defects)

state := Map()
state["language"] := "AutoHotkey v2.1"
state["code"] := candidate

reply := JevClient(apiKey).Ask(state, questions)
answers := reply["answers"]
Print("defect {} ({:.2f})", answers["defect"]["choice"], answers["defect"]["confidence"])
for label, p in answers["defect"]["probabilities"]
    Print("  {:-20s} {:.2f}", label, p)
```

Run headless on the fork, that prints:

```text
defect unbound_this (0.64)
  missing_persistent   0.10
  v1_syntax            0.02
  none                 0.15
  unbound_this         0.73
```

One thing to know if you are on the fork: `JSON.Parse` returns a `JSON.Object`, not a `Map`. Bracket indexing and `for k, v in` both work on it; dot access does not. The full demo, with the `.env` reader and the score question, is `Demo\JevClient_Demo.ahk` in the repo.

## The Setup

Every graded submission on the three boards, plus a 13-task probe of less-common language features (`__Enum` closures, `__Item` indexers, `Array.Prototype.DefineProp`, `Buffer`/`NumPut`, VarRef dereference) that ran across the roster the same weekend, went through Jev with its task card and the hidden cases the grader used. That is 1,476 Eval functions from 41 models, 263 Contract classes from 11, 617 Repair fixes from 21, and 596 esoteric-feature submissions from 42. Ground truth is the harness's own record: did it parse, and how many hidden cases passed. Jev saw the spec and the cases; it did not see the grade.

Each script got the same three questions: a `noul` for "will this pass every listed case," a `noul` for "does this load without a syntax error," and a four-way `choice` between `all_pass`, `partial`, `none_pass` and `syntax_error`. A typical call was 877 input tokens and $0.000037. The whole run — 2,952 scripts, three questions each — cost **$0.13** and took about two minutes at six concurrent requests.

Three numbers matter per suite. **Accuracy** is how often Jev's pass probability, thresholded at 0.5, agrees with "all hidden cases passed." **Baseline** is what you get by always guessing the majority class. **AUROC** is the probability that Jev ranks a random passing script above a random failing one — 0.5 is a coin, 1.0 is the interpreter.

<img src="posts/img/bench/jev-judge.svg" alt="Grouped columns per suite: Jev's accuracy at predicting a full pass beside the always-say-yes baseline, with AUROC labeled above each pair" style="max-width:100%;border:1px solid #303030;border-radius:8px;background:#141414">

<div class="bm-wrap"><table class="bm-heat"><thead><tr><th style="text-align:left">Suite</th><th>items</th><th>real pass rate</th><th>Jev accuracy</th><th>baseline</th><th>AUROC</th><th>leaderboard ρ</th></tr></thead><tbody><tr><td class="h-name">AHK-Eval</td><td class="h-dim">1,476</td><td class="h-dim">0.746</td><td class="h-blue">0.764</td><td class="h-dim">0.746</td><td class="h-amber">0.64</td><td class="h-red">0.33</td></tr><tr><td class="h-name">AHK-Contract</td><td class="h-dim">263</td><td class="h-dim">0.810</td><td class="h-blue">0.848</td><td class="h-dim">0.810</td><td class="h-amber">0.71</td><td class="h-amber">0.64</td></tr><tr><td class="h-name">AHK-Repair</td><td class="h-dim">617</td><td class="h-dim">0.462</td><td class="h-blue">0.608</td><td class="h-dim">0.538</td><td class="h-amber">0.73</td><td class="h-emer">0.84</td></tr><tr><td class="h-name">Esoteric</td><td class="h-dim">596</td><td class="h-dim">0.719</td><td class="h-blue">0.798</td><td class="h-dim">0.719</td><td class="h-amber">0.79</td><td class="h-amber">0.66</td></tr></tbody></table></div>

On AHK-Eval, Jev beats the always-yes baseline by 1.8 points. Its AUROC of 0.64 means that shown one script that passes and one that fails, it picks the right one about two times in three.

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

## Per Task: Right Where It Is Easy

Break the Eval agreement down by task and a pattern appears that is almost too clean.

<img src="posts/img/bench/jev-tasks.svg" alt="Horizontal bars for all 36 AHK-Eval tasks sorted by how often Jev's four-way outcome matched the interpreter, from 33% on NaturalSort to 100% on Clamp, with a white tick on each bar marking the task's real pass rate; the tick sits at the end of nearly every bar" style="max-width:100%;border:1px solid #303030;border-radius:8px;background:#141414">

The white tick on each bar is the share of the 42 models that actually solved that task. On thirty-one of thirty-six tasks it sits within three points of the end of Jev's agreement bar. That is what it looks like when a judge says yes to everything: its accuracy on a task *is* the pass rate on that task. The tasks where it looks worst — `AE_NaturalSort` at 33%, `AE_Pivot` at 40%, `AE_GroupByFirstLetter` and `AE_MergeRanges` at 48% — are simply the tasks most models fail, and Jev fails to notice. Deciding whether a natural-sort comparator handles leading zeros means running it in your head. Nothing in the decisions API runs anything.

## If Jev Ran the Leaderboard

Average each model's pass probability across its 36 submissions and rank by it, and you get a leaderboard that correlates with the real one at ρ = 0.33.

<img src="posts/img/bench/jev-rank.svg" alt="Scatter of 42 models, real AHK-Eval rank on the x axis and Jev rank on the y axis. Points scatter widely around the diagonal. GPT-6 Astra, the real number one, sits at Jev rank 13; its xhigh arm at 29; Grok 4.5, real rank 19, is Jev's number one; Qwen3 Coder at real rank 39 is Jev's seventh" style="max-width:100%;border:1px solid #303030;border-radius:8px;background:#141414">

GPT-6 Astra, the only perfect entry, lands thirteenth; its xhigh arm, also perfect, lands twenty-ninth. Grok 4.5, really nineteenth, is Jev's number one. Qwen3 Coder, thirty-ninth of forty-two, is Jev's seventh. The subtitle explains why the picture is so scattered: every model's mean probability sits between 0.75 and 0.85. The whole roster is compressed into a tenth of the scale, and inside that band the ordering is noise.

## Calibration: Where the One Real Signal Lives

A probability is a promise. If Jev says 0.9, then nine of every ten scripts it says that about should pass. The reliability diagram checks that promise decile by decile across all 2,952 scripts.

<img src="posts/img/bench/jev-calibration.svg" alt="Reliability diagram: ten dots, one per decile of Jev's pass probability, sized by count, against the share that actually passed. The bottom-left dots sit on the diagonal at zero; the middle dots fall below it; the top dots are large and slightly below the line" style="max-width:100%;border:1px solid #303030;border-radius:8px;background:#141414">

Two things are true at once. The top of the distribution over-promises: the 0.8–0.9 bin holds 963 scripts and 79% of them passed against an 85% average prediction, and the 0.9+ bin's 13% miss rate is 80 scripts that a grader would have accepted on Jev's word. The middle is worse — the 0.4–0.5 bin says "maybe" and delivers 24%.

But the bottom is honest. The 39 scripts Jev rated below 0.1 all failed. The 27 it rated 0.1–0.2 had one pass among them. Restricting to AHK-Eval, of the 45 submissions rated below 0.4, 36 really did fail, and every one of the 15 below 0.2. Jev's confidence is asymmetric: when it says pass it is often wrong, when it says fail it is usually right. That asymmetry is the whole practical value of the model, and it is also why the Repair suite is its best result — Repair has the lowest pass rate on the board, 46%, so there is more failure to find, and the failures are blatant because the inputs were broken to begin with. Jev's ranking of the 21 Repair models hits ρ = 0.84 on a suite where the same instrument managed 0.33 on Eval.

## Where It Belongs, and Where It Does Not

Put the numbers together and a pipeline design falls out.

<img src="posts/img/bench/jev-pipeline.svg" alt="Five-stage flow: candidate files, a Jev syntax gate rejecting scripts with parse probability under 0.3, a Jev pass gate rejecting scripts with pass probability under 0.2, the fork's validate step, and headless execution. Annotations show the first gate would have rejected 42 of 2,952 scripts with zero passing scripts lost, and the second 66 more with one lost. A red box warns not to order candidates by Jev's pass probability: 1.83 interpreter runs to first pass versus 1.41 in random order" style="max-width:100%;border:1px solid #303030;border-radius:8px;background:#141414">

**Two gates, both safe.** A syntax gate at `p_parse < 0.3` would have rejected 42 of the 2,952 scripts; 39 of them really were syntax errors and none of them passed. A pass gate at `p_pass < 0.2` rejects 66 more, 2.2% of the corpus, at the cost of exactly one passing script. Between them they skip about 4% of interpreter time for a few cents and a couple of seconds. That is not nothing in a harness that fans out hundreds of candidates per task, and it is the only use of Jev this data supports.

**Ordering candidates is worse than random.** The obvious next idea is best-of-N: generate several candidates, run them in Jev's order of confidence, stop at the first one that passes. Simulated over the 36 Eval tasks with all 1,512 candidates, random order reaches a true pass in 1.41 interpreter runs on average. Jev's order takes 1.83. On `AE_Pivot` it takes 18, because seventeen fluent, wrong pivots outscored the correct one. The high end of Jev's distribution is not a ranking; it is where everything that looks like code ends up.

**The `choice` question is the one to keep.** The four-way outcome prediction was 75% accurate overall, and that number is inflated by `all_pass` for the same reason as everything else. But the first probe — pick the defect from a short list of named bugs — is a different kind of question. It is not "is this correct," it is "which of these four patterns does this resemble," and resemblance is what the model does. A triage step that sorts failed submissions into *called a nonexistent function*, *v1 syntax*, *unbound callback*, *wrong return type* would be worth a follow-up sweep, because the harness knows which scripts failed and could check the labels.

## The Esoteric Suite, Briefly

On the 13-task language-feature probe Jev posted its best AUROC, 0.79, and its numbers there deserve one caveat. The probe's failures skew toward outright parse errors — "Functions cannot contain classes" was the single most common one, from models that nested a helper class inside the function body — and parse errors are the thing Jev can partly see. Its parse-validity AUROC on that suite was 0.77, and of the 68 zero-pass scripts, 23 were at least not called `all_pass` — a better ratio than anywhere else. Take the feature-level scores with that in mind: it was grading a suite that happened to fail in its favorite way.

## Verdict

Jev is a genuinely new shape of model on OpenRouter and it does what it says: structured probabilities, no prose, one request in a few hundred milliseconds, for less than the cost of the HTTP round trip, callable from a forty-line AHK class. It is not a code judge. On the suite this blog cares about most it clears the trivial baseline by under two points, rubber-stamps 94% of the scripts that pass nothing, and would rank the only perfect model thirteenth. Ordering candidates by its confidence is worse than shuffling them.

What it is good for is the job nobody wants to spend an LLM on: a sub-cent, sub-second reject filter with high precision at the low end, in front of a real grader — and, plausibly, a labeler for failures the grader has already found. Both uses lean on the one thing the calibration chart proved: when Jev says no, it means it. When it says yes, run the code.

*Disclosure: Claude Fable 5.1 built the harness that sent each submission to Jev, wrote the AHK v2 client, computed the agreement statistics, made the charts, and wrote this post. Ground truth for every item is the same pipeline that graded the leaderboards — parse validation against the v2.1-alpha.30+Console fork, headless execution, and the hidden cases. The Jev sweep itself cost $0.13.*
