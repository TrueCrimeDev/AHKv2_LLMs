#Requires AutoHotkey v2.1-alpha.34
Echo(fmt, args*) => FileAppend(Format(fmt, args*) "`n", "*")   ; native stdout
; alpha.34: anonymous unions in structs
;
; A struct may contain a union block without naming it; its members sit at
; the same offset and are accessed directly on the struct. Before alpha.34 a
; union needed DefineProp(..., {Type: ..., Offset: ...}) per member, after the
; struct was declared.

; --- 1. A tagged value: one slot, several views -------------------------------
struct Value {
    kind : Int32          ; 1 = int, 2 = float, 3 = bytes
    union {
        i     : Int32
        f     : Float32
        bytes : UInt8[4]
    }
}
v := Value()
Echo("Size {} (4 for kind + 4 shared)", v.Size)

v.kind := 2, v.f := 1.5
Echo("f=1.5 reads as i=0x{:X} and bytes {} {} {} {}", v.i, v.bytes[1], v.bytes[2], v.bytes[3], v.bytes[4])
v.kind := 1, v.i := 0x40490FDB
Echo("i=0x40490FDB reads as f={:.5f} and bytes[4]=0x{:X}", v.f, v.bytes[4])

; --- 2. Dispatch on the tag ----------------------------------------------------
Show(val) {
    switch val.kind {
        case 1: return "int " val.i
        case 2: return Format("float {:.5f}", val.f)
        case 3: return Format("bytes {:02X}{:02X}{:02X}{:02X}", val.bytes[1], val.bytes[2], val.bytes[3], val.bytes[4])
    }
}
v.kind := 3
Echo("{}", Show(v))
v.kind := 2
Echo("{}", Show(v))

; --- 3. The classic Win32 case: INPUT -----------------------------------------
; INPUT has a type field followed by a union of MOUSEINPUT, KEYBDINPUT and
; HARDWAREINPUT. With an anonymous union the struct reads like the C header.
struct MOUSEINPUT {
    dx : Int32
    dy : Int32
    mouseData : UInt32
    dwFlags : UInt32
    time : UInt32
    dwExtraInfo : IntPtr
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
inp.type := 1                   ; INPUT_KEYBOARD
inp.ki.wVk := 0x41              ; 'A'
inp.ki.dwFlags := 2             ; KEYEVENTF_KEYUP
Echo("INPUT size {} (C says {} on x64), ki.wVk 0x{:X}, same bytes as mi.dx 0x{:X}",
    inp.Size, A_PtrSize = 8 ? 40 : 28, inp.ki.wVk, inp.mi.dx)
; Not sent: SendInput would type into whatever window has focus.
