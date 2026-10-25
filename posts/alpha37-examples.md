# AutoHotkey v2.1-alpha.37: Five Scripts for the New Syntax

Alpha.37 landed on October 25, 2026. It is a DllCall and Struct release: `unset` is a null pointer for `Str` and pointer parameters, a struct class takes its field values as constructor arguments, `IsSet` accepts a property or a call without a written `?`, `Struct.At` works on `Struct` itself, and a numeric struct instance passes its value to C. Five crashes or silent memory writes became catchable errors.

The release notes list those changes one line each. This post takes a different angle: five short scripts, one per change, each built around something the change makes *pleasant* rather than merely possible. Every script runs with exit 0 on the `2.1-alpha.37+Console` build and prints what the engine does; the comments record what alpha.36 did instead. The tested files live in the fork repository under [`examples/alpha37/`](https://github.com/TrueCrimeDev/AutoHotkey/tree/alpha/examples/alpha37).

One caveat up front. The forum announcement went out before the `v2.1-alpha.37` tag was pushed, so as of writing the only build that runs these scripts is the [+Console fork](https://github.com/TrueCrimeDev/AutoHotkey), built from upstream commit `279247ee` plus fixes for five regressions the alpha.37 commits introduced. Script 5 shows one of those fixes, and the section says so.

---

## 1. Struct literals: `POINT(10, 20)`

`Struct.Prototype.__New(fieldValues*)` is the change most people will feel first. Calling a struct class with arguments fills its fields in declaration order, so a `POINT` or `RECT` is one expression instead of four assignment lines. The count must match exactly, and a script-defined `__New` can delegate to `super.__New` to validate or normalize before storing.

The interesting consequence is that structs stop needing names. A `POINT` built inside a `DllCall` argument list is passed to `PtInRect` by value and discarded. A table of corners is a single array literal. And `Span(90, 30)` stores `30..90` because its constructor sorts the arguments on the way through `super.__New`.

Before alpha.37, `POINT(10, 20)` threw "Too many parameters passed to function."

```ahk2
#Requires AutoHotkey v2.1-alpha.37

struct POINT {
    x : Int32
    y : Int32
}

struct RECT {
    left   : Int32
    top    : Int32
    right  : Int32
    bottom : Int32
}

; --- 1. Literals -------------------------------------------------------------
pt := POINT(10, 20)
rc := RECT(0, 0, 100, 50)
Print("POINT({}, {})  RECT({}, {}, {}, {})", pt.x, pt.y, rc.left, rc.top, rc.right, rc.bottom)
Print("POINT() still zero-initializes: ({}, {})", POINT().x, POINT().y)

; --- 2. Straight into a Win32 call -------------------------------------------
; PtInRect takes a RECT* and a POINT by value. The POINT literal is built in
; the argument list and never needs a name.
hit := DllCall("user32\PtInRect", "Ptr", rc.Ptr, POINT, POINT(10, 10), "Int")
miss := DllCall("user32\PtInRect", "Ptr", rc.Ptr, POINT, POINT(10, 60), "Int")
Print("PtInRect (10,10): {}   (10,60): {}", hit, miss)

; --- 3. A table of structs in one expression ---------------------------------
corners := [POINT(rc.left, rc.top), POINT(rc.right, rc.top),
            POINT(rc.right, rc.bottom), POINT(rc.left, rc.bottom)]
out := ""
for c in corners
    out .= Format("({},{}) ", c.x, c.y)
Print("corners: {}", out)

; --- 4. A constructor that normalizes its input ------------------------------
; super.__New(fieldValues*) is the new base constructor, so a subclass can
; accept arguments in any order and store them canonically.
struct Span {
    lo : Int32
    hi : Int32
    __New(a, b) {
        super.__New(Min(a, b), Max(a, b))
    }
    Length => this.hi - this.lo
}
s := Span(90, 30)
Print("Span(90, 30) stores {}..{} (length {})", s.lo, s.hi, s.Length)

; --- 5. The count is checked ----------------------------------------------------
try POINT(1)
catch Error as e
    Print("POINT(1): {}", e.Message)
try RECT(1, 2, 3, 4, 5)
catch Error as e
    Print("RECT(1, 2, 3, 4, 5): {}", e.Message)
```

Source: [`01_struct_constructors.ahk`](https://github.com/TrueCrimeDev/AutoHotkey/blob/alpha/examples/alpha37/01_struct_constructors.ahk)

---

## 2. `IsSet(obj.prop)` and `IsSet(f())`

`IsSet` used to accept only a variable or an explicitly optional expression such as `IsSet(o.b?)`. Now a property access or a call without the `?` is read as if it had one. That turns two common questions into one short test each: *is this property there?* and *did this call return a value?*

The script uses it five ways. Settings with defaults fall through from a user object to a defaults object with `IsSet(user.%name%)`. A finder function returns nothing instead of a sentinel, and the caller tests the call itself. Feature detection on objects you did not write becomes `IsSet(obj.Describe)`. A `Button` class declares `onClick => unset` as an empty slot that a wired instance fills with `DefineProp`. The last section shows the one rule to remember: only the final access is optional, so `IsSet(cfg.disk.path)` still throws when `cfg.disk` itself is missing.

Before alpha.37, `IsSet(o.prop)` was a load-time error: "IsSet requires a variable or unset expression."

```ahk2
#Requires AutoHotkey v2.1-alpha.37

; --- 1. Optional settings on a plain object -----------------------------------
defaults := {retries: 3, timeout: 30}
user := {timeout: 5}

Setting(name) => IsSet(user.%name%) ? user.%name% : defaults.%name%
Print("retries = {}  timeout = {}", Setting("retries"), Setting("timeout"))

; --- 2. A function that returns unset for "no result" ------------------------
; A finder can return nothing instead of a sentinel such as 0 or "", and the
; caller tests the call itself.
FindFirst(items, pred) {
    for item in items
        if pred(item)
            return item
    ; falls off the end: returns unset
}
nums := [4, 9, 16, 23]
Print("first > 10: {}", IsSet(FindFirst(nums, x => x > 10)) ? FindFirst(nums, x => x > 10) : "none")
Print("first > 50: {}", IsSet(FindFirst(nums, x => x > 50)) ? FindFirst(nums, x => x > 50) : "none")

; --- 3. Feature detection on objects you did not write -----------------------
class Plain {
}
class Loud {
    Describe() => "I can describe myself"
}
for obj in [Plain(), Loud()]
    Print("{}: {}", Type(obj), IsSet(obj.Describe) ? obj.Describe() : "(no Describe)")

; --- 4. Optional handler slots (pairs with 05_safer_errors.ahk) --------------
; A getter that returns unset is an empty slot. IsSet(b.onClick) reads it as
; "not wired"; the wired instance supplies a value through DefineProp. Calling
; btn.onClick() invokes the getter's value as a method, so the handler receives
; the button as its first parameter.
class Button {
    onClick => unset
}
b := Button()
wired := Button()
wired.DefineProp("onClick", {Get: (*) => (self) => Type(self) " clicked"})
for name, btn in Map("b", b, "wired", wired)
    Print("{}.onClick: {}", name, IsSet(btn.onClick) ? btn.onClick() : "not wired")

; --- 5. Only the last access is optional ----------------------------------------
cfg := {net: {proxy: "proxy.local"}}
Print("cfg.net.proxy set: {}", IsSet(cfg.net.proxy))
Print("cfg.net.port set:  {}", IsSet(cfg.net.port))
try IsSet(cfg.disk.path)                 ; cfg.disk does not exist
catch PropertyError as e
    Print("IsSet(cfg.disk.path): {}", e.Message)
Print("guarded: {}", IsSet(cfg.disk) && IsSet(cfg.disk.path) ? "set" : "not set")

; The explicit form still works and means the same thing.
Print("IsSet(cfg.net.proxy?) = {}", IsSet(cfg.net.proxy?))
```

Source: [`02_isset_properties.ahk`](https://github.com/TrueCrimeDev/AutoHotkey/blob/alpha/examples/alpha37/02_isset_properties.ahk)

---

## 3. `unset` as a null pointer in DllCall

Many Win32 functions take an optional pointer: pass NULL and they skip that output, answer a size query, or mean "the current module". That used to require `"Ptr", 0` and a lie about the parameter's type. In alpha.37 a `"Str"`, `"*"` or `"P"` parameter keeps its type and `unset` is the null pointer.

Two spellings look alike and mean different things. `"UInt*", unset` passes NULL with no variable involved. `"UInt*", &v := unset` passes the address of `v`, which then receives the output. The script shows a `GetCurrentDirectoryW` size query, `GetModuleHandleW(NULL)`, skipping the process-id output of `GetWindowThreadProcessId`, and a proof via `_wcsdup` that the pointer really is 0 rather than a pointer to an empty string. The last section is the pattern I expect to see most: a wrapper with an optional by-reference parameter that passes NULL when the caller did not ask for the output.

Before alpha.37 both `"Str", unset` and `"Int*", unset` threw "Missing a required parameter."

```ahk2
#Requires AutoHotkey v2.1-alpha.37

; --- 1. A size query, then the real call ----------------------------------------
; GetCurrentDirectoryW(0, NULL) returns the length needed, including the
; terminator.
len := DllCall("GetCurrentDirectoryW", "UInt", 0, "Str", unset, "UInt")
buf := Buffer(len * 2)
DllCall("GetCurrentDirectoryW", "UInt", len, "Ptr", buf, "UInt")
Print("GetCurrentDirectoryW needs {} chars: {}", len - 1, StrGet(buf))

; --- 2. NULL means "this module" ---------------------------------------------------
hSelf := DllCall("GetModuleHandleW", "Str", unset, "Ptr")
hUser := DllCall("GetModuleHandleW", "Str", "user32.dll", "Ptr")
Print("GetModuleHandleW(NULL) = 0x{:X}  (user32 = 0x{:X})", hSelf, hUser)

; --- 3. Skip an output you do not want --------------------------------------------
; GetWindowThreadProcessId returns the thread id and writes the process id
; through its second parameter, which may be NULL.
hwnd := DllCall("GetConsoleWindow", "Ptr") || DllCall("GetDesktopWindow", "Ptr")
tid := DllCall("GetWindowThreadProcessId", "Ptr", hwnd, "UInt*", unset, "UInt")
Print("thread id only: {}", tid)
tid := DllCall("GetWindowThreadProcessId", "Ptr", hwnd, "UInt*", &pid := 0, "UInt")
Print("thread id {} and process id {}", tid, pid)

; --- 4. The null pointer really is 0, not a pointer to 0 -----------------------------
; _wcsdup(NULL) returns NULL; _wcsdup("") allocates an empty string.
Print("_wcsdup(NULL) = {}", DllCall("msvcrt\_wcsdup", "Str", unset, "Ptr"))
p := DllCall("msvcrt\_wcsdup", "Str", "", "Ptr")
Print("_wcsdup(`"`") = 0x{:X} (freed)", p)
DllCall("msvcrt\free", "Ptr", p)

; --- 5. Optional parameters in a wrapper -------------------------------------------
; A wrapper with an optional by-reference parameter passes NULL when the
; caller did not ask for the output, and the variable's address when it did.
WindowThread(hwnd, &pid?) {
    if !IsSet(pid)
        return DllCall("GetWindowThreadProcessId", "Ptr", hwnd, "UInt*", unset, "UInt")
    return DllCall("GetWindowThreadProcessId", "Ptr", hwnd, "UInt*", &pid, "UInt")
}
Print("WindowThread(hwnd) = {}", WindowThread(hwnd))
Print("WindowThread(hwnd, &pid) = {}, pid = {}", WindowThread(hwnd, &pid2 := 0), pid2)
```

Source: [`03_dllcall_unset_null.ahk`](https://github.com/TrueCrimeDev/AutoHotkey/blob/alpha/examples/alpha37/03_dllcall_unset_null.ahk)

---

## 4. Numeric structs by value, and `Struct.At` as an address carrier

Two smaller changes share a script. First, `DllCall(..., Int32, n, ...)` with `n := Int32()` now passes the instance's *value*, the same as `"Int", n.__Value`. Before, `Int32` threw `TypeError` "Expected a Number but got an Int32." and `Int64` corrupted memory. A typed default parameter such as `Clamp(v, lo := Int32(), hi := Int32())` therefore works as a real typed zero, and the same instance can still go by pointer through `.Ptr` when the callee writes back.

Second, `Struct.At(ptr)` no longer needs a subclass. It returns a zero-size view whose only job is to carry an address, which other struct classes then reinterpret with their own `.At`. The script walks a packed array of `Pair` records with nothing but that address and `Pair().Size`. Note the instance call: `Size` is an instance property, so `Pair.Size` is a `PropertyError`.

```ahk2
#Requires AutoHotkey v2.1-alpha.37

; --- 1. Typed counters passed straight to C ----------------------------------
delta := Int32()
delta.__Value := -42
Print("abs({}) = {}", delta.__Value, DllCall("msvcrt\abs", Int32, delta, "Int"))

big := Int64()
big.__Value := -9000000000
Print("_abs64({}) = {}", big.__Value, DllCall("msvcrt\_abs64", Int64, big, "Int64"))

; A typed default parameter: the callee gets a real Int32 zero, not a string.
Clamp(v, lo := Int32(), hi := Int32()) {
    if hi.__Value = 0
        hi.__Value := 100
    return Min(Max(v, lo.__Value), hi.__Value)
}
Print("Clamp(150) = {}  Clamp(-5) = {}", Clamp(150), Clamp(-5))

; The same instance can still be passed by pointer when the function writes
; back: Int32.Ptr hands over its address.
n := Int32()
n.__Value := DllCall("GetCurrentDirectoryW", "UInt", 0, "Str", unset, "UInt")
Print("by value: {}   by pointer reads back: {}", DllCall("msvcrt\abs", Int32, n, "Int"), NumGet(n.Ptr, "Int"))

; --- 2. Struct.At as an address carrier ---------------------------------------
struct Pair {
    a : Int32
    b : Int32
}
buf := Buffer(16, 0)
NumPut("Int", 7, "Int", 9, "Int", 11, "Int", 13, buf)

anchor := Struct.At(buf.Ptr)
Print("Struct.At: Type {}  Size {}  Ptr matches buffer: {}", Type(anchor), anchor.Size, anchor.Ptr = buf.Ptr)

; Reinterpret the same memory through two different layouts. Size is an
; instance property, so read it from a throwaway Pair().
pairSize := Pair().Size
first := Pair.At(anchor.Ptr)
second := Pair.At(anchor.Ptr + pairSize)
Print("Pair #1 = ({}, {})   Pair #2 = ({}, {})", first.a, first.b, second.a, second.b)

; Walk a packed array of Pair with nothing but an address and a size.
Walk(base, count) {
    out := ""
    loop count {
        p := Pair.At(base + (A_Index - 1) * Pair().Size)
        out .= Format("{}+{}={} ", p.a, p.b, p.a + p.b)
    }
    return out
}
Print("walk: {}", Walk(anchor.Ptr, 2))

; A Struct view is still a struct: it cannot grow properties by accident.
try anchor.label := "x"
catch PropertyError as e
    Print("anchor.label := `"x`": {}", e.Message)
```

Source: [`04_numeric_structs_and_struct_at.ahk`](https://github.com/TrueCrimeDev/AutoHotkey/blob/alpha/examples/alpha37/04_numeric_structs_and_struct_at.ahk)

---

## 5. Safer errors: four crashes become `catch`

Four cases that used to crash the process or write memory silently now throw an ordinary `Error` subclass. `a.b()` when `a.b => unset` throws `UnsetError` (it exited 11 before). `a.b[c]` when `a.b` is a method throws `PropertyError` (it returned silently). `NumGet`/`NumPut` with a bad type throw `ValueError` (they read or wrote a pointer-sized integer). `DllCall(..., IntPtr, obj)` with a plain object throws `TypeError` (exit 11).

The first one enables a pattern worth stealing. A `Pipeline` class declares its hooks as `onStart => unset`, `onItem => unset`, `onDone => unset`, and a generic `Fire(name, args*)` method tests `IsSet(this.%name%)` before calling `this.%name%(args*)`. Subclasses or instances supply real callables; the base class runs fine with none. The `NumPut` section validates type names coming from data, which matters if your layout table is read from a file.

Section 5 is fork-specific. Upstream alpha.37 commit `2f4f3967` tests whether the property returned a value *before* checking whether the getter threw, so a getter that raises `ValueError("handler is not configured")` is reported as `UnsetError` "No value was returned." and the real message is lost. The fork build (`a911f73d`) checks the result first and restores the `ValueError`; the report to upstream is in [`docs/upstream/alpha37-regressions.md`](https://github.com/TrueCrimeDev/AutoHotkey/blob/alpha/docs/upstream/alpha37-regressions.md) alongside four other regressions the same review found.

```ahk2
#Requires AutoHotkey v2.1-alpha.37

; --- 1. Optional hooks: an unset getter is an empty slot ----------------------
class Pipeline {
    ; Hooks default to "nothing". Subclasses or instances supply real callables.
    onStart => unset
    onItem  => unset
    onDone  => unset

    Run(items) {
        this.Fire("onStart")
        for item in items
            this.Fire("onItem", item)
        this.Fire("onDone", items.Length)
    }

    ; Fire a hook that may be empty: IsSet(this.%name%) reads the slot without
    ; calling it. this.%name%(args*) then calls the slot's value as a method,
    ; so every hook receives the pipeline as its first parameter.
    Fire(name, args*) {
        if IsSet(this.%name%)
            this.%name%(args*)
    }
}
class LoggingPipeline extends Pipeline {
    onItem => (self, item) => Print("  item {}", item)
    onDone => (self, n) => Print("  done, {} items", n)
}
Print("Pipeline with no hooks:")
Pipeline().Run([1, 2])
Print("LoggingPipeline:")
LoggingPipeline().Run(["a", "b", "c"])

; Calling an empty slot directly is an ordinary error now.
try Pipeline().onStart()
catch UnsetError as e
    Print("Pipeline().onStart(): {}: {}", Type(e), e.Message)

; --- 2. A method is not an indexable property --------------------------------
class Grid {
    Cell(i) => i * 10
}
try Grid().Cell[2]
catch PropertyError as e
    Print("Grid().Cell[2]: {}", e.Message)
Print("Grid().Cell(2) = {}", Grid().Cell(2))

; --- 3. Validate NumGet/NumPut type names from data --------------------------
layout := Map("version", "UShort", "flags", "UInt", "ratio", "Quad")   ; "Quad" is not a type
buf := Buffer(16, 0)
offset := 0
for name, kind in layout {
    try {
        NumPut(kind, 1, buf, offset)
        Print("{} as {}: ok at offset {}", name, kind, offset)
        offset += kind ~= "i)Short" ? 2 : 4
    } catch ValueError as e
        Print("{} as {}: {}", name, kind, e.Message)
}

; --- 4. DllCall rejects an object where a pointer-sized integer is expected --
try DllCall("msvcrt\abs", IntPtr, {}, "Int")
catch TypeError as e
    Print("DllCall(IntPtr, {{}}): {}", e.Message)

; --- 5. Fork fix: a throwing getter keeps its exception when called ---------------
class Guarded {
    handler {
        get {
            throw ValueError("handler is not configured")
        }
    }
}
try Guarded().handler()
catch Error as e
    Print("Guarded().handler(): {}: {}", Type(e), e.Message)
; Upstream alpha.37 reported UnsetError "No value was returned." here, hiding
; the real message; the fork (a911f73d) restores the ValueError.
```

Source: [`05_safer_errors.ahk`](https://github.com/TrueCrimeDev/AutoHotkey/blob/alpha/examples/alpha37/05_safer_errors.ahk)

---

## Things I tripped over writing these

- **Calling a property calls its value as a method.** `obj.hook()` where `hook` is a getter returning a function invokes that function with `obj` as its first parameter. Every hook in scripts 2 and 5 is therefore written `(self, item) =>`. A bare `(item) =>` fails with "Too many parameters passed to function."
- **`Size` is an instance property.** `Pair().Size`, not `Pair.Size`.
- **Type names match on their first letter.** `NumPut("Flaot", ...)` is accepted as `Float`, which is why script 5 uses `"Quad"` as its invalid example.
- **Do not name a variable `type`.** It shadows the `Type()` function for the whole script. Names are case-insensitive, so `pt` and `PT` clash the same way.
- **Forwarding an optional `&param?`** needs a branch on `IsSet(pid)`. Passing `&pid` straight through when the caller omitted it throws `UnsetError`.

---

## Running them

Every script starts with `#Requires AutoHotkey v2.1-alpha.37`. On alpha.36 each stops at its first use of the new syntax with a clear load error, which is itself a useful check that you are on the build you think you are.

```powershell
git clone https://github.com/TrueCrimeDev/AutoHotkey
# build per BUILD.md, or copy a release Console engine into bin\
.\bin\AutoHotkey64Console.exe examples\alpha37\01_struct_constructors.ahk
```

The scripts use `Print`, the fork's stdout function, so they need the Console build. Replacing each `Print(...)` with `MsgBox(Format(...))` makes them run on a stock alpha.37 once the upstream tag ships, with the section-5 difference described above.

*Disclosure: Claude Fable 5.1 wrote the five scripts, ran them on the fork build, and drafted this post. Every behaviour claim was observed on `2.1-alpha.37+Console` (`a911f73d`) or on the unfixed merge build; the alpha.36 comparisons come from running the same code on `165d7384`.*
