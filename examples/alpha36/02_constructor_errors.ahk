#Requires AutoHotkey v2.1-alpha.36

; alpha.36: calling a native class that cannot be constructed directly now
; throws ValueError "Invalid base." Before, RegExMatchInfo(), File(), Func(),
; BoundFunc(), Closure() and Enumerator() returned a plain Object wearing the
; native prototype; the first native method call on it read past its end.

; --- 1. A generic factory can finally tell "constructible" from "not" -------------
Construct(cls, args*) {
    try
        return cls(args*)
    catch ValueError as e
        return "cannot construct (" e.Message ")"
}
for cls in [RegExMatchInfo, File, Func, BoundFunc, Closure, Enumerator]
    Print("{}() -> {}", cls.Prototype.__Class, Construct(cls))
Print("")
Print("Map()   -> {}", Type(Construct(Map)))
Print("Error() -> {}", Type(Construct(Error, "x")))
Print("Buffer(8) -> {} bytes", Construct(Buffer, 8).Size)

; --- 2. Object.Call used as a "raw" constructor behaves the same ---------------------
; (Object.Call)(Class) builds an instance on Class.Prototype without running
; __New. It now refuses the same native classes ...
oc := Object.Call
try oc(RegExMatchInfo)
catch ValueError as e
    Print("(Object.Call)(RegExMatchInfo): {}", e.Message)
; ... and, as a side effect, accepts Struct, which it rejected in alpha.35.
Print("(Object.Call)(Struct) -> {}", Type(oc(Struct)))

; --- 3. Script classes are untouched -----------------------------------------------
class Inventory extends Map {
    Add(item, qty := 1) => (this[item] := this.Get(item, 0) + qty, this)
}
inv := Inventory().Add("bolt", 10).Add("bolt", 5).Add("nut")
Print("Inventory: bolt {} nut {}  Type {}", inv["bolt"], inv["nut"], Type(inv))

; --- 4. Struct views reject own properties again (fork fix f24c23d1) -------------------
; The upstream alpha.36 build let every memory view grow ad-hoc properties:
; Pt.At(ptr).foo := 1 succeeded where alpha.35 threw PropertyError. The
; +Console fork restores the error; on the official build this section prints
; "accepted" instead.
struct Pt {
    x : Int32
    y : Int32
}
buf := Buffer(8, 0)
for pair in [["Pt.At", Pt.At(buf.Ptr)], ["ObjCreateWithDataPtr", ObjCreateWithDataPtr(Pt, buf.Ptr)]] {
    name := pair[1], view := pair[2]
    try {
        view.foo := 1
        Print("{}: own property accepted", name)
    } catch PropertyError as e
        Print("{}: {}", name, e.Message)
}
; An ordinary object made the same way still can own properties.
m := ObjCreateWithDataPtr(Map, 0)
m.note := "fine"
Print("Map from ObjCreateWithDataPtr: note = {}", m.note)
