# Customizing TapHoldManager.ahk

TapHoldManager is a powerful library that enables you to create sophisticated key behaviors beyond simple hotkeys. It distinguishes between taps, holds, multi-taps, and tap-and-hold combinations.

## What is TapHoldManager?

TapHoldManager lets you define multiple actions for a single key:

- **Tap:** Quick press and release
- **Hold:** Press and hold for a duration
- **Multi-Tap:** Multiple quick taps (double-tap, triple-tap)
- **Tap-and-Hold:** Quick taps followed by a hold

## Basic Setup

```cpp
#Requires AutoHotkey v2.0
#Include TapHoldManager.ahk

thm := TapHoldManager()
thm.Add("F1", KeyHandler)

KeyHandler(isHold, taps, state) {
    if isHold {
        ToolTip("Holding F1 - State: " state)
        if state = 0
            ToolTip()
    } else {
        ToolTip("Tapped F1 " taps " time(s)")
        SetTimer(() => ToolTip(), -1000)
    }
}
```

## Understanding the Callback Parameters

```cpp
MyHandler(isHold, taps, state) {
    ; isHold: true = hold action, false = tap action
    ; taps:   number of taps (1 = single, 2 = double, etc.)
    ; state:  1 = key down, 0 = key up (for holds)
}
```

## Configuration Options

```cpp
thm := TapHoldManager(
    150,    ; tapTime - max time for a tap (ms)
    150,    ; holdTime - min time to trigger hold (ms)
    3,      ; maxTaps - max consecutive taps to track
    50,     ; prefixTime - window for prefix keys (ms)
    true    ; $prefix - use $ prefix for hotkeys
)
```

## Practical Examples

### Media Key Behavior

Single tap for play/pause, hold for stop:

```cpp
thm := TapHoldManager()
thm.Add("F8", MediaControl)

MediaControl(isHold, taps, state) {
    if isHold && state = 1
        Send("{Media_Stop}")
    else if !isHold
        Send("{Media_Play_Pause}")
}
```

### Multi-Function Escape Key

Different actions based on tap count:

```cpp
thm := TapHoldManager(, , 3)
thm.Add("Escape", EscapeHandler)

EscapeHandler(isHold, taps, state) {
    if isHold && state = 1 {
        WinClose("A")
        return
    }

    if !isHold {
        switch taps {
            case 1: Send("{Escape}")
            case 2: Send("^w")
            case 3: WinMinimize("A")
        }
    }
}
```

### Window Management

CapsLock as a window management key:

```cpp
thm := TapHoldManager(200, 300, 2)
thm.Add("CapsLock", WindowManager)

WindowManager(isHold, taps, state) {
    if isHold {
        if state = 1
            Send("#Tab")
        return
    }

    switch taps {
        case 1: Send("!{Escape}")
        case 2:
            if WinGetMinMax("A") = 1
                WinRestore("A")
            else
                WinMaximize("A")
    }
}
```

## Advanced: Tap-and-Hold Combinations

```cpp
thm := TapHoldManager(150, 200, 3)
thm.Add("Space", SpaceCombo)

SpaceCombo(isHold, taps, state) {
    ; Tap-tap-hold pattern
    if isHold && taps = 2 && state = 1 {
        ToolTip("Double-tap-hold detected!")
        return
    }

    ; Tap-hold pattern
    if isHold && taps = 1 && state = 1 {
        Send("+{Right}")
        return
    }

    if isHold && state = 0 {
        ToolTip()
        return
    }

    if !isHold
        Send("{Space " taps "}")
}
```

## Per-Key Options

Override global settings for specific keys:

```cpp
thm := TapHoldManager(150, 150, 3)

; F1 with custom hold time of 500ms
thm.Add("F1", F1Handler, 500)

; F2 with custom tap time and hold time
thm.Add("F2", F2Handler, 300, 400)
```

## Integration with Classes

```cpp
class HotkeyManager {
    __New() {
        this.thm := TapHoldManager()
        this.RegisterHotkeys()
    }

    RegisterHotkeys() {
        this.thm.Add("F1", this.OnF1.Bind(this))
        this.thm.Add("F2", this.OnF2.Bind(this))
    }

    OnF1(isHold, taps, state) {
        if isHold && state = 1
            this.ShowHelp()
        else if !isHold && taps = 1
            this.QuickAction()
    }

    ShowHelp() {
        MsgBox("Help content here")
    }

    QuickAction() {
        MsgBox("Quick action triggered")
    }
}

manager := HotkeyManager()
```

## Best Practices

### Immediate vs Delayed Actions

```cpp
Handler(isHold, taps, state) {
    if isHold {
        if state = 1
            StartDragging()  ; Immediate
        else
            StopDragging()   ; On release
    }
}
```

### Preventing Native Key Action

```cpp
; By default, native key action is blocked
thm.Add("CapsLock", Handler)

; Use ~ prefix to allow native action
thm.Add("~Space", Handler)
```

## Key Takeaway

TapHoldManager transforms simple keys into multi-function power tools. Start with basic tap/hold patterns and gradually add complexity. Timing thresholds that feel natural are key to good UX.
