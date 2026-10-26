#Requires AutoHotkey v2.1-alpha.28

; alpha.28, two struct changes:
;   StructClass.Prototype is read-only. A struct class keeps a direct
;   pointer to its prototype, so reassigning it was never honoured.
;   StructClass.At(ptr) works on a struct with no fields, which makes a
;   fieldless struct a typed, opaque handle: the address is the value.
; Also fixed: StructClass.At on a struct that contains a nested struct,
; which alpha.27 broke (6979d3ad).

; --- 1. Prototype cannot be swapped ----------------------------------------------------
struct POINT {
    x : Int32
    y : Int32
}
try POINT.Prototype := Object()
catch Error as e
    Print("POINT.Prototype := Object() -> {}", e.Message)

; --- 2. A fieldless struct as an opaque handle ---------------------------------------------
; Window handles are integers that are easy to mix up with other integers.
; A zero-field struct gives them a type, a place for methods, and no data.
struct Window {
    Title => WinGetTitle("ahk_id " this.Ptr)
    Class => WinGetClass("ahk_id " this.Ptr)
}
DetectHiddenWindows(true)
w := Window.At(A_ScriptHwnd)
Print("Window size {}  Ptr matches A_ScriptHwnd: {}  Type {}", w.Size, w.Ptr = A_ScriptHwnd, Type(w))
Print("class {}", w.Class)
Print("is Window: {}   is Struct: {}", w is Window, w is Struct)

; --- 3. A view over memory that contains a nested struct ------------------------------
struct RECT2 {
    tl : POINT
    br : POINT
}
buf := Buffer(16)
NumPut("Int", 10, "Int", 20, "Int", 110, "Int", 220, buf)
view := RECT2.At(buf.Ptr)
Print("view: ({},{})-({},{})  width {}", view.tl.x, view.tl.y, view.br.x, view.br.y, view.br.x - view.tl.x)
view.br.x := 500                      ; writes through to the buffer
Print("buffer now holds br.x = {}", NumGet(buf, 8, "Int"))
