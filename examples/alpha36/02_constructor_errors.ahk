#Requires AutoHotkey v2.1-alpha.36

; alpha.36: calling a native class that cannot be constructed directly now
; throws ValueError "Invalid base." Before, RegExMatchInfo(), File(), Func(),
; BoundFunc(), Closure() and Enumerator() returned a plain Object wearing the
; native prototype; the first native method call on it read past its end.

; --- 1. A generic factory can finally tell "constructible" from "not" -------
Construct(cls, args*) {
    try
        return cls(args*)
    catch ValueError as e
        return "cannot construct (" e.Message ")"
}
for cls in [RegExMatchInfo, File, Func, BoundFunc, Closure, Enumerator]
    Print("{}() -> {}", cls.Prototype.__Class, Construct(cls))
Print("Map() -> {}   Error() -> {}   Buffer(8) -> {} bytes",
    Type(Construct(Map)), Type(Construct(Error, "x")), Construct(Buffer, 8).Size)

; --- 2. Object.Call as a "raw" constructor behaves the same -----------------
; (Object.Call)(Class) builds an instance on Class.Prototype without __New.
; It refuses the same native classes and, as a side effect, now accepts
; Struct, which it rejected in alpha.35.
oc := Object.Call
try oc(RegExMatchInfo)
catch ValueError as e
    Print("(Object.Call)(RegExMatchInfo): {}", e.Message)
Print("(Object.Call)(Struct) -> {}", Type(oc(Struct)))

; --- 3. Struct views reject own properties again (fork fix f24c23d1) --------
; The upstream alpha.36 build let every memory view grow ad-hoc properties:
; Pt.At(ptr).foo := 1 succeeded where alpha.35 threw PropertyError. The
; +Console fork restores the error; the official build prints "accepted".
struct Pt {
    x : Int32
    y : Int32
}
buf := Buffer(8, 0)
for pair in [["Pt.At", Pt.At(buf.Ptr)], ["ObjCreateWithDataPtr", ObjCreateWithDataPtr(Pt, buf.Ptr)]] {
    try {
        pair[2].foo := 1
        Print("{}: own property accepted", pair[1])
    } catch PropertyError as e
        Print("{}: {}", pair[1], e.Message)
}
m := ObjCreateWithDataPtr(Map, 0)      ; an ordinary object still can
m.note := "fine"
Print("Map from ObjCreateWithDataPtr: note = {}", m.note)
