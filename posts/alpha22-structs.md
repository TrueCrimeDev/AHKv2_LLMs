# AutoHotkey v2.1-alpha.22: The Struct Revolution

Alpha.22 is the most significant AHK v2 alpha release to date. It introduces the native `Struct` keyword -- a first-class language construct for defining typed memory layouts. This single feature transforms how AHK scripts interact with the Windows API, replacing fragile `NumPut`/`NumGet` patterns with clean, type-safe declarations.

## The Struct Keyword

The `Struct` keyword creates classes with defined memory layouts. Fields use typed annotations that map directly to C data types:

```cpp
Struct POINT {
    x: i32
    y: i32
}

pt := POINT()
pt.x := 100
pt.y := 200
; Type=POINT, Size=8 bytes
```

### Type Annotations

| AHK Type | C Equivalent | Size | Range |
|----------|-------------|------|-------|
| `i32` | `int` | 4 bytes | -2B to 2B |
| `u32` | `unsigned int` | 4 bytes | 0 to 4B |
| `i16` / `u16` | `short` | 2 bytes | signed/unsigned |
| `i8` / `u8` | `char` | 1 byte | signed/unsigned |
| `i64` / `u64` | `long long` | 8 bytes | 64-bit range |
| `iptr` / `uptr` | `intptr_t` | 4 or 8 bytes | pointer-sized |

These replace the old approach of manually calculating offsets with `NumPut("Int", value, buf, offset)`. The struct handles layout, alignment, and byte ordering automatically.

### Nested Structs

Structs can embed other structs, and the memory layout is computed correctly:

```cpp
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
    dwItemSpec: uptr
    uItemState: u32
    lItemlParam: iptr
}

ncd := NMCUSTOMDRAW()
ncd.hdr.code := -12  ; NM_CUSTOMDRAW
ncd.rc.left := 10    ; access nested fields naturally
```

This is a massive ergonomic improvement. Previously, accessing nested struct fields required manual offset math like `NumGet(buf, 16 + 0, "Int")` -- error-prone and unreadable.

## Automatic Struct.Ptr Subclasses

Every `Struct` automatically gets a `.Ptr` subclass for pointer handling. This replaces the old `StructFromPtr` function.

```cpp
; In a WM_NOTIFY handler:
WM_NOTIFY(wParam, lParam, msg, hwnd) {
    hdr := NMHDR.At(lParam)  ; zero-copy view at lParam
    if hdr.code == -12
        ncd := NMCUSTOMDRAW.At(lParam)
}
```

`Struct.At(ptr)` provides a zero-copy view into existing memory. No allocation, no copying -- just a typed overlay on a raw pointer. This is essential for callback handlers where Windows passes struct pointers through `lParam`.

## DefineProp() as a Top-Level Function

Alpha.22 adds `DefineProp()` as a standalone function, complementing the existing `obj.DefineProp()` method:

```cpp
obj := {}
DefineProp(obj, "Name", {
    Get: (this) => this._name ?? "unnamed",
    Set: (this, value) => this._name := value
})
obj.Name := "alpha22"  ; uses the setter
```

The top-level form is useful when the target object is dynamic or passed as a parameter. It also works for adding properties to class prototypes:

```cpp
DefineProp(Counter.Prototype, "Count", {
    Get: (this) => this._count,
    Set: (this, value) => this._count := Max(0, value)
})
```

## Type() Returns "unset"

`Type()` called with no argument (or an omitted optional parameter) now returns the string `"unset"` instead of throwing an error. This enables clean type-dispatch patterns:

```cpp
FormatValue(val?) {
    if !IsSet(val)
        return "(unset)"
    switch Type(val) {
        case "Integer", "Float": return Format("Number: {}", val)
        case "String":           return Format('String: "{}"', val)
        case "Array":            return Format("Array[{}]", val.Length)
    }
}
```

## IsSet() Permits Unset Expressions

`IsSet()` can now take optional parameters directly, and correctly returns `0` for unset virtual references:

```cpp
SmartFunc(a, b?, c?) {
    parts := [Format("a={}", a)]
    parts.Push(IsSet(b) ? Format("b={}", b) : "b=unset")
    parts.Push(IsSet(c) ? Format("c={}", c) : "c=unset")
}
```

## Export Syntax Change

A subtle but important change: `export func() => expr` is now treated as a function **call** (matching v2.0 behavior), not a fat-arrow definition. Exported module functions must use block syntax:

```cpp
; WRONG in alpha.22+:
export MyFunc(x) => x * 2

; CORRECT:
export MyFunc(x) {
    return x * 2
}
```

## Practical: Win32 API with Structs

The real power of the `Struct` keyword shows in Win32 API calls. Define once, use everywhere:

```cpp
Struct MEMORYSTATUSEX {
    dwLength: u32
    dwMemoryLoad: u32
    ullTotalPhys: u64
    ullAvailPhys: u64
    ullTotalPageFile: u64
    ullAvailPageFile: u64
    ullTotalVirtual: u64
    ullAvailVirtual: u64
    ullAvailExtendedVirtual: u64
}

ms := MEMORYSTATUSEX()
ms.dwLength := ms.Size
DllCall("GlobalMemoryStatusEx", MEMORYSTATUSEX, ms)
```

Compare this to the old approach -- a `Buffer` with manual `NumPut`/`NumGet` at hardcoded offsets. The struct version is self-documenting, type-safe, and impossible to get wrong.

## Bug Fixes

- Fixed `!~=` (not-regex-match) operator
- `DllCall` now requires proper `Struct` subclasses for struct parameters (no more `ObjGetDataPtr` fallback)
- `#Import __Init` works without sub-modules
- Module reopening at end of file fixed
