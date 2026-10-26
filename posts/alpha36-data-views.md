# AutoHotkey v2.1-alpha.36: Objects That View Memory, and Three Errors That Finally Fire

Alpha.36 (October 18, 2026) adds `ObjCreateWithDataPtr(ClassObj, Address)`, any constructible class over a given address, and fixes three alpha-only bugs: `AhkLibPath` after a missing folder, native classes such as `RegExMatchInfo()` constructing garbage, and a local shadowing a function-level `#Import`.

The official build corrupts the heap on `ObjCreateWithDataPtr(Map, addr)` and lets struct views grow properties; the [+Console fork](https://github.com/TrueCrimeDev/AutoHotkey) fixed both (`a41db9a1`, `f24c23d1`), report in [`docs/upstream/alpha36-createstructptr-offset.md`](https://github.com/TrueCrimeDev/AutoHotkey/blob/alpha/docs/upstream/alpha36-createstructptr-offset.md).

**`Print` is a fork built-in**, not stock AutoHotkey. `Print("x = {}", x)` formats through `Format` and writes one line to stdout; a single argument is written as-is. On stock AutoHotkey add this line under `#Requires` and pipe through `| more`:

```ahk2
Print(fmt := "", args*) => FileAppend((args.Length ? Format(fmt, args*) : fmt) "`n", "*")
```

---

## 1. Pixel views over a raw buffer

`Pixel`, an ordinary class with four `UInt8` typed properties and methods, views four bytes of an RGBA buffer per instance; writes go to the buffer. `__Init` and `__New` are skipped, `__Delete` runs on release. Address 0 is accepted, unlike `Int32.At`.

```ahk2
#Requires AutoHotkey v2.1-alpha.36

; alpha.36: ObjCreateWithDataPtr(ClassObj, Address) makes an instance of any
; directly constructible class whose data pointer is Address. __Init and __New
; are skipped, __Delete runs on release, and Address 0 is allowed.
; Before alpha.36 only StructClass.At could view memory, and only via a struct.

; --- 1. Pixel views over a raw RGBA buffer ----------------------------------
; An ordinary class with typed properties and a computed one. Each view is 4
; bytes of the buffer; writing through it writes the buffer.
class Pixel {
    r : UInt8
    g : UInt8
    b : UInt8
    a : UInt8
    Hex => Format("#{:02X}{:02X}{:02X}", this.r, this.g, this.b)
    Fade(pct) => (this.a := Round(this.a * pct / 100), this)
}
pixels := Buffer(3 * 4, 0)
NumPut("UInt", 0xFF0000FF, "UInt", 0xFF00FF00, "UInt", 0xFFFF0000, pixels)   ; little-endian ABGR

View(i) => ObjCreateWithDataPtr(Pixel, pixels.Ptr + (i - 1) * 4)
loop 3
    Print("pixel {}: {} alpha {}", A_Index, View(A_Index).Hex, View(A_Index).a)
View(2).Fade(50)
Print("after Fade(50) on pixel 2: byte 7 of the buffer = {}", NumGet(pixels, 7, "UChar"))

; --- 2. The constructor is skipped, the destructor is not -------------------
class Tracked {
    static log := ""
    label := "set by __Init"              ; an instance initializer
    n : Int32
    __New() => Tracked.log .= "new "
    __Delete() => Tracked.log .= "delete "
}
counter := Buffer(4, 0)
NumPut("Int", 41, counter)
t := ObjCreateWithDataPtr(Tracked, counter.Ptr)
Print("t.n = {}   HasOwnProp(label) = {}   log = `"{}`"", t.n, t.HasOwnProp("label"), Tracked.log)
t.n += 1
t := ""                                   ; release: __Delete runs
Print("buffer now {}   log = `"{}`"", NumGet(counter, "Int"), Tracked.log)

; --- 3. Numeric classes, Address 0, and reading the pointer back ------------
v := ObjCreateWithDataPtr(Int32, counter.Ptr)
v.__Value := 1000
Print("Int32 view wrote {}; ObjGetDataPtr matches: {}", NumGet(counter, "Int"), ObjGetDataPtr(v) = counter.Ptr)
Print("Address 0 is allowed: ObjGetDataPtr = {}", ObjGetDataPtr(ObjCreateWithDataPtr(Int32, 0)))
try Int32.At(0)
catch Error as e
    Print("Int32.At(0): {}", e.Message)
```

Output:

```text
pixel 1: #FF0000 alpha 255
pixel 2: #00FF00 alpha 255
pixel 3: #0000FF alpha 255
after Fade(50) on pixel 2: byte 7 of the buffer = 128
t.n = 41   HasOwnProp(label) = 0   log = ""
buffer now 42   log = "delete "
Int32 view wrote 1000; ObjGetDataPtr matches: 1
Address 0 is allowed: ObjGetDataPtr = 0
Int32.At(0): Parameter #1 of Struct.At is invalid.
```

Source: [`01_data_views.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha36/01_data_views.ahk)

---

## 2. `Invalid base.`: a factory that can tell constructible from not

`RegExMatchInfo()`, `File()`, `Func()`, `BoundFunc()`, `Closure()` and `Enumerator()` now throw `ValueError` "Invalid base." instead of building an object that crashes on first use, so `Construct(cls, args*)` can tell the two kinds apart. Section 3 is the fork fix: `Pt.At(ptr).foo := 1` throws `PropertyError` again.

```ahk2
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
```

Output:

```text
RegExMatchInfo() -> cannot construct (Invalid base.)
File() -> cannot construct (Invalid base.)
Func() -> cannot construct (Invalid base.)
BoundFunc() -> cannot construct (Invalid base.)
Closure() -> cannot construct (Invalid base.)
Enumerator() -> cannot construct (Invalid base.)
Map() -> Map   Error() -> Error   Buffer(8) -> 8 bytes
(Object.Call)(RegExMatchInfo): Invalid base.
(Object.Call)(Struct) -> Struct
Pt.At: This value of type "Pt" has no property named "foo".
ObjCreateWithDataPtr: This value of type "Pt" has no property named "foo".
Map from ObjCreateWithDataPtr: note = fine
```

Source: [`02_constructor_errors.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha36/02_constructor_errors.ahk)

---

## 3. Load-time checks: `AhkLibPath` after a missing folder, and `#Import` clashes

Each check runs a child script with `/ErrorStdOut`. `AhkLibPath` set to `does-not-exist;lib` now finds `<Greet>` (fork fix, upstream `abe3ff20`), and `#Import Settings {Timeout}` beside a `local` or parameter `Timeout` is now a load error. In a continuation section the child's `` `n `` must be written ``` ``n ```.

```ahk2
#Requires AutoHotkey v2.1-alpha.36

; alpha.36 fixes two load-time behaviours, so this file writes small scripts
; to a temp folder and runs each in a child AutoHotkey through the shell.
;   1. AhkLibPath: a folder listed after one that does not exist is searched.
;      Before: everything after the missing folder was dropped.
;   2. #Import inside a function is a load error when a local or a parameter
;      of the same name exists. Before: the local silently shadowed the import.

root := A_Temp "\ahk36_load_" A_TickCount
DirCreate(root "\lib")
FileAppend('Greet() => "found Greet.ahk"`n', root "\lib\Greet.ahk", "UTF-8")

RunChild(name, source) {
    global root
    script := root "\" name ".ahk", log := script ".log"
    FileAppend(source, script, "UTF-8")
    RunWait(A_ComSpec ' /c ""' A_AhkPath '" /ErrorStdOut "' script '" > "' log '" 2>&1"',, "Hide")
    out := FileExist(log) ? Trim(FileRead(log), "`r`n") : "(no output)"
    return StrReplace(out, root "\", "")       ; keep the temp path out of the output
}

; --- 1. A missing folder no longer swallows the rest of AhkLibPath ----------
EnvSet("AhkLibPath", root "\does-not-exist;" root "\lib")
Print("missing;lib -> {}", RunChild("libpath", "#Requires AutoHotkey v2.1-alpha.36`n#Include <Greet>`nFileAppend(Greet() `"``n`", `"*`")`n"))
EnvSet("AhkLibPath", "")

; --- 2. #Import inside a function that clashes with a local or a parameter --
; Without the clash F() returns 30. Inside a continuation section a backtick
; is processed by the parent, so ``n reaches the child as `n.
module := "`n#Module Settings`nTimeout := 30`n"
clash := "
(
F() {
    #Import Settings {Timeout}
    local Timeout := 5          ; before alpha.36 this quietly won: F() = 5
    return Timeout
}
FileAppend("F() = " F() "``n", "*")
)"
Print("local of same name -> {}", RunChild("import_local", clash module))

param := "
(
F(Timeout := 5) {
    #Import Settings {Timeout}
    return Timeout
}
FileAppend("F() = " F() "``n", "*")
)"
Print("parameter clash    -> {}", RunChild("import_param", param module))

DirDelete(root, true)
```

Output:

```text
missing;lib -> found Greet.ahk
local of same name -> import_local.ahk (2) : ==> This import declaration conflicts with an existing local variable.
     Specifically: Timeout
parameter clash    -> import_param.ahk (2) : ==> This import declaration conflicts with an existing parameter.
     Specifically: Timeout
```

Source: [`03_load_time_checks.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha36/03_load_time_checks.ahk)

---

## Running them

`#Requires AutoHotkey v2.1-alpha.36` on every script. Fork: run as-is. Stock: add the `Print` line and pipe through `| more`.

```powershell
# +Console fork
.\bin\AutoHotkey64Console.exe 01_data_views.ahk

# stock AutoHotkey v2.1-alpha.36 or later (GUI exe), with the Print line added
AutoHotkey64.exe 01_data_views.ahk | more
```

*Scripts and text by Claude Fable 5.1, run on `2.1-alpha.37+Console` (`a911f73d`); "before" behaviour from the fork's release notes.*
