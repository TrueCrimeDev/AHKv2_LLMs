#Requires AutoHotkey v2.1-alpha.27
Echo(fmt, args*) => FileAppend(Format(fmt, args*) "`n", "*")   ; native stdout

; alpha.27: destructors of nested structs and of structs inside typed arrays
; now run reliably. __Delete runs on the outer object first, then on each
; embedded struct, and every element of a Struct[N] array is destructed when
; the array goes away.
; Before alpha.27 an array element with nested objects could skip its
; destructor and keep its Base reference alive (e6ed8924), so a wrapper that
; releases a handle in __Delete could leak when stored in an array.

; --- 1. A GDI handle that releases itself --------------------------------------
struct Brush {
    h : IntPtr
    Create(rgb) {
        this.h := DllCall("gdi32\CreateSolidBrush", "UInt", rgb, "Ptr")
        return this
    }
    __Delete() {
        if this.h {
            DllCall("gdi32\DeleteObject", "Ptr", this.h)
            Echo("  released brush 0x{:X}", this.h)
        }
    }
}
b := Brush().Create(0x0000FF)
Echo("brush 0x{:X} created", b.h)
b := ""                                 ; last reference gone: __Delete runs now

; --- 2. Outer first, then nested -----------------------------------------------
struct Pen {
    id : Int32
    __Delete() => Echo("  ~Pen {}", this.id)
}
struct Toolkit {
    pen : Pen
    __Delete() => Echo("  ~Toolkit (pen {})", this.pen.id)
}
t := Toolkit()
t.pen.id := 7
Echo("dropping a Toolkit:")
t := ""

; --- 3. Every element of an array is destructed ---------------------------------
Echo("dropping a Toolkit[3]:")
kits := Toolkit[3]()
loop 3
    kits[A_Index].pen.id := A_Index
kits := ""

; --- 4. Brushes in an array are all released ------------------------------------
Echo("dropping a Brush[2]:")
brushes := Brush[2]()
brushes[1].Create(0xFF0000), brushes[2].Create(0x00FF00)
brushes := ""
Echo("done")
