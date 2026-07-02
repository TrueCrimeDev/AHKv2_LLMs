# Claude Fable 5: Five Entries, Five Windows

Anthropic's **Claude Fable 5** just joined the [clipboard-formatter benchmark](post.html?slug=llm-clipboard-benchmark) — and it's the first model to be tested the way I actually use models: not once, but **five times under five different harness configurations**, from a bare session with no tooling at all to a full knowledge-tree setup. Same strict prompt as the other 72 entries, same two-signal grading against the v2.1-alpha.30+Console fork: does it *parse*, and does it *run*.

Every other multi-entry model on the board is there twice. Fable 5 fielded five — and didn't drop one.

<div class="bm-wrap"><table class="bm-heat"><thead><tr><th>#</th><th style="text-align:left">Entry</th><th>config</th><th>runs</th><th>code</th><th>visual</th><th>lines</th></tr></thead><tbody><tr><td class="h-rank">1</td><td class="h-name"><a href="model.html?id=Claude_Fable_5_Full_Harness">Fable 5 (Full Harness)</a></td><td class="h-dim">full live harness</td><td class="h-emer">✓</td><td class="h-emer">98</td><td class="h-emer">20/20</td><td class="h-dim">175</td></tr><tr><td class="h-rank">8</td><td class="h-name"><a href="model.html?id=Claude_Fable_5_Spotlight">Fable 5 (Spotlight)</a></td><td class="h-dim">feature showcase</td><td class="h-emer">✓</td><td class="h-emer">89</td><td class="h-emer">20/20</td><td class="h-dim">533</td></tr><tr><td class="h-rank">12</td><td class="h-name"><a href="model.html?id=Claude_Fable_5_AHK_OOP">Fable 5 (AHK OOP)</a></td><td class="h-dim">OOP knowledge tree</td><td class="h-emer">✓</td><td class="h-emer">86</td><td class="h-emer">20/20</td><td class="h-dim">76</td></tr><tr><td class="h-rank">13</td><td class="h-name"><a href="model.html?id=Claude_Fable_5">Fable 5</a></td><td class="h-dim">default</td><td class="h-emer">✓</td><td class="h-blue">85</td><td class="h-dim">4/20</td><td class="h-dim">78</td></tr><tr><td class="h-rank">14</td><td class="h-name"><a href="model.html?id=Claude_Fable_5_Skills">Fable 5 (Skills)</a></td><td class="h-dim">skills harness</td><td class="h-emer">✓</td><td class="h-blue">85</td><td class="h-dim">4/20</td><td class="h-dim">78</td></tr><tr><td class="h-rank">17</td><td class="h-name"><a href="model.html?id=Claude_Fable_5_NoSkills">Fable 5 (No Skills)</a></td><td class="h-dim">bare, no tooling</td><td class="h-emer">✓</td><td class="h-blue">80</td><td class="h-dim">4/20</td><td class="h-dim">40</td></tr></tbody></table></div>

## Update (July 1): A Sixth Run Takes Rank 1

A sixth config joined the sweep: **[Full Harness](model.html?id=Claude_Fable_5_Full_Harness)** — the live, day-to-day working setup, with auto-loading syntax rules, skills, and one thing no June run had: *this post in its context*. Same prompt, same one-shot rules, same pipeline.

It's the first entry on the 78-model board to clear all three signals at once: **98 code** (the board high — GPT-5.5 Pro held 95), a running window, and a 20/20 fully dark visual. Rank 1 overall.

The interesting part isn't the score — it's *which* points moved. The two spec items every June config missed ("What It Didn't Do", below) are exactly what the July run shipped: a real two-stack undo/redo with `.Opt()` gating, and `ControlWrapper` inheritance where both derived overrides do work the base can't — `EditWrap.Value` normalizes clipboard line endings so the char count is honest, `ButtonWrap.Value` remaps to the button label. The config delta this time wasn't tooling. It was feedback: a harness that remembers what its last review said.

The June entries each slid down one rank to make room; the table above shows current board positions.

## Why the Sweep Is the Story

On this board, **35% of submissions don't compile** and another quarter parse cleanly and then crash on launch — the benchmark's whole thesis is that runtime mortality hides behind green parse checks. Against that baseline, Fable 5 went **five-for-five at both gates**. No hallucinated API, no class-as-variable trap, no invalid GUI option — across five independent generations, including one with no harness support whatsoever.

That last one is the sharpest data point. The [No Skills](model.html?id=Claude_Fable_5_NoSkills) entry is a **40-line program** written with zero project context — the smallest of the five and the leanest runner on the entire board — and it still parses, opens a window, transforms the clipboard, and closes on Escape. The model's floor, not its ceiling, clears a bar that 44 of 74 entries missed.

The sweep is what lifted the Anthropic family run rate to **nine of ten** — the best of any family with a real spread of entries.

## The Dark-Mode Pair

The two knowledge-tree configs didn't just run — they shipped **fully dark windows, 20/20 on the pixel-level visual check** (dark client area *and* dark title bar). Before Fable 5, exactly two entries on the 77-model board had managed that: the pair of GPT-5.5 Pro runs.

<img src="posts/img/shots/Claude_Fable_5_Spotlight.png" alt="Fable 5 (Spotlight) — fully dark clipboard editor" style="max-width:100%;border:1px solid #303030;border-radius:8px">

The Spotlight entry does it the right way — a `Theme` class as the single source of truth, and the Win32 calls most models hallucinate done correctly:

```ahk
this.gui.BackColor := Theme.WinBg
DllCall("dwmapi\DwmSetWindowAttribute", "ptr", this.gui.Hwnd, "int", 20, "int*", true, "int", 4)   ; dark title bar
DllCall("dwmapi\DwmSetWindowAttribute", "ptr", this.gui.Hwnd, "int", 33, "int*", 2, "int", 4)      ; Mica backdrop
```

Attribute `20` is `DWMWA_USE_IMMERSIVE_DARK_MODE` — the exact call, with the exact types. Compare that with the board's most common cause of death: a confidently invented method like `Gui.Edit.SetSel()` or `IsMap()`.

## The Code Reads Like AHK v2

The default entry's core is transforms-as-data — a `Map` of function references driving both the buttons and the dispatch, with every callback properly bound:

```ahk
this.transforms := Map(
    "UPPERCASE", StrUpper,
    "lowercase", StrLower,
    "Title Case", StrTitle
)

OnTransform(label, *) {
    fn := this.transforms[label]
    this.Text := fn(this.Text)
    this.status.SetText(Format("Applied {} to {} characters", label, this.CharCount))
}
```

`Text` there is a real property (`get`/`set` over the Edit control), `CharCount` a computed one. No object literals for storage, no JS idioms, no empty catches — the static checker's rule-adherence items come back clean on all five entries.

## What It Didn't Do

The honest column. Two spec items went unclaimed in **every June** config (the July Full Harness run later shipped both — see the update above):

- **No undo/redo stack.** The prompt asks for multi-step undo on `Ctrl+Z`/`Ctrl+Y`; none of the five implements it. It's the single most expensive consistent miss.
- **Little inheritance.** The spec's `ControlWrapper` base-class-plus-subclasses architecture mostly didn't appear (four entries have zero `extends`, Spotlight has one).

That's why the code scores cap at 89 while GPT-5.5 Pro holds 95: Fable 5 consistently chose a smaller program that runs over a bigger one that covers the checklist. On a benchmark whose central finding is that high-scoring code frequently *doesn't run* — Hermes 4 405B scores 95 and ranks 31st — that trade has a strong claim to being the right one. But a sweep of the spec it is not.

## Verdict

Fable 5's profile on this board is **reliability first**: the only five-entry sweep of both gates, two of the four full-dark windows in existence, and idiomatic v2 from a 40-line bare-session floor to a 533-line showcase. If you need one-shot AHK v2 that *opens a window every time*, this is currently the strongest signal the board has produced.

*Disclosure: Claude Fable 5 helped write this post. Every number in it comes from the same automated pipeline that graded all 77 entries — parse validation, live launch + window capture, and the pixel-level visual check — and the per-model pages linked above show the full source and itemized scorecards.*
