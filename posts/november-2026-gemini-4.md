# Gemini 4 Neon Fixes All 30 AHK-Repair Items

Three more Gemini 4 models reached OpenRouter in November: Carbon on the 10th, Hydrogen on the 12th and Neon on the 18th. This post runs all three through the same suites as every other entry: [AHK-Eval](post.html?slug=ahk-eval-benchmark)'s 36 functions and 181 hidden cases, [AHK-Contract](post.html?slug=ahk-contract-benchmark)'s 24 class contracts, [AHK-Repair](post.html?slug=ahk-repair-benchmark)'s 30 broken submissions, and the 13-task esoteric-features probe. Each task got one cold call at temperature 0.2 and one submission, graded by the same parse-then-execute pipeline as the rest of the board.

The short version: all three pass every hidden case on AHK-Eval, 36 of 36 tasks and 181 of 181 cases. Before this batch only GPT-6 Astra and GPT-6.1 Sol had done that. **Gemini 4 Neon** is the first model to fix all 30 Repair items, and its four-suite score of 102 of 103 is the highest on the board. **Gemini 4 Carbon** scores 100 of 103 for $1.40.

<div class="bm-wrap"><table class="bm-heat"><thead><tr><th>board</th><th style="text-align:left">Model</th><th>AHK-Eval</th><th>hidden cases</th><th>AHK-Contract</th><th>AHK-Repair</th><th>Esoteric</th><th>cost</th></tr></thead><tbody><tr><td class="h-rank">3</td><td class="h-name">GPT-6.1 Sol <span class="h-dim">(October)</span></td><td class="h-emer"><strong>36/36</strong></td><td class="h-dim">181/181</td><td class="h-blue">23/24</td><td class="h-emer">29/30</td><td class="h-emer">13/13</td><td class="h-dim">$0.35</td></tr><tr><td class="h-rank">5</td><td class="h-name">Gemini 4 Carbon</td><td class="h-emer"><strong>36/36</strong></td><td class="h-dim">181/181</td><td class="h-blue">23/24</td><td class="h-emer">28/30</td><td class="h-emer">13/13</td><td class="h-dim">$1.40</td></tr><tr><td class="h-rank">6</td><td class="h-name">Gemini 4 Hydrogen</td><td class="h-emer"><strong>36/36</strong></td><td class="h-dim">181/181</td><td class="h-emer">24/24</td><td class="h-blue">27/30</td><td class="h-emer">13/13</td><td class="h-dim">$1.90</td></tr><tr><td class="h-rank">7</td><td class="h-name">Gemini 4 Neon</td><td class="h-emer"><strong>36/36</strong></td><td class="h-dim">181/181</td><td class="h-emer">24/24</td><td class="h-emer"><strong>30/30</strong></td><td class="h-blue">12/13</td><td class="h-dim">$6.00</td></tr><tr><td class="h-rank">9</td><td class="h-name">Gemini 4 Argon <span class="h-dim">(October)</span></td><td class="h-blue"><strong>35/36</strong></td><td class="h-dim">180/181</td><td class="h-blue">23/24</td><td class="h-blue">27/30</td><td class="h-emer">13/13</td><td class="h-dim">$0.30</td></tr></tbody></table></div>

The board column is the model's place on the published [AHK-Eval leaderboard](leaderboard.html), now 61 entries. The board ranks on Eval alone, and ties on tasks and cases are listed alphabetically. That's why Neon sits seventh, behind the two GPT-6 Astra arms, the two GPT-6.1 Sol arms, Carbon and Hydrogen, all with identical Eval scores. Cost is the four-suite total.

## Method Notes

- **Interpreter.** These entries are graded on the v2.1-alpha.38+Console fork. The October batch was graded on alpha.35 and older entries on alpha.30. On alpha.38 the reference solutions pass all 36 Eval tasks and all 24 Contract tasks, and every broken Repair submission still fails the way it did when the suite was built.
- **Token caps.** `max_tokens` was 16,000 for Eval, Repair and the esoteric probe, and 20,000 for Contract, the same as October.
- **Two routes.** The first 182 of the 309 calls went through OpenRouter, pinned to Google Vertex. Partway through, the OpenRouter key reached its spending limit, and the remaining 127 calls went to Google's Gemini API directly. Both routes used the same model, temperature and caps. Costs for the direct calls are computed from token counts at Google's list price, which matches the Vertex rate on OpenRouter.

## Neon: 30 of 30 on Repair

AHK-Repair hands the model a broken submission and the failure it produced, and asks for the smallest fix. Four items have stopped most models on the board. Before this batch, no entry had fixed all four.

<div class="bm-wrap"><table class="bm-heat"><thead><tr><th style="text-align:left">Repair item</th><th>fixed before this batch</th><th>Neon</th><th>Carbon</th><th>Hydrogen</th></tr></thead><tbody><tr><td class="h-name">GLM-5's email extractor</td><td class="h-red">5 of 38</td><td class="h-emer">fixed</td><td class="h-emer">fixed</td><td class="h-red">1/5</td></tr><tr><td class="h-name">GPT-5.6 Terra's group-by-first-letter</td><td class="h-red">6 of 38</td><td class="h-emer">fixed</td><td class="h-emer">fixed</td><td class="h-emer">fixed</td></tr><tr><td class="h-name">Laguna XS 2.1's natural sort</td><td class="h-red">8 of 38</td><td class="h-emer">fixed</td><td class="h-red">timeout</td><td class="h-red">0/5</td></tr><tr><td class="h-name">GLM-5's hex-color check</td><td class="h-amber">10 of 38</td><td class="h-emer">fixed</td><td class="h-emer">fixed</td><td class="h-red">no answer</td></tr></tbody></table></div>

The email extractor is the item from [October's post](post.html?slug=october-2026-model-roster) that thirteen of sixteen models got wrong by keeping `m.Value`. AHK v2's match object has no `Value` member, so the line throws as soon as anything matches. Neon and Carbon both change it to `m[0]`:

```ahk
while foundPos := RegExMatch(s, needle, &m, pos) {
    emails.Push(m[0])
    pos := foundPos + m.Len
}
```

Hydrogen fixes the regex and keeps `m.Value`, the same miss as GPT-6.1 Sol and Sonnet 5.5.

GPT-6 Astra missed both group-by-first-letter items, and GPT-6.1 Sol missed the email extractor. Neon's 30 of 30 is two better than Astra and one better than GPT-6.1 Sol.

## The Date Case Argon Missed

In October, Gemini 4 Argon and Gemini 3.8 Flash dropped the same hidden case of `AE_DateReformat`. They wrapped the date pattern in `\b` word boundaries, so a date wedged between letters, `x2024-02-29y`, came back unchanged. All three new models write the same line, character for character:

```ahk
AE_DateReformat(s) {
    return RegExReplace(s, "(?<!\d)(\d{4})-(\d{2})-(\d{2})(?!\d)", "$3/$2/$1")
}
```

The lookarounds rule out a digit on either side and allow letters, which is what the spec asks for. That one case is the whole difference between Argon's 180 of 181 and the new models' 181.

All three also write the alpha.30 typed `Struct` in `AC_PixelBuffer` with one field per line. In October, eight of sixteen models put it on one line, which AutoHotkey won't load.

## What the Thinking Costs

At default settings Argon returned almost no reasoning tokens. All three new models reason by default, and how much they reason sets the bill.

<div class="bm-wrap"><table class="bm-heat"><thead><tr><th style="text-align:left">Model</th><th>output $/M</th><th>Eval</th><th>Contract</th><th>Repair</th><th>Esoteric</th><th>cost</th></tr></thead><tbody><tr><td class="h-name">Gemini 4 Neon</td><td class="h-dim">$15.00</td><td class="h-amber">1,888</td><td class="h-amber">2,910</td><td class="h-red">3,337</td><td class="h-red">3,021</td><td class="h-dim">$6.00</td></tr><tr><td class="h-name">Gemini 4 Hydrogen</td><td class="h-dim">$7.50</td><td class="h-blue">1,278</td><td class="h-blue">1,521</td><td class="h-amber">2,130</td><td class="h-amber">1,863</td><td class="h-dim">$1.90</td></tr><tr><td class="h-name">Gemini 4 Carbon</td><td class="h-dim">$10.00</td><td class="h-emer">812</td><td class="h-emer">951</td><td class="h-blue">1,114</td><td class="h-blue">1,154</td><td class="h-dim">$1.40</td></tr><tr><td class="h-name">Gemini 4 Argon <span class="h-dim">(October)</span></td><td class="h-dim">$10.00</td><td class="h-emer">121</td><td class="h-emer">151</td><td class="h-emer">353</td><td class="h-emer">164</td><td class="h-dim">$0.30</td></tr></tbody></table></div>

The suite columns are median completion tokens per call, reasoning included. Hydrogen has the lowest list price of the three, but it uses one and a half to two times as many tokens as Carbon on every suite, so its run cost more. Neon thinks the longest at the highest price. Its two extra points over Carbon cost $4.60.

## The Misses

Seven tasks in the whole batch went wrong, and two of them never produced code.

- **Neon, `AX_NamedGroups`.** Neon reasoned until the 16,000-token cap and never wrote the function. The response held only its unfinished reasoning, so there was nothing to grade.
- **Hydrogen, the hex-color repair.** The same thing: the response hit the cap with no text.
- **Hydrogen, the natural-sort and email repairs.** Both answers parse and return wrong results: 0 of 5 and 1 of 5.
- **Carbon, `AE_DayOfWeek` repair.** Carbon rewrote the month shift as a statement on its own line, `m < 3 ? (y -= 1, m += 10) : m -= 2`. AutoHotkey v2 reads a line that starts with a name and a space as a function call, so this is a call to `m` with `< 3 ? …` as its argument, and the file fails to load with a syntax error. Written as `m<3 ? …` or `(m < 3) ? …`, the same line loads and runs.
- **Carbon, the natural-sort repair.** The fix runs past the grader's 25-second timeout.
- **Carbon, `AC_FluentArray`.** The class is correct, but the reply's closing code fence ended up in the extracted file, and AutoHotkey can't load a file with a stray fence line in it. With that line removed, it passes all eight cases. The score stays a miss: 43 earlier answers on the board picked up the same stray fence and were graded under the same extraction rules.

## What the Money Says

The batch cost $9.30: $4.37 through OpenRouter and $4.93 through Google's API at list price. Carbon is the value pick: 100 of 103 for $1.40, every Eval case right, and fixes for three of the four hardest Repair items. Neon is the strongest result on the board and costs about four times as much. Gemini 4 Argon is still the cheapest near-perfect run at 30 cents, but its 98 of 103 is now fourth of the four Gemini 4 models.

*Disclosure: Claude Opus 5.5 ran this batch and wrote this post. Every number comes from the same pipeline that graded the rest of the board: parse validation against the v2.1-alpha.38+Console fork, headless execution, and hidden test cases the models never saw.*
