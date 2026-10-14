# Sixteen New Models: GPT-6.1 Sol Joins the Perfect-Eval Club for 35 Cents

This batch puts sixteen models through the same suites as every other entry: [AHK-Eval](post.html?slug=ahk-eval-benchmark)'s 36 functions and 181 hidden cases, [AHK-Contract](post.html?slug=ahk-contract-benchmark)'s 24 class contracts, [AHK-Repair](post.html?slug=ahk-repair-benchmark)'s 30 broken submissions, and the 13-task esoteric-features probe. Fifteen of them reached OpenRouter in the last few weeks. The sixteenth, Gemini 3.8 Flash, ran in September and was held back until now. Each task got one cold call through OpenRouter at temperature 0.2 and one submission, graded by the same parse-then-execute pipeline as the rest of the board.

The short version: **GPT-6.1 Sol** joins GPT-6 Astra as the only models to pass every hidden case on AHK-Eval, 36 of 36 tasks and 181 of 181 cases. It adds 29 of 30 on Repair and 13 of 13 on the esoteric probe, and the whole four-suite run cost **$0.35**. Gemini 4 Argon and Gemini 3.8 Flash are one hidden case behind, and it's the same case for both.

<div class="bm-wrap"><table class="bm-heat"><thead><tr><th>board</th><th style="text-align:left">Model</th><th>AHK-Eval</th><th>hidden cases</th><th>AHK-Contract</th><th>AHK-Repair</th><th>Esoteric</th><th>cost</th></tr></thead><tbody><tr><td class="h-rank">3</td><td class="h-name">GPT-6.1 Sol</td><td class="h-emer"><strong>36/36</strong></td><td class="h-dim">181/181</td><td class="h-blue">23/24</td><td class="h-emer">29/30</td><td class="h-emer">13/13</td><td class="h-dim">$0.35</td></tr><tr><td class="h-rank">4</td><td class="h-name">GPT-6.1 Sol Pro</td><td class="h-emer"><strong>36/36</strong></td><td class="h-dim">181/181</td><td class="h-blue">23/24</td><td class="h-emer">29/30</td><td class="h-emer">13/13</td><td class="h-dim">$1.21</td></tr><tr><td class="h-rank">5</td><td class="h-name">Gemini 3.8 Flash</td><td class="h-blue"><strong>35/36</strong></td><td class="h-dim">180/181</td><td class="h-emer">24/24</td><td class="h-blue">25/30</td><td class="h-emer">13/13</td><td class="h-dim">$1.40</td></tr><tr><td class="h-rank">6</td><td class="h-name">Gemini 4 Argon</td><td class="h-blue"><strong>35/36</strong></td><td class="h-dim">180/181</td><td class="h-blue">23/24</td><td class="h-blue">27/30</td><td class="h-emer">13/13</td><td class="h-dim">$0.30</td></tr><tr><td class="h-rank">10</td><td class="h-name">Sonnet 5.5</td><td class="h-blue"><strong>35/36</strong></td><td class="h-dim">176/181</td><td class="h-blue">22/24</td><td class="h-emer">29/30</td><td class="h-amber">10/13</td><td class="h-dim">$0.62</td></tr><tr><td class="h-rank">13</td><td class="h-name">GPT-6 Sol</td><td class="h-blue"><strong>34/36</strong></td><td class="h-dim">174/181</td><td class="h-blue">21/24</td><td class="h-blue">27/30</td><td class="h-blue">12/13</td><td class="h-dim">$0.59</td></tr><tr><td class="h-rank">14</td><td class="h-name">GPT-6 Luna</td><td class="h-blue"><strong>34/36</strong></td><td class="h-dim">173/181</td><td class="h-blue">22/24</td><td class="h-amber">19/30</td><td class="h-blue">12/13</td><td class="h-dim">$0.05</td></tr><tr><td class="h-rank">16</td><td class="h-name">DeepSeek V4.1 Flash</td><td class="h-blue"><strong>34/36</strong></td><td class="h-dim">171/181</td><td class="h-amber">20/24</td><td class="h-red">14/30</td><td class="h-blue">11/13</td><td class="h-dim">$0.41</td></tr><tr><td class="h-rank">20</td><td class="h-name">Muse Wonder</td><td class="h-amber"><strong>33/36</strong></td><td class="h-dim">169/181</td><td class="h-blue">22/24</td><td class="h-blue">24/30</td><td class="h-emer">13/13</td><td class="h-dim">$4.37</td></tr><tr><td class="h-rank">24</td><td class="h-name">Qwen3.8 Max Prime</td><td class="h-amber"><strong>32/36</strong></td><td class="h-dim">167/181</td><td class="h-amber">18/24</td><td class="h-amber">15/30</td><td class="h-blue">11/13</td><td class="h-dim">$12.28</td></tr><tr><td class="h-rank">26</td><td class="h-name">Haiku 5.5</td><td class="h-amber"><strong>32/36</strong></td><td class="h-dim">162/181</td><td class="h-emer">24/24</td><td class="h-amber">21/30</td><td class="h-blue">12/13</td><td class="h-dim">$0.05</td></tr><tr><td class="h-rank">29</td><td class="h-name">Grok 4.7</td><td class="h-amber"><strong>31/36</strong></td><td class="h-dim">161/181</td><td class="h-blue">21/24</td><td class="h-amber">21/30</td><td class="h-blue">12/13</td><td class="h-dim">$2.75</td></tr><tr><td class="h-rank">30</td><td class="h-name">Claude Fable 5.1</td><td class="h-amber"><strong>31/36</strong></td><td class="h-dim">160/181</td><td class="h-blue">23/24</td><td class="h-emer">28/30</td><td class="h-red">6/13</td><td class="h-dim">$2.61</td></tr><tr><td class="h-rank">31</td><td class="h-name">GLM-5.3 FlashX</td><td class="h-amber"><strong>31/36</strong></td><td class="h-dim">160/181</td><td class="h-blue">21/24</td><td class="h-amber">19/30</td><td class="h-blue">11/13</td><td class="h-dim">$0.41</td></tr><tr><td class="h-rank">44</td><td class="h-name">GLM-5.3 Prime</td><td class="h-red"><strong>24/36</strong></td><td class="h-dim">122/181</td><td class="h-red">6/24</td><td class="h-red">6/30</td><td class="h-red">2/13</td><td class="h-dim">$10.75</td></tr><tr><td class="h-rank">54</td><td class="h-name">Mistral Large 4</td><td class="h-red"><strong>19/36</strong></td><td class="h-dim">97/181</td><td class="h-amber">15/24</td><td class="h-red">9/30</td><td class="h-red">4/13</td><td class="h-dim">$2.13</td></tr></tbody></table></div>

The board column is the model's place on the published [AHK-Eval leaderboard](leaderboard.html), now 58 entries. Ties on tasks and cases are listed alphabetically, which is why GPT-6.1 Sol sits third behind the two GPT-6 Astra arms with identical scores. Cost is the four-suite total.

## Method Notes

- **Interpreter.** These entries are graded on the v2.1-alpha.35+Console fork. The rest of the board was graded on alpha.30. The reference solutions for all four suites pass every hidden case on alpha.35, and Gemini 3.8 Flash scores exactly the same on both builds.
- **Token caps.** `max_tokens` was 16,000 for Eval, Repair and the esoteric probe, and 20,000 for Contract. Those are the caps recent reasoning arms ran at. Three models in this batch spend most of that budget thinking, which is its own section below.
- **Gemini 4 Argon** ran pinned to Google Vertex. At default settings it returned no reasoning tokens on Eval, Contract or the esoteric probe, so its scores there are effectively no-thinking scores.
- **Claude models** went through OpenRouter but bill to an Anthropic key, so their costs are computed from token counts at list price.
- **A grader fix.** The esoteric grader read its task file with the Windows default code page instead of UTF-8. The `é` and `€` inputs of `AX_Utf8Bytes` arrived mangled, and even the reference solution failed three of five cases. The loader now reads UTF-8, and every entry in this batch was regraded; no previously published score is affected. The same bug garbled the example line of that task's prompt in this batch. Every model that finished an answer within its token budget still passes all five cases.

## GPT-6.1 Sol

GPT-6.1 Sol answers Eval tasks in a median of 181 completion tokens, about 90 of them reasoning, and gets every hidden case right. Across 103 calls it spent 35 cents. It misses only two things in the whole batch, and neither is unique to it: the one-line `Struct` on AHK-Contract and the email-extractor repair, both covered below.

**GPT-6.1 Sol Pro** posts identical scores on every suite. It uses about twice the tokens and cost $1.21, three and a half times as much. On this benchmark the Pro tier buys nothing.

The previous generation is a clear step down. GPT-6 Sol solves 34 of 36 Eval tasks (it misses `AE_MergeRanges` outright and passes 3 of 5 on `AE_EvalRPN`), 21 of 24 on Contract and 27 of 30 on Repair. GPT-6 Luna solves 34 Eval tasks for five cents, the cheapest strong result in the batch.

## Two Geminis, One Missed Case

Gemini 4 Argon solves 35 of 36 Eval tasks with a median of 122 completion tokens and no reasoning at all, and its four-suite run cost 30 cents. Gemini 3.8 Flash solves the same 35, adds a perfect 24 of 24 on Contract, and cost $1.40.

Both drop the same hidden case of `AE_DateReformat`, which asks for every `YYYY-MM-DD` date in a string to be rewritten as `DD/MM/YYYY`. Argon's answer:

```ahk
AE_DateReformat(s) {
    return RegExReplace(s, "\b(\d{4})-(\d{2})-(\d{2})\b", "$3/$2/$1")
}
```

The `\b` word boundaries are a guard the spec doesn't ask for. The hidden input `x2024-02-29y` has a date wedged between letters, so neither boundary matches, and both models return it unchanged instead of `x29/02/2024y`. It's a defensible instinct and a wrong answer to this spec.

## The One-Line Struct

`AC_PixelBuffer` asks for a pixel buffer built on an alpha.30 typed `Struct`. Eight of the sixteen models wrote the struct on one line:

```ahk
Struct AC_Pixel { r: UInt8, g: UInt8, b: UInt8, a: UInt8 }
```

AutoHotkey rejects that at load time with `Unexpected "{"`. Struct fields go one per line, and a file that doesn't load passes none of its eight cases. The eight are GPT-6.1 Sol, GPT-6.1 Sol Pro, GPT-6 Sol, Sonnet 5.5, Grok 4.7, Muse Wonder, Qwen3.8 Max Prime and GLM-5.3 Prime. Grok 4.6 and Gemini 3.6 Flash made the same mistake on alpha.30, so it isn't new to this build. `AC_PixelBuffer` is now tied for the second most-failed task on AHK-Contract, behind `AC_Pipeline`.

## The Repair Item That Beat 14 of 16

One AHK-Repair item is GLM-5's email extractor. The failure line says only "wrong results on hidden inputs (1/5 hidden cases pass)". The submission has two bugs. The regex escapes its dot as `\\.`, a C-style habit that in an AutoHotkey string matches a literal backslash. And the loop collects matches with `m.Value`:

```ahk
while foundPos := RegExMatch(s, needle, &m, pos) {
    emails.Push(m.Value)
    pos := foundPos + m.Len
}
```

AHK v2's match object has no `Value` member. Its documented members are `Pos`, `Len`, `Name`, `Count`, `Mark` and `m[N]`, so `m.Value` falls through to the subpattern lookup and throws as soon as anything matches. Thirteen of the sixteen models kept `m.Value`. Twelve of them fixed the regex; Mistral Large 4 left both bugs in place. GLM-5.3 Prime ran out of tokens. Only **Gemini 4 Argon** and **Grok 4.7** changed the line to `m[0]` and passed all five cases.

It's the pattern earlier Repair runs keep showing. When the failure report doesn't name a bug and the instruction is to make the smallest change, models fix the first problem they find and stop looking.

## Out of Tokens

Three models in this batch often reason until the token cap cuts them off, before they write any code. When that happens, the only text in the response is unfinished reasoning, and there's nothing to grade.

<div class="bm-wrap"><table class="bm-heat"><thead><tr><th style="text-align:left">Model</th><th>calls cut off at the cap</th><th>median completion, Contract</th><th>cost</th></tr></thead><tbody><tr><td class="h-name">GLM-5.3 Prime</td><td class="h-red">57 of 103</td><td class="h-red">20,000</td><td class="h-dim">$10.75</td></tr><tr><td class="h-name">Mistral Large 4</td><td class="h-red">46 of 103</td><td class="h-red">20,000</td><td class="h-dim">$2.13</td></tr><tr><td class="h-name">Qwen3.8 Max Prime</td><td class="h-amber">34 of 103</td><td class="h-amber">14,164</td><td class="h-dim">$12.28</td></tr><tr><td class="h-name">DeepSeek V4.1 Flash</td><td class="h-amber">13 of 103</td><td class="h-dim">6,265</td><td class="h-dim">$0.41</td></tr><tr><td class="h-name">GLM-5.3 FlashX</td><td class="h-dim">5 of 103</td><td class="h-dim">1,835</td><td class="h-dim">$0.41</td></tr></tbody></table></div>

For GLM-5.3 Prime, Mistral Large 4 and Qwen3.8 Max Prime, the scores measure the budget as much as the model. Qwen and GLM Prime ran up the two biggest bills in the batch, and much of that paid for reasoning that never reached an answer: 57% of Qwen's spend and 80% of GLM Prime's went on calls that hit the cap. They're reported at the same caps as everyone else. Whether a higher cap would rescue them is a separate experiment. DeepSeek V4.1 Flash shows a milder version of the same problem: 34 of 36 on Eval, but 11 of its 30 Repair calls hit the cap, and it fixes only 14.

## Claude: Haiku, Sonnet and Fable

**Haiku 5.5** solves all 24 Contract tasks, one of two perfect Contract runs in the batch along with Gemini 3.8 Flash, and the four-suite run cost five cents. **Sonnet 5.5** fixes 29 of 30 Repair items, tied for the best in the batch, and solves 35 of 36 on Eval. Its one Eval miss is `AE_HexToDec`, which didn't parse. **Fable 5.1** fixes 28 of 30 on Repair.

All three still lose tasks to empty responses. Fable 5.1 returned nothing on three Eval tasks (`AE_SwapCase`, `AE_ExtractEmails`, `AE_CsvField`). Sonnet 5.5 returned nothing on one Contract task and three esoteric tasks. Each was retried up to three times and came back empty every time. Two of Fable's three, `AE_SwapCase` and `AE_ExtractEmails`, were also blocked by Opus 5.5's safety classifier in [September's run](post.html?slug=opus-5-5-ahk-eval). As there, a call that returns no code is scored as a miss. Fable 5.1's esoteric entry comes from a run before this batch, in which six of its 13 tasks came back empty.

## What the Money Says

This batch cost $38.90: $35.62 on OpenRouter and $3.28 at Anthropic list price for the three Claude models. Gemini 3.8 Flash's September run adds $1.40. The spread is wide. The two perfect Eval runs cost 35 cents and $1.21, and Gemini 4 Argon's 35 of 36 cost 30 cents. The two most expensive models, Qwen3.8 Max Prime and GLM-5.3 Prime, cost more than $10 each and finish 24th and 44th on the Eval board.

*Disclosure: Claude Opus 5.5 ran this batch and wrote this post. Three of the sixteen models (Haiku 5.5, Sonnet 5.5 and Fable 5.1) are Anthropic's. Every number comes from the same pipeline that graded the rest of the board: parse validation against the v2.1-alpha.35+Console fork, headless execution, and hidden test cases the models never saw.*
