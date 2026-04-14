/*
Alpha25_Example.ahk -- AutoHotkey v2.1-alpha.25 feature showcase

Features demonstrated:
  1. ahk_opt -- inline WinTitle search options
  2. WinExist exclusion logic fixes
  3. DllCall safety: rejects array classes for return type
  4. Struct.Ptr.__Value consolidation
  5. Hotkey behavior fixes (key-up, neutral modifiers, SendLevel)
  6. Module system fixes
  7. GUI and timer fixes

Run: bin\AutoHotkey64.exe Alpha25_Example.ahk
*/
#Requires AutoHotkey v2.1-alpha.25

; AHK_OPT -- per-call window search options

; Find windows with inline options -- no global state changes.
; Options: Hidden, Hidden0, HiddenText, HiddenText0,
;          1, 2, 3, RegEx, Fast, Slow

; Find Notepad even if hidden, title match mode 2 (contains)
hwnd_notepad := WinExist("Notepad ahk_opt Hidden 2")

; Find taskbar via class (hidden by default)
hwnd_taskbar := WinExist("ahk_class Shell_TrayWnd ahk_opt Hidden")

; Combine ahk_exe with ahk_opt
hwnd_explorer := WinExist("ahk_exe explorer.exe ahk_opt Hidden RegEx")

; Global DetectHiddenWindows stays untouched
globalDHW := A_DetectHiddenWindows

; Enumerate hidden system windows without touching globals
hiddenWindows := []
for title in ["Program Manager", "MSCTFIME UI", "Default IME"] {
    hwnd := WinExist(title " ahk_opt Hidden 1")
    if hwnd
        hiddenWindows.Push({title: title, hwnd: hwnd})
}

hwnd_progman := WinExist("ahk_class Progman ahk_opt Hidden")
if hwnd_progman
    hiddenWindows.Push({title: "Progman class", hwnd: hwnd_progman})

; WINEXIST EXCLUSION FIXES

; Fix 1: ExcludeText no longer excludes controlless windows
; Fix 2: WinExist("", "Text") no longer reads all window titles
hwnd_active := WinExist("A")

; DLLCALL SAFETY

; Array class as return type -> proper error, not crash
; DllCall("SomeFunc", POINT[3])  ; TypeError in alpha.25

Struct POINT {
    x: i32
    y: i32
}

; STRUCT.PTR.__VALUE -- consolidated to base class

Struct Vec2 {
    x: Float32
    y: Float32
}

vec := Vec2()
vec.x := 10.5
vec.y := 20.5

; HOTKEY FIXES (behavioral, shown in comments)

; Key-up fires consistently as prefix+suffix:
;   LCtrl::Send "hello"
;   LCtrl up::ToolTip "up"
;
; Neutral modifiers in custom combos:
;   Alt & Esc::MsgBox "works"
;
; Key suppression respects SendLevel

; MODULE FIXES (requires separate module files)

; - ModuleA.B initializes classes on access
; - Wildcard imports resolve correctly in A.B
; - Unset globals via Module -> error, not segfault
; - global g / export global g conflict resolved

; GUI + TIMER FIXES

; - GUI control sizing fixed for Windows 7
; - Timer threads wait for MsgBox to fully display

; OUTPUT SUMMARY

stdout := FileOpen("*", "w", "UTF-8")
P(text := "") => stdout.Write(text "`n")

P "=== Alpha.25 Results ==="
P Format("Version: {}", A_AhkVersion)
P ""
P "── ahk_opt ──"
P Format("  Notepad (Hidden 2): {}", hwnd_notepad ? "found" : "not found")
P Format("  Taskbar (Hidden): {}",
    hwnd_taskbar ? Format("0x{:X}", hwnd_taskbar) : "not found")
P Format("  Explorer (Hidden RegEx): {}",
    hwnd_explorer ? Format("0x{:X}", hwnd_explorer) : "not found")
P Format("  DetectHiddenWindows unchanged: {}", globalDHW)
P ""
P Format("  Hidden system windows found: {}", hiddenWindows.Length)
for item in hiddenWindows
    P Format("    {} (0x{:X})", item.title, item.hwnd)
P ""
P "── WinExist ──"
P Format("  Active window: {}", hwnd_active ? Format("0x{:X}", hwnd_active) : "none")
P ""
P "── Struct.Ptr ──"
P Format("  Vec2({:.1f}, {:.1f})", vec.x, vec.y)
