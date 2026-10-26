# AutoHotkey v2.1-alpha.34: Hidden Properties, Anonymous Unions, Typed NumPut

Alpha.34 shipped on October 9, 2026 (upstream tag `v2.1-alpha.34`) with three changes that matter day to day: `Enumerable: false` hides a property from `Props()`, a struct may contain an anonymous `union`, and `NumPut`/`NumGet` take the numeric classes in place of type strings. `DefineProp` also validates its descriptor and `a.%b?% ?? c` short-circuits; one short script per change.

**About `Print`.** The scripts write their output with `Print`, which is not stock AutoHotkey: it is a built-in of the [+Console fork](https://github.com/TrueCrimeDev/AutoHotkey). `Print("x = {}, y = {}", x, y)` runs its arguments through `Format` and writes the result plus a newline to stdout; a single argument is written as-is, and `Print()` writes a blank line. To run the scripts on stock AutoHotkey, add this one line under `#Requires` (it reproduces those three shapes) and pipe the output through `| more`, because the GUI executable only shows stdout when it is redirected:

```ahk2
Print(fmt := "", args*) => FileAppend((args.Length ? Format(fmt, args*) : fmt) "`n", "*")
```

---

## 1. `Enumerable: false`: bookkeeping that stays out of the data

A property defined with `Enumerable: false` is skipped by `Props()` and the debugger but is still an own property, so the script's `Record` keeps a dirty flag and a version counter that a serializer walking `Props()` never sees, and hides an accessor the same way. The script also shows `DefineProp` rejecting a misspelt key (`Vlaue`) with `ValueError` instead of creating a property that does nothing, and `obj.%name?% ?? default` skipping the access when `name` is unset. Before alpha.34, `Enumerable` was itself an unknown key, so the first `DefineProp` in `Record.__New` threw.

```ahk2
#Requires AutoHotkey v2.1-alpha.34
; alpha.34: Enumerable: false hides a property from Props() while it stays an
; own property. DefineProp also validates its descriptor now, and
; a.%name?% ?? default short-circuits when name is unset.

; A record carries a dirty flag and a version that anything walking Props()
; (a serializer, a diff, a debugger) never sees.
class Record {
    __New(fields) {
        for name, value in fields.OwnProps()
            this.%name% := value
        this.DefineProp("_dirty", {Value: false, Enumerable: false})
        this.DefineProp("_version", {Value: 1, Enumerable: false})
    }
    Touch() => (this._dirty := true, this._version += 1)
}
Serialize(obj) {
    out := ""
    for name in obj.Props()
        out .= name "=" obj.%name% " "
    return Trim(out)
}
rec := Record({id: 7, title: "alpha.34"})
rec.Touch()
Print("Props():    {}", Serialize(rec))
Print("HasOwnProp(_dirty) {}  ObjOwnPropCount {}  _version {}", rec.HasOwnProp("_dirty"), ObjOwnPropCount(rec), rec._version)

; The flag works on accessors too.
rec.DefineProp("summary", {Get: this => this.id ": " this.title, Enumerable: false})
Print("summary = {}  (Props() still: {})", rec.summary, Serialize(rec))

; A typo in the descriptor used to be ignored; now it throws.
try rec.DefineProp("oops", {Vlaue: 1})
catch ValueError as e
    Print("DefineProp with Vlaue: {}", e.Message)

; a.%name?% ?? default: with name unset the whole access is skipped.
Field(obj, name?) => obj.%name?% ?? "(no field)"
Print("Field(rec, `"title`") = {}   Field(rec) = {}", Field(rec, "title"), Field(rec))
```

Output:

```text
Props():    id=7 title=alpha.34
HasOwnProp(_dirty) 1  ObjOwnPropCount 4  _version 2
summary = 7: alpha.34  (Props() still: id=7 title=alpha.34)
DefineProp with Vlaue: Parameter #2 of Object.Prototype.DefineProp is invalid.
Field(rec, "title") = alpha.34   Field(rec) = (no field)
```

Source: [`01_enumerable_props.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha34/01_enumerable_props.ahk)

---

## 2. Anonymous unions: one slot, several views

A struct may contain a `union { ... }` block without a name; its members share an offset and are accessed directly on the struct. The script's `Value` views the same four bytes as an `Int32`, a `Float32` and a `UInt8[4]`, so writing `1.5` through `f` reads back as `0x3FC00000` through `i`, and Win32's `INPUT` (a `type` field followed by a union of `MOUSEINPUT` and `KEYBDINPUT`) is declared the way the C header reads it, with `Size` 40 on x64 as C says; nothing is sent. Before alpha.34 the first member was a field and the others were added afterwards with `DefineProp(Cls.Prototype, name, {Type: ..., Offset: ...})`, which still works.

```ahk2
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
```

Output:

```text
Size 8 (4 for kind + 4 shared)
f=1.5 reads as i=0x3FC00000 and bytes 0 0 192 63
i=0x40490FDB reads as f=3.14159
INPUT size 40 (C says 40 on x64), ki.wVk 0x41 = low word of mi.dx 0x41
```

Source: [`02_anonymous_unions.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha34/02_anonymous_unions.ahk)

---

## 3. Numeric classes in `NumPut` and `NumGet`

`NumPut(Int32, v, buf)` and `NumGet(buf, Int32)` accept the numeric classes (`Int8` to `Int64`, `UInt8` to `UInt32`, `IntPtr`, `Float32`, `Float64`) where only strings such as `"Int"` worked before. A class carries its own width (`UInt16().Size` is 2), so the script's binary layout is a table of names and classes that one `Pack` and one `Unpack` walk with no size column to keep in sync; it also mixes classes in one `NumPut` call and decodes `SYSTEMTIME` from a list of names. The change came through the v2.0 branch, so a fork build labelled alpha.33 may already accept it.

```ahk2
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
```

Output (the date will differ):

```text
packed 24 bytes: magic 0x4B4841 version 34 flags 3 ratio 0.75 count -5
-7 2.5 4294967295   (as "Int": -7)
GetSystemTime: 2026-10-26 (year is Integer)
```

Source: [`03_numput_classes.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha34/03_numput_classes.ahk)

---

## Running them

Every script starts with `#Requires AutoHotkey v2.1-alpha.34`. On the +Console fork they run as they are; on stock AutoHotkey add the `Print` line from the top of this post and pipe through `| more`.

```powershell
# +Console fork
.\bin\AutoHotkey64Console.exe 01_enumerable_props.ahk

# stock AutoHotkey v2.1-alpha.34 or later (GUI exe), with the Print line added
AutoHotkey64.exe 01_enumerable_props.ahk | more
```

*Disclosure: Claude Fable 5.1 wrote and ran the scripts on `2.1-alpha.37+Console` (`a911f73d`) and drafted this post; the "before" lines come from the fork's release notes.*
