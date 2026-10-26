# AutoHotkey v2.1-alpha.36: Objects That View Memory, and Three Errors That Finally Fire

Alpha.36 was tagged on October 18, 2026, five upstream commits after alpha.35. The new function is `ObjCreateWithDataPtr(ClassObj, Address)`: it makes an instance of any directly constructible class whose data pointer is `Address`, so an ordinary class with typed properties becomes a view over a buffer, a struct view can have address 0, and the object's `__Delete` runs when it goes away. The three fixes are all alpha-only bugs: an `AhkLibPath` folder was ignored when the one before it did not exist, `RegExMatchInfo()` and five other native classes built an unusable object instead of throwing, and `#Import` inside a function was silently shadowed by a local of the same name.

Three scripts below, one per theme, each built around a pattern the change makes pleasant. The comments record what alpha.35 did instead, and all three run with exit 0 on the `2.1-alpha.37+Console` build.

Two of the sections are fork-specific, and the scripts say so. The official alpha.36 build stores `ObjCreateWithDataPtr`'s pointer at the wrong offset for a native class larger than `Object`, so `ObjCreateWithDataPtr(Map, addr)` overwrites the `Map`'s own fields and corrupts the heap (exit 127 when the object is released). The same change also let every struct view grow ad-hoc properties, which alpha.35 refused. The [+Console fork](https://github.com/TrueCrimeDev/AutoHotkey) fixed both before shipping alpha.36 (`a41db9a1` and `f24c23d1`, pinned by its `qa/tests/test_alpha36.ahk`); the report to upstream is in [`docs/upstream/alpha36-createstructptr-offset.md`](https://github.com/TrueCrimeDev/AutoHotkey/blob/alpha/docs/upstream/alpha36-createstructptr-offset.md) and had not been sent as of this post. Script 1 guards its `Map` section on the fork's version string; script 2 prints whichever outcome your build gives.

**About `Print`.** The scripts write their output with `Print`, which is not stock AutoHotkey: it is a built-in of the [+Console fork](https://github.com/TrueCrimeDev/AutoHotkey). `Print("x = {}, y = {}", x, y)` runs its arguments through `Format` and writes the result plus a newline to stdout; a single argument is written as-is, and `Print()` writes a blank line. To run the scripts on stock AutoHotkey, add this one line under `#Requires` (it reproduces those three shapes) and pipe the output through `| more`, because the GUI executable only shows stdout when it is redirected:

```ahk2
Print(fmt := "", args*) => FileAppend((args.Length ? Format(fmt, args*) : fmt) "`n", "*")
```

---

## 1. Pixel views over a raw buffer

The pleasant thing about `ObjCreateWithDataPtr` is that the class doing the viewing can be an ordinary one, with methods and computed properties, not a struct. `Pixel` has four `UInt8` typed properties, a `Hex` getter and a `Fade` method; `View(i)` returns an instance whose data pointer is four bytes into an RGBA buffer, and writing through it writes the buffer. Three views over a 12-byte buffer print `#FF0000`, `#00FF00`, `#0000FF`, and `View(2).Fade(50)` halves byte 7 in place.

Section 2 shows the two lifecycle rules worth memorising: `__Init` and `__New` are skipped (the `label` initializer never runs, `log` stays empty), but `__Delete` is called on release, unlike a view from `StructClass.At`. Section 3 covers the numeric classes, address 0 (accepted here, rejected by `Int32.At`), an address below 65536 (`ValueError`), and `ObjGetDataPtr` to read the pointer back. Section 4 puts a data pointer on a `Map`, which is only safe on the fork build, so it checks `A_AhkVersion` for `+Console` first.

Before alpha.36, the function did not exist; `StructClass.At` was the only way to view memory, and only through a struct.

```ahk2
#Requires AutoHotkey v2.1-alpha.36

; alpha.36: ObjCreateWithDataPtr(ClassObj, Address) creates an instance of any
; directly constructible class whose data pointer is Address. It skips __Init
; and __New (instance initializers do not run) but calls __Delete on release,
; and unlike StructClass.At it accepts Address 0. Typed properties on the
; object read and write the memory at Address.
;
; Before alpha.36 the function did not exist; StructClass.At was the only way
; to view memory, and only through a struct.

; --- 1. Pixel views over a raw RGBA buffer ---------------------------------------
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
loop 3 {
    p := View(A_Index)
    Print("pixel {}: {} alpha {}", A_Index, p.Hex, p.a)
}
View(2).Fade(50)
Print("after Fade(50) on pixel 2: byte 7 of the buffer = {}", NumGet(pixels, 7, "UChar"))

; --- 2. The constructor is skipped, the destructor is not --------------------------
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

; --- 3. Numeric classes, Address 0, and reading the pointer back ----------------
v := ObjCreateWithDataPtr(Int32, counter.Ptr)
v.__Value := 1000
Print("Int32 view wrote {}; ObjGetDataPtr matches: {}", NumGet(counter, "Int"), ObjGetDataPtr(v) = counter.Ptr)
z := ObjCreateWithDataPtr(Int32, 0)
Print("Address 0 is allowed: ObjGetDataPtr = {}   (Int32.At(0) throws)", ObjGetDataPtr(z))
try Int32.At(0)
catch Error as e
    Print("Int32.At(0): {}", e.Message)
try ObjCreateWithDataPtr(Int32, 100)
catch ValueError as e
    Print("ObjCreateWithDataPtr(Int32, 100): {}", e.Message)

; --- 4. A data pointer on a Map (needs the +Console fork, see the post) -------------
; The official alpha.36 build stores the pointer over a Map's own fields and
; corrupts the heap (exit 127 on release). The fork fixed that before shipping
; alpha.36, so this section only runs there.
if InStr(A_AhkVersion, "+Console") {
    tagged := ObjCreateWithDataPtr(Map, counter.Ptr)
    tagged["name"] := "a Map that carries an address"
    Print("Map with data pointer: Count {}  ptr matches {}", tagged.Count, ObjGetDataPtr(tagged) = counter.Ptr)
    tagged := ""
    Print("released cleanly")
} else
    Print("skipping the Map section on {}", A_AhkVersion)
```

Source: [`01_data_views.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha36/01_data_views.ahk)

---

## 2. `Invalid base.`: a factory that can tell constructible from not

`RegExMatchInfo()`, `File()`, `Func()`, `BoundFunc()`, `Closure()` and `Enumerator()` used to return a plain `Object` on the native prototype. `Type()` reported the class name, so nothing looked wrong until the first native method read past the end of the object. Alpha.36 removes the inherited factory, so each call throws `ValueError` "Invalid base.", and a generic `Construct(cls, args*)` helper can finally separate the classes you may instantiate from the ones only the engine builds. `(Object.Call)(Class)`, the raw constructor that skips `__New`, refuses the same classes, and as a side effect now accepts `Struct`, which it rejected in alpha.35.

Script classes are untouched; `Inventory extends Map` constructs and chains as before. Section 4 is the fork-specific one: the upstream alpha.36 build let `Pt.At(ptr).foo := 1` and `ObjCreateWithDataPtr(Pt, ptr).foo := 1` succeed, where alpha.35 threw `PropertyError`. On the fork both throw again, while a `Map` made with `ObjCreateWithDataPtr` can still own properties. On the official build the section prints `own property accepted` twice instead.

Before alpha.36, `RegExMatchInfo()` returned an object that reported `RegExMatchInfo` as its type and crashed on first use.

```ahk2
#Requires AutoHotkey v2.1-alpha.36

; alpha.36: calling a native class that cannot be constructed directly now
; throws ValueError "Invalid base." Before, RegExMatchInfo(), File(), Func(),
; BoundFunc(), Closure() and Enumerator() returned a plain Object wearing the
; native prototype; the first native method call on it read past its end.

; --- 1. A generic factory can finally tell "constructible" from "not" -------------
Construct(cls, args*) {
    try
        return cls(args*)
    catch ValueError as e
        return "cannot construct (" e.Message ")"
}
for cls in [RegExMatchInfo, File, Func, BoundFunc, Closure, Enumerator]
    Print("{}() -> {}", cls.Prototype.__Class, Construct(cls))
Print("")
Print("Map()   -> {}", Type(Construct(Map)))
Print("Error() -> {}", Type(Construct(Error, "x")))
Print("Buffer(8) -> {} bytes", Construct(Buffer, 8).Size)

; --- 2. Object.Call used as a "raw" constructor behaves the same ---------------------
; (Object.Call)(Class) builds an instance on Class.Prototype without running
; __New. It now refuses the same native classes ...
oc := Object.Call
try oc(RegExMatchInfo)
catch ValueError as e
    Print("(Object.Call)(RegExMatchInfo): {}", e.Message)
; ... and, as a side effect, accepts Struct, which it rejected in alpha.35.
Print("(Object.Call)(Struct) -> {}", Type(oc(Struct)))

; --- 3. Script classes are untouched -----------------------------------------------
class Inventory extends Map {
    Add(item, qty := 1) => (this[item] := this.Get(item, 0) + qty, this)
}
inv := Inventory().Add("bolt", 10).Add("bolt", 5).Add("nut")
Print("Inventory: bolt {} nut {}  Type {}", inv["bolt"], inv["nut"], Type(inv))

; --- 4. Struct views reject own properties again (fork fix f24c23d1) -------------------
; The upstream alpha.36 build let every memory view grow ad-hoc properties:
; Pt.At(ptr).foo := 1 succeeded where alpha.35 threw PropertyError. The
; +Console fork restores the error; on the official build this section prints
; "accepted" instead.
struct Pt {
    x : Int32
    y : Int32
}
buf := Buffer(8, 0)
for pair in [["Pt.At", Pt.At(buf.Ptr)], ["ObjCreateWithDataPtr", ObjCreateWithDataPtr(Pt, buf.Ptr)]] {
    name := pair[1], view := pair[2]
    try {
        view.foo := 1
        Print("{}: own property accepted", name)
    } catch PropertyError as e
        Print("{}: {}", name, e.Message)
}
; An ordinary object made the same way still can own properties.
m := ObjCreateWithDataPtr(Map, 0)
m.note := "fine"
Print("Map from ObjCreateWithDataPtr: note = {}", m.note)
```

Source: [`02_constructor_errors.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha36/02_constructor_errors.ahk)

---

## 3. Load-time checks: `AhkLibPath` after a missing folder, and `#Import` clashes

Both fixes happen while a script loads, so this script writes small scripts to a temp folder and runs each in a child AutoHotkey through the shell, with `/ErrorStdOut` so a load error comes back as text. The first child sets `AhkLibPath` to `does-not-exist;lib` and includes `<Greet>`: on the official alpha.35 build the missing first entry made the second one vanish and the include failed; here it prints `found Greet.ahk`. That is the fix the +Console fork made on October 12 and upstream merged as `abe3ff20`.

The other four children exercise `#Import` inside a function against a `#Module Settings` that exports `Timeout := 30`. With no clash, `F()` returns 30. A `local Timeout`, a parameter `Timeout`, or an alias target `Limit` that already exists as a local each produce a load error naming the conflict, "This import declaration conflicts with an existing local variable." or "... with an existing parameter.", whether the local is declared before or after the `#Import`.

Before alpha.36, the local or parameter silently shadowed the import, so `F()` returned 5 and the module value was never read.

```ahk2
#Requires AutoHotkey v2.1-alpha.36

; alpha.36 fixes two load-time behaviours. Both can only be seen by loading a
; script, so this file writes small scripts to a temp folder and runs each in
; a child AutoHotkey, capturing its output and load errors through the shell.
;
;   1. AhkLibPath: a folder listed after one that does not exist is searched.
;      Before: everything after the missing folder was dropped (fixed in the
;      +Console fork on 2026-10-12, then upstream in abe3ff20).
;   2. #Import inside a function is a load error when a local, a parameter or
;      an "as" alias of the same name exists. Before: the local silently
;      shadowed the import.

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

; --- 1. A missing folder no longer swallows the rest of AhkLibPath -----------------
EnvSet("AhkLibPath", root "\does-not-exist;" root "\lib")
Print("missing;lib -> {}", RunChild("libpath", "#Requires AutoHotkey v2.1-alpha.36`n#Include <Greet>`nFileAppend(Greet() `"``n`", `"*`")`n"))
EnvSet("AhkLibPath", "")

; --- 2. #Import inside a function, with and without a clash -------------------------
module := "`n#Module Settings`nTimeout := 30`n"
ok := "
(
F() {
    #Import Settings {Timeout}
    return Timeout
}
FileAppend("F() = " F() "``n", "*")
)"
Print("no conflict        -> {}", RunChild("import_ok", ok module))

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

alias := "
(
F() {
    local Limit := 5
    #Import Settings {Timeout as Limit}
    return Limit
}
FileAppend("F() = " F() "``n", "*")
)"
Print("alias clash        -> {}", RunChild("import_alias", alias module))

DirDelete(root, true)
```

Source: [`03_load_time_checks.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha36/03_load_time_checks.ahk)

---

## Things I tripped over writing these

- **Continuation sections process backticks.** Writing a child script inside a `( ... )` block turns `` `n `` into a real newline *in the parent*, which left the child with a string broken across two lines ("Missing \""). Double it: ``` ``n ``` reaches the child as `` `n ``.
- **`Map` iterates in key order.** A `Map("Pt.At", ..., "ObjCreateWithDataPtr", ...)` printed the second entry first; an array of pairs keeps the order you wrote.
- **`ObjCreateWithDataPtr(Map, ...)` is a fork-only demo today.** Guarding on `InStr(A_AhkVersion, "+Console")` is the simplest way to keep a script runnable on the official build without crashing it.

---

## Running them

Every script starts with `#Requires AutoHotkey v2.1-alpha.36`. On the +Console fork they run as they are; on stock AutoHotkey add the `Print` line from the top of this post and pipe through `| more`.

```powershell
# +Console fork
.\bin\AutoHotkey64Console.exe 01_data_views.ahk

# stock AutoHotkey v2.1-alpha.36 or later (GUI exe), with the Print line added
AutoHotkey64.exe 01_data_views.ahk | more
```

*Disclosure: Claude Fable 5.1 wrote the scripts, ran them on the +Console fork build `a911f73d` (`2.1-alpha.37+Console`), and drafted this post. The alpha.35 comparisons and the official-build behaviour come from the fork's release notes, its `qa/tests/test_alpha36.ahk` (which records what the official alpha.36 zip did) and the upstream report linked above.*
