#Requires AutoHotkey v2.1-alpha.34
; alpha.34: NumPut and NumGet accept the numeric classes (Int8..Int64,
; UInt8..UInt32, IntPtr, Float32, Float64) in place of type strings. A class
; knows its own width, so a layout can be data. Before, only the strings worked.

; One layout table drives both the writer and the reader; no size column.
layout := [["magic", UInt32], ["version", UInt16], ["flags", UInt16], ["ratio", Float64], ["count", Int64]]
Pack(fields, values) {
    size := 0
    for f in fields
        size += f[2]().Size
    buf := Buffer(size, 0), off := 0
    for f in fields
        NumPut(f[2], values[f[1]], buf, off), off += f[2]().Size
    return buf
}
Unpack(fields, buf) {
    out := Map(), off := 0
    for f in fields
        out[f[1]] := NumGet(buf, off, f[2]), off += f[2]().Size
    return out
}
buf := Pack(layout, Map("magic", 0x4B4841, "version", 34, "flags", 3, "ratio", 0.75, "count", -5))
back := Unpack(layout, buf)
Print("packed {} bytes: magic 0x{:X} version {} flags {} ratio {} count {}", buf.Size, back["magic"], back["version"], back["flags"], back["ratio"], back["count"])

; Classes mix in one call and are interchangeable with the strings.
pair := Buffer(12, 0)
NumPut(Int32, -7, Float32, 2.5, UInt32, 0xFFFFFFFF, pair)
Print("{} {} {}   (as `"Int`": {})", NumGet(pair, Int32), NumGet(pair, 4, Float32), NumGet(pair, 8, UInt32), NumGet(pair, "Int"))

; SYSTEMTIME is eight UInt16 fields; a name list is enough to read it.
st := Buffer(16, 0)
DllCall("GetSystemTime", "Ptr", st)
t := Map()
for i, name in ["year", "month", "dow", "day", "hour", "min", "sec", "ms"]
    t[name] := NumGet(st, (i - 1) * UInt16().Size, UInt16)
Print("GetSystemTime: {}-{:02}-{:02} (year is {})", t["year"], t["month"], t["day"], Type(t["year"]))
