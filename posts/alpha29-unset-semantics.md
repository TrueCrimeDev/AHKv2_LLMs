# AutoHotkey v2.1-alpha.29: When Nothing Is a Value

Alpha.29 shipped on May 10, 2026 (upstream tag `v2.1-alpha.29`). It is a small release with one theme: in v2.1 mode, "no value" is `unset`, not an empty string. The maybe operator `?` now short-circuits almost every operator, a function that has a `return expr` somewhere but falls off the end returns `unset`, a fat-arrow tail call passes a blank return through, and a long list of built-ins return `unset` where they used to hand back `""` or `0`.

None of that sounds like much until you write code against it. The point of `unset` is that it cannot be mistaken for data: an empty string is a perfectly good value, but `unset` either reaches a `??` or `IsSet`, or it throws at the line that tried to use it. Three scripts below, one per theme, each built around a pattern the change makes shorter. They run on the `2.1-alpha.37+Console` build and write to stdout with one line of plain AutoHotkey, `FileAppend(..., "*")`; everything in them is alpha.29 syntax, so nothing from later releases is used.

---

## 1. Optional values flow through operators

`var?` turns an unset variable into a sentinel instead of an error. What alpha.29 adds is reach: the sentinel passes through `*`, `>`, `.`, `||`, the ternary and the rest, turning the whole subexpression into `unset`, so you write the fallback once at the outside with `??`. The script uses that for optional parameters in arithmetic (`Scale`), optional limits in comparisons (`Over`), optional pieces of a string (`Label`) and an optional flag in a ternary (`Describe`), each as a one-line function with no `IsSet` branch.

Section 5 is the parser bug the release fixed: `(() => a? || 1)()` used to fail to load. Section 6 records the two things `?` still cannot do. It applies to a variable only, and the parser still has to decide whether a `?` opens a ternary: `missing? + 1` reads as `missing ? +1 : ...` and is rejected, and so was a `suffix? . ")"` I tried first. Writing the maybe as `(var?)` removes the ambiguity in every position, which is why section 3 does.

Before alpha.29, an unset operand inside `*` or `>` raised "This variable has not been assigned a value." even with the `?` present.

```ahk2
#Requires AutoHotkey v2.1-alpha.29
Echo(fmt, args*) => FileAppend(Format(fmt, args*) "`n", "*")   ; native stdout

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
Echo("Scale(10) = {}   Scale(10, 3) = {}", Scale(10), Scale(10, 3))

; --- 2. Optional limits in comparisons ------------------------------------------
; A missing limit means "no limit": the comparison is unset, so ?? false wins.
Over(spent, limit?) => (spent > limit?) ?? false
Echo("Over(120) = {}   Over(120, 100) = {}   Over(80, 100) = {}", Over(120), Over(120, 100), Over(80, 100))

; --- 3. Optional parts of a string ---------------------------------------------------
; The parenthesised piece is unset as a whole when suffix is, so nothing is
; appended rather than a stray " ()". (suffix?) is wrapped on purpose; see 6.
Label(name, suffix?) => name . ((" (" . (suffix?) . ")") ?? "")
Echo("{}  /  {}", Label("build"), Label("build", "release"))

; --- 4. Ternary and logical operators short-circuit too ------------------------------
Describe(flag?) => (flag? ? "on" : "off") ?? "unknown"
Echo("Describe() = {}   Describe(1) = {}   Describe(0) = {}", Describe(), Describe(1), Describe(0))
Echo("(missing? || 5) ?? 'unset' = {}", (missing? || 5) ?? "unset")

; --- 5. The IIFE that crashed the alpha.28 parser ----------------------------------------
; (() => a? || 1)() failed to parse before alpha.29. Now it evaluates, and the
; unset sentinel still propagates through || to the outer ??.
Echo("(() => zz? || 1)() ?? 'unset' = {}", (() => zz? || 1)() ?? "unset")

; --- 6. Two things ? does not do --------------------------------------------------------
; It applies to a variable, not to an expression: (a? + 1)? is a syntax error.
; And the parser still has to decide whether ? starts a ternary: `missing? + 1`
; (a ? +1 : ...) fails to load, and so did `suffix? . ")"` above. Wrapping
; the maybe as (var?) removes the ambiguity everywhere.
total := ((missing?) + 1) ?? 0
Echo("((missing?) + 1) ?? 0 = {}", total)
```

Source: [`01_maybe_operator.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha29/01_maybe_operator.ahk)

---

## 2. Functions that return nothing now say so

Two return-convention changes share a script. First, in v2.1 mode a function with at least one `return expr` that falls off the end returns `unset`, not `""`. `FindIndex` has no sentinel value: it returns an index or nothing, and the caller picks the fallback with `??`. Assigning the nothing is an `UnsetError` at that line, which is the feature: a forgotten branch surfaces where it happens instead of as an empty string three calls later.

Second, a fat-arrow tail call passes a blank-unset return through. `Forward(c) => c.Reset()` used to produce `""` whatever `Reset` did; now it produces nothing, through any depth of forwarding. Section 4 shows the limit I ran into: the propagation covers blank-unset only. The `unset` that `EvenOrUnset` returns by falling through counts as an explicit "no value", so `Wrap(n) => EvenOrUnset(n)` throws at its own expression, and the `??` belongs inside the wrapper. Section 5 confirms that a function with no `return expr` at all is unchanged.

Before alpha.29, `FindIndex` returned `""` on a miss and `Forward(c)` returned `""` always.

```ahk2
#Requires AutoHotkey v2.1-alpha.29
Echo(fmt, args*) => FileAppend(Format(fmt, args*) "`n", "*")   ; native stdout

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
Echo("first > 10 at index {}", FindIndex(nums, x => x > 10) ?? "none")
Echo("first > 50 at index {}", FindIndex(nums, x => x > 50) ?? "none")

; --- 2. Consuming an unset result -------------------------------------------------
; A plain assignment of nothing is an error, which is the point: the mistake
; surfaces where it happens instead of as an empty string three calls later.
try {
    idx := FindIndex(nums, x => x > 50)
    Echo("idx = {}", idx)
} catch UnsetError as e
    Echo("idx := FindIndex(...): {}", e.Message)

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
Echo("Forward(c) ?? 'nothing' = {}   n = {}", Forward(c) ?? "nothing", c.n)
c.Bump()
Echo("Chain(c) ?? 'nothing' = {}   n = {}", Chain(c) ?? "nothing", c.n)

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
    Echo("Wrap(5) = {}", Wrap(5) ?? "odd")
catch UnsetError as e
    Echo("Wrap(5): {}", e.Message)
SafeWrap(n) => EvenOrUnset(n) ?? "odd"
Echo("SafeWrap(4) = {}   SafeWrap(5) = {}", SafeWrap(4), SafeWrap(5))

; --- 5. Functions with no `return expr` are unchanged ---------------------------------------
; Only a bare return (or none): blank-unset as before. IsSet on a call is
; alpha.37 syntax, so test it the alpha.29 way, through ??.
Log(msg) {
    return
}
Echo("Log('x') ?? 'blank' = {}", Log("x") ?? "blank")
```

Source: [`02_unset_returns.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha29/02_unset_returns.ahk)

---

## 3. Built-ins that return `unset`

The broad part of the release is a pass over built-ins that used to return `""` or `0` for "nothing there". `ObjGetBase` and `.Base` return `unset` past `Any.Prototype`, so a prototype-chain walk is a `loop ... until !IsSet(p)` with no string compare. `RegExMatch` leaves its output variable unset on a miss, so a tokenizer tests `IsSet(m)` instead of `m[0] = ""`. `Array.RemoveAt`, `Pop` and `Delete` return `unset` for a hole (a `Pop` on an empty array still throws "Array is empty", which I checked). `GetMethod`, `DeleteProp` and `GetOwnPropDesc` return `unset` for a missing member, which makes `CallIfPresent` three lines. The Gui and Menu handle lookups, `Gui.MenuBar`, `Gui.FocusedCtrl`, `Gui[name]` and the `InputHook` handlers do the same; the script creates a `Gui` to read them but never shows it.

One idiom worth noting from sections 1 and 4: `p := ObjGetBase(p) ?? unset` is how you move an unset result into a local without throwing, so the next line can `IsSet` it.

Before alpha.29 these returned `""`, so the chain walk needed a `= ""` test and a regex miss looked like an empty match.

```ahk2
#Requires AutoHotkey v2.1-alpha.29
Echo(fmt, args*) => FileAppend(Format(fmt, args*) "`n", "*")   ; native stdout

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
Echo("chain: {}", Chain(Dog.Prototype))
Echo("Any.Prototype.Base ?? 'unset' = {}", Any.Prototype.Base ?? "unset")

; --- 2. A regex miss leaves the output variable unset ---------------------------------
; A tokenizer can test IsSet(m) instead of comparing m[0] against "".
NextNumber(text, &pos) {
    if RegExMatch(text, "\d+", &m, pos) {
        pos := m.Pos + m.Len
        return m[0]
    }
    Echo("  no match: IsSet(m) = {}", IsSet(m))
}
pos := 1
Echo("token: {}", NextNumber("a1b22c333", &pos) ?? "none")
Echo("token: {}", NextNumber("a1b22c333", &pos) ?? "none")
Echo("token: {}", NextNumber("a1b22c333", &pos) ?? "none")
Echo("token: {}", NextNumber("a1b22c333", &pos) ?? "none")

; --- 3. Removing a hole from an array -------------------------------------------------------
sparse := [1, , 3]                      ; element 2 is a hole
Echo("RemoveAt(2) on a hole = {}", sparse.RemoveAt(2) ?? "unset")
Echo("RemoveAt(1) on a value = {}", sparse.RemoveAt(1) ?? "unset")
holed := [1], holed.Length := 2         ; extend with a hole at the end
Echo("Pop() of a hole = {}   Pop() of a value = {}", holed.Pop() ?? "unset", holed.Pop() ?? "unset")

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
    Echo("{}: {}", Type(obj), CallIfPresent(obj, "Describe"))
o := {a: 1}
Echo("DeleteProp('a') = {}   DeleteProp('a') again = {}", o.DeleteProp("a") ?? "unset", o.DeleteProp("a") ?? "unset")
Echo("GetOwnPropDesc('b') = {}", o.GetOwnPropDesc("b") ?? "unset")

; --- 5. Handle lookups --------------------------------------------------------------------
; 0 is never a Gui, control or menu handle. Each lookup says so with unset.
Echo("GuiFromHwnd(0) = {}   GuiCtrlFromHwnd(0) = {}   MenuFromHandle(0) = {}", GuiFromHwnd(0) ?? "unset", GuiCtrlFromHwnd(0) ?? "unset", MenuFromHandle(0) ?? "unset")
g := Gui()                              ; created, never shown
Echo("g.MenuBar = {}   g.FocusedCtrl = {}   g['nope'] = {}", g.MenuBar ?? "unset", g.FocusedCtrl ?? "unset", g["nope"] ?? "unset")
ih := InputHook()
Echo("InputHook().OnEnd = {}", ih.OnEnd ?? "unset")
```

Source: [`03_builtins_unset.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha29/03_builtins_unset.ahk)

---

## Things I tripped over writing these

- **`??` needs a left side that can be unset.** `(b + 1) ?? 0` and `(!b) ?? a` are load errors ("Unexpected ?"), not no-ops.
- **`?` before `+` or `-` is a ternary to the parser.** `missing? + 1` fails to load; `(missing?) + 1` works. The same happened with `suffix? . ")"`. Parenthesise the maybe.
- **`?` is for variables.** `(expr)?` is a syntax error, so put the `??` outside and let the sentinel reach it.
- **Explicit unset is not forwarded by tail calls.** `Wrap(n) => EvenOrUnset(n)` throws when `EvenOrUnset` falls through; only a bare `return` propagates.
- **`Pop` on an empty array throws.** Only a hole returns `unset`; the script extends an array with `Length := 2` to make one.

---

## Running them

Every script starts with `#Requires AutoHotkey v2.1-alpha.29`, which is also what puts the file in v2.1 mode; the default-return and built-in changes apply only there.

```powershell
# stock AutoHotkey v2.1 alpha (GUI exe): pipe or redirect to see stdout
AutoHotkey64.exe 01_maybe_operator.ahk | more

# +Console fork: stdout is a real console stream
.\AutoHotkey64Console.exe 01_maybe_operator.ahk
```

`FileAppend` with `*` as the file name is AutoHotkey's native stdout; the stock GUI executable only shows it when its output is piped or redirected, so the `| more` is not optional there. Nothing in these scripts is fork-specific.

*Disclosure: Claude Fable 5.1 wrote the three scripts, ran them, and drafted this post. Every behaviour claim was observed on `2.1-alpha.37+Console` (`a911f73d`), which still runs alpha.29 syntax unchanged; the "before" statements come from the fork's alpha.29 release notes, not from a run on an older build.*
