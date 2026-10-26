#Requires AutoHotkey v2.1-alpha.33
; alpha.33: #Import inside a function
;
; A function body may contain #Import. The names it brings in are scoped to
; that function, so a helper can lean on a module without adding anything to
; the file's own namespace. Before alpha.33, #Import was only valid at the top
; level of a module.
;
; The modules live in this file so the example is self-contained; #Import
; works the same for a module in its own file.

#Module Geometry
global PI := 3.14159265
Circle(r) => PI * r * r

#Module Temperature
global PI := "not a number"     ; the same name, a different module
ToF(c) => c * 9 / 5 + 32

#Module __Main

; --- 1. A helper imports exactly what it needs, where it needs it -----------
Area(r) {
    #Import Geometry {PI}
    return PI * r * r
}
Print("Area(2) = {:.4f}", Area(2))

; --- 2. The import did not leak into the file's scope ------------------------
; PI is not defined at the top level of __Main: it is an unset global here,
; not Geometry's constant.
Print("top-level PI is set: {}", IsSet(PI))

; --- 3. Two functions, two modules, one name -------------------------------
; Each function sees its own PI. At the top level that would have been a
; conflict; inside a function it is just a local import.
Describe() {
    #Import Temperature {PI}
    return "Temperature's PI is '" PI "'"
}
Print("{}", Describe())
Print("Area(1) = {:.5f}", Area(1))

; --- 4. Importing the whole module as a namespace ---------------------------
Convert(c) {
    #Import Temperature
    return Temperature.ToF(c)
}
Print("Convert(100) = {}", Convert(100))
