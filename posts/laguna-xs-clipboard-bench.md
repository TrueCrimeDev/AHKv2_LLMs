# Poolside Laguna XS 2.1: The Coding Agent That Writes AHK v1

Poolside's **Laguna XS 2.1** — their latest coding-agent model in the 33B-A3B class — joins the [clipboard-formatter benchmark](post.html?slug=llm-clipboard-benchmark) as the board's first Poolside entry, tested on both the paid [`poolside/laguna-xs-2.1`](model.html?id=Laguna_XS_2-1) endpoint and the [free tier](model.html?id=Laguna_XS_2-1_Free). Same one-shot prompt as the other 80 entries, July 7, via OpenRouter.

Neither entry parses. But the *way* they fail is more interesting than the failure: Laguna doesn't make AHK v2 mistakes — it writes a different language altogether.

<div class="bm-wrap"><table class="bm-heat"><thead><tr><th>#</th><th style="text-align:left">Entry</th><th>endpoint</th><th>parse</th><th>code</th><th>lines</th><th style="text-align:left">died on</th></tr></thead><tbody><tr><td class="h-rank">63</td><td class="h-name"><a href="model.html?id=Laguna_XS_2-1">Laguna XS 2.1</a></td><td class="h-dim">poolside/laguna-xs-2.1</td><td class="h-red">✗</td><td class="h-amber">50</td><td class="h-dim">260</td><td class="h-dim" style="text-align:left">Missing """</td></tr><tr><td class="h-rank">66</td><td class="h-name"><a href="model.html?id=Laguna_XS_2-1_Free">Laguna XS 2.1 (free)</a></td><td class="h-dim">poolside/laguna-xs-2.1:free</td><td class="h-red">✗</td><td class="h-amber">48</td><td class="h-dim">267</td><td class="h-dim" style="text-align:left">This line does not contain a recognized action.</td></tr></tbody></table></div>

## A Dialect Problem, Not a Detail Problem

The validator stops the paid entry at a mismatched quote and the free entry at a bare class field. Those are just the *first* errors. Read past them and the files are a v1/JavaScript hybrid that no AHK v2 interpreter has ever accepted:

```ahk
this.Edit := new EditWrap(this.GuiRef, "WorkingText", 10, 10, 400, 150)
```

`new` was removed in v2 — and the fun part is that it isn't even a keyword anymore, so this line *parses* as string concatenation with an unset variable named `new` and would die at runtime instead. The paid entry does this six times. It also reads the clipboard through v1's bare `Clipboard` variable, invents `ClipboardType` (which never existed in *any* AHK version), slices arrays with `History[1..i]`, and calls `.Length` on a string — Python and JS idioms wearing an AHK costume.

The free entry commits to the hybrid even harder:

```ahk
this.gui.Add("Button", "gUndoBtn", "Undo")          ; v1 g-label option
this.gui.OnEvent("UndoBtn", this.Undo.Bind(this))   ; wired to an event that can't exist
```

g-labels are v1's event system; `OnEvent` is v2's — the free entry uses both halves at once, plus a `gui.Controls[...]` collection and a `KeyDown` GUI event that v2 has never defined. To its credit, the undo/redo stack logic inside all that is genuinely coherent, and every real callback is correctly `.Bind(this)`-ed. The architecture is fine. The language is wrong.

Both endpoints produce the same profile — this is the model's identity, not sampling noise.

## In Its Size Class

No confirmed sub-50B open model has ever cleared this board's parse gate, and Laguna doesn't break the pattern — but it lands at the *top* of that class:

<div class="bm-wrap"><table class="bm-heat"><thead><tr><th>#</th><th style="text-align:left">Model</th><th>size</th><th>parse</th><th>code</th></tr></thead><tbody><tr><td class="h-rank">63</td><td class="h-name"><a href="model.html?id=Laguna_XS_2-1">Laguna XS 2.1</a></td><td class="h-dim">33B-A3B</td><td class="h-red">✗</td><td class="h-amber">50</td></tr><tr><td class="h-rank">67</td><td class="h-name"><a href="model.html?id=Nemotron_Super_49B">Nemotron Super 49B</a></td><td class="h-dim">49B</td><td class="h-red">✗</td><td class="h-amber">48</td></tr><tr><td class="h-rank">68</td><td class="h-name"><a href="model.html?id=Phi-4">Phi-4</a></td><td class="h-dim">14B</td><td class="h-red">✗</td><td class="h-amber">48</td></tr><tr><td class="h-rank">70</td><td class="h-name"><a href="model.html?id=Hunyuan_A13B">Hunyuan A13B</a></td><td class="h-dim">80B-A13B</td><td class="h-red">✗</td><td class="h-amber">46</td></tr><tr><td class="h-rank">79</td><td class="h-name"><a href="model.html?id=Reka_Flash_3">Reka Flash 3</a></td><td class="h-dim">21B</td><td class="h-red">✗</td><td class="h-amber">18</td></tr></tbody></table></div>

More striking: Laguna's static 50 **ties DeepSeek V3.2 and Devstral 2512, and sits within five points of Command A (111B) and Jamba Large 1.7 (398B)** — dense and MoE models an order of magnitude larger, all stuck at the same gate. With 3B active parameters, matching the parse-fail tier's mid-table is not nothing.

## Against Closed Models Its Size

Closed vendors don't publish parameter counts, so the honest comparison is the closed *small/cheap* tier — and it splits right down the middle:

- **GPT-5.4 nano** ($0.20/$1.25): code 77, **runs** — rank 20, above forty larger models
- **Gemini 3.1 Flash Lite** ($0.25/$1.50): code 83, **runs** — rank 16
- **GPT-5.4 mini** ($0.75/$4.50): code 32, parse-fail — rank 78, *18 points below Laguna*

At $0.06/M in, $0.12/M out, Laguna is among the cheapest paid models on the board — GPT-5.4 mini costs roughly twelve times more per output token and scores 18 points lower. But nano and Flash Lite prove the small-and-cheap tier *can* ship running AHK v2 windows — being small explains Laguna's rank; it doesn't excuse the dialect.

## Verdict

Laguna XS 2.1 is a coding-agent model, and it shows in both directions. The program structure — wrapper classes, undo stacks, event wiring — is more ambitious than half the models above it. But AHK v2 is clearly outside its training distribution, and it fills the gap with confident v1/JS syntax that a validator rejects on line 7. This is precisely the model profile that needs its natural habitat: an agent loop with a compiler in it. One `/validate` round-trip would tell it about `new`; one-shot generation never gets that chance. On this board, one-shot is the test — and the test says: wrong language.

*Disclosure: Claude Fable 5 generated these entries via the OpenRouter API and wrote this post. Every number comes from the same pipeline that graded all 82 entries — parse validation against the v2.1-alpha.30+Console fork, runtime launch where applicable, and the static rule checker. The per-model pages linked above show full source and itemized scorecards.*
