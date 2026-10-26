#Requires AutoHotkey v2.1-alpha.33
; alpha.33: two crashes become errors
;   a.b[c] when a.b returns unset      -> UnsetError (was: process crash)
;   ObjSetCapacity(struct, n) and kin  -> TypeError  (was: corrupted the struct)

; --- 1. Indexing through an unset property is an ordinary error -----------
class Registry {
    table => unset      ; a lookup table that may not be configured yet
}
try Registry().table["key"]
catch UnsetError as e
    Print("Registry().table[`"key`"]: {}", e.Message)

; Guard it the usual way and fall back.
Lookup(reg, key) => IsSet(reg.table?) ? reg.table[key] : "(no table)"
Print("Lookup: {}", Lookup(Registry(), "key"))

; --- 2. Capacity functions refuse a Struct ---------------------------------
struct Pixel {
    r : UInt8
    g : UInt8
    b : UInt8
}
px := Pixel()
px.r := 255
for name, fn in Map("ObjSetCapacity", ObjSetCapacity.Bind(px, 8), "ObjGetCapacity", ObjGetCapacity.Bind(px)) {
    try fn()
    catch TypeError as e
        Print("{}: {}", name, e.Message)
}
Print("Pixel intact: r={} Size={}", px.r, px.Size)
