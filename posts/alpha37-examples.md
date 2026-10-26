# AutoHotkey v2.1-alpha.37: Five Scripts for the New Syntax

Alpha.37 (October 25, 2026) is a DllCall and Struct release: `unset` as a null pointer, struct constructors that take field values, `IsSet` on properties and calls, `Struct.At` on `Struct` itself, numeric structs by value, and five crashes turned into errors.

The tag was not pushed when the announcement went out, so for now these run only on the [+Console fork](https://github.com/TrueCrimeDev/AutoHotkey), which also fixes five regressions the alpha.37 commits introduced (`a911f73d`). The scripts also live there under [`examples/alpha37/`](https://github.com/TrueCrimeDev/AutoHotkey/tree/alpha/examples/alpha37).

**`Print` is a fork built-in**, not stock AutoHotkey. `Print("x = {}", x)` formats through `Format` and writes one line to stdout; a single argument is written as-is. On stock AutoHotkey add this line under `#Requires` and pipe through `| more`:

```ahk2
Print(fmt := "", args*) => FileAppend((args.Length ? Format(fmt, args*) : fmt) "`n", "*")
```

---

## 1. Struct literals: `POINT(10, 20)`

Calling a struct class with arguments fills its fields in order, so `POINT(10, 20)` replaces four assignments; the count must match, and a script `__New` can normalize through `super.__New`. The script passes a `POINT` straight into `PtInRect`, builds a table of corners in one literal, and `Span(90, 30)` sorts its arguments. Before: "Too many parameters passed to function."

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

Output:

```text
POINT(10, 20)  RECT(0, 0, 100, 50)
POINT() still zero-initializes: (0, 0)
PtInRect (10,10): 1   (10,60): 0
corners: (0,0) (100,0) (100,50) (0,50) 
Span(90, 30) stores 30..90 (length 60)
POINT(1): Invalid number of parameters.
RECT(1, 2, 3, 4, 5): Invalid number of parameters.
```

Source: [`01_struct_constructors.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha37/01_struct_constructors.ahk)

---

## 2. `IsSet(obj.prop)` and `IsSet(f())`

`IsSet(obj.prop)` and `IsSet(f())` no longer need a written `?`. The script uses that for settings with defaults, a finder that returns nothing, feature detection, and a `Button` with `onClick => unset` as an empty slot. Only the last access is optional: `IsSet(cfg.disk.path)` still throws when `cfg.disk` is missing.

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

Output:

```text
retries = 3  timeout = 5
first > 10: 16
first > 50: none
Plain: (no Describe)
Loud: I can describe myself
b.onClick: not wired
wired.onClick: Button clicked
cfg.net.proxy set: 1
cfg.net.port set:  0
IsSet(cfg.disk.path): This value of type "Object" has no property named "disk".
guarded: not set
IsSet(cfg.net.proxy?) = 1
```

Source: [`02_isset_properties.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha37/02_isset_properties.ahk)

---

## 3. `unset` as a null pointer in DllCall

A `"Str"`, `"*"` or `"P"` parameter now takes `unset` as NULL, so no more `"Ptr", 0`. `"UInt*", unset` is NULL; `"UInt*", &v := unset` is the address of `v`. The script does a size query, `GetModuleHandleW(NULL)`, a skipped output, proof via `_wcsdup` that the pointer is 0, and a wrapper with an optional `&param`.

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

Output (handles, ids and the folder will differ):

```text
GetCurrentDirectoryW needs <length> chars: <the script's own folder>
GetModuleHandleW(NULL) = 0x7FF7FB6F0000  (user32 = 0x7FFE52460000)
thread id only: 67704
thread id 67704 and process id 1896
_wcsdup(NULL) = 0
_wcsdup("") = 0x21D70C47F00 (freed)
WindowThread(hwnd) = 67704
WindowThread(hwnd, &pid) = 67704, pid = 1896
```

Source: [`03_dllcall_unset_null.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha37/03_dllcall_unset_null.ahk)

---

## 4. Numeric structs by value, and `Struct.At` as an address carrier

`DllCall(..., Int32, n)` with `n := Int32()` now passes the value, so `Clamp(v, lo := Int32(), hi := Int32())` is a real typed zero; before, `Int32` threw and `Int64` corrupted memory. `Struct.At(ptr)` works without a subclass and returns a zero-size address carrier that `Pair.At` reinterprets. `Size` is an instance property: `Pair().Size`.

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

Output:

```text
abs(-42) = 42
_abs64(-9000000000) = 9000000000
Clamp(150) = 100  Clamp(-5) = 0
by value: 135   by pointer reads back: 135
Struct.At: Type Struct  Size 0  Ptr matches buffer: 1
Pair #1 = (7, 9)   Pair #2 = (11, 13)
walk: 7+9=16 11+13=24 
anchor.label := "x": This value of type "Struct" has no property named "label".
```

Source: [`04_numeric_structs_and_struct_at.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha37/04_numeric_structs_and_struct_at.ahk)

---

## 5. Safer errors: four crashes become `catch`

`a.b()` with `a.b => unset` throws `UnsetError`, `a.b[c]` on a method throws `PropertyError`, a bad `NumPut` type throws `ValueError`, and `DllCall(..., IntPtr, obj)` throws `TypeError`; all four crashed or wrote memory before. `Pipeline` uses the first for optional hooks: `onItem => unset` plus `IsSet(this.%name%)` before the call. Section 5 is fork-specific: upstream alpha.37 reports a throwing getter as `UnsetError` "No value was returned.", the fork (`a911f73d`) keeps the real `ValueError`; see [`docs/upstream/alpha37-regressions.md`](https://github.com/TrueCrimeDev/AutoHotkey/blob/alpha/docs/upstream/alpha37-regressions.md).

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

Output:

```text
Pipeline with no hooks:
LoggingPipeline:
  item a
  item b
  item c
  done, 3 items
Pipeline().onStart(): UnsetError: No value was returned.
Grid().Cell[2]: This value of type "Func" has no property named "__Item".
Grid().Cell(2) = 20
flags as UInt: ok at offset 0
ratio as Quad: Invalid parameter(s).
version as UShort: ok at offset 4
DllCall(IntPtr, {}): Expected a Number but got an Object.
Guarded().handler(): ValueError: handler is not configured
```

Source: [`05_safer_errors.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha37/05_safer_errors.ahk)

---

## Things I tripped over writing these

- **A property call passes the object first.** Hooks are `(self, item) =>`.
- **`Size` is an instance property.** `Pair().Size`, not `Pair.Size`.
- **Type names match on their first letter.** `"Flaot"` is `Float`; script 5 uses `"Quad"`.
---

## Running them

`#Requires AutoHotkey v2.1-alpha.37` on every script. Fork: run as-is. Stock: add the `Print` line and pipe through `| more`.

```powershell
# +Console fork
.\bin\AutoHotkey64Console.exe 01_struct_constructors.ahk

# stock AutoHotkey v2.1-alpha.37 or later (GUI exe), with the Print line added
AutoHotkey64.exe 01_struct_constructors.ahk | more
```

*Scripts and text by Claude Fable 5.1, run on `2.1-alpha.37+Console` (`a911f73d`); "before" behaviour from the fork's release notes.*
