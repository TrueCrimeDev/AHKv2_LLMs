# AutoHotkey v2.1-alpha.34: Hidden Properties, Anonymous Unions, Typed NumPut

Alpha.34 shipped on October 9, 2026 (upstream tag `v2.1-alpha.34`). It tightens structs and property descriptors: a `DefineProp` descriptor can hide a property from `Props()` with `Enumerable: false`, a struct may contain an anonymous `union`, and `NumPut`/`NumGet` accept the numeric type classes in place of type strings. `DefineProp` now validates its descriptor, `a.%b?% ?? c` short-circuits properly, and a `StructClass.Array` decays to `StructClass.Ptr` in typed properties and `DllCall`.

Three scripts, one per headline. Each is built around a pattern the change makes pleasant rather than a bare demonstration, and each prints what the engine does so you can compare against your own build.

---

## 1. `Enumerable: false`: bookkeeping that stays out of the data

A property defined with `Enumerable: false` is skipped by `Props()` and by the debugger's variable list. It is still an own property: `OwnProps()`, `HasOwnProp` and `ObjOwnPropCount` all see it, and it reads and writes as usual. The script's `Record` class keeps a dirty flag and a version counter that way, so a serializer walking `Props()` sees only the real fields. The same flag works on an accessor (`summary` is a hidden getter).

Two smaller alpha.34 changes share the script. `DefineProp` now rejects a descriptor with an unknown key, or with `Value` mixed with `Get`, `Set` or `Call`, with `ValueError` "Parameter #2 of Object.Prototype.DefineProp is invalid." instead of ignoring it, which is how a typo like `Vlaue` used to produce a property that silently did nothing. And `obj.%name?% ?? default` now short-circuits the whole access when `name` is unset, the same as `%r?% ?? c`, instead of invoking the default property.

Before alpha.34, `Enumerable` was itself an unknown descriptor key, so the first `DefineProp` in `Record.__New` threw.

```ahk2
#Requires AutoHotkey v2.1-alpha.34
Echo(fmt, args*) => FileAppend(Format(fmt, args*) "`n", "*")   ; native stdout
; alpha.34: Enumerable: false in a DefineProp descriptor
;
; A property defined with Enumerable: false is skipped by Props() and by the
; debugger's variable list, but it is still an own property: OwnProps(),
; HasOwnProp and ObjOwnPropCount see it and it reads and writes normally.
; Before alpha.34, Enumerable was an unknown descriptor key and DefineProp
; threw ValueError.

; --- 1. Bookkeeping that stays out of the data -----------------------------
; A record carries a dirty flag and a version. Anything that walks Props()
; (a serializer, a diff, a debugger) sees only the real fields.
class Record {
    __New(fields) {
        for name, value in fields.OwnProps()
            this.%name% := value
        this.DefineProp("_dirty", {Value: false, Enumerable: false})
        this.DefineProp("_version", {Value: 1, Enumerable: false})
    }
    Touch() {
        this._dirty := true
        this._version += 1
    }
}
Serialize(obj) {
    out := ""
    for name in obj.Props()
        out .= name "=" obj.%name% " "
    return Trim(out)
}
rec := Record({id: 7, title: "alpha.34"})
rec.Touch()
Echo("Props():    {}", Serialize(rec))
own := ""
for name in rec.OwnProps()
    own .= name " "
Echo("OwnProps(): {}", Trim(own))
Echo("HasOwnProp(_dirty) {}  ObjOwnPropCount {}  _version {}",
    rec.HasOwnProp("_dirty"), ObjOwnPropCount(rec), rec._version)

; --- 2. The flag works on accessors as well as values ------------------------
rec.DefineProp("summary", {Get: this => this.id ": " this.title, Enumerable: false})
Echo("summary = {}  (still not in Props: {})", rec.summary, Serialize(rec))

; --- 3. alpha.34 validates the descriptor -----------------------------------
; An unknown key, or Value mixed with Get/Set/Call, is a ValueError instead of
; being silently ignored.
for keys, bad in Map("Vlaue", {Vlaue: 1}, "Value+Get", {Value: 1, Get: (*) => 2}) {
    try rec.DefineProp("oops", bad)
    catch ValueError as e
        Echo("DefineProp with {}: {}", keys, e.Message)
}

; --- 4. Also new: a.%name?% ?? default short-circuits -----------------------
; With name unset the whole access is skipped and the default wins; before
; alpha.34 the engine tried the default property instead.
Field(obj, name?) => obj.%name?% ?? "(no field)"
Echo("Field(rec, `"title`") = {}   Field(rec) = {}", Field(rec, "title"), Field(rec))
```

Source: [`01_enumerable_props.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha34/01_enumerable_props.ahk)

---

## 2. Anonymous unions: one slot, several views

A struct may contain a `union { ... }` block without a name; its members share an offset and are accessed directly on the struct. The script's `Value` is a tagged union of an `Int32`, a `Float32` and a `UInt8[4]` byte view over the same four bytes, so writing `1.5` through `f` and reading `i` gives the IEEE bit pattern `0x3FC00000`, and the bytes come out little-endian. A `switch` on the tag dispatches to the right view.

Section 3 is the case most people meet first: Win32's `INPUT`, a `type` field followed by a union of `MOUSEINPUT`, `KEYBDINPUT` and `HARDWAREINPUT`. With an anonymous union the AutoHotkey declaration reads like the C header, and `Size` comes out at 40 bytes on x64, as C says. The script fills a key-up event and stops there; it does not call `SendInput`, which would type into whatever window has focus.

Before alpha.34, a union meant declaring the first member as a field and adding the others afterwards with `DefineProp(Cls.Prototype, name, {Type: ..., Offset: ...})`, which alpha.24 introduced and which still works.

```ahk2
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
```

Source: [`02_anonymous_unions.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha34/02_anonymous_unions.ahk)

---

## 3. Numeric classes in `NumPut` and `NumGet`

`NumPut(Int32, v, buf)` and `NumGet(buf, Int32)` accept the numeric classes (`Int8` to `Int64`, `UInt8` to `UInt32`, `IntPtr`, `Float32`, `Float64`) where only strings such as `"Int"` were accepted before. The point is that a class carries its own width: `UInt16().Size` is 2. So a binary layout can be a table of names and classes, and one `Pack` and one `Unpack` walk it with no size column to keep in sync. The script packs a five-field header that way and reads it back, mixes classes in a single `NumPut` call, shows a class and its string are interchangeable, and decodes `SYSTEMTIME` from `GetSystemTime` with nothing but a list of names.

This change arrived on the v2.0 branch and reached the fork as a post-alpha.33 commit before the alpha.34 tag included it, so a fork build labelled alpha.33 may already accept it. The `#Requires` line says alpha.34 because that is the first tagged release that has it.

Before alpha.34, only the type strings were accepted; a class in that position was rejected as an invalid parameter.

```ahk2
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
```

Source: [`03_numput_classes.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha34/03_numput_classes.ahk)

---

## Things I tripped over writing these

- **`in` is a reserved word.** `in := INPUT()` is a load error ("Unexpected reserved word"), so the variable is `inp`.
- **There is no `UIntPtr` class.** The numeric classes stop at `UInt32` on the unsigned side; `dwExtraInfo : UIntPtr` is a warning at load and an `UnsetError` at run time. Use `IntPtr`; the width is the same.
- **`Format` and nested braces.** `Format("{{{}}}", x)` does not give `{x}`; it printed the braces and dropped the argument. Put the braces in the argument, or keep them away from the placeholder.

---

## Running them

Every script starts with `#Requires AutoHotkey v2.1-alpha.34` and writes through `FileAppend(..., "*")`, AutoHotkey's native stdout. The stock GUI executable only shows that stream when it is piped or redirected, so the `| more` below is not optional there; the [+Console fork](https://github.com/TrueCrimeDev/AutoHotkey) prints it directly.

```powershell
# stock AutoHotkey v2.1-alpha.34 or later (GUI exe): pipe or redirect to see stdout
AutoHotkey64.exe 01_enumerable_props.ahk | more

# +Console fork: stdout is a real console stream
.\bin\AutoHotkey64Console.exe 01_enumerable_props.ahk
```

*Disclosure: Claude Fable 5.1 wrote the scripts, ran them, and drafted this post. Every behaviour claim was observed on `2.1-alpha.37+Console` (`a911f73d`), which carries this release, or comes from the fork's release notes for it; the "before" lines are from those notes.*
