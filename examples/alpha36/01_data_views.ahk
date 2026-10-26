#Requires AutoHotkey v2.1-alpha.36

; alpha.36: ObjCreateWithDataPtr(ClassObj, Address) makes an instance of any
; directly constructible class whose data pointer is Address. __Init and __New
; are skipped, __Delete runs on release, and Address 0 is allowed.
; Before alpha.36 only StructClass.At could view memory, and only via a struct.

; --- 1. Pixel views over a raw RGBA buffer ----------------------------------
; An ordinary class with typed properties and a computed one. Each view is 4
; bytes of the buffer; writing through it writes the buffer.
class Pixel {
    r : UInt8
    g : UInt8
    b : UInt8
    a : UInt8
    Hex => Format("#{:02X}{:02X}{:02X}", this.r, this.g, this.b)
    Fade(pct) => (this.a := Round(this.a * pct / 100), this)
}
pixels := Buffer(3 * 4, 0)
NumPut("UInt", 0xFF0000FF, "UInt", 0xFF00FF00, "UInt", 0xFFFF0000, pixels)   ; little-endian ABGR

View(i) => ObjCreateWithDataPtr(Pixel, pixels.Ptr + (i - 1) * 4)
loop 3
    Print("pixel {}: {} alpha {}", A_Index, View(A_Index).Hex, View(A_Index).a)
View(2).Fade(50)
Print("after Fade(50) on pixel 2: byte 7 of the buffer = {}", NumGet(pixels, 7, "UChar"))

; --- 2. The constructor is skipped, the destructor is not -------------------
class Tracked {
    static log := ""
    label := "set by __Init"              ; an instance initializer
    n : Int32
    __New() => Tracked.log .= "new "
    __Delete() => Tracked.log .= "delete "
}
counter := Buffer(4, 0)
NumPut("Int", 41, counter)
t := ObjCreateWithDataPtr(Tracked, counter.Ptr)
Print("t.n = {}   HasOwnProp(label) = {}   log = `"{}`"", t.n, t.HasOwnProp("label"), Tracked.log)
t.n += 1
t := ""                                   ; release: __Delete runs
Print("buffer now {}   log = `"{}`"", NumGet(counter, "Int"), Tracked.log)

; --- 3. Numeric classes, Address 0, and reading the pointer back ------------
v := ObjCreateWithDataPtr(Int32, counter.Ptr)
v.__Value := 1000
Print("Int32 view wrote {}; ObjGetDataPtr matches: {}", NumGet(counter, "Int"), ObjGetDataPtr(v) = counter.Ptr)
Print("Address 0 is allowed: ObjGetDataPtr = {}", ObjGetDataPtr(ObjCreateWithDataPtr(Int32, 0)))
try Int32.At(0)
catch Error as e
    Print("Int32.At(0): {}", e.Message)
