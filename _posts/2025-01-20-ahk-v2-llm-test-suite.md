---
layout: post
title: "AutoHotkey v2 Test Prompts for Evaluating Coding Agents"
date: 2025-01-20 09:00:00 -0500
categories: [Testing]
tags: [autohotkey, prompts, evaluation]
description: A curated collection of AutoHotkey v2 prompts for benchmarking LLM-powered coding assistants.
---

Large language models can write useful AutoHotkey v2 scripts, but their output quality varies with the
prompt, scenario, and the assistant you choose. To track improvements across tools, I keep a repeatable
suite of prompts that stress different parts of the language—GUIs, classes, object lifetime, and
method resolution. Below is an overview of each test, the exact prompt I run, and the behavior I expect
from a well-performing assistant.

## 1. GUI Clipboard Manager

This scenario checks whether the assistant can assemble a complete GUI workflow: creating windows,
responding to button clicks, and using the clipboard. It is especially helpful for spotting
hallucinated function names or wrong AHK v1 syntax.

**Prompt**

```md
Create a clipboard text editor that:
Opens the GUI when the script starts
Shows the clipboard contents when the GUI opens in an edit box
Create three buttons to change the case and format of the code
Save the newly edited version to the users clipboard
```

**Desired result**

```autohotkey
#Requires AutoHotkey v2.1-alpha.16
#SingleInstance Force

ClipboardManager()

class ClipboardManager {
    __New() {
        this.gui := Gui("+Resize", "Clipboard Manager")
        this.gui.SetFont("s10")
        this.gui.OnEvent("Close", (*) => this.gui.Hide())
        this.gui.OnEvent("Escape", (*) => this.gui.Hide())
        
        this.editor := this.gui.AddEdit("vContent w400 h300 Multi")
        this.editor.Value := A_Clipboard
        
        this.gui.AddButton("w100", "UPPERCASE").OnEvent("Click", this.ConvertCase.Bind(this, "upper"))
        this.gui.AddButton("w100 x+5", "lowercase").OnEvent("Click", this.ConvertCase.Bind(this, "lower"))
        this.gui.AddButton("w100 x+5", "Title Case").OnEvent("Click", this.ConvertCase.Bind(this, "title"))
        
        this.gui.Show()
    }
    
    ConvertCase(caseType, *) {
        text := this.editor.Value
        switch caseType {
            case "upper": text := StrUpper(text)
            case "lower": text := StrLower(text)
            case "title": text := StrTitle(text)
        }
        this.editor.Value := text
        A_Clipboard := text
    }
}
```

A correct solution demonstrates a working understanding of GUI creation and the `Bind()` pattern for
callback methods.

## 2. Method Dispatch & Inheritance

Inheritance is easy to get wrong in AutoHotkey v2 because you have to initialize parent classes
explicitly with `super.__New`. This test ensures the model respects constructor chaining and method
resolution order.

**Prompt**

```md
What will be the output of obj.method() based on the code below?
```

```autohotkey
#Requires AutoHotkey v2.1-alpha.16
#SingleInstance Force

class Base {
    __New(val) {
        this.val := val
    }
    method() {
        return "Base: " . this.val
    }
}

class Derived extends Base {
    __New(val) {
        super.__New(val * 2)
    }
    method() {
        return super.method() . ", Derived: " . this.val
    }
}

obj := Derived(5)
```

**Expected answer**

```text
10
```

An ideal assistant explains that the derived constructor doubles the initial value before calling the
base implementation, so `super.method()` returns `Base: 10`, `this.val` equals `10`, and the combined
string prints `Base: 10, Derived: 10`. When asked for only the final output, the assistant should
respond with `10`.

## 3. Tooltip Timer & Lifetime Management

Object lifetime management is a subtle part of AutoHotkey v2. This test verifies that the model can use
`ObjAddRef` and `ObjRelease` correctly, bind timers, and handle clean-up in `__Delete`.

**Prompt**

```md
Create an AutoHotkey v2 class called TooltipTimer that:
Shows a persistent tooltip using ObjPtr reference counting
Updates tooltip every 1000ms while managing object lifetime
Handles cleanup properly with __Delete
Uses proper timer binding pattern with .Bind(this)
```

**Desired result**

```autohotkey
#Requires AutoHotkey v2.1-alpha.16
#SingleInstance Force

TooltipTimer()
class TooltipTimer {
    __New() {
        this.Timer := this.Update.Bind(this)
        SetTimer(this.Timer, 1000)
        this.ptr := ObjPtr(this)
        ObjAddRef(this.ptr)
    }
    
    __Delete() {
        SetTimer(this.Timer, 0)
        ObjRelease(this.ptr)
        this.Timer := unset
    }
    
    Update() {
        ToolTip("Updating...")
    }
}
```

If the assistant produces the snippet above (or an equivalent implementation), you can be confident it
understands timers, bound functions, and reference counting—areas where hallucinations often creep in.

---

These prompts give me a baseline for comparing model updates or different tools. Feel free to propose
additional challenges in a pull request or GitHub issue. The more diverse the suite, the better we can
shape future AutoHotkey-aware LLMs.
