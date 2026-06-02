# One Prompt, 60 Models: An AHK v2 Clipboard-Formatter Benchmark

I have a folder of AutoHotkey v2 scripts named after the model that wrote each one — `GPT-5-5-Pro.ahk`, `Gemini_3_Pro.ahk`, `Hermes_4_405B.ahk`, and five dozen more. Every file is the same model answering the **same prompt**. This post grades all of them on three escalating signals — does it *parse*, does it *run*, does it *look right* — then adds two live multi-provider sweeps through OpenRouter.

The headline up front: of **61 outputs, 39 parse, only 24 build a working window, and just 2 render the dark theme the prompt demanded.** Each filter throws away roughly a third of the field. **Every model below has its own page** — click any name for the full source, an itemized scorecard, the captured window, and a per-model breakdown.

## The Prompt

Every model received one strict spec: build a **dark-mode clipboard text-formatter** as a single dependency-free AHK v2 GUI. The prompt is a full agent harness with a `P0_CRITICAL` rule block, a tiered reasoning system, and an eight-item `DIAGNOSTIC_CHECKLIST`. The build target is specific and gradeable: load the clipboard on startup; three transforms (`StrUpper`/`StrLower`/`StrTitle`); multi-step undo + redo on `Ctrl+Z`/`Ctrl+Y`; a live char/line counter; a resizable, **dark-themed**, `Escape`-to-close window; and a `ControlWrapper` base class with two overriding subclasses.

Its `P0_CRITICAL` block even spends a paragraph on one AHK trap: reusing the class name as the storage variable throws `Class 'X' cannot be used as an output variable`, because identifiers are case-insensitive. Hold that thought.

## How Scoring Works

Three signals of increasing strictness, all against the **v2.1-alpha.30+Console** fork.

**1. Parse (`/validate`).** A parse-only load: exit `0` parses, exit `12` is a syntax error. Objective, but weak — it never runs a line.

**2. Runs (launch + capture).** Each parsing script is *launched* under `/ErrorStdOut`. A PowerShell harness waits for the main window, captures it with `PrintWindow` (occlusion-proof), then kills it. Builds a window → ✅. Throws before drawing → ❌. This separates "looks like AHK" from "is a program."

**3. Visual (pixel analysis).** Each captured window is scored 0–20: dark background, dark title bar, dark-mode consistency, sane proportions, visible content — measured from the actual pixels. The prompt *required* dark mode, so this checks whether the model delivered it on screen, not just in the source.

Plus a **code score (0–100)** — an automated `DIAGNOSTIC_CHECKLIST` pass (Map storage, `.Bind(this)`, inheritance, transforms, undo/redo, no empty catch, etc.). The leaderboard sorts by **Runs first, then code score.** A crash on launch ranks below every program that opens, however clean its source.

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

`GPT-5.5 Pro` takes it outright — the only family to both top the code score and fully render the dark theme:

<img src="posts/img/gpt55pro-gui.png" alt="GPT-5.5 Pro clipboard formatter, fully dark theme, sample text loaded" style="max-width:100%;border:1px solid #303030;border-radius:8px">

The full 1–61 standings — every link live — are at the end.

## Does It Actually Run?

Parse-validation passed **39** of 61 outputs. Launch them, and **15 die before drawing a pixel** — a runtime mortality rate hiding behind a green check. Only **24 build a window.**

<img src="posts/img/clipboard-gallery.png" alt="Contact sheet of the 24 LLM clipboard formatters that build a working window" style="max-width:100%;border:1px solid #303030;border-radius:8px">

Every crash parsed clean and then threw on launch. By cause:

| Count | Runtime crash cause                                              |
|-------|-----------------------------------------------------------------|
| 6     | **Hallucinated API** — called a function that doesn't exist (`IsMap()`, `Exception()`) |
| 4     | **Invalid GUI control option** string                           |
| 2     | **Wrong argument count** to a function                          |
| 2     | **Hallucinated method** — `Gui.Edit.SetSel()` (no such method)   |
| 1     | **Void return used as a value** — `.Opt()` inside a property setter |

The hallucination pattern is the killer. `IsMap()` is not an AHK built-in; the real test is `value is Map`. `Gui.Edit` has no `SetSel`. These are syntactically perfect calls to functions that don't exist, so the parser waves them through and the runtime throws the instant control reaches them. Two labs' models — [GPT-5 Codex](model.html?id=GPT-5_Codex) and [Gemini 2.5 Pro](model.html?id=Gemini_2-5_Pro) — independently invented the *same* `SetSel()` method.

## The Dark-Mode Gap

The prompt said dark mode. Here is how many of the 24 running programs actually delivered it on screen:

- **2 fully dark** (20/20) — dark client *and* dark title bar: [GPT-5.5 Pro](model.html?id=GPT-5-5-Pro) and its Extra variant.
- **3 partially dark** (15/20) — dark editor, but a stock light Windows title bar: [Qwen 3.7](model.html?id=Qwen_3-7), [Opus 4.7 Fast](model.html?id=Opus_4-7_Fast), [Opus 4.8 Fast](model.html?id=Opus_4-8_Fast).
- **19 light** (≤4/20) — a white window despite the requirement.

So **79% of the running programs ignored or fumbled the dark-mode requirement visually** — even though most of them *contain* dark-mode code that scores points on the rubric. Writing `DwmSetWindowAttribute(...)` earns the code point; getting the window to actually paint dark is a different skill, and only a handful have it. This gap is exactly why a screenshot belongs in the loop: "has dark-mode code" and "looks dark" are not the same claim. Each model's page shows its captured window and an itemized visual scorecard.

## The Live OpenRouter Sweeps

To pressure-test the folder with models that had never seen this prompt, I ran two sweeps live through OpenRouter — 24 models across a dozen providers, one user message, `temperature 0.2`, the AHK block extracted and saved into the folder. **22 returned code.** Of those:

- **6 parsed.**
- **1 ran** — [WizardLM 2 8x22B](model.html?id=WizardLM_2_8x22B).

One. Every other live generation — Hermes 4 (405B *and* 70B), Mistral Large 3, Llama 3.3 70B, Nemotron 3 Super, Opus 4.8, and the rest — either failed to parse or crashed on launch. The runnable entries in the folder are the *pre-existing* ones, pasted from richer chat sessions. That gap is itself the finding: **single-turn, low-temperature API generation of niche-syntax code is dramatically more fragile than a curated chat output** — a 1-in-22 hit rate here. It was also pointed that both of Mistral's *coding-specialized* models, Codestral and Devstral, didn't even parse, while general models from the same lab did better.

## The Class-as-Variable Trap

Before runtime, 22 outputs never parsed at all. The most common single error is the one the prompt explicitly warned about. AHK identifiers are **case-insensitive**, so `main` and `Main` are the same name:

```ahk
main := Main()        ; throws: Class cannot be used as an output variable

class Main {
}
```

[Phi-4](model.html?id=Phi-4) and [ERNIE 4.5](model.html?id=ERNIE_4-5_300B) both wrote exactly `main := Main()`. [GLM-4.6](model.html?id=GLM_4-6) reproduced the prompt's *verbatim invalid example*, `clipboardEditor := ClipboardEditor()`. The passers just renamed the variable — `editor := ClipboardEditor()` — as instructed. The fix is one word; the warning wasn't enough to plant the reflex.

## Clean Code That Doesn't Run

The runtime gate's sharpest lesson: *readability is not correctness.* Here is [Hermes 4 405B](model.html?id=Hermes_4_405B)'s base class — arguably the most elegant `ControlWrapper` in the whole folder, and a 95 on the code score:

```ahk
class ControlWrapper {
   Control := ""
   Options := Map()
   __New(options := "") {
      this.Options := IsMap(options) ? options : Map()
   }
}
```

It reads beautifully. It also calls `IsMap()` — a function that **does not exist in AHK v2**. So it parses without complaint, scores 95, and throws `UnsetError` the instant `__New` runs. The prettiest base class in the benchmark never opens a window, and ranks 25th behind every program that does.

Contrast the winner, [GPT-5.5 Pro](model.html?id=GPT-5-5-Pro), which treats transforms as data and uses only symbols that exist:

```ahk
this.transforms.Add("Upper", TextTransform("Upper", StrUpper))
this.transforms.Add("Lower", TextTransform("Lower", StrLower))
```

## Two Surprises

**Size is not correctness.** GPT-5.5 Pro's 721-line answer is the largest in the folder and the #1 result — yet it ships **undo with no redo**, a required feature simply absent. It runs, renders dark, and tops the board while quietly missing the spec.

**Reasoning time bought nothing.** NVIDIA's [Nemotron 3 Super](model.html?id=Nemotron_3_Super_120B) spent 201 seconds — 5× the next-slowest — producing clean-parsing code that still crashed on an undefined variable. Extra deliberation polished the prose without fixing the one fact that mattered.

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

## Reproduce It

Parse, then *run*, then look:

```bash
AutoHotkey64.exe /ErrorStdOut /validate "Model.ahk"   # exit 0 parses, 12 = syntax error
```

```powershell
$p = Start-Process $exe -ArgumentList '/ErrorStdOut "Model.ahk"' -PassThru
while (-not $p.HasExited -and $p.MainWindowHandle -eq 0) { Start-Sleep -m 250 }
if ($p.MainWindowHandle -ne 0) { [Win32]::PrintWindow($h, $hdc, 2) }  # runs - capture it
else { "crashed: exit $($p.ExitCode)" }                               # crashed
```

The captured PNG then feeds a pixel pass (background luminance, title-bar darkness) for the visual score. Generation posts `Prompt.md` to OpenRouter and writes each response into the folder named after the model — so the leaderboard grows itself every time a new model ships.

## Takeaways

- **Parse-rate is a vanity metric.** 64% of outputs parse; 39% run; 3% nail the visual brief. A green `/validate` means the syntax is plausible, nothing more. Launch generated code before trusting it, and look at it before shipping it.

- **Hallucinated APIs are the #1 runtime killer.** Six models called functions that don't exist; two invented a method. The code looks expert; the symbols are fiction — a failure mode both a linter and a parser miss.

- **"Has the feature in code" ≠ "shows the feature on screen."** Most running GUIs contain dark-mode calls and still render light. Pixels are the only honest test of a visual requirement.

- **One-shot API generation is brittle for niche syntax.** 1 of 22 live OpenRouter generations produced a runnable program. Context and iteration, not just model choice, decide whether it runs.

- **Readability ≠ correctness.** The folder's most elegant base class scores 95 and never opens a window.
