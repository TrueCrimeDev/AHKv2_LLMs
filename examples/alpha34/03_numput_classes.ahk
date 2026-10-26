#Requires AutoHotkey v2.1-alpha.34
Echo(fmt, args*) => FileAppend(Format(fmt, args*) "`n", "*")   ; native stdout
; alpha.34: numeric type classes in NumPut and NumGet
;
; NumPut(Int32, v, buf) and NumGet(buf, Int32) accept the numeric classes
; (Int8..Int64, UInt8..UInt32, IntPtr, UIntPtr, Float32, Float64) in place of
; the type strings. The class carries its own size, so a layout can be data
; instead of a string you keep in sync by hand. Before alpha.34 only the
; strings ("Int", "UShort", ...) were accepted.

; --- 1. A layout table drives both the writer and the reader ----------------
layout := [["magic", UInt32], ["version", UInt16], ["flags", UInt16], ["ratio", Float64], ["count", Int64]]
Pack(fields, values) {
    size := 0
    for f in fields
        size += f[2]().Size            ; each class knows its width
    buf := Buffer(size, 0)
    off := 0
    for f in fields {
        NumPut(f[2], values[f[1]], buf, off)
        off += f[2]().Size
    }
    return buf
}
Unpack(fields, buf) {
    out := Map(), off := 0
    for f in fields {
        out[f[1]] := NumGet(buf, off, f[2])
        off += f[2]().Size
    }
    return out
}
buf := Pack(layout, Map("magic", 0x4B4841, "version", 34, "flags", 3, "ratio", 0.75, "count", -5))
back := Unpack(layout, buf)
Echo("packed {} bytes: magic 0x{:X} version {} flags {} ratio {} count {}",
    buf.Size, back["magic"], back["version"], back["flags"], back["ratio"], back["count"])

; --- 2. Mixed in one NumPut call, exactly like the strings -------------------
pair := Buffer(12, 0)
NumPut(Int32, -7, Float32, 2.5, UInt32, 0xFFFFFFFF, pair)
Echo("{} {} {}", NumGet(pair, Int32), NumGet(pair, 4, Float32), NumGet(pair, 8, UInt32))

; --- 3. Classes and strings are interchangeable ---------------------------------
Echo("Int32 as string: {}   IntPtr width {}", NumGet(pair, "Int"), IntPtr().Size)

; --- 4. Decoding a Win32 struct without a struct declaration ------------------
; SYSTEMTIME is eight UInt16 fields; a class list is enough to read it.
st := Buffer(16, 0)
DllCall("GetSystemTime", "Ptr", st)
names := ["year", "month", "dow", "day", "hour", "min", "sec", "ms"]
t := Map()
for i, name in names
    t[name] := NumGet(st, (i - 1) * UInt16().Size, UInt16)
Echo("GetSystemTime: {}-{:02}-{:02} (year is a {} value)", t["year"], t["month"], t["day"], Type(t["year"]))
