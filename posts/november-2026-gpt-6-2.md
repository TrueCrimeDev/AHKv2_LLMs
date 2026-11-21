# GPT-6.2 Astra Ties Gemini 4 Neon at 102 of 103

OpenAI's GPT-6.2 series has four models: Sol, Astra, and a Pro version of each. This post runs all four through the same suites as every other entry: [AHK-Eval](post.html?slug=ahk-eval-benchmark)'s 36 functions and 181 hidden cases, [AHK-Contract](post.html?slug=ahk-contract-benchmark)'s 24 class contracts, [AHK-Repair](post.html?slug=ahk-repair-benchmark)'s 30 broken submissions, and the 13-task esoteric-features probe. Each task got one cold call and one submission, graded by the same parse-then-execute pipeline as the rest of the board.

All four pass every hidden case on AHK-Eval. **GPT-6.2 Astra** scores 102 of 103 across the four suites for $0.92. That ties [Gemini 4 Neon](post.html?slug=november-2026-gemini-4) for the best total on the board, at about a sixth of Neon's $6.00. The two Pro models score exactly what the base models score and miss the same items. Sol Pro costs 3.6 times as much as Sol, and Astra Pro 4.3 times as much as Astra. GPT-6.1 Sol Pro did the same in October.

<div class="bm-wrap"><table class="bm-heat"><thead><tr><th>board</th><th style="text-align:left">Model</th><th>AHK-Eval</th><th>hidden cases</th><th>AHK-Contract</th><th>AHK-Repair</th><th>Esoteric</th><th>total</th><th>cost</th></tr></thead><tbody><tr><td class="h-rank">1</td><td class="h-name">GPT-6 Astra <span class="h-dim">(September)</span></td><td class="h-emer"><strong>36/36</strong></td><td class="h-dim">181/181</td><td class="h-emer">24/24</td><td class="h-emer">28/30</td><td class="h-emer">13/13</td><td class="h-blue">101</td><td class="h-dim">—</td></tr><tr><td class="h-rank">3</td><td class="h-name">GPT-6.1 Sol <span class="h-dim">(October)</span></td><td class="h-emer"><strong>36/36</strong></td><td class="h-dim">181/181</td><td class="h-blue">23/24</td><td class="h-emer">29/30</td><td class="h-emer">13/13</td><td class="h-blue">101</td><td class="h-dim">$0.35</td></tr><tr><td class="h-rank">4</td><td class="h-name">GPT-6.1 Sol Pro <span class="h-dim">(October)</span></td><td class="h-emer"><strong>36/36</strong></td><td class="h-dim">181/181</td><td class="h-blue">23/24</td><td class="h-emer">29/30</td><td class="h-emer">13/13</td><td class="h-blue">101</td><td class="h-dim">$1.21</td></tr><tr><td class="h-rank">5</td><td class="h-name">GPT-6.2 Astra</td><td class="h-emer"><strong>36/36</strong></td><td class="h-dim">181/181</td><td class="h-emer">24/24</td><td class="h-emer">29/30</td><td class="h-emer">13/13</td><td class="h-emer"><strong>102</strong></td><td class="h-dim">$0.92</td></tr><tr><td class="h-rank">6</td><td class="h-name">GPT-6.2 Astra Pro</td><td class="h-emer"><strong>36/36</strong></td><td class="h-dim">181/181</td><td class="h-emer">24/24</td><td class="h-emer">29/30</td><td class="h-emer">13/13</td><td class="h-emer"><strong>102</strong></td><td class="h-dim">$3.93</td></tr><tr><td class="h-rank">7</td><td class="h-name">GPT-6.2 Sol</td><td class="h-emer"><strong>36/36</strong></td><td class="h-dim">181/181</td><td class="h-blue">23/24</td><td class="h-emer">28/30</td><td class="h-emer">13/13</td><td class="h-blue">100</td><td class="h-dim">$0.33</td></tr><tr><td class="h-rank">8</td><td class="h-name">GPT-6.2 Sol Pro</td><td class="h-emer"><strong>36/36</strong></td><td class="h-dim">181/181</td><td class="h-blue">23/24</td><td class="h-emer">28/30</td><td class="h-emer">13/13</td><td class="h-blue">100</td><td class="h-dim">$1.20</td></tr><tr><td class="h-rank">11</td><td class="h-name">Gemini 4 Neon <span class="h-dim">(November)</span></td><td class="h-emer"><strong>36/36</strong></td><td class="h-dim">181/181</td><td class="h-emer">24/24</td><td class="h-emer"><strong>30/30</strong></td><td class="h-blue">12/13</td><td class="h-emer"><strong>102</strong></td><td class="h-dim">$6.00</td></tr></tbody></table></div>

The board column is the model's place on the published [AHK-Eval leaderboard](leaderboard.html), now 65 entries. The board ranks on Eval alone. Eleven entries now have all 36 tasks and all 181 cases, so their order is alphabetical. That's why the GPT-6.2 models sit fifth to eighth and Gemini 4 Neon has moved from seventh to eleventh. At the top of the board, the four-suite total is the better comparison.

Cost is the four-suite total. GPT-6 Astra's is left out because its Eval run used OpenAI's half-price flex tier.

## Method Notes

- **Interpreter.** These entries are graded on the v2.1-alpha.38+Console fork, the same build as the Gemini 4 batch.
- **Token caps.** `max_tokens` was 16,000 for Eval, Repair and the esoteric probe, and 20,000 for Contract. No call came near the cap. The longest answer in the batch was 1,794 tokens.
- **Two routes.** Sol and Astra went to OpenAI's API directly, because the OpenRouter key had reached its spending limit when the batch started. Sol Pro and Astra Pro aren't served on that API key, so they went through OpenRouter after the limit was raised. Both routes used the same prompt and caps.
- **Temperature.** Every other entry runs at temperature 0.2. OpenAI's API rejects any value but the default for Sol and Astra, and OpenRouter lists no temperature setting for any of the four, so all four ran at default sampling.
- **Cost.** For Sol and Astra, cost is the token counts at OpenAI's list price, which is also OpenRouter's catalog price. For the Pro models it is what OpenRouter billed. That comes to about twice the list price of the tokens the API reported. GPT-6.1 Sol Pro also billed above its list price in October.

## The Pro Tier

Sol Pro misses the same three items as Sol, and Astra Pro misses the same one as Astra. The answers aren't copies. Only 35 of Sol Pro's 103 answers match Sol's character for character, and 44 of Astra Pro's match Astra's. The Pro models write longer answers, report more reasoning and take a little longer.

<div class="bm-wrap"><table class="bm-heat"><thead><tr><th style="text-align:left">Model</th><th>output $/M</th><th>Eval</th><th>Contract</th><th>Repair</th><th>Esoteric</th><th>median time</th><th>cost</th></tr></thead><tbody><tr><td class="h-name">GPT-6.2 Sol</td><td class="h-dim">$10.00</td><td class="h-emer">127</td><td class="h-emer">164</td><td class="h-emer">242</td><td class="h-emer">225</td><td class="h-dim">3.1 s</td><td class="h-dim">$0.33</td></tr><tr><td class="h-name">GPT-6.2 Sol Pro</td><td class="h-dim">$10.00</td><td class="h-amber">403</td><td class="h-amber">360</td><td class="h-amber">559</td><td class="h-amber">532</td><td class="h-dim">4.6 s</td><td class="h-dim">$1.20</td></tr><tr><td class="h-name">GPT-6.2 Astra</td><td class="h-dim">$40.00</td><td class="h-emer">106</td><td class="h-emer">140</td><td class="h-emer">146</td><td class="h-emer">139</td><td class="h-dim">2.9 s</td><td class="h-dim">$0.92</td></tr><tr><td class="h-name">GPT-6.2 Astra Pro</td><td class="h-dim">$40.00</td><td class="h-blue">246</td><td class="h-blue">314</td><td class="h-blue">362</td><td class="h-blue">316</td><td class="h-dim">5.2 s</td><td class="h-dim">$3.93</td></tr></tbody></table></div>

The suite columns are median completion tokens per call, reasoning included. On the items the base models miss, the Pro models make the same mistake.

## Three Misses

Three items account for every point the batch lost.

### The email extractor (all four)

This is the Repair item from [October's post](post.html?slug=october-2026-model-roster) that thirteen of sixteen models got wrong. The broken submission has two bugs. Its pattern escapes the dot twice, `\\.`, but AutoHotkey strings don't use backslash as an escape character, so the regex asks for a literal backslash and finds no emails at all. All four models fix the pattern, and all four keep the second bug:

```ahk
while foundPos := RegExMatch(s, needle, &m, pos) {
    emails.Push(m.Value)
    pos := foundPos + m.Len
}
```

On an AutoHotkey v2 match object, `m.Value` looks up a named subpattern called `Value`. The pattern has none, so the line throws a `ValueError` on the first match. Only the hidden case with no email in it passes, 1 of 5. The fix is `m[0]`. Seven of the 45 entries on AHK-Repair make it, including GPT-6 Astra in September. GPT-6.2 Astra doesn't.

### The group-by sort (Sol and Sol Pro)

The broken `AE_GroupByFirstLetter` puts the group letters in order with a bubble sort that compares them with `>`:

```ahk
if letters[j] > letters[j + 1] {
```

On the alpha.38 interpreter, `>` compares numbers only. Given two letters, it throws a `TypeError`: `Expected a Number but got a String`. Inputs whose words all start with the same letter never reach the comparison, which is why 2 of the 5 hidden cases pass. Sol and Sol Pro trim spaces and skip empty words, and leave the comparison alone. Astra and Astra Pro change it to `StrCompare(letters[j], letters[j + 1]) > 0`, which passes all five.

Eleven of the 45 Repair entries fix this item. GPT-6 Astra missed it and the other group-by-first-letter item. GPT-6.2 Astra fixes both.

### `isSet` in `AC_Proxy` (Sol and Sol Pro)

`AC_Proxy` routes `GetX()` and `SetX(v)` calls through `__Call`. Sol and Sol Pro both store the kind of call in a local variable named `isSet`:

```ahk
isSet := match[1] == "Set"
```

AutoHotkey names aren't case-sensitive, and `IsSet` is a built-in that the parser handles itself, so the name has to be followed by `(`. The line fails to load with `Missing "("`, and a file that doesn't load fails all eight cases. Astra and Astra Pro use other names. 26 of the 35 entries on AHK-Contract pass `AC_Proxy`.

## Against Earlier GPT Models

- **GPT-6.2 Astra vs. GPT-6 Astra.** 102 against 101. GPT-6.2 Astra fixes the two group-by items GPT-6 Astra missed, and misses the email extractor GPT-6 Astra fixed. The output price is down from $50 to $40 per million tokens.
- **GPT-6.2 Sol vs. GPT-6.1 Sol.** 100 against 101. GPT-6.2 Sol writes `AC_PixelBuffer`'s typed `Struct` with one field per line, which GPT-6.1 Sol got wrong, but it misses `AC_Proxy` and the group-by sort. It cost $0.33 against $0.35.

## What the Money Says

The batch cost $6.38: $1.25 for Sol and Astra on OpenAI's API, and $5.13 for the two Pro models on OpenRouter. GPT-6.2 Astra is the pick of the four: 102 of 103 for $0.92, the same total as Gemini 4 Neon for about a sixth of the price. Sol gets 100 for 33 cents. For the second release in a row, the Pro tier adds cost and no points.

*Disclosure: Claude Opus 5.5 ran this batch and wrote this post. Every number comes from the same pipeline that graded the rest of the board: parse validation against the v2.1-alpha.38+Console fork, headless execution, and hidden test cases the models never saw.*
