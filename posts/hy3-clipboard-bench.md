# Tencent Hy3: One Option String From a Window

Tencent's **Hy3** — a 295B-parameter MoE with 21B active (192 experts, top-8 routing) — joins the [clipboard-formatter benchmark](post.html?slug=llm-clipboard-benchmark) with **two entries**: the paid [`tencent/hy3`](model.html?id=Hy3) endpoint and the free [`tencent/hy3:free`](model.html?id=Hy3_Free) tier, both hit through OpenRouter on July 7 with the same strict one-shot prompt as the other 80 entries. Total API spend for both runs: **$0.0015**.

The result is the purest specimen of this board's thesis to date: both entries post a **code score of 87 — tied for the best static score Tencent has ever put up, and tied exactly with GLM-4.7 and GPT-OSS 120B** — and both crash before drawing a single pixel.

<div class="bm-wrap"><table class="bm-heat"><thead><tr><th>#</th><th style="text-align:left">Entry</th><th>endpoint</th><th>parse</th><th>runs</th><th>code</th><th>lines</th><th style="text-align:left">died on</th></tr></thead><tbody><tr><td class="h-rank">41</td><td class="h-name"><a href="model.html?id=Hy3">Hy3</a></td><td class="h-dim">tencent/hy3</td><td class="h-emer">✓</td><td class="h-red">✗</td><td class="h-blue">87</td><td class="h-dim">196</td><td class="h-dim" style="text-align:left">Invalid option.</td></tr><tr><td class="h-rank">42</td><td class="h-name"><a href="model.html?id=Hy3_Free">Hy3 (free)</a></td><td class="h-dim">tencent/hy3:free</td><td class="h-emer">✓</td><td class="h-red">✗</td><td class="h-blue">87</td><td class="h-dim">201</td><td class="h-dim" style="text-align:left">Invalid control type.</td></tr></tbody></table></div>

## The Family Ladder

Tencent's previous entry, [Hunyuan A13B](model.html?id=Hunyuan_A13B), sits at rank 70 with a code score of 46 — it never made it past the parser (`Unexpected "{"`). Hy3 clears the parse gate on both endpoints and gains **+41 static points**. That's a real generational jump, up the exact ladder this benchmark measures: the syntax is v2, the callbacks are `.Bind(this)`, the class-name-as-variable trap is dodged, and there's genuine `ControlWrapper → EditWrap / ButtonWrap` inheritance doing real work.

And for scale: the only other ~300B open entry on the board, ERNIE 4.5 300B, is still stuck at the parse gate (54, rank 58). Hy3's static profile is legitimately top-tier for its class.

Then it launches.

## Two Endpoints, Two One-Line Deaths

The paid entry dies in its `SetEnabled` helper — before `Show()` is ever reached:

```ahk
SetEnabled(state) {
    this.ctrl.Opt(state ? "+Enabled" : "-Enabled")   ; ==> Invalid option.
}
```

There is no `Enabled` option keyword in AHK v2 — the real toggle is `-Disabled`/`+Disabled` (or the `.Enabled` property). `Invalid option.` is one of the board's signature runtime killers: Qwen 3.6, Gemini 3 Pro, Grok 4 Fast, and Grok Code Fast 1 all died on the exact same class of invented option string. Hy3 makes five.

The free entry dies even earlier — on the **first control it tries to create** — by merging the control type and its options into one argument:

```ahk
this.ctrl := parent.Add(opts)   ; opts = "Edit x10 y10 w400 h200 vEdit"
                                ; ==> Invalid control type.
```

`Gui.Add` wants `Add("Edit", "x10 y10 ...")` — the fused string is the same death certificate GLM-4.7 and GPT-OSS 120B carry at their identical score of 87.

The paid run has one more twist. Before its real crash, it pops an error dialog *blaming the clipboard*:

```ahk
if (!IsString(txt)) {   ; IsString does not exist in AHK v2
```

The hallucinated call throws, a broad `catch` swallows it, and the script reports "Could not read clipboard" — while holding a perfectly good clipboard. The capture harness had to dismiss that dialog just to let the script reach its actual death two lines later. A hallucinated API producing a *misdirected* error message is nastier than a crash: it sends the user debugging the wrong thing.

## Against Its Open-Weight Performance Range

The 87-score crash band is crowded with big open models — but the more interesting comparison is the open MoE cohort that *runs*:

- **Qwen3-VL 235B-A22B** — code 75, **runs** (rank 25)
- **MiniMax 3** — code 75, **runs** (rank 24)
- **DeepSeek V4** — code 83, **runs** (rank 15)
- **Qwen 3.7** — code 92, **runs**, partial dark mode (rank 5)

Every one of them scores *lower or equal* on static checks than Hy3's 87 — and every one of them beats it where it counts, because on this board a window at 75 outranks a corpse at 95. Hermes 4 405B is the standing proof at the other end: 95 static, rank 32, never ran.

## Against Closed Models at the Same Price

Tencent doesn't publish closed-competitor parameter counts any more than OpenAI does, so price is the fairest proxy: Hy3 sells at **$0.20/M in, $0.80/M out** — squarely in the closed budget tier. That tier, on this board (OpenRouter list prices, July 2026):

<div class="bm-wrap"><table class="bm-heat"><thead><tr><th>#</th><th style="text-align:left">Model</th><th>price in/out per M</th><th>runs</th><th>code</th></tr></thead><tbody><tr><td class="h-rank">16</td><td class="h-name"><a href="model.html?id=Gemini_3-1_Flash_Lite">Gemini 3.1 Flash Lite</a></td><td class="h-dim">$0.25 / $1.50</td><td class="h-emer">✓</td><td class="h-blue">83</td></tr><tr><td class="h-rank">20</td><td class="h-name"><a href="model.html?id=GPT-5-4-nano">GPT-5.4 nano</a></td><td class="h-dim">$0.20 / $1.25</td><td class="h-emer">✓</td><td class="h-blue">77</td></tr><tr><td class="h-rank">41</td><td class="h-name"><a href="model.html?id=Hy3">Hy3</a></td><td class="h-dim">$0.20 / $0.80</td><td class="h-red">✗</td><td class="h-blue">87</td></tr></tbody></table></div>

Both closed models at Hy3's price point ship working windows with *worse-looking* code. Hy3 out-writes them on the static checklist and loses to them at the only gate a user feels. Its closest closed twin by failure profile — [Gemini 3.5 Flash](model.html?id=Gemini_3-5_Flash), code 86, parses clean, crashes on launch — costs 7–11× more ($1.50/$9.00), which at least proves the profile isn't a budget-tier exclusive.

## Stability Footnote

The free endpoint's *first* generation (discarded after an upstream retry) burned 26,046 completion tokens and emitted v1-style `catch e {` syntax — a parse failure. The kept run used 1,398 tokens and parsed clean. Same model, same prompt, two generations, two different dialects. One-shot variance at this scale is itself a benchmark finding: Hy3's floor and ceiling are far apart.

## Verdict

Hy3 is the strongest Tencent showing on this board by a wide margin, and both entries are — literally — **one corrected line away from running**. Swap `"+Enabled"` for `"-Disabled"` in the paid entry, or split `Add(opts)` into `Add(type, opts)` in the free one, and each opens its window. The model has learned nearly everything about AHK v2 except the part that only running the code teaches. That's exactly the gap agent-style validation loops exist to close — and exactly what a one-shot benchmark is designed to expose.

*Disclosure: Claude Fable 5 generated these entries via the OpenRouter API and wrote this post. Every number comes from the same pipeline that graded all 82 entries — parse validation against the v2.1-alpha.30+Console fork, live launch with stderr capture (including one dismissed error dialog), and the static rule checker. The per-model pages linked above show full source and itemized scorecards.*
