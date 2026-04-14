# AutoHotkey v2.1-alpha.25: Inline Window Options and Stability Fixes

Alpha.25 is a stability-focused release with one standout user-facing feature: `ahk_opt`, which lets you specify window search options directly in the WinTitle string. The rest of the release addresses hotkey behavior, module initialization, and edge-case crashes.

## ahk_opt: Inline Window Search Options

This is the headline feature. Previously, finding hidden windows required changing global state:

```ahk2
; Old way: changes global setting
DetectHiddenWindows true
hwnd := WinExist("Notepad")
DetectHiddenWindows false  ; hope you remembered to reset
```

`ahk_opt` lets you specify these settings per-call:

```ahk2
; New way: inline, no global side effects
hwnd := WinExist("Notepad ahk_opt Hidden 2")
```

### Supported Options

| Option | Effect |
|--------|--------|
| `Hidden` / `Hidden1` | Detect hidden windows (this call only) |
| `Hidden0` | Ignore hidden windows |
| `HiddenText` / `HiddenText1` | Detect hidden text |
| `HiddenText0` | Ignore hidden text |
| `1` / `2` / `3` / `RegEx` | Title match mode |
| `Fast` / `Slow` | Title detection speed |

### Combining with Other Criteria

`ahk_opt` works alongside all existing `ahk_` criteria:

```ahk2
; Find taskbar even when hidden
hwnd := WinExist("ahk_class Shell_TrayWnd ahk_opt Hidden")

; Explorer with RegEx matching
hwnd := WinExist("ahk_exe explorer.exe ahk_opt Hidden RegEx")

; Multiple options at once
hwnd := WinExist("Untitled ahk_opt Hidden 2 Fast")
```

### Why This Matters

Global state is the enemy of reliable scripts. When you call `DetectHiddenWindows true`, every subsequent `WinExist`/`WinActivate`/`WinWaitActive` in your script (and any included libraries) is affected. If a timer fires between your "set" and "reset," it operates with your changed setting.

`ahk_opt` eliminates this entire class of bugs. Each window operation specifies exactly what it needs, with zero side effects.

### Practical: Finding Hidden System Windows

```ahk2
found := []
for title in ["Program Manager", "MSCTFIME UI", "Default IME"] {
    hwnd := WinExist(title " ahk_opt Hidden 1")
    if hwnd
        found.Push(Format("{} (0x{:X})", title, hwnd))
}
```

No need to toggle global state just to enumerate system windows.

## WinExist Exclusion Fixes

Two bugs fixed in `WinExist`:

**Fix 1:** `WinExist("A",,,"ExcludeText")` no longer incorrectly excludes windows that have no controls. Previously, any controlless window was excluded regardless of the ExcludeText value.

**Fix 2:** `WinExist("", "Text")` no longer reads the title of every window on the system. This was a significant performance regression -- it now only checks windows that match the text criterion.

## DllCall Safety

Alpha.25 adds a guard against a crash scenario: passing a struct array class as a `DllCall` return type.

```ahk2
Struct POINT { x: i32, y: i32 }

; Before alpha.25: crash
; After alpha.25: proper error
DllCall("SomeFunc", POINT[3])  ; TypeError
```

This was a silent crash with no error message. Now you get a clear error explaining that array classes cannot be used as return types.

## Hotkey Behavior Fixes

Three fixes that improve hotkey reliability:

### Key-Up Consistency

Key-up hotkeys now fire consistently when the same key is used as both prefix and suffix:

```ahk2
LCtrl::Send "hello"      ; LCtrl as prefix
LCtrl up::ToolTip "up"   ; LCtrl up as suffix -- now reliable
```

Previously the up hotkey might not fire depending on timing.

### Neutral Modifier Combos

Custom combo hotkeys with neutral modifiers now work:

```ahk2
Alt & Esc::MsgBox "works"  ; Alt (not LAlt/RAlt) as prefix
```

Before this fix, you had to specify `LAlt` or `RAlt` explicitly.

### SendLevel Suppression

Key suppression now respects `SendLevel`. A hotkey at SendLevel 0 won't suppress keys sent at SendLevel > 0, making layered hotkey scripts more predictable. This is important for scripts that use `SendLevel` to allow hotkeys to trigger other hotkeys.

## Module System Fixes

Four fixes to the module/import system:

1. **Sub-module initialization**: `ModuleA.B` now properly initializes classes and imported modules when accessed. Previously, accessing a sub-module could skip initialization entirely.

2. **Wildcard import resolution**: `A.B` where `B` is wildcard-imported into module `A` now works correctly.

3. **Unset global safety**: Calling an unset global via a Module object now raises a proper error instead of crashing.

4. **Export conflict**: Fixed conflict between `global g` in a function and a prior `export global g` in the same module.

## GUI and Timer Fixes

**Windows 7 GUI fix**: Fixed GUI control sizing calculations that produced invalid values on Windows 7, causing a Critical Error dialog.

**Timer/MsgBox interaction**: Fixed timer threads interrupting MsgBox before the window is fully shown. Previously, a timer could fire in the gap between `MsgBox()` creation and display, potentially re-entering code unexpectedly.
