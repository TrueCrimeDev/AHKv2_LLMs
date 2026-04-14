/*
Alpha24_Example.ahk -- AutoHotkey v2.1-alpha.24 feature showcase

Features demonstrated:
  1. CallbackCreate with typed parameter arrays
  2. DefineProp Offset for union-like field overlays
  3. Struct.Ptr inheritance chain
  4. GetOwnPropDesc returns type classes
  5. #Import Export X {*} wildcard re-export
  6. Struct circular reference and cleanup fixes

Run: bin\AutoHotkey64.exe Alpha24_Example.ahk
*/
#Requires AutoHotkey v2.1-alpha.24

; CALLBACKCREATE -- typed parameter arrays

; Classic: count-based (integer-only)
AddInts(a, b) => a + b
cb_classic := CallbackCreate(AddInts, , 2)
r_classic := DllCall(cb_classic, "Int", 15, "Int", 27, "Int")
CallbackFree(cb_classic)

; Typed: [ParamTypes..., ReturnType]
cb_typed := CallbackCreate(AddInts, , [Int32, Int32, Int32])
r_typed := DllCall(cb_typed, "Int", 100, "Int", 200, "Int")
CallbackFree(cb_typed)

; Float callback -- without typed params, float values get misread
; from integer registers instead of XMM registers on x64
AddFloats(a, b) => a + b
cb_float := CallbackCreate(AddFloats, , [Float64, Float64, Float64])
r_float := DllCall(cb_float, "Double", 1.5, "Double", 2.7, "Double")
CallbackFree(cb_float)

; Mixed int + float
Multiply(x, factor) => x * factor
cb_mix := CallbackCreate(Multiply, , [Float64, Int32, Float64])
r_mix := DllCall(cb_mix, "Double", 3.14, "Int", 3, "Double")
CallbackFree(cb_mix)

; DEFINEPROP OFFSET -- C-style unions

; VARIANT-style discriminated union: multiple types at same offset
Struct Variant {
    vtype: u16
}
DefineProp(Variant.Prototype, "intVal",  {Type: Int32,   Offset: 8})
DefineProp(Variant.Prototype, "fltVal",  {Type: Float64, Offset: 8})
DefineProp(Variant.Prototype, "ptrVal",  {Type: IntPtr,  Offset: 8})

vInt := Variant()
vInt.vtype := 3   ; VT_I4
vInt.intVal := 42

vFlt := Variant()
vFlt.vtype := 5   ; VT_R8
vFlt.fltVal := 3.14159

; RGBA color: packed u32 with individual byte overlays
Struct Color {
    rgba: u32
}
DefineProp(Color.Prototype, "r", {Type: UInt8, Offset: 0})
DefineProp(Color.Prototype, "g", {Type: UInt8, Offset: 1})
DefineProp(Color.Prototype, "b", {Type: UInt8, Offset: 2})
DefineProp(Color.Prototype, "a", {Type: UInt8, Offset: 3})

c := Color()
c.rgba := 0xFF8040C0
c_r := c.r, c_g := c.g, c_b := c.b, c_a := c.a

; Write channels, read as packed
c.r := 0x00, c.g := 0xFF, c.b := 0x00, c.a := 0xFF
c_packed := c.rgba

; Named offset: reference another field's position
Struct Register {
    lo: u16
    hi: u16
}
DefineProp(Register.Prototype, "full", {Type: UInt32, Offset: "lo"})

reg := Register()
reg.full := 0xDEADBEEF

; STRUCT.PTR INHERITANCE

; a.Ptr subclasses a.base.Ptr -- proper polymorphism
Struct Shape {
    area: Float64
}

Struct Circle extends Shape {
    radius: Float64
}

ci := Circle()
ci.radius := 5.0
ci.area := 3.14159 * ci.radius ** 2
; Circle.Ptr -> Shape.Ptr -> Struct.Ptr

; GETOWNPROPDESC -- runtime type introspection

Struct Sensor {
    value: Float32
    id: UInt16
    flags: UInt8
}

; desc.Type returns the actual class (Float32, etc.)
sensorFields := Map()
for field in ["value", "id", "flags"]
    sensorFields[field] := Sensor.Prototype.GetOwnPropDesc(field).Type

; MODULE RE-EXPORT (requires separate files)

; #Import Export ModuleName {*}  -- re-exports all public symbols
;
; ; math/vector.ahk
; #Module Math.Vector
; export Vec2(x, y) => {x: x, y: y}
;
; ; math/index.ahk (barrel module)
; #Module Math
; #Import Export Math.Vector {*}
;
; ; app.ahk
; #Import Math {Vec2}  ; works via re-export

; STRUCT CLEANUP FIXES

; Struct.Ptr and Struct[N] no longer leak via circular refs
Struct Tile {
    id: u16
    elevation: Float32
}
grid := Tile[6]()
loop 6 {
    grid[A_Index].id := A_Index
    grid[A_Index].elevation := A_Index * 1.5
}

; Nested struct release: outer frees inner correctly
Struct Inner { data: u32 }
Struct Outer {
    header: Inner
    tag: u16
}
o := Outer()
o.header.data := 0xCAFEBABE
o.tag := 24

; OUTPUT SUMMARY

stdout := FileOpen("*", "w", "UTF-8")
P(text := "") => stdout.Write(text "`n")

P "=== Alpha.24 Results ==="
P Format("Version: {}", A_AhkVersion)
P ""
P "── Typed Callbacks ──"
P Format("  Classic:  AddInts(15, 27) = {}", r_classic)
P Format("  Typed:    AddInts(100, 200) = {}", r_typed)
P Format("  Float:    AddFloats(1.5, 2.7) = {:.1f}", r_float)
P Format("  Mixed:    Multiply(3.14, 3) = {:.2f}", r_mix)
P ""
P "── Union Overlays ──"
P Format("  Variant(int): vtype={}, intVal={}", vInt.vtype, vInt.intVal)
P Format("  Variant(flt): vtype={}, fltVal={:.5f}", vFlt.vtype, vFlt.fltVal)
P Format("  Color 0xFF8040C0: r=0x{:02X} g=0x{:02X} b=0x{:02X} a=0x{:02X}",
    c_r, c_g, c_b, c_a)
P Format("  After channel write: rgba=0x{:08X}", c_packed)
P Format("  Register 0xDEADBEEF: lo=0x{:04X} hi=0x{:04X}", reg.lo, reg.hi)
P ""
P "── Struct Inheritance ──"
P Format("  Circle: radius={:.1f}, area={:.2f}, Size={} bytes", ci.radius, ci.area, ci.Size)
P ""
P "── Type Introspection ──"
for field, typ in sensorFields
    P Format("  Sensor.{}: Type={}", field, typ)
P ""
P "── Cleanup ──"
P Format("  Tile[6]: [{},{},{},{},{},{}]",
    grid[1].id, grid[2].id, grid[3].id, grid[4].id, grid[5].id, grid[6].id)
P Format("  Nested: Outer.header.data=0x{:08X}, tag={}", o.header.data, o.tag)
