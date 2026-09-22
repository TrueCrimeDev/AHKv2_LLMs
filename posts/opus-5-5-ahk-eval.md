# Claude Opus 5.5: Every Answer Right, Eleven Answers Missing

Anthropic's **Claude Opus 5.5** replaces Opus 5 at a lower price: $4/M in, $20/M out. It went through the same three published suites as every other entry: [AHK-Eval](post.html?slug=ahk-eval-benchmark)'s 36 functions and 181 hidden cases, [AHK-Contract](post.html?slug=ahk-contract-benchmark)'s 24 class contracts, and [AHK-Repair](post.html?slug=ahk-repair-benchmark)'s 30 broken submissions. It also ran the 13-task esoteric-features probe, which hasn't been published yet. Each task got one cold call to the direct Anthropic API and one submission, graded by the same parse-then-execute pipeline against the v2.1-alpha.30+Console fork. Total spend was **about $1.05**.

The short version: **every task Opus 5.5 answered, it solved** — on Eval and on the esoteric probe. It also solved every Contract task and fixed 27 of 30 Repair items. The tasks it didn't solve on those two suites are the ones it never saw: an Anthropic safety classifier blocked them before the model produced a token.

<div class="bm-wrap"><table class="bm-heat"><thead><tr><th style="text-align:left">Suite</th><th>score</th><th>hidden cases</th><th>refused</th><th>answered &amp; solved</th><th>cost</th></tr></thead><tbody><tr><td class="h-name">AHK-Eval</td><td class="h-blue"><strong>33/36</strong></td><td class="h-dim">166/181</td><td class="h-dim">3</td><td class="h-emer"><strong>33/33</strong></td><td class="h-dim">$0.27</td></tr><tr><td class="h-name">AHK-Contract</td><td class="h-blue"><strong>24/24</strong></td><td class="h-dim">173/173</td><td class="h-dim">0</td><td class="h-emer"><strong>24/24</strong></td><td class="h-dim">$0.28</td></tr><tr><td class="h-name">AHK-Repair</td><td class="h-blue"><strong>27/30</strong></td><td class="h-dim">139/151</td><td class="h-dim">0</td><td class="h-dim">27/30</td><td class="h-dim">$0.40</td></tr><tr><td class="h-name">Esoteric probe</td><td class="h-blue">5/13</td><td class="h-dim">25/65</td><td class="h-dim">8</td><td class="h-emer"><strong>5/5</strong></td><td class="h-dim">$0.09</td></tr></tbody></table></div>

Two methodology notes. The Opus 5.5 API rejects `temperature` with an HTTP 400, so where the OpenRouter arms ran at 0.2, this one ran at the model's default sampling (the same was true of Fable 5 and GPT-6 Astra). Thinking can't be turned off on this model either, so it ran with adaptive thinking at the API's default effort of `medium`. The prompts, the extractor, `max_tokens`, the interpreter and the hidden cases are byte-identical to every other arm.

## The Refusals

The first pass came back with 16 of 103 calls refused: 5 on Eval, 11 on the esoteric probe, none on Contract or Repair. Every one looked the same:

```json
{"content": [], "stop_reason": "refusal",
 "stop_details": {"type": "refusal", "category": "cyber",
   "explanation": "This request triggered restrictions on violative cyber content and was blocked under Anthropic's Usage Policy. ..."}}
```

Zero output tokens, about 1.5 seconds per call. The model didn't decline these. A classifier gate did, before the model wrote anything.

Here are the tasks it blocked:

- swap the case of every letter
- convert CamelCase to snake_case
- convert hex to decimal
- strip HTML tags
- extract email addresses
- reverse an enumerator
- swap two variables through `&` references
- sort by a key function
- pack integers into a `Buffer`
- count UTF-8 bytes

Nothing on that list is sensitive. The best guess (and it is only a guess) is the language itself: AutoHotkey shows up in a lot of keyloggers, game cheats and malware droppers, and tasks built on byte packing, encodings and text scraping look like the parts those tools are made of.

**The gate is not deterministic.** Re-sending the 16 refused prompts unchanged, once each, recovered five: `AE_SwapCase`, `AE_CamelToSnake`, `AX_Curry`, `AX_MapLookup` and `AX_StaticInit`. All five then passed every hidden case. One inconsistency stands out. `AE_ExtractEmails` is blocked as an Eval task but goes through as a Repair item, where the prompt carries another model's broken email extractor and asks for a fix. The underlying work is the same.

The scores above are after that single retry. Eleven tasks are still refused and are scored as missing, because a blocked call has no code to grade. With the three Eval refusals counted as misses, Opus 5.5 places **13th of 42** on the published AHK-Eval board. On the 33 tasks it did get to answer it posts a perfect record: 166 of 166 hidden cases. For context, Opus 5 went through AHK-Eval via OpenRouter in July and had 20 of 36 tasks refused. Refusals are down sharply, but they're still there.

The refusal message points API integrators at server-side fallbacks, which re-run a refused request on a different model. This run doesn't use them. A fallback answer would be another model's code scored under Opus 5.5's name.

## AHK-Contract: 24 for 24

The class-contract suite covers construction protocol, meta-function routing, `this`-binding across callbacks, exact error-class contracts and the alpha.30 typed-property surface. **Opus 5.5 solves all twenty-four, 173 of 173 hidden cases**, with no parse failures and no refusals. On the published board, only GPT-6 Astra and Gemini 3.7 Flash have done that before. Median completion was 286 tokens at about five seconds a task, for $0.28.

## AHK-Repair: 27 of 30

Handed thirty broken submissions, each with the original task card, one line of observed failure and an instruction to make the smallest change, Opus 5.5 fixes **27**, with 139 of 151 hidden cases passing. That's third, one item behind GPT-6 Astra and Gemini 3.7 Flash at 28. Average minimality is 0.835, the same surgical profile as Astra.

The three misses are more interesting than the score. Two of them are fixes that look right and aren't, because each one keeps a second bug the failure line never mentioned.

**`AE_Caesar` (GLM-5's submission).** The original compared characters with `c >= "A"`, and AHK v2's relational operators throw on strings. Opus 5.5 spotted that and switched to character codes:

```ahk
n := Asc(c)
if (n >= 65 && n <= 90)
    result .= Chr(Mod(Asc(c) - 65 + k, 26) + 65)
```

The comparison fix is correct. But `Asc` doesn't exist in AHK v2. It's a v1 function; v2 has `Ord`. The original already called it, and the fix adds a third call. The interpreter reads `Asc` as an unassigned local variable, so every call throws `UnsetError`: 0 of 5.

**`AE_ExtractEmails` (GLM-5's submission).** The original wrote `\\.` in the regex, carrying over the C-style habit of doubling a backslash. AutoHotkey strings don't escape backslashes, so that pattern matches a literal backslash. Opus 5.5 fixed it and even corrected the comment. Two lines further down, `pos := foundPos + m.Len` survived. On this alpha.30 build, `m.Len` with no subpattern index falls through to the match object's `__Get` and throws. 1 of 5, and the one pass is the input with no emails.

**`AE_ISOWeek` (Tencent Hy3's submission).** The original didn't parse: Hy3 used `%` as a C-style modulo operator, which AHK reads as the start of a dynamic reference. The minimal fix would have repaired the syntax. Opus 5.5 rewrote the inverse Julian-day block and the day-of-week formula instead (minimality 0.56, its lowest of the thirty), and the result gets 2 of 5 hidden cases.

In both of the first two, the failure report said only "wrong results on hidden inputs". Opus 5.5 found one bug, fixed it and stopped looking. GPT-6 Astra's two Repair misses follow the same pattern: when the target is the smallest change, a bug the failure report didn't name is easy to keep.

## The Esoteric Probe

The unpublished esoteric probe is 13 tasks built on less-common v2 features: typed buffers, meta-functions, `&` references, static initializers, named regex groups. The best entries score 13 of 13 on it. Opus 5.5 answered five and solved all five. The classifier blocked the other eight, which include most of the byte- and buffer-level tasks. On this probe the refusal rate, not the model, decides the score.

## What the Money Says

About $1.05 for the whole run at list price — $0.27 Eval, $0.28 Contract, $0.40 Repair, $0.09 esoteric, including the 16 retries. Refused calls cost almost nothing: the input tokens only, with no output. Median completion was 219 tokens on Eval and 390 on Repair. At 40% of Fable 5's output price, Opus 5.5 lands a perfect Contract run and third on Repair. On Eval, what holds it back is the refusal gate, not the code.

*Disclosure: Claude Opus 5.5 — the model under test — generated these entries through the Anthropic API and wrote this post. Every number comes from the same pipeline that graded the other entries: parse validation against the v2.1-alpha.30+Console fork, headless execution, and hidden test cases the model never saw.*
