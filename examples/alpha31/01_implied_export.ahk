#Requires AutoHotkey v2.1-alpha.31
Echo(fmt, args*) => FileAppend(Format(fmt, args*) "`n", "*")   ; native stdout

; alpha.31: every name defined in a #Module is exported; `export` is gone.
;
; A module is now a library by default. Functions, classes, `global`
; declarations and plain top-level assignments are all visible to any module
; that imports it. The one escape hatch is a leading underscore, which keeps a
; name out of {*} imports while leaving it reachable by explicit import or
; through the module object.
;
; Before alpha.31 (alpha.11 through alpha.30), nothing left a module without an
; `export` prefix: this script loaded with "never assigned" warnings and died
; at the first call with "This global variable has not been assigned a value."

; --- 1. The library ------------------------------------------------------------
#Module Geometry

global Pi := 3.14159265358979          ; exported, no keyword
CircleArea(r) => Pi * r ** 2            ; exported
class Point {                           ; exported
    __New(x, y) {
        this.x := x
        this.y := y
    }
    Dist(other) => Sqrt((this.x - other.x) ** 2 + (this.y - other.y) ** 2)
}
Scale := 2                              ; a plain top-level assignment is exported too

; Private by convention: skipped by {*}, still callable inside the module.
_Clamp(v, lo, hi) => Min(Max(v, lo), hi)
ClampedArea(r) => CircleArea(_Clamp(r, 0, 10))

; `Export` is an ordinary identifier again (alpha.20 reserved it).
Export(obj) => "exported a " Type(obj)

; --- 2. The consumer -----------------------------------------------------------
#Module __Main
#Import Geometry {*}

Echo("CircleArea(2) = {}", Round(CircleArea(2), 3))
Echo("Point(3, 4).Dist(Point(0, 0)) = {}", Point(3, 4).Dist(Point(0, 0)))
Echo("Scale = {}", Scale)
Echo("ClampedArea(50) = {} (radius clamped to 10)", Round(ClampedArea(50), 3))

; The underscore helper did not come through the wildcard...
Echo("_Clamp after {{}*{}} import: {}", IsSet(_Clamp) ? "imported" : "skipped")
; ...but the module object still reaches it, as it reaches every module global.
Echo("Geometry._Clamp(15, 0, 10) = {}", Geometry._Clamp(15, 0, 10))
Echo("Geometry.Pi = {}", Geometry.Pi)

Echo("Export(Point(1, 1)) = {}", Export(Point(1, 1)))
