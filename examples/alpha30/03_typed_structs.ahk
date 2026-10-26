#Requires AutoHotkey v2.1-alpha.30
Echo(fmt, args*) => FileAppend(Format(fmt, args*) "`n", "*")   ; native stdout

; alpha.30: struct fields name a class, never a string or a bare size
;
; Two shorthands stopped loading:
;   x: i32        -> x: Int32       (i8/i16/i32/i64, u8/u16/u32, f32/f64, ptr)
;   buf: 32       -> a typed array such as Int8[32], or a Buffer alongside
;
; The replacement classes are Int8, Int16, Int32, Int64, UInt8, UInt16,
; UInt32, Float32, Float64 and IntPtr. There is no UInt64 class: store the
; value in an Int64 and mask when you read it, or split it into two UInt32s.

; --- 1. The migrated layout --------------------------------------------------------------
struct Point {
    x: Int32
    y: Int32
}
struct Record {
    id: UInt16                 ; 2 bytes, then 2 bytes of padding before pos
    pos: Point                 ; nested struct, 8 bytes
    tag: Int8[4]               ; the old `tag: 4` raw region, now typed
    ratio: Float64             ; 8-byte aligned
}
r := Record()
r.id := 7, r.pos.x := 3, r.pos.y := 4, r.ratio := 0.75
Echo("Record.Size = {}   Point.Size = {}", r.Size, r.pos.Size)
Echo("id {}  pos ({}, {})  ratio {}", r.id, r.pos.x, r.pos.y, r.ratio)

; --- 2. The raw region is an array of bytes -------------------------------------------------
; Int8[4] is indexable and has a Length, which a bare `tag: 4` never had.
for i, ch in StrSplit("AHK!")
    r.tag[i] := Ord(ch)
tagText := ""
loop r.tag.Length
    tagText .= Chr(r.tag[A_Index])
Echo("tag = '{}' ({} bytes)", tagText, r.tag.Length)

; --- 3. Variable-length data stays in a Buffer ----------------------------------------------
; When the size is not a constant, keep a Buffer beside the struct and pass
; its pointer where a C API wants one.
class Packet {
    __New(payloadBytes) {
        this.header := Record()
        this.payload := Buffer(payloadBytes, 0)
    }
}
p := Packet(128)
Echo("Packet: header {} bytes at 0x{:X}, payload {} bytes at 0x{:X}", p.header.Size, p.header.Ptr, p.payload.Size, p.payload.Ptr)

; --- 4. Unsigned 64-bit values ---------------------------------------------------------------
struct FileSize {
    bytes: Int64
}
fs := FileSize()
fs.bytes := -1                                    ; 0xFFFFFFFFFFFFFFFF as unsigned
hi := (fs.bytes >> 32) & 0xFFFFFFFF
lo := fs.bytes & 0xFFFFFFFF
Echo("Int64 {} read as two UInt32 halves: 0x{:08X} 0x{:08X}", fs.bytes, hi, lo)
