#Requires AutoHotkey v2.1-alpha.27
Echo(fmt, args*) => FileAppend(Format(fmt, args*) "`n", "*")   ; native stdout

; alpha.27: the Base of anything with typed properties is fixed. Assigning
; .Base to or from a struct instance or prototype throws instead of silently
; corrupting the memory layout that was computed from the old base.
; Before alpha.27 `a.Base := b` with typed properties on either side was
; accepted and left the object's layout and its data out of step.

struct POINT {
    x : Int32
    y : Int32
    Len => Sqrt(this.x ** 2 + this.y ** 2)
}

; --- 1. A plain object cannot adopt a struct prototype ---------------------------
o := {}
try o.Base := POINT.Prototype
catch ValueError as e
    Echo("{{}}.Base := POINT.Prototype -> {}", e.Message)

; --- 2. A struct instance cannot be re-based either ----------------------------
p := POINT()
try p.Base := {}
catch ValueError as e
    Echo("POINT().Base := {{}} -> {}", e.Message)
try POINT.Prototype.Base := Object.Prototype
catch ValueError as e
    Echo("POINT.Prototype.Base := ... -> {}", e.Message)

; --- 3. Inheritance happens at definition time instead ----------------------------
; A derived struct appends its fields after the base fields, keeps the base
; methods, and the layout is fixed once, when the class is created.
struct Labeled extends POINT {
    tag : Int32
}
q := Labeled()
q.x := 3, q.y := 4, q.tag := 9
Echo("Labeled size {} (POINT {} + tag {}), Len {} from the base method", q.Size, POINT().Size, q.Size - POINT().Size, q.Len)
Echo("q is POINT: {}   tag at +{}", q is POINT, q.Size - 4)

; --- 4. Behaviour that varies per instance goes in a property, not a Base swap ----
; Keep the struct as the data layout and attach the varying part as a value.
struct Shape {
    kind : Int32
    w    : Int32
    h    : Int32
    Area => this.kind = 1 ? this.w * this.h : 3.14159 * this.w * this.h / 4
}
box := Shape(), box.kind := 1, box.w := 10, box.h := 4
oval := Shape(), oval.kind := 2, oval.w := 10, oval.h := 4
Echo("box area {}  oval area {:.2f}", box.Area, oval.Area)
