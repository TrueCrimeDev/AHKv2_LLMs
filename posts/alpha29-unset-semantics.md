# AutoHotkey v2.1-alpha.29: When Nothing Is a Value

Alpha.29 (May 10, 2026) has one theme: in v2.1 mode "no value" is `unset`, not `""`. The maybe operator `?` short-circuits through almost every operator, a function that falls off the end after a `return expr` returns `unset`, fat-arrow tail calls pass a blank return through, and many built-ins return `unset` where they returned `""` or `0`.

**`Print` is a fork built-in**, not stock AutoHotkey. `Print("x = {}", x)` formats through `Format` and writes one line to stdout; a single argument is written as-is. On stock AutoHotkey add this line under `#Requires` and pipe through `| more`:

```ahk2
Print(fmt := "", args*) => FileAppend((args.Length ? Format(fmt, args*) : fmt) "`n", "*")
```

---

## 1. Optional values flow through operators

`var?` turns an unset variable into a sentinel, and alpha.29 lets that sentinel pass through `*`, `>`, `.`, `||` and the ternary, so one `??` at the outside covers the whole expression. The script writes `Scale`, `Over`, `Label` and `Describe` as one-liners with no `IsSet` branch, shows the fixed `(() => a? || 1)()` parser bug, and shows the limits: `?` applies to a variable only, and `missing? + 1` parses as a ternary, so write `(var?)`.

```ahk2
#Requires AutoHotkey v2.1-alpha.29

; alpha.29: the maybe operator (?) short-circuits most operators
;
; var? turns an unset variable into the unset sentinel instead of throwing.
; In alpha.29 that sentinel passes through arithmetic, comparison, string
; concatenation, logical and ternary operators: the whole subexpression
; becomes unset, and you supply the fallback once, at the boundary you
; control, with ??.
;
; Before alpha.29 only a few operators tolerated the sentinel; an unset
; operand inside * or > raised "This variable has not been assigned a value."

; --- 1. Optional parameters in arithmetic --------------------------------------
; factor is optional. If the caller omitted it, v * factor? is unset and ?? v
; returns the input unchanged. No IsSet, no second code path.
Scale(v, factor?) => (v * factor?) ?? v
Print("Scale(10) = {}   Scale(10, 3) = {}", Scale(10), Scale(10, 3))

; --- 2. Optional limits in comparisons ------------------------------------------
; A missing limit means "no limit": the comparison is unset, so ?? false wins.
Over(spent, limit?) => (spent > limit?) ?? false
Print("Over(120) = {}   Over(120, 100) = {}   Over(80, 100) = {}", Over(120), Over(120, 100), Over(80, 100))

; --- 3. Optional parts of a string ---------------------------------------------------
; The parenthesised piece is unset as a whole when suffix is, so nothing is
; appended rather than a stray " ()". (suffix?) is wrapped on purpose; see 6.
Label(name, suffix?) => name . ((" (" . (suffix?) . ")") ?? "")
Print("{}  /  {}", Label("build"), Label("build", "release"))

; --- 4. Ternary and logical operators short-circuit too ------------------------------
Describe(flag?) => (flag? ? "on" : "off") ?? "unknown"
Print("Describe() = {}   Describe(1) = {}   Describe(0) = {}", Describe(), Describe(1), Describe(0))
Print("(missing? || 5) ?? 'unset' = {}", (missing? || 5) ?? "unset")

; --- 5. The IIFE that crashed the alpha.28 parser ----------------------------------------
; (() => a? || 1)() failed to parse before alpha.29. Now it evaluates, and the
; unset sentinel still propagates through || to the outer ??.
Print("(() => zz? || 1)() ?? 'unset' = {}", (() => zz? || 1)() ?? "unset")

; --- 6. Two things ? does not do --------------------------------------------------------
; It applies to a variable, not to an expression: (a? + 1)? is a syntax error.
; And the parser still has to decide whether ? starts a ternary: `missing? + 1`
; (a ? +1 : ...) fails to load, and so did `suffix? . ")"` above. Wrapping
; the maybe as (var?) removes the ambiguity everywhere.
total := ((missing?) + 1) ?? 0
Print("((missing?) + 1) ?? 0 = {}", total)
```

Output:

```text
Scale(10) = 10   Scale(10, 3) = 30
Over(120) = 0   Over(120, 100) = 1   Over(80, 100) = 0
build  /  build (release)
Describe() = unknown   Describe(1) = on   Describe(0) = off
(missing? || 5) ?? 'unset' = unset
(() => zz? || 1)() ?? 'unset' = unset
((missing?) + 1) ?? 0 = 0
```

Source: [`01_maybe_operator.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha29/01_maybe_operator.ahk)

---

## 2. Functions that return nothing now say so

In v2.1 mode a function with a `return expr` somewhere that falls off the end returns `unset`, so `FindIndex` returns an index or nothing and the caller picks the fallback with `??`; assigning the nothing throws where it happens. A fat-arrow tail call such as `Forward(c) => c.Reset()` now passes a blank return through instead of producing `""`. Only a bare `return` propagates: `Wrap(n) => EvenOrUnset(n)` throws when the callee falls through, so the `??` belongs inside the wrapper.

```ahk2
#Requires AutoHotkey v2.1-alpha.29

; alpha.29: functions that return nothing now say so
;
; Two changes to return conventions in v2.1 mode:
;   1. A function with at least one `return expr` that falls off the end
;      returns unset, not "". Forgetting a branch becomes visible.
;   2. A fat-arrow tail call, f() => g(), passes g's blank-unset return
;      (a bare `return`, or no return at all) through instead of turning it
;      into "".
;
; Before alpha.29, FindIndex below returned "" on a miss and Forward()
; returned "" whatever Reset() did, so callers could not tell "no result"
; from "empty".

; --- 1. A finder with no sentinel value -------------------------------------------
; Returns the index, or nothing. The caller chooses the fallback with ??.
FindIndex(items, pred) {
    for i, item in items
        if pred(item)
            return i
    ; falls off the end: unset, because the function has a `return expr`
}
nums := [4, 9, 16, 23]
Print("first > 10 at index {}", FindIndex(nums, x => x > 10) ?? "none")
Print("first > 50 at index {}", FindIndex(nums, x => x > 50) ?? "none")

; --- 2. Consuming an unset result -------------------------------------------------
; A plain assignment of nothing is an error, which is the point: the mistake
; surfaces where it happens instead of as an empty string three calls later.
try {
    idx := FindIndex(nums, x => x > 50)
    Print("idx = {}", idx)
} catch UnsetError as e
    Print("idx := FindIndex(...): {}", e.Message)

; --- 3. Tail calls pass a blank return through -------------------------------------
class Counter {
    n := 0
    Reset() {
        this.n := 0
        return                      ; bare return: blank-unset
    }
    Bump() => ++this.n
}
Forward(c) => c.Reset()             ; alpha.29: also blank-unset, not ""
Chain(c) => Forward(c)              ; and so on through any depth
c := Counter()
c.Bump(), c.Bump()
Print("Forward(c) ?? 'nothing' = {}   n = {}", Forward(c) ?? "nothing", c.n)
c.Bump()
Print("Chain(c) ?? 'nothing' = {}   n = {}", Chain(c) ?? "nothing", c.n)

; --- 4. The limit: an explicit unset is not forwarded ----------------------------------
; Propagation covers blank-unset only. The unset that EvenOrUnset returns by
; falling through (section 1's rule) is an explicit "no value", so a fat-arrow
; wrapper around it throws at its own expression. Put the ?? inside the wrapper.
EvenOrUnset(n) {
    if Mod(n, 2) = 0
        return n
}
Wrap(n) => EvenOrUnset(n)
try
    Print("Wrap(5) = {}", Wrap(5) ?? "odd")
catch UnsetError as e
    Print("Wrap(5): {}", e.Message)
SafeWrap(n) => EvenOrUnset(n) ?? "odd"
Print("SafeWrap(4) = {}   SafeWrap(5) = {}", SafeWrap(4), SafeWrap(5))

; --- 5. Functions with no `return expr` are unchanged ---------------------------------------
; Only a bare return (or none): blank-unset as before. IsSet on a call is
; alpha.37 syntax, so test it the alpha.29 way, through ??.
Log(msg) {
    return
}
Print("Log('x') ?? 'blank' = {}", Log("x") ?? "blank")
```

Output:

```text
first > 10 at index 3
first > 50 at index none
idx := FindIndex(...): No value was returned.
Forward(c) ?? 'nothing' = nothing   n = 0
Chain(c) ?? 'nothing' = nothing   n = 0
Wrap(5): No value was returned.
SafeWrap(4) = 4   SafeWrap(5) = odd
Log('x') ?? 'blank' = blank
```

Source: [`02_unset_returns.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha29/02_unset_returns.ahk)

---

## 3. Built-ins that return `unset`

Built-ins that used to return `""` or `0` for "nothing there" now return `unset`: `ObjGetBase` and `.Base` past `Any.Prototype`, `RegExMatch`'s output variable on a miss, `RemoveAt`, `Pop` and `Delete` on a hole, `GetMethod`, `DeleteProp` and `GetOwnPropDesc` on a missing member, and the Gui, Menu and `InputHook` lookups. The script walks a prototype chain with `until !IsSet(p)`, tokenizes with `IsSet(m)`, and writes `CallIfPresent` in three lines. `p := ObjGetBase(p) ?? unset` moves an unset result into a local without throwing.

```ahk2
#Requires AutoHotkey v2.1-alpha.29

; alpha.29: built-ins return unset for "nothing there" in v2.1 mode
;
; ObjGetBase / .Base at the top of a chain, RegExMatch's output variable on
; no match, Array.Pop / RemoveAt / Delete on a hole, Object.DeleteProp /
; GetMethod / GetOwnPropDesc on a missing member, and the Gui / Menu handle
; lookups all return unset instead of "" or 0. "Is there one?" becomes
; IsSet or ??, with no sentinel to compare against.
;
; Before alpha.29 each of these returned "" (ObjGetBase, RegExMatch's
; variable, the handle lookups) or an empty value, so a loop over a
; prototype chain needed a `= ""` test and a regex miss looked like an
; empty match.

; --- 1. Walk a prototype chain to the top -------------------------------------------
class Animal {
}
class Dog extends Animal {
}
Chain(obj) {
    names := ""
    p := obj
    loop {
        names .= p.__Class " > "
        p := ObjGetBase(p) ?? unset         ; unset past Any.Prototype
    } until !IsSet(p)
    return RTrim(names, " >")
}
Print("chain: {}", Chain(Dog.Prototype))
Print("Any.Prototype.Base ?? 'unset' = {}", Any.Prototype.Base ?? "unset")

; --- 2. A regex miss leaves the output variable unset ---------------------------------
; A tokenizer can test IsSet(m) instead of comparing m[0] against "".
NextNumber(text, &pos) {
    if RegExMatch(text, "\d+", &m, pos) {
        pos := m.Pos + m.Len
        return m[0]
    }
    Print("  no match: IsSet(m) = {}", IsSet(m))
}
pos := 1
Print("token: {}", NextNumber("a1b22c333", &pos) ?? "none")
Print("token: {}", NextNumber("a1b22c333", &pos) ?? "none")
Print("token: {}", NextNumber("a1b22c333", &pos) ?? "none")
Print("token: {}", NextNumber("a1b22c333", &pos) ?? "none")

; --- 3. Removing a hole from an array -------------------------------------------------------
sparse := [1, , 3]                      ; element 2 is a hole
Print("RemoveAt(2) on a hole = {}", sparse.RemoveAt(2) ?? "unset")
Print("RemoveAt(1) on a value = {}", sparse.RemoveAt(1) ?? "unset")
holed := [1], holed.Length := 2         ; extend with a hole at the end
Print("Pop() of a hole = {}   Pop() of a value = {}", holed.Pop() ?? "unset", holed.Pop() ?? "unset")

; --- 4. Object reflection without sentinels ------------------------------------------------
class Plain {
}
class Loud {
    Describe() => "I can describe myself"
}
; Call a method if the object has one. GetMethod returns unset otherwise, and
; ?? unset carries that into a local the next line can test.
CallIfPresent(obj, name) {
    m := obj.GetMethod(name) ?? unset
    return IsSet(m) ? m(obj) : "(no " name ")"
}
for obj in [Plain(), Loud()]
    Print("{}: {}", Type(obj), CallIfPresent(obj, "Describe"))
o := {a: 1}
Print("DeleteProp('a') = {}   DeleteProp('a') again = {}", o.DeleteProp("a") ?? "unset", o.DeleteProp("a") ?? "unset")
Print("GetOwnPropDesc('b') = {}", o.GetOwnPropDesc("b") ?? "unset")

; --- 5. Handle lookups --------------------------------------------------------------------
; 0 is never a Gui, control or menu handle. Each lookup says so with unset.
Print("GuiFromHwnd(0) = {}   GuiCtrlFromHwnd(0) = {}   MenuFromHandle(0) = {}", GuiFromHwnd(0) ?? "unset", GuiCtrlFromHwnd(0) ?? "unset", MenuFromHandle(0) ?? "unset")
g := Gui()                              ; created, never shown
Print("g.MenuBar = {}   g.FocusedCtrl = {}   g['nope'] = {}", g.MenuBar ?? "unset", g.FocusedCtrl ?? "unset", g["nope"] ?? "unset")
ih := InputHook()
Print("InputHook().OnEnd = {}", ih.OnEnd ?? "unset")
```

Output:

```text
chain: Dog > Animal > Object > Any
Any.Prototype.Base ?? 'unset' = unset
token: 1
token: 22
token: 333
  no match: IsSet(m) = 0
token: none
RemoveAt(2) on a hole = unset
RemoveAt(1) on a value = 1
Pop() of a hole = unset   Pop() of a value = 1
Plain: (no Describe)
Loud: I can describe myself
DeleteProp('a') = 1   DeleteProp('a') again = unset
GetOwnPropDesc('b') = unset
GuiFromHwnd(0) = unset   GuiCtrlFromHwnd(0) = unset   MenuFromHandle(0) = unset
g.MenuBar = unset   g.FocusedCtrl = unset   g['nope'] = unset
InputHook().OnEnd = unset
```

Source: [`03_builtins_unset.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha29/03_builtins_unset.ahk)

---

## Things I tripped over writing these

- `??` needs a left side that can be unset: `(b + 1) ?? 0` is a load error.
- `missing? + 1` parses as a ternary; write `(missing?) + 1`.
- `Pop` on an empty array still throws; only a hole returns `unset`.

---

## Running them

`#Requires AutoHotkey v2.1-alpha.29` on every script. That line also selects v2.1 mode. Fork: run as-is. Stock: add the `Print` line and pipe through `| more`.

```powershell
# +Console fork
.\bin\AutoHotkey64Console.exe 01_maybe_operator.ahk

# stock AutoHotkey v2.1-alpha.29 or later (GUI exe), with the Print line added
AutoHotkey64.exe 01_maybe_operator.ahk | more
```

*Scripts and text by Claude Fable 5.1, run on `2.1-alpha.37+Console` (`a911f73d`); "before" behaviour from the fork's release notes.*
