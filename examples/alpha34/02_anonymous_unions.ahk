#Requires AutoHotkey v2.1-alpha.34
; alpha.34: a struct may contain an anonymous union; its members share an
; offset and are accessed directly on the struct. Before alpha.34 each extra
; member needed DefineProp(..., {Type: ..., Offset: ...}) after the declaration.

; A tagged value: one 4-byte slot, three views of it.
struct Value {
    kind : Int32          ; 1 = int, 2 = float, 3 = bytes
    union {
        i     : Int32
        f     : Float32
        bytes : UInt8[4]
    }
}
v := Value()
Print("Size {} (4 for kind + 4 shared)", v.Size)
v.kind := 2, v.f := 1.5
Print("f=1.5 reads as i=0x{:X} and bytes {} {} {} {}", v.i, v.bytes[1], v.bytes[2], v.bytes[3], v.bytes[4])
v.kind := 1, v.i := 0x40490FDB
Print("i=0x40490FDB reads as f={:.5f}", v.f)

; Win32's INPUT: a type field, then a union. Nothing is sent.
struct MOUSEINPUT {
    dx : Int32
    dy : Int32
    mouseData : UInt32
    dwFlags : UInt32
    time : UInt32
    dwExtraInfo : IntPtr      ; no UIntPtr class exists; same width
}
struct KEYBDINPUT {
    wVk : UInt16
    wScan : UInt16
    dwFlags : UInt32
    time : UInt32
    dwExtraInfo : IntPtr
}
struct INPUT {
    type : UInt32
    union {
        mi : MOUSEINPUT
        ki : KEYBDINPUT
    }
}
inp := INPUT()
inp.type := 1, inp.ki.wVk := 0x41, inp.ki.dwFlags := 2    ; keyboard, 'A', key-up
Print("INPUT size {} (C says {} on x64), ki.wVk 0x{:X} = low word of mi.dx 0x{:X}", inp.Size, A_PtrSize = 8 ? 40 : 28, inp.ki.wVk, inp.mi.dx)
