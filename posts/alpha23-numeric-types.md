# AutoHotkey v2.1-alpha.23: Numeric Types and Struct Arrays

Alpha.23 builds on the Struct foundation from alpha.22 with two major additions: dedicated numeric type classes and structured array syntax. Together they bring C-level data handling to AHK scripts.

## Numeric Type Classes

Alpha.23 introduces named numeric types that extend the Struct system. These replace the short-form annotations (`i32`, `u8`) with full class names:

| Class | Size | Description |
|-------|------|-------------|
| `Int8` / `UInt8` | 1 byte | Signed/unsigned byte |
| `Int16` / `UInt16` | 2 bytes | Signed/unsigned short |
| `Int32` / `UInt32` | 4 bytes | Signed/unsigned int |
| `Int64` / `UInt64` | 8 bytes | Signed/unsigned long |
| `Float32` | 4 bytes | Single-precision float |
| `Float64` | 8 bytes | Double-precision float |
| `IntPtr` / `UIntPtr` | Platform | Pointer-sized integer |

These work as struct field types and enable float support in struct definitions:

```cpp
Struct Vec3f {
    x: Float32
    y: Float32
    z: Float32
}

v := Vec3f()
v.x := 1.5, v.y := 2.7, v.z := -3.14
; 12 bytes total
```

### Mixed Types

Numeric types can be freely mixed in a single struct. The compiler handles alignment automatically:

```cpp
Struct SensorReading {
    timestamp: Int64       ; 8 bytes
    temperature: Float32   ; 4 bytes
    humidity: Float32      ; 4 bytes
    sensor_id: UInt16      ; 2 bytes
    flags: UInt8           ; 1 byte
}
```

This maps directly to how you'd define the struct in C. The AHK runtime computes proper padding and alignment so the memory layout matches what a C compiler would produce.

## Struct Arrays with StructClass[N]

The `StructClass[N]` syntax creates typed arrays -- contiguous blocks of memory holding N elements of a given type. This is one of the most requested features for Win32 interop.

### Primitive Arrays

```cpp
a := Int32[4]()
a[1] := 10, a[2] := 20, a[3] := 30, a[4] := 40
; 16 bytes total, Length=4
```

Key behaviors:
- **1-based indexing** (consistent with AHK arrays)
- **Negative indexing** supported: `a[-1]` returns the last element
- **`.Size`** returns the total byte size
- **`.Length`** returns the element count

### Float Arrays

```cpp
f := Float64[3]()
f[1] := 3.14159
f[2] := 2.71828
f[3] := 1.41421
; 24 bytes total
```

Float arrays are critical for scientific computing, graphics, and any API that expects a contiguous buffer of doubles or floats.

### Struct Arrays

The real power: arrays of user-defined structs.

```cpp
Struct POINT {
    x: i32
    y: i32
}

pa := POINT[3]()
pa[1].x := 10,  pa[1].y := 20
pa[2].x := 100, pa[2].y := 200
pa[3].x := 50,  pa[3].y := 150
; 24 bytes (3 * 8)
```

Each element is a full struct instance. You access fields with the standard dot notation after indexing. The memory is contiguous -- exactly what Win32 APIs like `Polyline()` or `SetDIBColorTable()` expect.

### Byte Buffers

`UInt8[N]` creates a typed byte buffer, useful for raw data manipulation:

```cpp
h := UInt8[32]()
loop 32
    h[A_Index] := Mod(A_Index * 17, 256)
```

### Practical: Color Palettes

Struct arrays shine when working with Win32 GDI:

```cpp
Struct RGBQUAD {
    blue: u8
    green: u8
    red: u8
    reserved: u8
}

pal := RGBQUAD[256]()
loop 256
    pal[A_Index].red := pal[A_Index].green := pal[A_Index].blue := A_Index - 1
; 1024 bytes -- a complete 256-color grayscale palette
```

This can be passed directly to `SetDIBColorTable` or any GDI function that expects an array of `RGBQUAD` values.

## Struct.Prototype.Size Fix

Alpha.23 fixes `.Size` to return the struct's **layout size** rather than the allocated object size. Previously, `.Size` could return a larger value that included internal AHK overhead. Now it matches the C `sizeof()` equivalent:

```cpp
Struct SmallPair {
    a: u8
    b: u8
}

s := SmallPair()
; s.Size = 2 bytes (correct C layout size)
```

This matters when passing struct sizes to Win32 APIs (like `MEMORYSTATUSEX.dwLength := ms.Size`) -- the value must match what the API expects.

## Why This Release Matters

Alpha.22 gave us the Struct keyword. Alpha.23 makes it production-ready:

- **Float support** via `Float32`/`Float64` types enables graphics, audio, and scientific APIs
- **Struct arrays** eliminate the need for manual buffer math when working with array parameters
- **Negative indexing** brings modern language ergonomics to low-level data access
- **Correct `.Size`** ensures Win32 API compatibility
