#Requires AutoHotkey v2.1-alpha.31
Echo(fmt, args*) => FileAppend(Format(fmt, args*) "`n", "*")   ; native stdout

; alpha.31: three fixes outside the module system.
;
;   1. Releasing a StructClass.At(ptr) view whose layout holds a nested struct
;      array no longer crashes (alpha.30: "Invalid memory read/write", exit 11).
;   2. A property's getter and setter may be declared in separate blocks in
;      either order (v2.0.27; alpha.30 rejected getter-then-setter as
;      "Duplicate declaration").
;   3. `a := src` where src is a &param bound to an object with __Value no
;      longer throws "This parameter has not been assigned a value".

; --- 1. A view over a buffer that owns nothing --------------------------------
struct Inner {
    a : Int32
}
struct Outer {
    items : Inner[3]                  ; nested struct array
    b     : Int32
}
buf := Buffer(64, 0)
view := Outer.At(buf.Ptr)             ; boxed pointer into buf
view.items[2].a := 5
view.b := 9
Echo("view.items[2].a = {}, view.b = {}, Outer size = {}", view.items[2].a, view.b, Outer().Size)
view := ""                            ; alpha.30 died here
Echo("view released, buffer still readable: items[2].a = {}", NumGet(buf, 4, "Int"))

; --- 2. Split getter and setter declarations ----------------------------------
; Useful when a mixin or a later section of a class adds the setter.
class Cfg {
    Level {
        get => 42
    }
    Level {                           ; alpha.30: "Duplicate declaration"
        set => this._log := "set " value
    }
}
c := Cfg()
c.Level := 7
Echo("c.Level = {}, c._log = {}", c.Level, c._log)

; --- 3. Simple assignment from a virtual reference ----------------------------
class Cell {
    __New(v) => this._v := v
    __Value {
        get => this._v
        set => this._v := value
    }
}
CopyOut(&src) {
    plain := src                      ; alpha.30: threw; alpha.31: copies the reference object
    value := src + 0                  ; any expression form reads __Value
    return Type(plain) " / " value
}
Echo("CopyOut(Cell(42)) = {}", CopyOut(Cell(42)))
x := 7
Echo("CopyOut(&x) = {}", CopyOut(&x))
