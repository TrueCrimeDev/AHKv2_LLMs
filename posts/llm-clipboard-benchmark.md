# One Prompt, 50 Models: An AHK v2 Clipboard-Formatter Benchmark

I have a folder of AutoHotkey v2 scripts named after the model that wrote each one — `GPT-5-5-Pro.ahk`, `Gemini_3_Pro.ahk`, `DeepSeek_V4.ahk`, and dozens more. Every file is the same model answering the **same prompt**. This post scores all of them on two hard signals, then adds a fresh 12-model sweep run live through OpenRouter.

The result is a leaderboard, a failure taxonomy, and one very consistent lesson: the mistake a prompt *explicitly forbids* is still the mistake models make most.

## The Prompt

Every model received one strict spec: build a **dark-mode clipboard text-formatter** as a single dependency-free AHK v2 GUI. The prompt is not a one-liner — it is a full agent harness with a `P0_CRITICAL` rule block, a tiered reasoning system, and an eight-item `DIAGNOSTIC_CHECKLIST` the model must clear before emitting code.

The build target is specific enough to be gradeable:

- Load the current clipboard into a multi-line edit on startup.
- Three transforms — `StrUpper`, `StrLower`, `StrTitle` — that rewrite the edit and the clipboard.
- **Undo and Redo** with full multi-step history, bound to `Ctrl+Z` / `Ctrl+Y`, disabled via `.Opt()` when empty.
- A live status line with character and line counts.
- A resizable, DPI-aware, dark-themed window with an `Escape`-to-close handler.
- A `ControlWrapper` base class plus **two derived classes** that each override at least one method — used for real, not decoration.

Crucially, the prompt's `P0_CRITICAL` section spends an entire block warning about one AHK-specific trap:

> Reusing the class name as the storage variable throws `Class 'X' cannot be used as an output variable`. The variable name must differ from the class name, case-insensitive.
> INVALID: `clipboardEditor := ClipboardEditor()`
> VALID: `editor := ClipboardEditor()`

Hold that thought.

## How Scoring Works

Each output is judged on two axes, validated against the actual interpreter the project targets — the **v2.1-alpha.30+Console** fork.

**1. Parse validation (40 pts, hard gate).** Every script runs through `AutoHotkey64.exe /validate`, a parse-only load. Exit `0` means it parses; exit `12` means a load-time syntax error with a line number. This is binary and objective — no opinion involved. It does *not* execute the GUI, so it catches syntax and structural errors but not runtime logic bugs.

**2. Rule + spec adherence (60 pts, automated heuristic).** Regex checks for the `DIAGNOSTIC_CHECKLIST` items (correct header, `Map()` storage, no `=> { multi-line }` blocks, no empty `catch {}`, `.Bind(this)` callbacks, no JS contamination) and the build-target features (inheritance depth, the three transforms, undo+redo, dark mode, resize, escape, `.Opt()`, live counts).

The second axis is a heuristic and is labeled as such. It under-credits very abstracted code — for example, a model that passes `StrUpper` as a bare function reference into a registry rather than calling `StrUpper(...)` directly. Where a number looked unfair I read the source by hand. Treat the parse column as fact and the score column as a strong-but-imperfect proxy.

## The Leaderboard

Top of the table, sorted by score. `src` is line count; `parse` is the hard interpreter gate.

| #  | Model                  | src | parse | score |
|----|------------------------|-----|-------|-------|
| 1  | GPT-5.5 Pro            | 721 | PASS  | 95    |
| 2  | GPT-5.5 Pro (Extra)    | 260 | PASS  | 95    |
| 3  | Hermes 4 405B 🆕        | 202 | PASS  | 95    |
| 4  | GPT-5.2 Pro (v2)       | 324 | PASS  | 92    |
| 5  | Opus 4.8 🆕             | 278 | PASS  | 92    |
| 6  | Qwen 3.7               | 229 | PASS  | 92    |
| 7  | Alpha Owl              | 251 | PASS  | 90    |
| 8  | Llama 3.3 70B 🆕        | 154 | PASS  | 90    |
| 9  | Mistral Large 3 🆕      | 196 | PASS  | 90    |
| 10 | Nemotron 3 Super 120B 🆕| 200 | PASS  | 90    |
| 11 | Opus 4.7 (Fast)        | 195 | PASS  | 88    |
| 12 | Opus 4.8 (Fast)        | 309 | PASS  | 88    |
| 13 | Gemini 3.5 Flash       | 176 | PASS  | 86    |
| 14 | DeepSeek V4            | 164 | PASS  | 83    |
| 15 | Gemini 3.1 Flash Lite  | 102 | PASS  | 83    |

A three-way tie at the top: GPT-5.5 Pro, its "Extra" variant, and — straight out of the live OpenRouter sweep — **Hermes 4 405B**, an open-weights model holding its own against frontier closed models on a strict AHK v2 spec. One rung down at 92, **Opus 4.8** (run live for this post) ties GPT-5.2 Pro and Qwen 3.7 with a tight 278-line answer — a reminder that the score rewards completeness over column inches.

Across all **51 model outputs that produced code, 37 (73%) parsed clean**. Three more models returned nothing usable (empty file). The bottom third is where it gets interesting. The full 1–51 standings — including three entries running under internal codenames (Alpha Owl, Spectre, Cognito) — are tabulated in the **Complete Standings** section at the end of this post.

## The Live OpenRouter Sweep

To pressure-test the folder with models that had never seen this prompt, I ran it through twelve models live via OpenRouter — one user message, `temperature 0.2`, the AHK block extracted from each response and saved straight into the folder.

| Model                  | Provider     | Latency | Out tokens | Parse |
|------------------------|--------------|---------|-----------|-------|
| Hermes 4 405B          | Nous         | 40 s    | 1658      | PASS  |
| Mistral Large 3        | Mistral      | 22 s    | 1504      | PASS  |
| Llama 3.3 70B          | Meta         | 36 s    | 1373      | PASS  |
| Nemotron 3 Super 120B  | NVIDIA       | 201 s   | 1659      | PASS  |
| Codestral 2508         | Mistral      | 8 s     | 1460      | FAIL  |
| Devstral 2512          | Mistral      | 33 s    | 1468      | FAIL  |
| Command A              | Cohere       | 17 s    | 1282      | FAIL  |
| Jamba Large 1.7        | AI21         | 27 s    | 1719      | FAIL  |
| ERNIE 4.5 300B         | Baidu        | 73 s    | 1926      | FAIL  |
| Llama 4 Maverick       | Meta         | 22 s    | 1128      | FAIL  |
| Nova Premier           | Amazon       | 41 s    | 1352      | FAIL  |
| Phi-4                  | Microsoft    | 16 s    | 1128      | FAIL  |

**Four of twelve parsed clean** — and the most pointed result is that both of Mistral's *coding-specialized* models, Codestral and Devstral, failed, while their general-purpose Mistral Large 3 sailed through at 90. A "coder" label is trained on mainstream languages; AHK v2's alpha syntax is far enough off the beaten path that general reasoning beat narrow code tuning here.

`anthropic/claude-opus-4.8` was added through the same pipeline on request: 3377 output tokens in 32 seconds, parsed clean, and landed at **#5 overall (92)** — the strongest single OpenRouter generation in this run after Hermes 4.

## What Separated Pass from Fail

Collapsing every parse failure to its first error message produces a remarkably short list:

| Count | Load-time error                                        |
|-------|--------------------------------------------------------|
| 4     | `This Class cannot be used as an output variable`      |
| 4     | (empty file / no output)                               |
| 3     | `Not a valid method, class or property definition`     |
| 2     | `This line does not contain a recognized action`       |
| 1     | `Invalid assignment`                                   |
| 1     | `Missing ")"`                                           |
| 1     | `This parameter declaration conflicts...`              |
| 1     | `Missing comma`                                         |

The single most common *syntax* failure is the one the prompt devoted a whole block to preventing.

## The Class-as-Variable Trap

AHK identifiers are **case-insensitive**. So `main` and `Main` are the same name. Write this:

```ahk
main := Main()

class Main {
    ; ...
}
```

…and the interpreter throws `This Class cannot be used as an output variable` on line 4, because you just tried to assign into the class's own name. The prompt warns about this explicitly. Phi-4 and ERNIE 4.5 both wrote exactly `main := Main()` and died on it.

GLM-4.6 went further and reproduced the prompt's *verbatim invalid example*:

```ahk
clipboardEditor := ClipboardEditor()

class ClipboardEditor {
    ; ...
}
```

That is character-for-character the line the prompt labels `INVALID`. The models that passed simply renamed the variable — `editor := ClipboardEditor()` — exactly as instructed. The fix is one word; recognizing that you need it is the hard part, and a warning in the prompt was not enough to plant the reflex.

## Patterns That Won

The high scorers shared an ergonomic instinct: treat the transforms as **data**, not branches. GPT-5.5 Pro built a registry and dropped the built-ins straight in as function objects:

```ahk
this.transforms.Add("Upper", TextTransform("Upper", StrUpper))
this.transforms.Add("Lower", TextTransform("Lower", StrLower))
```

No `if/else` ladder, no duplicated wiring — adding a transform is one line. (This is also the pattern a naive regex under-scores, because `StrUpper` never appears with a trailing `(`.)

Hermes 4 405B, the top open-weights finisher, nailed the part most models fumble — a genuinely *useful* base class whose derived types override real behavior rather than existing for show:

```ahk
class ControlWrapper {
   Control := ""
   Options := Map()
   __New(options := "") {
      this.Options := IsMap(options) ? options : Map()
   }
   Opt(options) {
      if IsMap(options)
         for option, value in options
            this.Control.Opt(option, value)
      else
         this.Control.Opt(options)
   }
}

class EditWrap extends ControlWrapper {
   ; overrides Create / value handling
}
```

That `Map()`-or-string `Opt()` overload is the kind of small, correct ergonomics the prompt rewards.

## Two Surprises

**Size is not correctness.** GPT-5.5 Pro's 721-line answer is by a wide margin the largest in the folder, with a full transform registry and a `TextHistory` class. It still **shipped undo with no redo** — a required feature, simply absent. Length signaled ambition, not completeness; the automated check caught the gap that a skim would miss.

**The 200-second outlier.** NVIDIA's Nemotron 3 Super spent 201 seconds reasoning — 5× the next-slowest — to land a clean, 90-scoring result. On a niche-syntax task, heavy deliberation paid off where fast coder models stumbled.

## Complete Standings

All 51 model outputs that emitted code, ranked. `src` is line count, `parse` is the hard interpreter gate, `score` is the 100-point composite. 🆕 marks the live OpenRouter sweep; `DNF` rows returned an empty file.

| # | Model | src | parse | score |
|---|-------|-----|-------|-------|
| 1 | GPT-5.5 Pro | 721 | PASS | 95 |
| 2 | GPT-5.5 Pro (Extra) | 260 | PASS | 95 |
| 3 | Hermes 4 405B 🆕 | 202 | PASS | 95 |
| 4 | GPT-5.2 Pro (v2) | 324 | PASS | 92 |
| 5 | Opus 4.8 🆕 | 278 | PASS | 92 |
| 6 | Qwen 3.7 | 229 | PASS | 92 |
| 7 | Alpha Owl | 251 | PASS | 90 |
| 8 | Llama 3.3 70B 🆕 | 154 | PASS | 90 |
| 9 | Mistral Large 3 🆕 | 196 | PASS | 90 |
| 10 | Nemotron 3 Super 120B 🆕 | 200 | PASS | 90 |
| 11 | Opus 4.7 (Fast) | 195 | PASS | 88 |
| 12 | Opus 4.8 (Fast) | 309 | PASS | 88 |
| 13 | Gemini 3.5 Flash | 176 | PASS | 86 |
| 14 | DeepSeek V4 | 164 | PASS | 83 |
| 15 | Gemini 3.1 Flash Lite | 102 | PASS | 83 |
| 16 | Sonnet 4.6 | 136 | PASS | 80 |
| 17 | Qwen 3.6 | 85 | PASS | 79 |
| 18 | Grok 4.2 | 299 | PASS | 78 |
| 19 | GPT-5.4 nano | 142 | PASS | 77 |
| 20 | GPT-5 Codex | 72 | PASS | 77 |
| 21 | Gemini 2.5 Pro | 59 | PASS | 77 |
| 22 | KAT-Coder Pro v2 | 247 | PASS | 76 |
| 23 | KAT-Coder | 92 | PASS | 76 |
| 24 | MiMo V2 Pro | 163 | PASS | 76 |
| 25 | Gemini 3 Pro | 54 | PASS | 75 |
| 26 | Grok 4 Fast | 71 | PASS | 75 |
| 27 | Grok Code Fast 1 | 71 | PASS | 75 |
| 28 | MiniMax 3 | 111 | PASS | 75 |
| 29 | Qwen3-VL 235B-A22B | 71 | PASS | 75 |
| 30 | GLM-5 Turbo | 106 | PASS | 74 |
| 31 | GPT-5.2 Pro | 185 | PASS | 74 |
| 32 | Opus 4.6 (Fast) | 51 | PASS | 74 |
| 33 | MiniMax 2.7 | 70 | PASS | 72 |
| 34 | Qwen3 Max | 50 | PASS | 72 |
| 35 | Spectre | 149 | PASS | 71 |
| 36 | Grok Code Fast 2 | 81 | PASS | 70 |
| 37 | MiniMax 2.7a | 70 | PASS | 70 |
| 38 | Codestral 2508 🆕 | 192 | FAIL | 55 |
| 39 | Command A 🆕 | 141 | FAIL | 55 |
| 40 | Jamba Large 1.7 🆕 | 147 | FAIL | 55 |
| 41 | ERNIE 4.5 300B 🆕 | 220 | FAIL | 54 |
| 42 | Llama 4 Maverick 🆕 | 131 | FAIL | 53 |
| 43 | Devstral 2512 🆕 | 180 | FAIL | 50 |
| 44 | Nova Premier 🆕 | 162 | FAIL | 50 |
| 45 | Phi-4 🆕 | 144 | FAIL | 48 |
| 46 | Grok 4.3 | 138 | FAIL | 41 |
| 47 | MiniMax 2 | 198 | FAIL | 38 |
| 48 | Cognito v2 | 74 | FAIL | 34 |
| 49 | GLM-4.6 | 65 | FAIL | 34 |
| 50 | DeepSeek (Web) | 35 | FAIL | 33 |
| 51 | GPT-5.4 mini | 52 | FAIL | 32 |
| — | DeepSeek V3-1 | 0 | DNF | 0 |
| — | DeepSeek V3-2 Exp | 0 | DNF | 0 |
| — | o3 DeepResearch | 0 | DNF | 0 |

A pattern worth noting in the long tail: line count and score barely correlate. `Grok 4.2` writes 299 lines for a score of 78; `Opus 4.6 (Fast)` writes 51 for 74. Verbosity is not adherence — several of the most compact passing entries out-score sprawling ones, and every `FAIL` below rank 37 wrote *more* than enough code to be correct. The defect was always structural, never a token budget.

## Reproduce It

The harness is two small scripts. Validation shells out to the fork:

```bash
AutoHotkey64.exe /ErrorStdOut /validate "Model.ahk"   # exit 0 = parses, 12 = syntax error
```

Generation posts `Prompt.md` to OpenRouter as a single user message, extracts the fenced AHK block, and writes it into the folder named after the model — so the leaderboard grows itself every time a new model ships.

## Takeaways

- **Parse-rate is the floor, not the ceiling.** 72% of models produce *loadable* AHK v2; far fewer produce *complete* AHK v2. Always run generated code through `/validate` before trusting it.
- **Explicit warnings under-perform.** Naming the exact trap in the prompt cut the class-as-variable error but did not eliminate it. Guardrails that *block* the mistake beat guardrails that *describe* it.
- **"Coder" models are not AHK models.** General-purpose frontier reasoning, and even a strong open-weights generalist like Hermes 4, beat code-tuned models on this alpha-syntax task.
- **Score, then read.** Automated rules rank the field fast; a human pass catches the abstracted winner and the oversized-but-incomplete entry. Use both.
