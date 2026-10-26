#Requires AutoHotkey v2.1-alpha.27

; alpha.27: a struct that contains other structs is one allocation.
; The nested objects are embedded in the outer block in definition order,
; so the bytes of RECT2 below are exactly the bytes of a Win32 RECT and the
; outer .Ptr can be handed to any API that expects one.
; Before alpha.27 each nested field was a separate heap object cross-linked
; through an index array; the layout was the same but every RECT2() cost
; three allocations instead of one.

struct POINT {
    x : Int32
    y : Int32
}

struct RECT2 {
    tl : POINT      ; top-left
    br : POINT      ; bottom-right
}

; --- 1. The nested fields sit inside the outer block ---------------------------
r := RECT2()
Print("RECT2 size {}  tl at +{}  br at +{}", r.Size, r.tl.Ptr - r.Ptr, r.br.Ptr - r.Ptr)

; --- 2. Win32 sees a plain RECT ------------------------------------------------
r.tl.x := 1, r.tl.y := 2, r.br.x := 30, r.br.y := 40
DllCall("user32\OffsetRect", "Ptr", r.Ptr, "Int", 5, "Int", 7)
Print("after OffsetRect(+5,+7): ({},{})-({},{})", r.tl.x, r.tl.y, r.br.x, r.br.y)
Print("NumGet(r.Ptr, 8) = {}  (br.x through raw memory)", NumGet(r.Ptr, 8, "Int"))

; --- 3. An array of nested structs is one contiguous block too ----------------
rects := RECT2[3]()
rects[2].tl.x := 100, rects[2].br.x := 200
Print("RECT2[3] size {}  stride {}  rects[2].tl.x = {}", rects.Size, rects[2].Ptr - rects[1].Ptr, NumGet(rects.Ptr, 16, "Int"))

; --- 4. Which means a whole batch can go to C at once ------------------------
; Pass the array's base pointer; the callee walks it with ordinary stride math.
loop 3
    DllCall("user32\SetRect", "Ptr", rects[A_Index].Ptr, "Int", 0, "Int", 0, "Int", A_Index * 10, "Int", A_Index * 10)
out := ""
loop 3
    out .= Format("[{}: {}x{}] ", A_Index, rects[A_Index].br.x, rects[A_Index].br.y)
Print("SetRect on each element: {}", out)
