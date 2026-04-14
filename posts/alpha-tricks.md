# AHK v2.1 Alpha Tricks: Unions, Arenas, and Prototype Black Magic

A collection of advanced patterns that combine alpha features in unexpected ways. Each trick uses struct unions, typed callbacks, `DefineProp`, or `Struct.At` to do something that would have been painful or impossible in v2.0.

All examples require `#Requires AutoHotkey v2.1-alpha.26`.

---

## IEEE 754 Float Dissection

Union a `Float64` with a `UInt64` to read the raw sign, exponent, and mantissa bits of any floating-point number. Zero copies -- the same 8 bytes are just interpreted differently.

```ahk2
Struct F64Bits {
    raw: u64
}
DefineProp(F64Bits.Prototype, "f", {Type: Float64, Offset: 0})

fv := F64Bits()
fv.f := -3.14
sign := (fv.raw >> 63) & 1        ; => 1
exp  := (fv.raw >> 52) & 0x7FF    ; => 1024
mant := fv.raw & 0xFFFFFFFFFFFFF  ; => 0x91EB851EB851F
```

Write a float, read the raw bits. This is the same technique graphics programmers use for fast inverse square root or NaN boxing. The union overlay means there's no conversion -- `fv.f` and `fv.raw` are the same memory.

---

## IPv4 Address as u32/4xu8 Overlay

Pack an IP address as a single `u32` for network calls, but read/write individual octets through byte overlays:

```ahk2
Struct IPv4 {
    addr: u32
}
DefineProp(IPv4.Prototype, "a", {Type: UInt8, Offset: 0})
DefineProp(IPv4.Prototype, "b", {Type: UInt8, Offset: 1})
DefineProp(IPv4.Prototype, "c", {Type: UInt8, Offset: 2})
DefineProp(IPv4.Prototype, "d", {Type: UInt8, Offset: 3})

ip := IPv4()
ip.a := 192, ip.b := 168, ip.c := 1, ip.d := 42
; ip.addr => 0x2A01A8C0 (little-endian packed)
```

Set octets individually, pass `ip.addr` as a single integer to Winsock APIs. Or receive a packed address from the network and read the octets back out. Same union pattern as the float trick.

---

## Named Bit Flags via Helper

Turn a raw `u32` bitfield into named boolean properties with a generic helper:

```ahk2
Struct Perms {
    bits: u32
}

BitFlag(proto, name, bit) {
    DefineProp(proto, name, {
        Get: (this) => (NumGet(this, 0, "UInt") >> bit) & 1,
        Set: (this, v) => NumPut("UInt", v
            ? NumGet(this, 0, "UInt") | (1 << bit)
            : NumGet(this, 0, "UInt") & ~(1 << bit), this)
    })
}

BitFlag(Perms.Prototype, "Read",    0)
BitFlag(Perms.Prototype, "Write",   1)
BitFlag(Perms.Prototype, "Execute", 2)

f := Perms()
f.Read := 1, f.Execute := 1
; f.Read => 1, f.Write => 0, f.Execute => 1, f.bits => 5
```

The `BitFlag` helper is reusable -- call it for any struct with a flags field. Each named property reads/writes a single bit without touching the others. Works for Win32 style flags, file permissions, hardware registers, etc.

---

## RGBA Color with Mix and Hex

A color struct with union byte access plus callable methods for hex formatting and linear interpolation:

```ahk2
Struct RGBA {
    packed: u32
}
DefineProp(RGBA.Prototype, "r", {Type: UInt8, Offset: 0})
DefineProp(RGBA.Prototype, "g", {Type: UInt8, Offset: 1})
DefineProp(RGBA.Prototype, "b", {Type: UInt8, Offset: 2})
DefineProp(RGBA.Prototype, "a", {Type: UInt8, Offset: 3})

DefineProp(RGBA.Prototype, "Hex", {
    Call: (this) => Format("#{:02X}{:02X}{:02X}", this.r, this.g, this.b)
})

DefineProp(RGBA.Prototype, "Mix", {
    Call: (this, o, t := 0.5) => RGB(
        Integer(this.r + (o.r - this.r) * t),
        Integer(this.g + (o.g - this.g) * t),
        Integer(this.b + (o.b - this.b) * t))
})

RGB(r, g, b, a := 255) {
    c := RGBA()
    c.r := r, c.g := g, c.b := b, c.a := a
    return c
}

red := RGB(255, 0, 0)
blue := RGB(0, 0, 255)
; red.Hex()           => "#FF0000"
; red.Mix(blue).Hex() => "#7F007F"
```

The `Mix` method returns a new `RGBA` instance, so you can chain: `red.Mix(blue, 0.3).Hex()`. The factory function `RGB()` keeps construction clean.

---

## Vec2 with Math Methods

A 2D vector struct with add, scale, dot product, length, normalize, and string conversion -- all attached via `DefineProp`:

```ahk2
Struct Vec2 {
    x: f32
    y: f32
}

V(x, y) {
    v := Vec2()
    v.x := x, v.y := y
    return v
}

DefineProp(Vec2.Prototype, "Add",   {Call: (this, o) => V(this.x + o.x, this.y + o.y)})
DefineProp(Vec2.Prototype, "Scale", {Call: (this, s) => V(this.x * s, this.y * s)})
DefineProp(Vec2.Prototype, "Dot",   {Call: (this, o) => this.x * o.x + this.y * o.y})
DefineProp(Vec2.Prototype, "Len",   {Get:  (this) => Sqrt(this.x ** 2 + this.y ** 2)})
DefineProp(Vec2.Prototype, "Norm",  {Call: (this) => this.Scale(1 / this.Len)})
DefineProp(Vec2.Prototype, "Str",   {Call: (this) => Format("({:.1f},{:.1f})", this.x, this.y)})

a := V(3, 4)
b := V(1, 2)
; a.Add(b).Str()   => "(4.0,6.0)"
; a.Scale(3).Str() => "(9.0,12.0)"
; a.Dot(b)         => 11.0
; a.Len            => 5.0
; a.Norm().Str()   => "(0.6,0.8)"
```

`Len` is a getter (no parens), everything else is a `Call`. Methods return new `Vec2` instances so the original is never mutated. `Float32` fields keep the struct at 8 bytes -- small enough to allocate thousands.

---

## Mat3 with Inline Float64[9]

A 3x3 matrix using an inline `Float64[9]` array with matrix multiplication:

```ahk2
Struct Mat3 {
    m: Float64[9]
}

M3(vals*) {
    mat := Mat3()
    for v in vals
        mat.m[A_Index] := v
    return mat
}

DefineProp(Mat3.Prototype, "Mul", {Call: (this, o) {
    r := Mat3()
    loop 3 {
        i := A_Index
        loop 3 {
            j := A_Index
            s := 0.0
            loop 3
                s += this.m[(i-1)*3 + A_Index] * o.m[(A_Index-1)*3 + j]
            r.m[(i-1)*3 + j] := s
        }
    }
    return r
}})

id    := M3(1,0,0, 0,1,0, 0,0,1)
scale := M3(2,0,0, 0,3,0, 0,0,1)
; id.Mul(scale).m[1] => 2.0
; id.Mul(scale).m[5] => 3.0
```

The `Float64[9]` array is embedded directly in the struct -- one allocation for the entire matrix. The `Mul` method does standard row-by-column multiplication. Extend this to `Mat4` for 3D transforms.

---

## Prototype Black Magic

Extend built-in `Integer`, `Float`, and `String` prototypes at the language level:

```ahk2
DefineProp(Integer.Prototype, "Hex", {
    Call: (this, w := 0) => w
        ? Format("0x{:0" w "X}", this)
        : Format("0x{:X}", this)
})

DefineProp(Integer.Prototype, "Clamp", {
    Call: (this, lo, hi) => Min(Max(this, lo), hi)
})

DefineProp(Float.Prototype, "Clamp", {
    Call: (this, lo, hi) => Min(Max(this, lo), hi)
})

DefineProp(Integer.Prototype, "Times", {
    Call: (this, fn) {
        loop this
            fn(A_Index)
    }
})

; (255).Hex()          => "0xFF"
; (255).Hex(4)         => "0x00FF"
; (-50).Clamp(0, 100)  => 0
; (3.14).Clamp(0, 1)   => 1.0
```

This works because AHK v2 exposes `.Prototype` on primitive types. Every integer literal gains `.Hex()`, `.Clamp()`, and `.Times()`. Use sparingly -- this modifies global behavior.

---

## Type Dispatch with Unset

Use `Type()` returning `"unset"` and `IsSet()` for clean multi-type dispatch:

```ahk2
Describe(val?) {
    if !IsSet(val)
        return "nothing"
    switch Type(val) {
        case "Integer": return val " (int)"
        case "Float":   return Format("{:.2f} (float)", val)
        case "String":  return '"' val '" (str)'
        case "Array":   return "[" val.Length " items]"
        default:        return Type(val)
    }
}

; Describe(42)    => "42 (int)"
; Describe(3.14)  => "3.14 (float)"
; Describe("hi")  => '"hi" (str)'
; Describe()      => "nothing"
```

The `val?` optional parameter combined with `IsSet()` handles the missing-argument case without throwing. This pattern is useful for building serializers, loggers, or debug formatters.

---

## Ring Buffer

A fixed-size circular buffer backed by a `Float64[8]` array inside a struct:

```ahk2
Struct Ring {
    data: Float64[8]
    head: u32
    count: u32
}

DefineProp(Ring.Prototype, "Push", {Call: (this, v) {
    idx := Mod(this.head + this.count, 8) + 1
    this.data[idx] := v
    if this.count < 8
        this.count += 1
    else
        this.head := Mod(this.head + 1, 8)
}})

DefineProp(Ring.Prototype, "Peek", {
    Call: (this, i := 0) => this.data[Mod(this.head + i, 8) + 1]
})

r := Ring()
loop 12
    r.Push(A_Index * 1.1)
; r.count  => 8 (capped at buffer size)
; r.Peek() => 5.5 (oldest surviving value)
```

The entire buffer is one struct allocation. `Push` overwrites the oldest entry when full. `Peek(0)` reads the oldest, `Peek(count-1)` reads the newest. Useful for rolling averages, input history, or sensor data windows.

---

## Arena Allocator via Struct.At

Pre-allocate a single buffer and stamp out zero-copy struct views with `Struct.At`:

```ahk2
Struct Particle {
    x: f32
    y: f32
    vx: f32
    vy: f32
}

arena := Buffer(Particle().Size * 1000)

Spawn(idx) => Particle.At(arena.Ptr + (idx - 1) * Particle().Size)

p := Spawn(1)
p.x := 100, p.y := 200, p.vx := 1.5, p.vy := -0.5

q := Spawn(2)
q.x := 300, q.y := 400
; 1000 particles, one allocation, zero copies
```

`Struct.At()` creates a typed view at an arbitrary pointer without allocating. The arena pattern gives you predictable memory layout and cache-friendly iteration. Free everything at once by dropping the `Buffer`.

---

## Typed Callback: Floats That Actually Work

Without typed parameters, float values get misread from integer registers on x64. The type array fixes this:

```ahk2
Dist(ax, ay, bx, by) => Sqrt((bx - ax) ** 2 + (by - ay) ** 2)

cb := CallbackCreate(Dist, , [Float64, Float64, Float64, Float64, Float64])
result := DllCall(cb, "Double", 0, "Double", 0, "Double", 3, "Double", 4, "Double")
; result => 5.0
CallbackFree(cb)
```

The last element in the array is the return type. This is the only way to pass floats through callbacks correctly on x64 -- the ABI uses XMM registers for floats, not the general-purpose registers that untyped callbacks read from.

---

## Dynamic Class Factory

Build struct-like classes at runtime from string specifications:

```ahk2
MakeType(name, fields) {
    cls := Class(name)
    off := 0
    sizes := Map("u8", 1, "u16", 2, "u32", 4, "f32", 4, "f64", 8)
    types := Map("u8", UInt8, "u16", UInt16, "u32", UInt32, "f32", Float32, "f64", Float64)
    for spec in fields {
        parts := StrSplit(spec, ":")
        DefineProp(cls.Prototype, Trim(parts[1]), {Type: types[Trim(parts[2])], Offset: off})
        off += sizes[Trim(parts[2])]
    }
    return cls
}

Pixel := MakeType("Pixel", ["r:u8", "g:u8", "b:u8", "a:u8"])
px := (Object.Call)(Pixel)
px.r := 255, px.g := 128, px.b := 0, px.a := 255
; px.r => 255, px.g => 128
```

`MakeType` reads a list of `"name:type"` strings, computes offsets, and attaches typed properties to a new class. This is a schema-driven approach -- you could load field definitions from a config file, a database, or a protocol spec. The runtime class behaves identically to a `Struct` declaration.
