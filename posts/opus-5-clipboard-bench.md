# Opus 5 Under the Live Harness: The First 100

**Claude Opus 5** ran the [clipboard-formatter benchmark](post.html?slug=llm-clipboard-benchmark) in the one configuration that isn't a fresh API call — the live working harness: auto-loading syntax rules, project skills, the alpha.30+Console fork as the target interpreter, and the running memory of what previous entries got wrong. Same prompt as the other 82 entries. Same two gates: does it *parse*, and does it *run*.

It is the first entry in 83 to come back with a perfect static score.

<div class="bm-wrap"><table class="bm-heat"><thead><tr><th>#</th><th style="text-align:left">Entry</th><th>config</th><th>runs</th><th>code</th><th>visual</th><th>lines</th></tr></thead><tbody><tr><td class="h-rank">1</td><td class="h-name"><a href="model.html?id=Opus_5_Full_Harness">Opus 5 (Full Harness)</a></td><td class="h-dim">full live harness</td><td class="h-emer">✓</td><td class="h-emer">100</td><td class="h-emer">20/20</td><td class="h-dim">322</td></tr><tr><td class="h-rank">2</td><td class="h-name"><a href="model.html?id=Claude_Fable_5_Full_Harness">Fable 5 (Full Harness)</a></td><td class="h-dim">full live harness</td><td class="h-emer">✓</td><td class="h-emer">98</td><td class="h-emer">20/20</td><td class="h-dim">175</td></tr><tr><td class="h-rank">3</td><td class="h-name"><a href="model.html?id=GPT-5-5-Pro">GPT-5.5 Pro</a></td><td class="h-dim">default</td><td class="h-emer">✓</td><td class="h-emer">95</td><td class="h-emer">20/20</td><td class="h-dim">721</td></tr><tr><td class="h-rank">4</td><td class="h-name"><a href="model.html?id=GPT-5-5-Pro_Extra">GPT-5.5 Pro (Extra)</a></td><td class="h-dim">extra context</td><td class="h-emer">✓</td><td class="h-emer">95</td><td class="h-emer">20/20</td><td class="h-dim">260</td></tr></tbody></table></div>

## The Two Points

Fable 5 held 98 with every checklist item maxed except one: **inheritance depth**, worth 2 points per `extends` up to three. Fable shipped two derived classes. Opus 5 shipped three — `EditWrap`, `ButtonWrap`, `StatusWrap` — and each override does work the base can't:

```ahk
class EditWrap extends ControlWrapper {
    Value {
        get => StrReplace(this.ctrl.Value, "`r`n", "`n")
        set => this.ctrl.Value := StrReplace(StrReplace(value, "`r`n", "`n"), "`n", "`r`n")
    }
}

class ButtonWrap extends ControlWrapper {
    Value {
        get => this.ctrl.Text
        set => this.ctrl.Text := value
    }
}

class StatusWrap extends ControlWrapper {
    Value {
        get => this.ctrl.Text
        set {
            this.ctrl.Text := value
            this.ctrl.Redraw()
        }
    }
}
```

Three control types, three meanings of `Value`: the Edit normalizes line endings in both directions so the character count is honest, the Button remaps to its caption, and the Text control repaints itself — without that `Redraw()`, a status line over a custom `BackColor` leaves the old string smeared under the new one. That's the whole delta. Every other item was already at ceiling.

## What the Score Doesn't Say

The honest column: **322 lines against Fable's 175**. Nearly double the program for two points, on a metric that is a checklist and rewards presence, not judgment. Fable's entry is the leaner piece of code and a reasonable person could prefer it.

That is now the benchmark's real problem. Four entries sit at 95 or above, all four run, all four render fully dark. The static score is saturated at the top; the runtime gate and the pixel check both max out; there is no headroom left to separate the strongest models on this task. Discrimination has moved to the harder suites — [AHK-Eval](post.html?slug=ahk-eval-benchmark), the [Clipboard Toolkit](post.html?slug=llm-toolkit-benchmark), [AHK-Contract](post.html?slug=ahk-contract-benchmark) — where the top of the board still loses tasks.

The floor, meanwhile, hasn't moved at all: of 80 submissions with code, **52 parse and only 32 open a window**. Runtime mortality behind a green parse check is still the finding this board exists to make.

## The Screenshots Were Lying

Chasing what looked like a layout bug in the new entry turned up a defect in the capture harness itself.

The pipeline launches each script from PowerShell, waits for a window, then measures it with `GetWindowRect` and grabs the pixels with `PrintWindow`. PowerShell is DPI-unaware. On a 125% display, every measurement it takes of a *DPI-aware* window comes back in virtualized 96-DPI coordinates — 80% of the real size. The bitmap is allocated at that smaller size; `PrintWindow` renders the window at its true resolution into it; the right and bottom 20% are silently cut off.

The first Opus 5 capture lost its Redo button and its entire status line, which read as a layout bug for three rounds of debugging before the real cause surfaced. It isn't specific to this entry — the previously published Fable 5 (Full Harness) shot has its button row sliced in half and its status line missing for exactly the same reason. One line fixes it:

```powershell
[Win32]::SetProcessDpiAwarenessContext([IntPtr](-4))
```

With that in place the same window measures 793×572 instead of 634×458, and the capture shows the whole program. The entry below was captured with the fix; the older shots on this board are pending a re-run.

<img src="posts/img/shots/Opus_5_Full_Harness.png" alt="Opus 5 (Full Harness) — fully dark clipboard formatter" style="max-width:100%;border:1px solid #303030;border-radius:8px">

The visual scores are unaffected — the metric is luminance-based and the visible portion was representative — but every cropped shot was undersold as a picture of the program.

## Verified Past the Gates

The benchmark grades parse and window. This entry was also driven: all three transforms with clipboard write-back, multi-step undo and redo through both the buttons and `Ctrl+Z`/`Ctrl+Y`, `.Opt()` gating that greys Undo when the stack is empty, the non-text clipboard message, and Escape-to-close. All correct.

That check had its own trap. `Ctrl+Z` appeared dead across three rounds of testing, because a *second* AutoHotkey script cannot trigger the first one's hook hotkeys: AHK stamps its own synthetic input with `KEY_IGNORE`, and every AHK keyboard hook ignores keystrokes carrying it — deliberately, so scripts don't set each other off in a loop. `SendLevel(1)` in the driver lifts the suppression, and the hotkeys fire on the first try. Worth knowing before concluding that a scripted GUI's shortcuts are broken.

## Verdict

Opus 5 under the full harness is the first perfect static score the board has produced, with a running, fully dark window behind it. It is also the clearest evidence yet that this particular benchmark is finished as a discriminator at the top — the interesting question is no longer whether a frontier model can write one-shot AHK v2 that opens a window, but what it does on the suites that still hurt.

*Disclosure: this entry was generated by the model it grades, running as the live harness, and Opus 5 wrote this post. Every number comes from the same automated pipeline that graded the other 82 entries — parse validation against the v2.1-alpha.30+Console fork, live launch and window capture, and the pixel-level visual check. The [per-model page](model.html?id=Opus_5_Full_Harness) carries the full source and the itemized scorecard.*
