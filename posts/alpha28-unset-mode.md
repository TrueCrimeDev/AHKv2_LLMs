# AutoHotkey v2.1-alpha.28: `#Requires` Decides What "Nothing" Means

Alpha.28 (April 26, 2026) makes `#Requires AutoHotkey v2.1-alpha.X` select v2.1 mode: a bare `return`, falling off the end of a function, and built-ins with nothing to report yield no value (unset) instead of `""`, and `#DefaultReturn` is gone. Also: empty `Map` and `Array` slots raise `UnsetItemError`, a struct class's `Prototype` is read-only, `StructClass.At` accepts a fieldless struct, and `ByRef` recursion and `OnMessage` returns are fixed.

**`Print` is a fork built-in**, not stock AutoHotkey. `Print("x = {}", x)` formats through `Format` and writes one line to stdout; a single argument is written as-is. On stock AutoHotkey add this line under `#Requires` and pipe through `| more`:

```ahk2
Print(fmt := "", args*) => FileAppend((args.Length ? Format(fmt, args*) : fmt) "`n", "*")
```

---

## 1. Nothing is not the empty string

In v2.1 mode `FindFirst` returns unset when nothing matches, so the caller writes `FindFirst(...) ?? "none"` and an empty-string setting no longer collides with "no such setting". Using nothing is an error: `v := Bare()` and `r := FileAppend(...)` throw `UnsetError`, while `FileAppend(...) ?? "ok"` is fine and `InStr` still returns 0. The mode is per file: a `#Requires AutoHotkey v2.0` file keeps `""`, and an included v2.1 file does not change its includer.

```ahk2
#Requires AutoHotkey v2.1-alpha.28

; alpha.28: the #Requires line above puts this file in v2.1 mode. In v2.1
; mode a bare `return`, falling off the end of a function, and every built-in
; that has nothing to say all produce *no value* (unset) instead of "".
; "No value" and "empty string" are different things now, and ?? tells them
; apart in one token.
; Before alpha.28 the same switch needed the separate #DefaultReturn unset
; directive, which is gone; a #Requires AutoHotkey v2.0 file keeps "" instead.

; --- 1. A finder that returns nothing, not a sentinel -------------------------------
FindFirst(items, pred) {
    for item in items
        if pred(item)
            return item
    ; falling off the end returns unset in v2.1 mode
}
nums := [4, 9, 16, 23]
Print("first > 10: {}", FindFirst(nums, x => x > 10) ?? "none")
Print("first > 50: {}", FindFirst(nums, x => x > 50) ?? "none")

; --- 2. The empty string is a real result now ------------------------------------------
; A lookup whose value is "" is distinguishable from a lookup that found nothing.
settings := Map("name", "", "retries", 3)
Lookup(key) {
    if settings.Has(key)
        return settings[key]
}
Print("name: '{}'   missing: '{}'", Lookup("name") ?? "(unset)", Lookup("missing") ?? "(unset)")

; --- 3. Using nothing is an error, not a silent "" ------------------------------------
Bare() {
    return
}
try v := Bare()
catch UnsetError as e
    Print("v := Bare() -> {}: {}", Type(e), e.Message)

; --- 4. Built-ins follow the same rule -------------------------------------------------
; FileAppend returns nothing. In v2.0 mode that was ""; here it is unset.
try r := FileAppend("", "*")
catch UnsetError as e
    Print("r := FileAppend(...) -> {}", e.Message)
Print("FileAppend(...) ?? 'ok' = {}", FileAppend("", "*") ?? "ok")
; Functions with a real "not found" value are unchanged: InStr still returns 0.
Print("InStr('abc', 'z') = {}", InStr("abc", "z"))
```

Output:

```text
first > 10: 16
first > 50: none
name: ''   missing: '(unset)'
v := Bare() -> UnsetError: No value was returned.
r := FileAppend(...) -> No value was returned.
FileAppend(...) ?? 'ok' = ok
InStr('abc', 'z') = 0
```

Source: [`01_unset_not_empty.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha28/01_unset_not_empty.ahk)

---

## 2. `UnsetItemError`: an empty slot is its own error

`[1, unset, 3]` has a hole: `Has(2)` is 0, `slots[2]` throws `UnsetItemError` "Item has no value.", `slots[2] ?? "free"` reads a default, and a missing `Map` key raises the same error. `Describe` catches `UnsetItemError`, then `UnsetError` for a never-assigned variable, then `IndexError`; since `UnsetItemError` extends `UnsetError`, an old broad catch still works. Before alpha.28 a hole and an unassigned variable were the same `UnsetError`.

```ahk2
#Requires AutoHotkey v2.1-alpha.28

; alpha.28: reading a Map key or Array index that has no value raises
; UnsetItemError, a subclass of UnsetError, so a handler can tell "this slot
; is empty" from "this variable was never assigned" and from "that index is
; out of range" (still IndexError).
; Before alpha.28 the empty-slot case raised the generic UnsetError.

; --- 1. A sparse array of slots -----------------------------------------------------
slots := [1, unset, 3]
Print("Length {}  Has(1) {}  Has(2) {}", slots.Length, slots.Has(1), slots.Has(2))
try v := slots[2]
catch UnsetItemError as e
    Print("slots[2] -> {}: {}", Type(e), e.Message)
try v := slots[9]
catch IndexError as e
    Print("slots[9] -> {}: {}", Type(e), e.Message)
Print("slots[2] ?? 'free' = {}", slots[2] ?? "free")

; --- 2. One handler, three different situations ---------------------------------------
Describe(fn) {
    try
        return "value " fn()
    catch UnsetItemError as e
        return "empty slot (" e.Message ")"
    catch UnsetError as e
        return "unset variable (" StrSplit(e.Message, "`n")[1] ")"
    catch IndexError as e
        return "bad index (" e.Message ")"
}
ReadUnset(assign := false) {
    if assign
        v := 1
    return v                           ; plain UnsetError: a variable, not an item
}
m := Map("a", 1)
Print("m['a']  : {}", Describe(() => m["a"]))
Print("m['zz'] : {}", Describe(() => m["zz"]))
Print("slots[2]: {}", Describe(() => slots[2]))
Print("slots[0]: {}", Describe(() => slots[0]))
Print("variable: {}", Describe(ReadUnset))

; --- 3. Assigning unset to a Map key removes it ----------------------------------------
m["b"] := 2
Print("Count {} after adding b", m.Count)
m["b"] := unset
Print("Count {} Has(b) {} after m['b'] := unset", m.Count, m.Has("b"))

; --- 4. The hierarchy, so a broad catch still works ---------------------------------------
Print("UnsetItemError extends UnsetError: {}", UnsetItemError.Prototype.Base = UnsetError.Prototype)
try v := slots[2]
catch UnsetError as e
    Print("caught as UnsetError: {}", Type(e))
```

Output:

```text
Length 3  Has(1) 1  Has(2) 0
slots[2] -> UnsetItemError: Item has no value.
slots[9] -> IndexError: Invalid index.
slots[2] ?? 'free' = free
m['a']  : value 1
m['zz'] : empty slot (Item has no value.)
slots[2]: empty slot (Item has no value.)
slots[0]: bad index (Invalid index.)
variable: unset variable (This local variable has not been assigned a value.)
Count 2 after adding b
Count 1 Has(b) 0 after m['b'] := unset
UnsetItemError extends UnsetError: 1
caught as UnsetError: UnsetItemError
```

Source: [`02_unset_item_error.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha28/02_unset_item_error.ahk)

---

## 3. A fieldless struct as an opaque handle

`StructClass.Prototype` is read-only now; assigning it used to be silently ignored. `StructClass.At(ptr)` accepts a fieldless struct, so `Window` with `Size` 0 wraps `A_ScriptHwnd` as a typed handle that satisfies `is Window` and answers `Class` and `Title`, where alpha.27 threw "Invalid class". The last section reads and writes through `RECT2.At(buf.Ptr)` over a nested `POINT`, which an alpha.27 commit had broken.

```ahk2
#Requires AutoHotkey v2.1-alpha.28

; alpha.28, two struct changes:
;   StructClass.Prototype is read-only. A struct class keeps a direct
;   pointer to its prototype, so reassigning it was never honoured.
;   StructClass.At(ptr) works on a struct with no fields, which makes a
;   fieldless struct a typed, opaque handle: the address is the value.
; Also fixed: StructClass.At on a struct that contains a nested struct,
; which alpha.27 broke (6979d3ad).

; --- 1. Prototype cannot be swapped ----------------------------------------------------
struct POINT {
    x : Int32
    y : Int32
}
try POINT.Prototype := Object()
catch Error as e
    Print("POINT.Prototype := Object() -> {}", e.Message)

; --- 2. A fieldless struct as an opaque handle ---------------------------------------------
; Window handles are integers that are easy to mix up with other integers.
; A zero-field struct gives them a type, a place for methods, and no data.
struct Window {
    Title => WinGetTitle("ahk_id " this.Ptr)
    Class => WinGetClass("ahk_id " this.Ptr)
}
DetectHiddenWindows(true)
w := Window.At(A_ScriptHwnd)
Print("Window size {}  Ptr matches A_ScriptHwnd: {}  Type {}", w.Size, w.Ptr = A_ScriptHwnd, Type(w))
Print("class {}", w.Class)
Print("is Window: {}   is Struct: {}", w is Window, w is Struct)

; --- 3. A view over memory that contains a nested struct ------------------------------
struct RECT2 {
    tl : POINT
    br : POINT
}
buf := Buffer(16)
NumPut("Int", 10, "Int", 20, "Int", 110, "Int", 220, buf)
view := RECT2.At(buf.Ptr)
Print("view: ({},{})-({},{})  width {}", view.tl.x, view.tl.y, view.br.x, view.br.y, view.br.x - view.tl.x)
view.br.x := 500                      ; writes through to the buffer
Print("buffer now holds br.x = {}", NumGet(buf, 8, "Int"))
```

Output:

```text
POINT.Prototype := Object() -> Property is read-only.
Window size 0  Ptr matches A_ScriptHwnd: 1  Type Window
class AutoHotkey
is Window: 1   is Struct: 1
view: (10,20)-(110,220)  width 100
buffer now holds br.x = 500
```

Source: [`03_struct_prototype_and_views.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha28/03_struct_prototype_and_views.ahk)

---

## 4. `ByRef` through recursion, and declining a message

`Increment(&val, limit)` recurses with the same alias; a global now stays aliased through every level (`counter` ends at 3), where alpha.27 could back it up like a local and leave it unset. `Observer` declines a message with a bare `return`, which alpha.28 treats as pass-through, so `Responder` answers 42 for a ping of 21; with `Responder` unregistered the message falls through to default handling and returns 0.

```ahk2
#Requires AutoHotkey v2.1-alpha.28

; alpha.28, two correctness fixes that matter in ordinary scripts:
;   A ByRef parameter aliasing a *global* stays aliased through recursion.
;   Before, a recursive call could back the alias up as if it were a local
;   and the global looked unset on return.
;   An OnMessage callback that returns unset (the v2.1 default for a bare
;   return) behaves as if it returned "": the message passes on to the next
;   callback and then to default handling, instead of raising an error.

; --- 1. A global counter threaded through recursion by reference -----------------------
global counter := 0
Increment(&val, limit) {
    val += 1
    if val < limit
        Increment(&val, limit)      ; same alias, same global
}
Increment(&counter, 3)
Print("counter = {} after Increment(&counter, 3)", counter)

; A local works the same way, which is the point: one rule for both.
total := 0
Increment(&total, 5)
Print("total = {} after Increment(&total, 5)", total)

; --- 2. OnMessage callbacks that decline a message ----------------------------------------
WM_APP_PING := 0x8001
Observer(wParam, lParam, msg, hwnd) {
    Print("  observer saw ping {}", wParam)
    ; bare return: unset in v2.1 mode, treated as "" -> pass the message on
    return
}
Responder(wParam, lParam, msg, hwnd) {
    Print("  responder answers ping {}", wParam)
    return wParam * 2                  ; a value stops the chain and is the result
}
OnMessage(WM_APP_PING, Observer)
OnMessage(WM_APP_PING, Responder)
reply := SendMessage(WM_APP_PING, 21, 0, , A_ScriptHwnd)
Print("SendMessage returned {}", reply)

; Only the observer registered: the message falls through to default handling.
OnMessage(WM_APP_PING, Responder, 0)
reply := SendMessage(WM_APP_PING, 7, 0, , A_ScriptHwnd)
Print("without a responder SendMessage returned {}", reply)
```

Output:

```text
counter = 3 after Increment(&counter, 3)
total = 5 after Increment(&total, 5)
  observer saw ping 21
  responder answers ping 21
SendMessage returned 42
  observer saw ping 7
without a responder SendMessage returned 0
```

Source: [`04_byref_and_onmessage.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha28/04_byref_and_onmessage.ahk)

---

## Things I tripped over writing these

- **`v := f()` throws when `f` returns nothing.** Test with `??` or catch `UnsetError`.
- **A never-assigned variable is a load-time warning.** Script 2 assigns it on a dead branch so only the runtime `UnsetError` fires.
- **`m[key] := unset` deletes the key.** A `Map` raises `UnsetItemError` only for keys that do not exist.

---

## Running them

`#Requires AutoHotkey v2.1-alpha.28` on every script. That line also selects v2.1 mode. Fork: run as-is. Stock: add the `Print` line and pipe through `| more`.

```powershell
# +Console fork
.\bin\AutoHotkey64Console.exe 01_unset_not_empty.ahk

# stock AutoHotkey v2.1-alpha.28 or later (GUI exe), with the Print line added
AutoHotkey64.exe 01_unset_not_empty.ahk | more
```

*Scripts and text by Claude Fable 5.1, run on `2.1-alpha.37+Console` (`a911f73d`); "before" behaviour from the fork's release notes.*
