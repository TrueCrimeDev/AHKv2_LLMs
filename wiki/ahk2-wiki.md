# AutoHotkey v2.1 Wiki

A comprehensive reference for the structural changes introduced in AutoHotkey v2.1 alpha releases. This document covers the new type system, memory model, module architecture, and Win32 interop patterns that transform AHK from a scripting language into a systems-capable tool.

The wiki is organized by concept, not by release. If you want per-release changelogs, see the [blog posts](index.html#posts).

---

## The Core Idea

AutoHotkey v2.1 introduces **native typed memory** to a language that previously treated everything as a variant. The `Struct` keyword, typed arrays, and numeric classes give you direct control over memory layout -- the same control you'd have in C -- while keeping AHK's scripting ergonomics.

This matters because Win32 APIs speak in structs. Every `DllCall` that passes a `POINT`, `RECT`, `SYSTEMTIME`, or `NMHDR` previously required manual `Buffer` allocation with `NumPut`/`NumGet` at hardcoded offsets. Now you define the struct once and use it everywhere, with the runtime handling layout, alignment, and pointer arithmetic.

The progression across alpha releases:

- **Alpha 22**: `Struct` keyword, typed fields, auto `.Ptr` classes, `DefineProp()` function
- **Alpha 23**: Numeric type classes (`Float32`, `Int64`), `StructClass[N]` arrays
- **Alpha 24**: Typed `CallbackCreate`, `DefineProp Offset` unions, module re-exports
- **Alpha 25**: `ahk_opt` inline window options, hotkey/module fixes
- **Alpha 26**: Memory co-allocation, array alignment, modal dialog fixes

---

## Structs

### Defining a Struct

The `Struct` keyword creates a class with a defined memory layout. Fields use typed annotations:

```ahk2
Struct POINT {
    x: i32
    y: i32
}

pt := POINT()
pt.x := 100
pt.y := 200
```

The struct knows its own size (`pt.Size` returns 8) and type (`Type(pt)` returns `"POINT"`). Fields are accessed with dot notation, not offset math.

### Type Annotations

| Short | Full Class | Bytes | Description |
|-------|-----------|-------|-------------|
| `i8` | `Int8` | 1 | Signed byte |
| `u8` | `UInt8` | 1 | Unsigned byte |
| `i16` | `Int16` | 2 | Signed short |
| `u16` | `UInt16` | 2 | Unsigned short |
| `i32` | `Int32` | 4 | Signed int |
| `u32` | `UInt32` | 4 | Unsigned int |
| `i64` | `Int64` | 8 | Signed long |
| `u64` | `UInt64` | 8 | Unsigned long |
| `iptr` | `IntPtr` | 4/8 | Pointer-sized signed |
| `uptr` | `UIntPtr` | 4/8 | Pointer-sized unsigned |
| — | `Float32` | 4 | Single-precision float |
| — | `Float64` | 8 | Double-precision float |

Short forms (`i32`) and full class names (`Int32`) are interchangeable in struct field declarations.

### Nested Structs

Structs can embed other structs. The compiler computes the correct offsets:

```ahk2
Struct NMHDR {
    hwndFrom: uptr
    idFrom: uptr
    code: i32
}

Struct NMCUSTOMDRAW {
    hdr: NMHDR
    dwDrawStage: u32
    hdc: uptr
    rc: RECT
}

ncd := NMCUSTOMDRAW()
ncd.hdr.code := -12
ncd.rc.left := 10
```

Access nested fields with dot chains. No manual offset calculation.

### Struct Inheritance

Structs support `extends`:

```ahk2
Struct Shape {
    area: Float64
}

Struct Circle extends Shape {
    radius: Float64
}

ci := Circle()
ci.radius := 5.0
ci.area := 3.14159 * ci.radius ** 2
```

The pointer type also inherits: `Circle.Ptr` subclasses `Shape.Ptr`. Functions accepting `Shape.Ptr` will accept `Circle.Ptr`.

---

## Struct Arrays

### StructClass[N] Syntax

Create typed arrays -- contiguous blocks of N elements:

```ahk2
a := Int32[4]()
a[1] := 10
a[2] := 20
a[-1]  ; 20 -- negative indexing supported
a.Size   ; 16 bytes
a.Length ; 4 elements
```

### Arrays of Structs

```ahk2
Struct POINT {
    x: i32
    y: i32
}

points := POINT[100]()
points[1].x := 10
points[1].y := 20
```

Memory is contiguous -- exactly what Win32 APIs like `Polyline()` expect. Pass the array directly to `DllCall`.

### Alignment

Alpha 26 fixed alignment for arrays inside structs. `Float64[3]` after a `u8` field correctly pads to an 8-byte boundary:

```ahk2
Struct AlignedRecord {
    id: u8
    values: Float64[3]  ; 8-byte aligned
    flags: u32
}
```

---

## Unions (DefineProp Offset)

### Overlapping Fields

`DefineProp` with an `Offset` parameter places typed fields at explicit byte positions. Multiple fields at the same offset share the same memory -- a C-style union:

```ahk2
Struct Variant {
    vtype: u16
}
DefineProp(Variant.Prototype, "intVal",  {Type: Int32,   Offset: 8})
DefineProp(Variant.Prototype, "fltVal",  {Type: Float64, Offset: 8})
DefineProp(Variant.Prototype, "ptrVal",  {Type: IntPtr,  Offset: 8})
```

Reading `intVal` and `fltVal` both access the same bytes, interpreted differently.

### Practical: RGBA Decomposition

```ahk2
Struct Color {
    rgba: u32
}
DefineProp(Color.Prototype, "r", {Type: UInt8, Offset: 0})
DefineProp(Color.Prototype, "g", {Type: UInt8, Offset: 1})
DefineProp(Color.Prototype, "b", {Type: UInt8, Offset: 2})
DefineProp(Color.Prototype, "a", {Type: UInt8, Offset: 3})

c := Color()
c.rgba := 0xFF8040C0
; c.r = 0xC0, c.g = 0x40, c.b = 0x80, c.a = 0xFF
```

### Named Offsets

Reference another field's position by name:

```ahk2
Struct Register {
    lo: u16
    hi: u16
}
DefineProp(Register.Prototype, "full", {Type: UInt32, Offset: "lo"})
```

---

## Callbacks

### Typed CallbackCreate

Alpha 24 added typed parameter arrays to `CallbackCreate`. The last element is the return type:

```ahk2
AddFloats(a, b) => a + b
cb := CallbackCreate(AddFloats, , [Float64, Float64, Float64])
result := DllCall(cb, "Double", 1.5, "Double", 2.7, "Double")
CallbackFree(cb)
```

Without types, float values get misread from integer registers on x64. Typed callbacks fix this.

### Mixed Types

```ahk2
Multiply(x, factor) => x * factor
cb := CallbackCreate(Multiply, , [Float64, Int32, Float64])
```

---

## Pointer Types

### Struct.Ptr

Every struct automatically gets a `.Ptr` subclass. Use `Struct.At(ptr)` for zero-copy views into existing memory:

```ahk2
; In a WM_NOTIFY handler:
WM_NOTIFY(wParam, lParam, msg, hwnd) {
    hdr := NMHDR.At(lParam)
    if hdr.code == -12
        ncd := NMCUSTOMDRAW.At(lParam)
}
```

No allocation, no copying -- just a typed overlay on a raw pointer.

### DllCall Integration

Pass struct types directly to `DllCall`:

```ahk2
Struct SYSTEMTIME {
    wYear: u16
    wMonth: u16
    wDayOfWeek: u16
    wDay: u16
    wHour: u16
    wMinute: u16
    wSecond: u16
    wMilliseconds: u16
}

st := SYSTEMTIME()
DllCall("GetLocalTime", SYSTEMTIME, st)
```

Alpha 26 added: passing `unset` for a struct param auto-creates a default instance.

---

## DefineProp

### Top-Level Function

Alpha 22 added `DefineProp()` as a standalone function (not just `obj.DefineProp()`):

```ahk2
obj := {}
DefineProp(obj, "Name", {
    Get: (this) => this._name ?? "unnamed",
    Set: (this, value) => this._name := value
})
```

### On Class Prototypes

```ahk2
DefineProp(Counter.Prototype, "Count", {
    Get: (this) => this._count,
    Set: (this, value) => this._count := Max(0, value)
})
```

### GetOwnPropDesc

Returns the actual type class (not a string) for struct fields:

```ahk2
desc := Sensor.Prototype.GetOwnPropDesc("value")
; desc.Type = Float32  (the class itself)
```

Enables runtime introspection of struct layouts.

---

## Window Management

### ahk_opt

Alpha 25 introduced inline window search options via `ahk_opt`. No more toggling global state:

```ahk2
; Old way -- changes global setting
DetectHiddenWindows(true)
hwnd := WinExist("Notepad")
DetectHiddenWindows(false)

; New way -- per-call, no side effects
hwnd := WinExist("Notepad ahk_opt Hidden 2")
```

### Options

| Option | Effect |
|--------|--------|
| `Hidden` | Detect hidden windows |
| `Hidden0` | Ignore hidden windows |
| `HiddenText` | Detect hidden text |
| `1` / `2` / `3` / `RegEx` | Title match mode |
| `Fast` / `Slow` | Detection speed |

Combine with other criteria: `"ahk_class Shell_TrayWnd ahk_opt Hidden"`

---

## Module System

### Export Syntax

Alpha 22 changed `export func() => expr` to be a function call, not a definition. Use block syntax:

```ahk2
export MyFunc(x) {
    return x * 2
}
```

### Wildcard Re-Export

Alpha 24 added `#Import Export ModuleName {*}` for barrel modules:

```ahk2
; math/index.ahk
#Module Math
#Import Export Math.Vector {*}
#Import Export Math.Matrix {*}

; app.ahk
#Import Math {Vec2, Mat4}  ; works via re-export
```

---

## Type System

### Type() and IsSet()

`Type()` with no argument returns `"unset"` instead of throwing:

```ahk2
FormatValue(val?) {
    if !IsSet(val)
        return "(unset)"
    switch Type(val) {
        case "Integer": return Format("int: {}", val)
        case "String":  return Format("str: {}", val)
    }
}
```

Alpha 26 fixed `IsSet(var?)` -- the maybe-unset `?` suffix now works inside `IsSet()`.

---

## Performance

### Memory Co-Allocation (Alpha 26)

Typed property memory is now allocated with the main object in a single allocation:

- 1 allocation instead of 2 per struct
- Better cache locality (header + field data adjacent)
- Lower GC pressure

Measurable in hot loops: particle systems, batch API calls, anything creating many short-lived structs.

### .Size Fix (Alpha 23)

`.Size` returns the struct's layout size (matching C `sizeof()`), not the internal allocation size. Critical for APIs that require `dwLength := ms.Size`.

---

## Behavioral Fixes

### Hotkeys (Alpha 25)
- Key-up hotkeys fire consistently when used as both prefix and suffix
- Neutral modifiers (`Alt & Esc::`) work in custom combos
- Key suppression respects `SendLevel`

### Reload (Alpha 26)
- `#SingleInstance` / `Reload` now sends `WM_CLOSE` to the old instance
- `OnExit` callbacks and `__Delete` destructors fire normally during reload

### Modal Dialogs (Alpha 26)
- Keyboard shortcuts (`Ctrl+C`, `Tab`, accelerators) work while MsgBox is displayed
- Message loop rewritten to dispatch to all windows, not just the active modal

### GUI (Alpha 25)
- Control sizing fixed for Windows 7
- Timer threads wait for MsgBox to fully display before firing

---

## Quick Reference

### Common Win32 Structs

```ahk2
Struct POINT { x: i32, y: i32 }
Struct RECT { left: i32, top: i32, right: i32, bottom: i32 }
Struct SIZE { cx: i32, cy: i32 }

Struct SYSTEMTIME {
    wYear: u16, wMonth: u16, wDayOfWeek: u16, wDay: u16
    wHour: u16, wMinute: u16, wSecond: u16, wMilliseconds: u16
}

Struct MEMORYSTATUSEX {
    dwLength: u32, dwMemoryLoad: u32
    ullTotalPhys: u64, ullAvailPhys: u64
    ullTotalPageFile: u64, ullAvailPageFile: u64
    ullTotalVirtual: u64, ullAvailVirtual: u64
    ullAvailExtendedVirtual: u64
}
```

### Patterns

```ahk2
; Get cursor position
pt := POINT()
DllCall("GetCursorPos", POINT, pt)

; Get system time
st := SYSTEMTIME()
DllCall("GetLocalTime", SYSTEMTIME, st)

; Memory info
ms := MEMORYSTATUSEX()
ms.dwLength := ms.Size
DllCall("GlobalMemoryStatusEx", MEMORYSTATUSEX, ms)

; Float callback
cb := CallbackCreate(MyFunc, , [Float64, Float64, Float64])
result := DllCall(cb, "Double", 1.5, "Double", 2.7, "Double")
CallbackFree(cb)

; Hidden window search
hwnd := WinExist("ahk_class Shell_TrayWnd ahk_opt Hidden")
```
