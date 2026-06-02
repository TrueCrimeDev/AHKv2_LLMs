# One Prompt, 60 Models: An AHK v2 Clipboard-Formatter Benchmark

I have a folder of AutoHotkey v2 scripts named after the model that wrote each one — `GPT-5-5-Pro.ahk`, `Gemini_3_Pro.ahk`, `Hermes_4_405B.ahk`, and five dozen more. Every file is the same model answering the **same prompt**. This post grades all of them on three escalating signals — does it *parse*, does it *run*, does it *look right* — then digs into *why* the flagships diverge. **Every model name links to its own page** with full source, itemized scorecards, the captured window, and analysis.

<style>
.bm-wrap{margin:22px 0;}
.bm-h{font-size:11px;letter-spacing:1.4px;text-transform:uppercase;color:#707070;font-weight:600;margin:0 0 10px;}
.bm-funnel{display:flex;flex-direction:column;gap:7px;}
.bm-frow{display:flex;align-items:center;gap:12px;}
.bm-fbar{height:38px;border-radius:7px;display:flex;align-items:center;padding:0 14px;color:#fff;font-weight:600;font-size:14px;white-space:nowrap;box-shadow:inset 0 0 0 1px rgba(255,255,255,.08);}
.bm-fmeta{font-size:12.5px;color:#9a9a9a;}
.bm-fmeta b{color:#d6d6d6;font-weight:600;}
.bm-bars{display:flex;flex-direction:column;gap:9px;}
.bm-brow{display:grid;grid-template-columns:172px 1fr 34px;align-items:center;gap:12px;font-size:13px;}
.bm-blabel{color:#c4c4c4;text-align:right;}
.bm-btrack{background:#1c1c1c;border-radius:5px;height:20px;overflow:hidden;border:1px solid #262626;}
.bm-bfill{height:100%;border-radius:5px;}
.bm-bval{color:#fff;font-variant-numeric:tabular-nums;font-weight:600;}
.bm-cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(168px,1fr));gap:12px;}
.bm-card{background:#121212;border:1px solid #2c2c2c;border-radius:12px;padding:14px 15px;border-top:3px solid #444;}
.bm-card h4{margin:0 0 2px;font-size:15px;color:#fff;}
.bm-card .prov{font-size:11px;color:#6f6f6f;margin-bottom:10px;}
.bm-stat{display:flex;justify-content:space-between;font-size:12.5px;padding:3px 0;border-bottom:1px solid #1d1d1d;}
.bm-stat:last-of-type{border-bottom:none;}
.bm-stat .k{color:#9a9a9a;}.bm-stat .v{color:#fff;font-weight:600;}
.bm-verdict{margin-top:9px;font-size:12px;line-height:1.5;color:#b6b6b6;border-top:1px solid #2c2c2c;padding-top:8px;}
.bm-flow{display:flex;flex-wrap:wrap;gap:0;align-items:stretch;margin:6px 0;}
.bm-fb{flex:1;min-width:120px;background:#161616;border:1px solid #2c2c2c;border-radius:9px;padding:11px 13px;font-size:12.5px;color:#d2d2d2;}
.bm-fb b{color:#fff;display:block;font-size:13.5px;margin-bottom:2px;}
.bm-arrow{display:flex;align-items:center;color:#5a5a5a;font-size:20px;padding:0 8px;}
.bm-split{display:grid;grid-template-columns:1fr 1fr;gap:14px;}
@media(max-width:680px){.bm-split{grid-template-columns:1fr;}}
.bm-good{border-left:3px solid #7BC96F;}.bm-bad{border-left:3px solid #DC3545;}
.bm-tag{display:inline-block;font-size:10.5px;font-weight:600;padding:2px 7px;border-radius:5px;margin-left:6px;vertical-align:middle;}
.bm-tag.run{background:rgba(123,201,111,.14);color:#7BC96F;}
.bm-tag.crash{background:rgba(220,53,69,.14);color:#e0727d;}
</style>

The headline up front:

<div class="bm-wrap"><div class="bm-h">Every filter discards roughly a third of the field</div><div class="bm-funnel"><div class="bm-frow"><div class="bm-fbar" style="width:100%;background:linear-gradient(90deg,#3a3a3a,#2a2a2a)">61 submitted code</div></div><div class="bm-frow"><div class="bm-fbar" style="width:64%;background:linear-gradient(90deg,#5B9FEF,#3f6ea8)">39 parse</div><div class="bm-fmeta"><b>64%</b> · 22 are syntactically broken</div></div><div class="bm-frow"><div class="bm-fbar" style="width:39%;background:linear-gradient(90deg,#22D3EE,#1a93a6)">24 run</div><div class="bm-fmeta"><b>39%</b> · 15 crash on launch</div></div><div class="bm-frow"><div class="bm-fbar" style="width:13%;background:linear-gradient(90deg,#A855F7,#7a3fb0)">5 render dark</div><div class="bm-fmeta"><b>8%</b> · 19 ignore the theme</div></div><div class="bm-frow"><div class="bm-fbar" style="width:6%;background:linear-gradient(90deg,#7BC96F,#56935f)">2 fully dark</div><div class="bm-fmeta"><b>3%</b> · title bar included</div></div></div></div>

A green parse check is the floor, not the ceiling. The drop from "parses" to "runs" to "looks like what we asked for" is where the models actually separate — and where the flagships behave very differently from one another.

## The Prompt

Every model received one strict spec: build a **dark-mode clipboard text-formatter** as a single dependency-free AHK v2 GUI. The prompt is a full agent harness with a `P0_CRITICAL` rule block and an eight-item `DIAGNOSTIC_CHECKLIST`. The build target is specific and gradeable: load the clipboard on startup; three transforms (`StrUpper`/`StrLower`/`StrTitle`); multi-step undo + redo on `Ctrl+Z`/`Ctrl+Y`; a live char/line counter; a resizable, **dark-themed**, `Escape`-to-close window; and a `ControlWrapper` base class with two overriding subclasses.

## How Scoring Works

Three signals of increasing strictness, all against the **v2.1-alpha.30+Console** fork.

**1. Parse (`/validate`)** — a parse-only load. Objective, but weak: it never runs a line. **2. Runs (launch + capture)** — each parsing script is launched, its window captured via `PrintWindow`, then killed. Builds a window → ✅, throws first → ❌. **3. Visual (pixel analysis)** — the captured window scored 0–20 from its actual pixels: dark background, dark title bar, consistency, proportions, content. Plus a **code score (0–100)** from the `DIAGNOSTIC_CHECKLIST`. The board sorts by **Runs, then code score** — a crash ranks below every program that opens.

## The Leaderboard

The top of the field — all ✅, all open a window. Click a model for its page.

| #  | Model                  | runs | code | visual |
|----|------------------------|:----:|:----:|:------:|
| 1  | [GPT-5.5 Pro](model.html?id=GPT-5-5-Pro) | ✅ | 95 | 20/20 |
| 2  | [GPT-5.5 Pro (Extra)](model.html?id=GPT-5-5-Pro_Extra) | ✅ | 95 | 20/20 |
| 3  | [GPT-5.2 Pro (v2)](model.html?id=GPT-5-2-Pro2) | ✅ | 92 | 4/20 |
| 4  | [Qwen 3.7](model.html?id=Qwen_3-7) | ✅ | 92 | 15/20 |
| 5  | [Alpha Owl](model.html?id=Alpha_Owl) | ✅ | 90 | 4/20 |
| 6  | [WizardLM 2 8x22B 🆕](model.html?id=WizardLM_2_8x22B) | ✅ | 90 | 4/20 |
| 7  | [Opus 4.7 (Fast)](model.html?id=Opus_4-7_Fast) | ✅ | 88 | 15/20 |
| 8  | [Opus 4.8 (Fast)](model.html?id=Opus_4-8_Fast) | ✅ | 88 | 15/20 |
| 9  | [DeepSeek V4](model.html?id=DeepSeek_V4) | ✅ | 83 | 4/20 |
| 10 | [Gemini 3.1 Flash Lite](model.html?id=Gemini_3-1_Flash_Lite) | ✅ | 83 | 4/20 |
| 11 | [Sonnet 4.6](model.html?id=Sonnet_4-6) | ✅ | 80 | 4/20 |
| 12 | [Grok 4.2](model.html?id=Grok_4-2_Test) | ✅ | 78 | 4/20 |
| 13 | [GPT-5.4 nano](model.html?id=GPT-5-4-nano) | ✅ | 77 | 4/20 |

<img src="posts/img/gpt55pro-gui.png" alt="GPT-5.5 Pro clipboard formatter, fully dark theme" style="max-width:100%;border:1px solid #303030;border-radius:8px">

## Who Beats Whom — by Family

The single most useful cut isn't model-by-model, it's **family-by-family**. Run rate (of the family's parsing entries) tells you who reliably ships a *working* program; best visual tells you who can actually paint the theme.

<div class="bm-wrap"><div class="bm-h">Run rate by family (parsing entries that build a window)</div><div class="bm-bars"><div class="bm-brow"><div class="bm-blabel">Anthropic · Opus/Sonnet</div><div class="bm-btrack"><div class="bm-bfill" style="width:80%;background:#7BC96F"></div></div><div class="bm-bval">4/5</div></div><div class="bm-brow"><div class="bm-blabel">MiniMax</div><div class="bm-btrack"><div class="bm-bfill" style="width:75%;background:#7BC96F"></div></div><div class="bm-bval">3/4</div></div><div class="bm-brow"><div class="bm-blabel">OpenAI · GPT-5.x</div><div class="bm-btrack"><div class="bm-bfill" style="width:71%;background:#7BC96F"></div></div><div class="bm-bval">5/7</div></div><div class="bm-brow"><div class="bm-blabel">Alibaba · Qwen</div><div class="bm-btrack"><div class="bm-bfill" style="width:50%;background:#F59E42"></div></div><div class="bm-bval">2/4</div></div><div class="bm-brow"><div class="bm-blabel">xAI · Grok</div><div class="bm-btrack"><div class="bm-bfill" style="width:40%;background:#F59E42"></div></div><div class="bm-bval">2/5</div></div><div class="bm-brow"><div class="bm-blabel">Google · Gemini</div><div class="bm-btrack"><div class="bm-bfill" style="width:25%;background:#DC3545"></div></div><div class="bm-bval">1/4</div></div><div class="bm-brow"><div class="bm-blabel">One-shot via API</div><div class="bm-btrack"><div class="bm-bfill" style="width:5%;background:#DC3545"></div></div><div class="bm-bval">1/22</div></div></div></div>

Three distinct personalities fall out of the data:

**OpenAI (GPT-5.x) — the only family that finishes the job.** Five of seven run, and it is the *sole* family to render a fully dark window, title bar included. The reason is one DllCall its rivals omit:

```ahk
; GPT-5.5 Pro — actually darkens the Windows title bar
DllCall("dwmapi\DwmSetWindowAttribute", "ptr", this.gui.Hwnd,
        "int", 20, "int*", enabled, "int", 4, "int")   ; DWMWA_USE_IMMERSIVE_DARK_MODE
```

**Anthropic (Opus / Sonnet) — the reliable runner that stops one call short.** Best run rate in the field (4/5), but every Anthropic entry caps at 15/20 visual. They paint the *client* dark and forget the *frame*:

```ahk
; Opus 4.7 Fast — dark client, but no DWM title-bar call
this.gui.BackColor := 0x1E1E1E
this.gui.Add("Edit", "... Background252526", "")
; …no DwmSetWindowAttribute(hwnd, 20, ...) anywhere → light title bar
```

That one missing line is the entire difference between 20/20 and 15/20 — and it's the same line across all three Anthropic runners.

**Google (Gemini) — writes the prettiest code that doesn't run.** Gemini's *code* scores well (up to 86), but 3 of 4 crash at launch, each on a confidently hallucinated API:

<div class="bm-split"><div class="bm-fb bm-bad"><b>Gemini 2.5 Pro <span class="bm-tag crash">crash</span></b><code>this.hEdit.SetSel(StrLen(...))</code> — <code>Gui.Edit</code> has no <code>SetSel</code> method. So does GPT-5 Codex, independently.</div><div class="bm-fb bm-bad"><b>Grok 4 Fast <span class="bm-tag crash">crash</span></b><code>Add("Edit", "... Multi ReadOnly? No")</code> — "ReadOnly? No" isn't an option token. <em>Invalid option.</em></div></div>

These parse perfectly — they are syntactically valid calls to things that don't exist — so only *running* the program exposes them.

## The Flagship Tale of the Tape

Five headline models, same prompt, wildly different outcomes:

<div class="bm-wrap"><div class="bm-cards"><div class="bm-card" style="border-top-color:#7BC96F"><h4>GPT-5.5 Pro</h4><div class="prov">OpenAI</div><div class="bm-stat"><span class="k">Runs</span><span class="v" style="color:#7BC96F">✅</span></div><div class="bm-stat"><span class="k">Visual</span><span class="v">20/20</span></div><div class="bm-stat"><span class="k">Code</span><span class="v">95</span></div><div class="bm-verdict">The only complete-and-dark winner. Transform registry, real DWM theming. Ships undo with no redo — its one miss.</div></div><div class="bm-card" style="border-top-color:#5B9FEF"><h4>Opus 4.8 Fast</h4><div class="prov">Anthropic</div><div class="bm-stat"><span class="k">Runs</span><span class="v" style="color:#7BC96F">✅</span></div><div class="bm-stat"><span class="k">Visual</span><span class="v">15/20</span></div><div class="bm-stat"><span class="k">Code</span><span class="v">88</span></div><div class="bm-verdict">Rock-solid runner, clean wrapper classes. Dark client, light title bar — one DWM call from perfect.</div></div><div class="bm-card" style="border-top-color:#5B9FEF"><h4>Qwen 3.7</h4><div class="prov">Alibaba</div><div class="bm-stat"><span class="k">Runs</span><span class="v" style="color:#7BC96F">✅</span></div><div class="bm-stat"><span class="k">Visual</span><span class="v">15/20</span></div><div class="bm-stat"><span class="k">Code</span><span class="v">92</span></div><div class="bm-verdict">Best open-ish runner: full undo+redo, all three transforms. Same light-title-bar gap as Anthropic.</div></div><div class="bm-card" style="border-top-color:#DC3545"><h4>Gemini 3 Pro</h4><div class="prov">Google</div><div class="bm-stat"><span class="k">Runs</span><span class="v" style="color:#e0727d">❌</span></div><div class="bm-stat"><span class="k">Visual</span><span class="v">—</span></div><div class="bm-stat"><span class="k">Code</span><span class="v">75</span></div><div class="bm-verdict">Reads well, dies on launch (Invalid option). High code score, zero working window.</div></div><div class="bm-card" style="border-top-color:#DC3545"><h4>Hermes 4 405B</h4><div class="prov">Nous · open weights</div><div class="bm-stat"><span class="k">Runs</span><span class="v" style="color:#e0727d">❌</span></div><div class="bm-stat"><span class="k">Visual</span><span class="v">—</span></div><div class="bm-stat"><span class="k">Code</span><span class="v">95</span></div><div class="bm-verdict">Tied for highest code score in the folder. Calls <code>IsMap()</code>, which doesn't exist. Never opens.</div></div></div></div>

## Does It Actually Run?

Parse passed **39** of 61. Fifteen die before drawing a pixel — runtime mortality hidden behind a green check. The causes are remarkably few:

<div class="bm-wrap"><div class="bm-h">Runtime crash causes (15 parsing scripts that then threw)</div><div class="bm-bars"><div class="bm-brow"><div class="bm-blabel">Hallucinated API</div><div class="bm-btrack"><div class="bm-bfill" style="width:100%;background:#DC3545"></div></div><div class="bm-bval">6</div></div><div class="bm-brow"><div class="bm-blabel">Invalid GUI option</div><div class="bm-btrack"><div class="bm-bfill" style="width:67%;background:#F59E42"></div></div><div class="bm-bval">4</div></div><div class="bm-brow"><div class="bm-blabel">Wrong arg count</div><div class="bm-btrack"><div class="bm-bfill" style="width:33%;background:#F59E42"></div></div><div class="bm-bval">2</div></div><div class="bm-brow"><div class="bm-blabel">Hallucinated method</div><div class="bm-btrack"><div class="bm-bfill" style="width:33%;background:#F59E42"></div></div><div class="bm-bval">2</div></div><div class="bm-brow"><div class="bm-blabel">Void return as value</div><div class="bm-btrack"><div class="bm-bfill" style="width:17%;background:#A855F7"></div></div><div class="bm-bval">1</div></div></div></div>

Eight of the fifteen — the hallucinated APIs and methods — are the same class of error: a perfectly-formed call to a function or method that AHK v2 does not define. `IsMap()` should be `value is Map`; `Gui.Edit` has no `SetSel`. A parser cannot catch these; only execution can.

<img src="posts/img/clipboard-gallery.png" alt="Contact sheet of the 24 LLM clipboard formatters that build a working window" style="max-width:100%;border:1px solid #303030;border-radius:8px">

## The Dark-Mode Gap, Explained

Of the 24 running programs, only 5 render meaningfully dark and only 2 are fully dark. But here's the catch: **most of the light ones contain dark-mode code.** Dark mode in AHK v2 is two independent jobs, and models routinely do one and skip the other:

<div class="bm-wrap"><div class="bm-flow"><div class="bm-fb"><b>Client area</b>set <code>gui.BackColor</code> + each control's <code>Background</code> option</div><div class="bm-arrow">+</div><div class="bm-fb"><b>Title bar</b><code>DwmSetWindowAttribute(hwnd, 20, true)</code></div><div class="bm-arrow">=</div><div class="bm-fb bm-good"><b>Fully dark</b>20/20 — only GPT-5.5 Pro &amp; Extra do both</div></div></div>

Skip the second job and you get a dark editor stapled to a stock white Windows title bar — the **15/20 tier**: Qwen 3.7, Opus 4.7 Fast, Opus 4.8 Fast. Skip both and you get a white app that nonetheless earns "dark-mode-code-present" points on the rubric — the **≤4/20 tier**, 19 of the 24. This is the cleanest demonstration in the whole benchmark that *containing* a feature and *delivering* it are different claims, and only pixels tell them apart.

## Clean Code That Doesn't Run

The runtime gate's sharpest lesson: *readability is not correctness.*

<div class="bm-wrap"><div class="bm-flow"><div class="bm-fb"><b>Hermes 4 405B</b>code score <b style="color:#fff">95</b> — tied best</div><div class="bm-arrow">→</div><div class="bm-fb bm-bad"><b style="color:#e0727d">❌ crashes</b>calls <code>IsMap()</code> — no such function → rank 25</div></div><div class="bm-flow" style="margin-top:8px"><div class="bm-fb"><b>GPT-5.5 Pro</b>code score <b style="color:#fff">95</b> — tied best</div><div class="bm-arrow">→</div><div class="bm-fb bm-good"><b style="color:#7BC96F">✅ runs &amp; renders dark</b>every symbol exists → rank 1</div></div></div></div>

Two identical code scores; opposite outcomes. Here is Hermes' base class — the most elegant `ControlWrapper` in the folder — and the one word that kills it:

```ahk
class ControlWrapper {
   Options := Map()
   __New(options := "") {
      this.Options := IsMap(options) ? options : Map()   ; IsMap() is not an AHK v2 function
   }
}
```

The fix is `options is Map`. It reads as expert AHK and throws `UnsetError` the instant `__New` runs. Contrast the winner, which treats transforms as data and uses only symbols that exist:

```ahk
this.transforms.Add("Upper", TextTransform("Upper", StrUpper))
this.transforms.Add("Lower", TextTransform("Lower", StrLower))
```

## The Class-as-Variable Trap

Before runtime, 22 outputs never parsed. The most common single error is the one the prompt explicitly warned about. AHK identifiers are **case-insensitive**, so `main` and `Main` are the same name:

```ahk
main := Main()        ; throws: Class cannot be used as an output variable
class Main {
}
```

[Phi-4](model.html?id=Phi-4) and [ERNIE 4.5](model.html?id=ERNIE_4-5_300B) both wrote exactly `main := Main()`. [GLM-4.6](model.html?id=GLM_4-6) reproduced the prompt's *verbatim invalid example*. The passers just renamed the variable — `editor := ClipboardEditor()`. The fix is one word; the warning wasn't enough to plant the reflex.

## The One-Shot Penalty

To stress-test with fresh models, I ran two live OpenRouter sweeps — 24 models, a dozen providers, one user message at `temperature 0.2`. The result is its own finding:

<div class="bm-wrap"><div class="bm-flow"><div class="bm-fb"><b>22</b>returned code</div><div class="bm-arrow">→</div><div class="bm-fb" style="border-left:3px solid #5B9FEF"><b>6</b>parsed</div><div class="bm-arrow">→</div><div class="bm-fb bm-good"><b>1</b>actually ran — WizardLM 2 8x22B</div></div></div>

Hermes 4 (405B *and* 70B), Mistral Large 3, Llama 3.3 70B, Nemotron 3 Super, Opus 4.8 — all generated live, all broken. The folder's *runnable* entries are the pre-existing ones, pasted from richer chat sessions. The lesson isn't "these models are bad"; it's that **single-turn, low-temperature API generation of niche-syntax code is brittle** — context and iteration, not just model choice, decide whether it runs. (Both of Mistral's *coding-specialized* models, Codestral and Devstral, didn't even parse, while general models did better.)

## Complete Standings

All 61 outputs that emitted code, ranked by **Runs, then code score.** ✅ builds a window · ❌ parses but crashes · `—` never parsed. 🆕 = live OpenRouter sweep. Every name links to its page.

| # | Model | runs | parse | code | visual |
|---|-------|:----:|:-----:|:----:|:------:|
| 1 | [GPT-5.5 Pro](model.html?id=GPT-5-5-Pro) | ✅ | PASS | 95 | 20 |
| 2 | [GPT-5.5 Pro (Extra)](model.html?id=GPT-5-5-Pro_Extra) | ✅ | PASS | 95 | 20 |
| 3 | [GPT-5.2 Pro (v2)](model.html?id=GPT-5-2-Pro2) | ✅ | PASS | 92 | 4 |
| 4 | [Qwen 3.7](model.html?id=Qwen_3-7) | ✅ | PASS | 92 | 15 |
| 5 | [Alpha Owl](model.html?id=Alpha_Owl) | ✅ | PASS | 90 | 4 |
| 6 | [WizardLM 2 8x22B 🆕](model.html?id=WizardLM_2_8x22B) | ✅ | PASS | 90 | 4 |
| 7 | [Opus 4.7 (Fast)](model.html?id=Opus_4-7_Fast) | ✅ | PASS | 88 | 15 |
| 8 | [Opus 4.8 (Fast)](model.html?id=Opus_4-8_Fast) | ✅ | PASS | 88 | 15 |
| 9 | [DeepSeek V4](model.html?id=DeepSeek_V4) | ✅ | PASS | 83 | 4 |
| 10 | [Gemini 3.1 Flash Lite](model.html?id=Gemini_3-1_Flash_Lite) | ✅ | PASS | 83 | 4 |
| 11 | [Sonnet 4.6](model.html?id=Sonnet_4-6) | ✅ | PASS | 80 | 4 |
| 12 | [Grok 4.2](model.html?id=Grok_4-2_Test) | ✅ | PASS | 78 | 4 |
| 13 | [GPT-5.4 nano](model.html?id=GPT-5-4-nano) | ✅ | PASS | 77 | 4 |
| 14 | [KAT-Coder](model.html?id=KAT_Coder) | ✅ | PASS | 76 | 4 |
| 15 | [KAT-Coder Pro v2](model.html?id=KAT-Coder-Pro-v2) | ✅ | PASS | 76 | 4 |
| 16 | [MiMo V2 Pro](model.html?id=MiMo-V2-Pro) | ✅ | PASS | 76 | 4 |
| 17 | [MiniMax 3](model.html?id=MiniMax3) | ✅ | PASS | 75 | 4 |
| 18 | [Qwen3-VL 235B-A22B](model.html?id=Qwen3_VL_235%20B_A22B_Instruct) | ✅ | PASS | 75 | 4 |
| 19 | [GPT-5.2 Pro](model.html?id=GPT-5-2-Pro) | ✅ | PASS | 74 | 4 |
| 20 | [Opus 4.6 (Fast)](model.html?id=Opus-4-6_Fast) | ✅ | PASS | 74 | 4 |
| 21 | [MiniMax 2.7](model.html?id=MiniMax2-7) | ✅ | PASS | 72 | 2 |
| 22 | [Spectre](model.html?id=Spectre) | ✅ | PASS | 71 | 4 |
| 23 | [Grok Code Fast 2](model.html?id=Grok_Code_Fast_2) | ✅ | PASS | 70 | 4 |
| 24 | [MiniMax 2.7a](model.html?id=MiniMax2-7a) | ✅ | PASS | 70 | 4 |
| 25 | [Hermes 4 405B 🆕](model.html?id=Hermes_4_405B) | ❌ | PASS | 95 | — |
| 26 | [Hermes 4 70B 🆕](model.html?id=Hermes_4_70B) | ❌ | PASS | 95 | — |
| 27 | [Opus 4.8](model.html?id=Opus_4-8) | ❌ | PASS | 92 | — |
| 28 | [Llama 3.3 70B 🆕](model.html?id=Llama_3-3_70B) | ❌ | PASS | 90 | — |
| 29 | [Mistral Large 3 🆕](model.html?id=Mistral_Large_3) | ❌ | PASS | 90 | — |
| 30 | [Nemotron 3 Super 120B 🆕](model.html?id=Nemotron_3_Super_120B) | ❌ | PASS | 90 | — |
| 31 | [Gemini 3.5 Flash](model.html?id=Gemini_3-5_Flash) | ❌ | PASS | 86 | — |
| 32 | [Qwen 3.6](model.html?id=Qwen_3-6) | ❌ | PASS | 79 | — |
| 33 | [GPT-5 Codex](model.html?id=GPT-5_Codex) | ❌ | PASS | 77 | — |
| 34 | [Gemini 2.5 Pro](model.html?id=Gemini_2-5_Pro) | ❌ | PASS | 77 | — |
| 35 | [Gemini 3 Pro](model.html?id=Gemini_3_Pro) | ❌ | PASS | 75 | — |
| 36 | [Grok 4 Fast](model.html?id=Grok_4_Fast) | ❌ | PASS | 75 | — |
| 37 | [Grok Code Fast 1](model.html?id=Grok_Code_Fast_1) | ❌ | PASS | 75 | — |
| 38 | [GLM-5 Turbo](model.html?id=GLM5-Turbo) | ❌ | PASS | 74 | — |
| 39 | [Qwen3 Max](model.html?id=Qwen3_Max) | ❌ | PASS | 72 | — |
| 40 | [Sonar Reasoning Pro 🆕](model.html?id=Sonar_Reasoning_Pro) | — | FAIL | 58 | — |
| 41 | [Codestral 2508 🆕](model.html?id=Codestral_2508) | — | FAIL | 55 | — |
| 42 | [Command A 🆕](model.html?id=Command_A) | — | FAIL | 55 | — |
| 43 | [Jamba Large 1.7 🆕](model.html?id=Jamba_Large_1-7) | — | FAIL | 55 | — |
| 44 | [Mistral Medium 3.1 🆕](model.html?id=Mistral_Medium_3-1) | — | FAIL | 55 | — |
| 45 | [ERNIE 4.5 300B 🆕](model.html?id=ERNIE_4-5_300B) | — | FAIL | 54 | — |
| 46 | [ERNIE 4.5 VL 424B 🆕](model.html?id=ERNIE_4-5_VL_424B) | — | FAIL | 53 | — |
| 47 | [Llama 4 Maverick 🆕](model.html?id=Llama_4_Maverick) | — | FAIL | 53 | — |
| 48 | [Devstral 2512 🆕](model.html?id=Devstral_2512) | — | FAIL | 50 | — |
| 49 | [Nova Premier 🆕](model.html?id=Nova_Premier) | — | FAIL | 50 | — |
| 50 | [Nova Pro 🆕](model.html?id=Nova_Pro) | — | FAIL | 50 | — |
| 51 | [Nemotron Super 49B 🆕](model.html?id=Nemotron_Super_49B) | — | FAIL | 48 | — |
| 52 | [Phi-4 🆕](model.html?id=Phi-4) | — | FAIL | 48 | — |
| 53 | [Hunyuan A13B 🆕](model.html?id=Hunyuan_A13B) | — | FAIL | 46 | — |
| 54 | [Grok 4.3](model.html?id=Grok_4-3_Test) | — | FAIL | 41 | — |
| 55 | [Command R+ 🆕](model.html?id=Command_R_Plus) | — | FAIL | 38 | — |
| 56 | [MiniMax 2](model.html?id=MiniMax2) | — | FAIL | 38 | — |
| 57 | [Cognito v2](model.html?id=Cognito_v2) | — | FAIL | 34 | — |
| 58 | [GLM-4.6](model.html?id=GLM_4-6) | — | FAIL | 34 | — |
| 59 | [DeepSeek (Web)](model.html?id=DeepSeek_Web) | — | FAIL | 33 | — |
| 60 | [GPT-5.4 mini](model.html?id=GPT-5-4-mini) | — | FAIL | 32 | — |
| 61 | [Reka Flash 3 🆕](model.html?id=Reka_Flash_3) | — | FAIL | 18 | — |
| — | DeepSeek V3-1 | — | — | 0 | — |
| — | DeepSeek V3-2 Exp | — | — | 0 | — |
| — | o3 DeepResearch | — | — | 0 | — |

The inversion at rank 25 is the whole argument: **Hermes 4 405B scores 95 — tied for the highest in the folder — and ranks 25th, behind every program that opens a window.**

## Takeaways

- **Parse-rate is a vanity metric.** 64% parse; 39% run; 3% nail the visual brief. Launch generated code before trusting it, and look at it before shipping it.
- **Hallucinated APIs are the #1 runtime killer.** Eight of fifteen crashes are calls to functions or methods that don't exist — invisible to a linter and a parser alike.
- **"Has the feature in code" ≠ "shows the feature."** Most running GUIs contain dark-mode calls and still render light; the winners make the one DWM title-bar call the others skip.
- **Families have personalities.** OpenAI finishes; Anthropic reliably runs but stops one call short of dark; Gemini writes clean code that crashes. Pick by the failure mode you can least afford.
- **One-shot API generation is brittle for niche syntax.** 1 of 22 live generations ran. Context and iteration beat raw model choice.
