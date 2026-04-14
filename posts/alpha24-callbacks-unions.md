# AutoHotkey v2.1-alpha.24: Typed Callbacks and C-Style Unions

Alpha.24 adds two features that complete the low-level interop story: typed callbacks via `CallbackCreate` and union-like memory overlays via `DefineProp` offsets. These unlock scenarios that were previously impossible without external DLLs.

## CallbackCreate with Typed Parameters

Before alpha.24, `CallbackCreate` only accepted a parameter count. The runtime treated all values as pointer-sized integers, which worked for integer APIs but broke for floating-point callbacks.

Alpha.24 lets you pass an array of type classes as the third parameter. The last element is the return type; everything before it defines parameter types:

```cpp
; Old way: count-based (integers only)
cb := CallbackCreate(AddInts, , 2)

; New way: typed parameters
cb := CallbackCreate(AddInts, , [Int32, Int32, Int32])
```

### Why This Matters: Float Callbacks

Without type information, float values passed through the callback mechanism get misinterpreted as integers (different CPU registers on x64). Typed callbacks fix this:

```cpp
AddFloats(a, b) => a + b

cb := CallbackCreate(AddFloats, , [Float64, Float64, Float64])
result := DllCall(cb, "Double", 1.5, "Double", 2.7, "Double")
; result = 4.2 (correct)
CallbackFree(cb)
```

Without the type array, this would return garbage because the float values would be read from integer registers instead of XMM registers.

### Mixed Type Callbacks

You can mix integer and float types freely:

```cpp
Multiply(x, factor) => x * factor

cb := CallbackCreate(Multiply, , [Float64, Int32, Float64])
result := DllCall(cb, "Double", 3.14, "Int", 3, "Double")
; result = 9.42
```

This is essential for interacting with C libraries that use mixed-type callback signatures, like audio processing APIs, numerical libraries, or custom DLLs.

## DefineProp Offset: C-Style Unions

The new `Offset` sub-parameter for `DefineProp` lets you place typed fields at explicit byte offsets within a struct. When multiple fields share the same offset, they overlay the same memory -- creating a C-style union.

### VARIANT-Style Unions

The classic use case is a discriminated union like COM's `VARIANT`:

```cpp
Struct Variant {
    vtype: u16
}

; All three value fields overlap at byte offset 8
DefineProp Variant.Prototype, "intVal",  {Type: Int32,   Offset: 8}
DefineProp Variant.Prototype, "fltVal",  {Type: Float64, Offset: 8}
DefineProp Variant.Prototype, "ptrVal",  {Type: IntPtr,  Offset: 8}

v := Variant()
v.vtype := 3     ; VT_I4
v.intVal := 42   ; writes to offset 8 as Int32

v.vtype := 5     ; VT_R8
v.fltVal := 3.14 ; writes to offset 8 as Float64
```

Reading `intVal` and `fltVal` both access the same 8 bytes of memory, just interpreted differently. This is exactly how C unions work.

### RGBA Color Decomposition

A practical example -- access a 32-bit color value both as a whole and as individual bytes:

```cpp
Struct Color {
    rgba: u32
}
DefineProp Color.Prototype, "r", {Type: UInt8, Offset: 0}
DefineProp Color.Prototype, "g", {Type: UInt8, Offset: 1}
DefineProp Color.Prototype, "b", {Type: UInt8, Offset: 2}
DefineProp Color.Prototype, "a", {Type: UInt8, Offset: 3}

c := Color()
c.rgba := 0xFF8040C0
; c.r = 0xC0, c.g = 0x40, c.b = 0x80, c.a = 0xFF
```

Write individual channels, read back as a packed u32 -- or vice versa. No bit shifting needed.

### Named Offsets

You can reference another field's position by name:

```cpp
Struct Register {
    lo: u16
    hi: u16
}
DefineProp Register.Prototype, "full", {Type: UInt32, Offset: "lo"}

reg := Register()
reg.full := 0xDEADBEEF
; reg.lo = 0xBEEF, reg.hi = 0xDEAD
```

`Offset: "lo"` means "place this field at the same byte offset as `lo`." This is more maintainable than hardcoding offset numbers.

## Struct.Ptr Inheritance Chain

Alpha.24 fixes the pointer type hierarchy. `StructA.Ptr` now subclasses `StructA.base.Ptr` instead of directly inheriting from `Struct.Ptr`:

```cpp
Struct Shape {
    area: Float64
}

Struct Circle extends Shape {
    radius: Float64
}

; Inheritance chain: Circle.Ptr -> Shape.Ptr -> Struct.Ptr
```

This means a function that accepts `Shape.Ptr` will also accept `Circle.Ptr` -- proper polymorphism for pointer types. Essential for building type-safe APIs around struct hierarchies.

## #Import Export {*} Wildcard Re-Export

New module syntax for creating barrel/facade modules:

```cpp
; math/vector.ahk
#Module Math.Vector
export Vec2(x, y) => {x: x, y: y}
export Vec3(x, y, z) => {x: x, y: y, z: z}

; math/index.ahk
#Module Math
#Import Export Math.Vector {*}   ; re-exports Vec2, Vec3

; app.ahk
#Import Math {Vec2, Vec3}        ; works via re-export
```

This enables library authors to organize code into sub-modules while presenting a clean public API through a single entry point.

## GetOwnPropDesc Returns Type Classes

`GetOwnPropDesc` now returns the actual type class instead of a string code:

```cpp
Struct Sensor {
    value: Float32
    id: UInt16
    flags: UInt8
}

desc := Sensor.Prototype.GetOwnPropDesc("value")
; desc.Type = Float32 (the class itself, not "Float32")
```

This enables runtime introspection -- you can programmatically examine struct layouts and build serializers, debuggers, or schema generators.

## Bug Fixes

- Struct.Ptr and Struct[N] classes no longer prevent garbage collection (circular reference fix)
- Releasing outer structs properly releases inner struct references
- Class declarations cannot subclass themselves
- `#Import` loops (variable pointing to itself) prevented
