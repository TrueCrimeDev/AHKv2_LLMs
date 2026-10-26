# AutoHotkey v2.1-alpha.28: `#Requires` Decides What "Nothing" Means

Alpha.28 shipped on April 26, 2026 (upstream tag `v2.1-alpha.28`). Its headline is a mode switch that most scripts will flip without noticing: `#Requires AutoHotkey v2.1-alpha.X` now puts the file into v2.1 mode, where a bare `return`, falling off the end of a function, and every built-in with nothing to report produce *no value* (unset) instead of an empty string. The separate `#DefaultReturn` directive is gone. Alongside that, reading an empty `Map` or `Array` slot raises `UnsetItemError`, a struct class's `Prototype` is read-only, `StructClass.At` accepts a struct with no fields, and two correctness bugs around `ByRef` recursion and `OnMessage` return values are fixed.

Four scripts, one theme each. The first is about telling "nothing" from `""` with `??`. The second builds a sparse-slot array and a handler that distinguishes an empty item from an unset variable from a bad index. The third turns a fieldless struct into a typed window handle and uses a struct view over a buffer that contains a nested struct, which alpha.27 had broken. The fourth threads a global through recursion by reference and shows an `OnMessage` callback declining a message with a bare `return`. All four run with exit 0 on the `2.1-alpha.37+Console` build; the comments say what alpha.27 did instead.

**About `Print`.** The scripts write their output with `Print`, which is not stock AutoHotkey: it is a built-in of the [+Console fork](https://github.com/TrueCrimeDev/AutoHotkey). `Print("x = {}, y = {}", x, y)` runs its arguments through `Format` and writes the result plus a newline to stdout; a single argument is written as-is, and `Print()` writes a blank line. To run the scripts on stock AutoHotkey, add this one line under `#Requires` (it reproduces those three shapes) and pipe the output through `| more`, because the GUI executable only shows stdout when it is redirected:

```ahk2
Print(fmt := "", args*) => FileAppend((args.Length ? Format(fmt, args*) : fmt) "`n", "*")
```

---

## 1. Nothing is not the empty string

The `#Requires` line at the top of the script is the whole configuration. In v2.1 mode `FindFirst` returns unset when the loop finds nothing, and the caller writes `FindFirst(...) ?? "none"`. The `Lookup` function shows why that matters: a setting whose value is the empty string is a real answer, and it no longer collides with "no such setting".

The other half of the change is that using nothing is an error. `v := Bare()` throws `UnsetError` "No value was returned." rather than quietly storing `""`, and built-ins follow the same rule: `r := FileAppend(...)` throws the same way, while `FileAppend(...) ?? "ok"` is fine. Functions with a real not-found value are untouched, so `InStr` still returns 0.

Before alpha.28 the same semantics needed `#DefaultReturn unset`, which no longer parses; a file that says `#Requires AutoHotkey v2.0` keeps the empty-string behaviour, and the mode is scoped per file, so an included v2.1 file does not change its includer.

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

Source: [`01_unset_not_empty.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha28/01_unset_not_empty.ahk)

---

## 2. `UnsetItemError`: an empty slot is its own error

`[1, unset, 3]` is a three-element array with a hole in the middle. `Has(2)` is 0, reading `slots[2]` throws `UnsetItemError` "Item has no value.", and `slots[2] ?? "free"` reads the hole as a default. An index outside the array is still `IndexError`. A missing `Map` key raises the same `UnsetItemError`, so one `catch` covers both containers.

The `Describe` function in the script is the pattern: `catch UnsetItemError` first, `catch UnsetError` second for a variable that was never assigned, `catch IndexError` for a bad index. Because `UnsetItemError` extends `UnsetError`, an existing broad `catch UnsetError` still catches it, which the last section demonstrates. One more observation from the script: assigning `unset` to an existing `Map` key removes it, so `Count` drops and `Has` is 0 afterwards.

Before alpha.28 an empty item raised the generic `UnsetError`, so a handler could not tell a hole in a container from a variable it forgot to assign.

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

Source: [`02_unset_item_error.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha28/02_unset_item_error.ahk)

---

## 3. A fieldless struct as an opaque handle

`StructClass.Prototype` is read-only in alpha.28 because a struct class keeps a direct pointer to its prototype and never consulted the property bag; the assignment used to be accepted and ignored, now it throws "Property is read-only."

The more useful change is that `StructClass.At(ptr)` accepts a struct with no fields. A zero-field struct has `Size` 0 and carries nothing but an address, which makes it a typed handle: the `Window` struct wraps `A_ScriptHwnd`, satisfies `is Window` and `is Struct`, and answers `Class` and `Title` through ordinary properties, while a bare integer would have none of that. The last section uses a view the other way round, `RECT2.At(buf.Ptr)` over a buffer that holds a nested `POINT`, reading through the nested fields and writing `br.x` back into the buffer. That case was broken by an alpha.27 commit (`6979d3ad`) and is fixed here.

Before alpha.28 `Handle.At(ptr)` on a fieldless struct threw "Invalid class", and `RECT2.At` on a struct with a nested field read the wrong memory.

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

Source: [`03_struct_prototype_and_views.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha28/03_struct_prototype_and_views.ahk)

---

## 4. `ByRef` through recursion, and declining a message

`Increment(&val, limit)` calls itself with the same alias. When the alias points at a global, alpha.28 keeps it pointing there through every level, so `counter` is 3 afterwards; a local goes through the same path and ends at 5. The script prints both because the fix is exactly that there is now one rule for both kinds of variable.

The `OnMessage` half pairs with the v2.1 default return. `Observer` ends with a bare `return`, which is unset in v2.1 mode; alpha.28 treats that as `""` in an `OnMessage` callback, so the message passes to `Responder`, whose numeric return ends the chain and becomes the `SendMessage` result (42 for a ping of 21). With `Responder` unregistered the observer still runs and the message falls through to default handling, which returns 0.

Before alpha.28 a recursive call could back up the global alias as if it were a local and the global appeared unset on return, and an unset return from an `OnMessage` callback did not behave as pass-through.

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

Source: [`04_byref_and_onmessage.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha28/04_byref_and_onmessage.ahk)

---

## Things I tripped over writing these

- **`v := f()` is an error when `f` returns nothing.** The first draft of script 1 assigned the result of `FileAppend` to show it was unset; in v2.1 mode that assignment itself throws. Test for nothing with `??`, or catch `UnsetError`.
- **A never-assigned variable is a load-time warning.** `() => neverAssigned` makes stock AutoHotkey show a `#Warn VarUnset` dialog before the script runs. Script 2 assigns the variable on a branch that never executes, so the warning is silent and the runtime `UnsetError` still fires.
- **`m[key] := unset` deletes the key.** It does not leave an empty item behind, so there is no way to make a `Map` raise `UnsetItemError` for a key that exists; the error is for keys that do not.

---

## Running them

Every script starts with `#Requires AutoHotkey v2.1-alpha.28`. That line is also what selects v2.1 mode. On the +Console fork they run as they are; on stock AutoHotkey add the `Print` line from the top of this post and pipe through `| more`.

```powershell
# +Console fork
.\bin\AutoHotkey64Console.exe 01_unset_not_empty.ahk

# stock AutoHotkey v2.1-alpha.28 or later (GUI exe), with the Print line added
AutoHotkey64.exe 01_unset_not_empty.ahk | more
```

*Disclosure: Claude Fable 5.1 wrote the four scripts, ran them, and drafted this post. Every behaviour claim was observed on `2.1-alpha.37+Console` (`a911f73d`); the alpha.27 comparisons come from the alpha.28 commit history, not from running an alpha.27 engine.*
