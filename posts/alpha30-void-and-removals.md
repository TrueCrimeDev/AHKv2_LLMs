# AutoHotkey v2.1-alpha.30: Void Returns and Three Removals

Alpha.30 shipped on May 22, 2026 (upstream tag `v2.1-alpha.30`), twenty upstream commits and the largest release in the series so far. One addition: `"Void"` as a return type for `DllCall`, `ComCall` and `CallbackCreate`. Three removals that finish the typed-property clean-up: `a?.()` and `a?.[]` are gone in favour of `(a?)()` and `(a?)[]`, the string type names `i32`, `u32` and friends are gone in favour of the classes, and a bare size in a struct field (`buf: 32`) is gone. Around them, a sweep of fixes in `String()`, `StrGet`, references and class objects.

If you have alpha.29 code, the removals are load errors, so migration is not optional. The four scripts below show the replacement for each one as something you would actually write, plus the new `Void` and the fixes. They run on the `2.1-alpha.37+Console` build and use alpha.30 syntax only.

**`Print` is a fork built-in**, not stock AutoHotkey. `Print("x = {}", x)` formats through `Format` and writes one line to stdout; a single argument is written as-is. On stock AutoHotkey add this line under `#Requires` and pipe through `| more`:

```ahk2
Print(fmt := "", args*) => FileAppend((args.Length ? Format(fmt, args*) : fmt) "`n", "*")
```

---

## 1. `"Void"`: a call with no value

Win32 is full of functions that return nothing. Before alpha.30 you still had to name a return type, so `DllCall("GetLocalTime", "Ptr", st, "Int")` produced whatever was in the return register, and that number could be assigned, compared or logged by accident. With `"Void"` the expression has no value: `??` sees `unset`, and a plain assignment is an `UnsetError` at the call site. The script fills a `SYSTEMTIME` struct through `GetLocalTime`, shows both readings of the result, and shows that `"Void"` in a parameter slot is a `ValueError`.

Section 4 is the `CallbackCreate` side. The type array is `[param types..., return type]`, and `"Void"` in the last slot means the AutoHotkey function may fall off the end. With `Int32` there instead, the same handler fails inside the callback with "Expected a Number but got an unset.", and that error is raised on the callback's own thread, so a `try` around the `DllCall` does not catch it. I found that out by trying.

Before alpha.30, `"Void"` was not a type and the call returned a meaningless integer.

```ahk2
#Requires AutoHotkey v2.1-alpha.30

; alpha.30: "Void" as a return type for DllCall, ComCall and CallbackCreate
;
; Many Win32 functions return nothing. Before alpha.30 you still had to name
; a return type, so the expression produced a meaningless integer that could
; be assigned, compared or printed by mistake. "Void" discards the register
; entirely: the call expression has no value, and trying to keep one is an
; UnsetError at the call site.
;
; In a CallbackCreate type array, "Void" in the last slot says the AHK
; function returns nothing, so the thunk does not try to convert a missing
; return value into a number.

struct SYSTEMTIME {
    wYear: UInt16
    wMonth: UInt16
    wDayOfWeek: UInt16
    wDay: UInt16
    wHour: UInt16
    wMinute: UInt16
    wSecond: UInt16
    wMilliseconds: UInt16
}

; --- 1. A void API whose result is the struct it filled ------------------------------
now := SYSTEMTIME()
DllCall("kernel32\GetLocalTime", "Ptr", now, "Void")
Print("GetLocalTime: {:04}-{:02}-{:02} {:02}:{:02}", now.wYear, now.wMonth, now.wDay, now.wHour, now.wMinute)

; --- 2. A Void call has no value ----------------------------------------------------------------
; ?? sees unset; a plain assignment is an UnsetError. Before alpha.30 this
; slot would have held whatever happened to be in the return register.
Print("DllCall(..., 'Void') ?? 'no value' = {}", DllCall("kernel32\GetLocalTime", "Ptr", now, "Void") ?? "no value")
try
    stamp := DllCall("kernel32\GetLocalTime", "Ptr", now, "Void")
catch UnsetError as e
    Print("stamp := DllCall(..., 'Void'): {}", e.Message)

; --- 3. Void is a return type only ------------------------------------------------------------
try
    DllCall("kernel32\GetLocalTime", "Void", 0)
catch ValueError as e
    Print("DllCall(..., 'Void', 0): {}", e.Message)

; --- 4. A callback that returns nothing --------------------------------------------------------
; The type array is [param types..., return type]. With "Void" the handler
; may fall off the end; with Int32 in that slot the same handler would fail
; inside the callback with "Expected a Number but got an unset."
seen := []
OnValue(n) {
    seen.Push(n * 2)
}
cb := CallbackCreate(OnValue, , [Int32, "Void"])
loop 3
    DllCall(cb, "Int", A_Index * 7, "Void")
CallbackFree(cb)
Print("callback saw: {}", seen[1] ", " seen[2] ", " seen[3])

; A Void parameter slot is rejected the same way as in DllCall.
try
    CallbackCreate(OnValue, , ["Void", Int32])
catch ValueError as e
    Print("CallbackCreate(..., ['Void', Int32]): {}", e.Message)
```

Output (the time will differ):

```text
GetLocalTime: 2026-10-26 07:03
DllCall(..., 'Void') ?? 'no value' = no value
stamp := DllCall(..., 'Void'): No value was returned.
DllCall(..., 'Void', 0): Invalid arg type.
callback saw: 14, 28, 42
CallbackCreate(..., ['Void', Int32]): Parameter #3 of CallbackCreate is invalid.
```

Source: [`01_void_return.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha30/01_void_return.ahk)

---

## 2. `(a?)()` and `(a?)[]`

The maybe-call and maybe-index shorthands were removed because `?.` already means maybe-property and stacking `()` or `[]` on it was ambiguous. The replacement is to parenthesise the maybe: `(cb?)(item)` is `unset` when `cb` is, and a call applied to `unset` short-circuits, so an emitter with optional hooks (`Run`) calls each one only if it was supplied and needs no `IsSet` per hook. `(list?)[1] ?? "(empty)"` does the same for an optional collection.

Two parser fixes travel with the removal. `cfg?.%key%` (maybe-property with a dynamic name) was a syntax error and now works, which gives `Setting` one path for "no config object"; a config object that lacks the key is still a `PropertyError`, so that case stays behind a `HasOwnProp` guard. And `!a ?? b` and `b + a ?? c` are rejected at load time until you add parentheses. While checking the other grouping I learned that `(!b) ?? a` is rejected for a different reason: the left side of `??` has to be something that can be unset.

Before alpha.30, `cb?.(item)` and `list?.[1]` were the spellings; they no longer load.

```ahk2
#Requires AutoHotkey v2.1-alpha.30

; alpha.30: (a?)() and (a?)[] replace a?.() and a?.[]
;
; The maybe-call and maybe-index shorthands are gone: ?. already means
; "maybe-property", and stacking () or [] on it made the grammar ambiguous.
; The replacement parenthesises the maybe first. (a?) is unset when a is,
; and a call or index applied to unset short-circuits to unset, so the whole
; chain collapses to the ?? on the right.
;
; Two related parser fixes landed with it: x?.%y% (maybe-property with a
; dynamic name) now parses, and the ambiguous forms `!a ?? b` and
; `b + a ?? c` are rejected at load time until you add parentheses.

; --- 1. Optional callbacks ---------------------------------------------------------------
; An emitter with optional hooks calls each one only if it was supplied.
Run(items, onItem?, onDone?) {
    for item in items
        (onItem?)(item)
    return (onDone?)(items.Length) ?? "(no onDone)"
}
Print("silent run: {}", Run([1, 2]))
Print("logged run: {}", Run(["a", "b", "c"], x => Print("  item {}", x), n => n " items"))

; --- 2. Optional collections -------------------------------------------------------------
First(list?) => (list?)[1] ?? "(empty)"
Print("First() = {}   First([9, 8]) = {}", First(), First([9, 8]))

; --- 3. Dynamic property on a maybe receiver -------------------------------------------------
; cfg?.%key% was a syntax error before alpha.30. It reads like cfg.%key% and
; short-circuits when cfg is unset, so one helper serves "no config at all"
; and "config without that key" (the latter needs the property to exist, so
; it is guarded with HasOwnProp).
Setting(key, cfg?) => (cfg?.%key%) ?? "default"
theme := {theme: "dark"}
Print("Setting('theme') = {}   Setting('theme', theme) = {}", Setting("theme"), Setting("theme", theme))
Print("HasOwnProp guard: {}", theme.HasOwnProp("lang") ? theme.lang : "default")

; --- 4. Precedence is spelled out, not guessed --------------------------------------------------
; `!a ?? b` and `b + a ?? c` no longer load. Write the grouping you mean. The
; other reading, (!a) ?? b, is rejected for a different reason: the left side
; of ?? must be something that can be unset, and !a never is.
a := unset
b := 42
Print("!(a ?? b) = {}   b + (a ?? 100) = {}", !(a ?? b), b + (a ?? 100))
```

Output:

```text
silent run: (no onDone)
  item a
  item b
  item c
logged run: 3 items
First() = (empty)   First([9, 8]) = 9
Setting('theme') = default   Setting('theme', theme) = dark
HasOwnProp guard: default
!(a ?? b) = 0   b + (a ?? 100) = 142
```

Source: [`02_maybe_call_index.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha30/02_maybe_call_index.ahk)

---

## 3. Struct fields name a class

The string shorthands (`i8`, `i16`, `i32`, `i64`, `u8`, `u16`, `u32`, `f32`, `f64`, `ptr`) are replaced by the classes `Int8` through `IntPtr`, and the bare-size field (`buf: 32`) is replaced by a typed array such as `Int8[4]`, which is indexable and has a `Length`, two things the raw region never had. The script builds a `Record` with a nested `Point`, a four-byte tag array and a `Float64`, and prints the sizes so the padding is visible: 24 bytes, with the `UInt16` id padded to the `Point` boundary and the array padded to the `Float64`.

Section 3 is the pattern for data whose size is not a constant: keep a `Buffer` beside the struct and pass its pointer where the API wants one. Section 4 is the `UInt64` question, since no such class exists: store the value in an `Int64` and split it into two `UInt32` halves with a shift and a mask when you need the unsigned reading.

Before alpha.30, `x: i32` and `tag: 4` loaded; on alpha.30 both are load errors.

```ahk2
#Requires AutoHotkey v2.1-alpha.30

; alpha.30: struct fields name a class, never a string or a bare size
;
; Two shorthands stopped loading:
;   x: i32        -> x: Int32       (i8/i16/i32/i64, u8/u16/u32, f32/f64, ptr)
;   buf: 32       -> a typed array such as Int8[32], or a Buffer alongside
;
; The replacement classes are Int8, Int16, Int32, Int64, UInt8, UInt16,
; UInt32, Float32, Float64 and IntPtr. There is no UInt64 class: store the
; value in an Int64 and mask when you read it, or split it into two UInt32s.

; --- 1. The migrated layout --------------------------------------------------------------
struct Point {
    x: Int32
    y: Int32
}
struct Record {
    id: UInt16                 ; 2 bytes, then 2 bytes of padding before pos
    pos: Point                 ; nested struct, 8 bytes
    tag: Int8[4]               ; the old `tag: 4` raw region, now typed
    ratio: Float64             ; 8-byte aligned
}
r := Record()
r.id := 7, r.pos.x := 3, r.pos.y := 4, r.ratio := 0.75
Print("Record.Size = {}   Point.Size = {}", r.Size, r.pos.Size)
Print("id {}  pos ({}, {})  ratio {}", r.id, r.pos.x, r.pos.y, r.ratio)

; --- 2. The raw region is an array of bytes -------------------------------------------------
; Int8[4] is indexable and has a Length, which a bare `tag: 4` never had.
for i, ch in StrSplit("AHK!")
    r.tag[i] := Ord(ch)
tagText := ""
loop r.tag.Length
    tagText .= Chr(r.tag[A_Index])
Print("tag = '{}' ({} bytes)", tagText, r.tag.Length)

; --- 3. Variable-length data stays in a Buffer ----------------------------------------------
; When the size is not a constant, keep a Buffer beside the struct and pass
; its pointer where a C API wants one.
class Packet {
    __New(payloadBytes) {
        this.header := Record()
        this.payload := Buffer(payloadBytes, 0)
    }
}
p := Packet(128)
Print("Packet: header {} bytes at 0x{:X}, payload {} bytes at 0x{:X}", p.header.Size, p.header.Ptr, p.payload.Size, p.payload.Ptr)

; --- 4. Unsigned 64-bit values ---------------------------------------------------------------
struct FileSize {
    bytes: Int64
}
fs := FileSize()
fs.bytes := -1                                    ; 0xFFFFFFFFFFFFFFFF as unsigned
hi := (fs.bytes >> 32) & 0xFFFFFFFF
lo := fs.bytes & 0xFFFFFFFF
Print("Int64 {} read as two UInt32 halves: 0x{:08X} 0x{:08X}", fs.bytes, hi, lo)
```

Output (addresses will differ):

```text
Record.Size = 24   Point.Size = 8
id 7  pos (3, 4)  ratio 0.75
tag = 'AHK!' (4 bytes)
Packet: header 24 bytes at 0x232BE5AEC58, payload 128 bytes at 0x232BE57C6D0
Int64 -1 read as two UInt32 halves: 0xFFFFFFFF 0xFFFFFFFF
```

Source: [`03_typed_structs.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha30/03_typed_structs.ahk)

---

## 4. Four fixes, four removed special cases

`String(obj)` used to crash the interpreter when the object's `ToString` returned nothing; now the result is `unset`, so `String(v) ?? "(no text)"` is a complete `Describe`. `StrGet(buf, 0)` returned an `Integer` (the pointer) since alpha.28 and returns an empty `String` again, so a length-prefixed reader can pass zero straight through. Assigning `unset` through a `&ref` parameter was rejected and now leaves the caller's variable unset, which is exactly what a `TryParse` should do on failure instead of storing `""`. And `ClassObj.Base := Other`, broken by alpha.28, works again, so static members can be inherited after the fact.

The release notes also list `DllCall` propagating an exception thrown by an output argument's `__Value` getter, `Struct.Ptr()` on the class object no longer crashing, `StructClass.Ptr().__Value := unset` working, a `TraySetIcon("HBITMAP:" h)` fix and `ControlGetItems` throwing on a Tab control. I did not build demonstrations for those; the first needs an output-typed struct argument whose getter throws, and the rest are GUI or crash cases that do not print anything useful.

Before alpha.30, `String(Silent())` crashed, `Type(StrGet(buf, 0))` was `Integer`, `out := unset` through a reference was an error, and `Widget.Base := Plugin` failed.

```ahk2
#Requires AutoHotkey v2.1-alpha.30

; alpha.30: four small fixes that each remove a special case
;
;   String(obj) when ToString() returns nothing   -> unset (was a crash)
;   StrGet(buf, 0)                                 -> "" of type String (was an Integer; broken by alpha.28)
;   out := unset through a &ref parameter          -> caller's variable becomes unset (was rejected)
;   ClassObj.Base := Other                         -> works again (broken by alpha.28)

; --- 1. String() on an object that declines to describe itself ---------------------------------
class Silent {
    ToString() {
    }
}
class Named {
    ToString() => "Named#1"
}
Describe(v) => String(v) ?? "(no text)"
Print("Describe(Named()) = {}   Describe(Silent()) = {}", Describe(Named()), Describe(Silent()))
try
    s := String(Silent())
catch UnsetError as e
    Print("s := String(Silent()): {}", e.Message)

; --- 2. StrGet with a zero length ------------------------------------------------------------------
; A length-prefixed reader can pass 0 straight through and still get a String.
buf := Buffer(64, 0)
StrPut("hello", buf, "UTF-16")
ReadPrefixed(ptr, n) => StrGet(ptr, n, "UTF-16")
for n in [0, 2, 5] {
    v := ReadPrefixed(buf, n)
    Print("StrGet(buf, {}) = '{}' ({})", n, v, Type(v))
}

; --- 3. Clearing a caller's variable through a reference -----------------------------------------
; A TryParse that leaves the output unset on failure, instead of storing "".
TryParseInt(text, &out) {
    if text ~= "^-?\d+$" {
        out := Integer(text)
        return true
    }
    out := unset
    return false
}
for text in ["42", "4x2"] {
    ok := TryParseInt(text, &value)
    Print("TryParseInt('{}') = {}   IsSet(value) = {}   value = {}", text, ok, IsSet(value), value ?? "unset")
}

; --- 4. Re-basing a class object -----------------------------------------------------------------------
class Plugin {
    static Kind => "plugin"
}
class Widget {
}
Widget.Base := Plugin                          ; static inheritance after the fact
Print("Widget.Kind = {}   Widget.Base is Plugin: {}", Widget.Kind, Widget.Base == Plugin)
```

Output:

```text
Describe(Named()) = Named#1   Describe(Silent()) = (no text)
s := String(Silent()): No value was returned.
StrGet(buf, 0) = '' (String)
StrGet(buf, 2) = 'he' (String)
StrGet(buf, 5) = 'hello' (String)
TryParseInt('42') = 1   IsSet(value) = 1   value = 42
TryParseInt('4x2') = 0   IsSet(value) = 0   value = unset
Widget.Kind = plugin   Widget.Base is Plugin: 1
```

Source: [`04_small_fixes.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha30/04_small_fixes.ahk)

---

## Things I tripped over writing these

- **An error inside a callback is not catchable at the `DllCall`.** A typed `Int32` return with a handler that returns nothing ends the script from the callback's thread. Use `"Void"` or return a number.
- **`??` needs a left side that can be unset.** `(!b) ?? a` and `(b + 1) ?? 0` are load errors, so the "other grouping" of the ambiguous forms cannot be written that way.
- **`cfg?.%key%` does not cover a missing key.** It short-circuits on an unset receiver only; a present object without the property still throws `PropertyError`.

---

## Running them

`#Requires AutoHotkey v2.1-alpha.30` on every script. Alpha.29 stops at `"Void"`. Fork: run as-is. Stock: add the `Print` line and pipe through `| more`.

```powershell
# +Console fork
.\bin\AutoHotkey64Console.exe 01_void_return.ahk

# stock AutoHotkey v2.1-alpha.30 or later (GUI exe), with the Print line added
AutoHotkey64.exe 01_void_return.ahk | more
```

*Scripts and text by Claude Fable 5.1, run on `2.1-alpha.37+Console` (`a911f73d`); "before" behaviour from the fork's release notes.*
