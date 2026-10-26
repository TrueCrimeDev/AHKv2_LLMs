#Requires AutoHotkey v2.1-alpha.36

; alpha.36: ObjCreateWithDataPtr(ClassObj, Address) creates an instance of any
; directly constructible class whose data pointer is Address. It skips __Init
; and __New (instance initializers do not run) but calls __Delete on release,
; and unlike StructClass.At it accepts Address 0. Typed properties on the
; object read and write the memory at Address.
;
; Before alpha.36 the function did not exist; StructClass.At was the only way
; to view memory, and only through a struct.

; --- 1. Pixel views over a raw RGBA buffer ---------------------------------------
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
loop 3 {
    p := View(A_Index)
    Print("pixel {}: {} alpha {}", A_Index, p.Hex, p.a)
}
View(2).Fade(50)
Print("after Fade(50) on pixel 2: byte 7 of the buffer = {}", NumGet(pixels, 7, "UChar"))

; --- 2. The constructor is skipped, the destructor is not --------------------------
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

; --- 3. Numeric classes, Address 0, and reading the pointer back ----------------
v := ObjCreateWithDataPtr(Int32, counter.Ptr)
v.__Value := 1000
Print("Int32 view wrote {}; ObjGetDataPtr matches: {}", NumGet(counter, "Int"), ObjGetDataPtr(v) = counter.Ptr)
z := ObjCreateWithDataPtr(Int32, 0)
Print("Address 0 is allowed: ObjGetDataPtr = {}   (Int32.At(0) throws)", ObjGetDataPtr(z))
try Int32.At(0)
catch Error as e
    Print("Int32.At(0): {}", e.Message)
try ObjCreateWithDataPtr(Int32, 100)
catch ValueError as e
    Print("ObjCreateWithDataPtr(Int32, 100): {}", e.Message)

; --- 4. A data pointer on a Map (needs the +Console fork, see the post) -------------
; The official alpha.36 build stores the pointer over a Map's own fields and
; corrupts the heap (exit 127 on release). The fork fixed that before shipping
; alpha.36, so this section only runs there.
if InStr(A_AhkVersion, "+Console") {
    tagged := ObjCreateWithDataPtr(Map, counter.Ptr)
    tagged["name"] := "a Map that carries an address"
    Print("Map with data pointer: Count {}  ptr matches {}", tagged.Count, ObjGetDataPtr(tagged) = counter.Ptr)
    tagged := ""
    Print("released cleanly")
} else
    Print("skipping the Map section on {}", A_AhkVersion)
