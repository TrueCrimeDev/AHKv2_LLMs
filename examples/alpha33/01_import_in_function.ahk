#Requires AutoHotkey v2.1-alpha.33
; alpha.33: #Import inside a function
; The names it brings in are scoped to that function, so a helper can use a
; module without adding anything to the file's namespace. Before alpha.33,
; #Import was only valid at the top level of a module.

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

; --- 2. The import did not leak: __Main has no PI of its own ----------------
Print("top-level PI is set: {}", IsSet(PI))

; --- 3. Two functions, two modules, one name --------------------------------
; At the top level this would be a conflict; inside a function it is local.
Describe() {
    #Import Temperature {PI}
    return "Temperature's PI is '" PI "'"
}
Print("{}", Describe())

; --- 4. Or import the whole module as a namespace ---------------------------
Convert(c) {
    #Import Temperature
    return Temperature.ToF(c)
}
Print("Convert(100) = {}", Convert(100))
