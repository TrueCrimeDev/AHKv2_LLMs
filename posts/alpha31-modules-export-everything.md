# AutoHotkey v2.1-alpha.31: Modules Export Everything

Alpha.31 (August 28, 2026) removes the `export` keyword: every name a `#Module` defines is exported, only its imports stay private, a leading underscore hides a name from `{*}`, and `#Import Export` forwards an import. Modules that still say `export` do not load; delete the keyword (symptoms at the end).

**`Print` is a fork built-in**, not stock AutoHotkey. `Print("x = {}", x)` formats through `Format` and writes one line to stdout; a single argument is written as-is. On stock AutoHotkey add this line under `#Requires` and pipe through `| more`:

```ahk2
Print(fmt := "", args*) => FileAppend((args.Length ? Format(fmt, args*) : fmt) "`n", "*")
```

---

## 1. A module is a library by default

Functions, classes, `global`s and top-level assignments in a `#Module` are all exported, and `Export` is an ordinary identifier again. `_Clamp` is skipped by `#Import Geometry {*}` but still importable by name and reachable as `Geometry._Clamp`. On alpha.30 this script exits 10 at the first call, because nothing was exported.

```ahk2
#Requires AutoHotkey v2.1-alpha.31

; alpha.31: every name defined in a #Module is exported; `export` is gone.
;
; A module is now a library by default. Functions, classes, `global`
; declarations and plain top-level assignments are all visible to any module
; that imports it. The one escape hatch is a leading underscore, which keeps a
; name out of {*} imports while leaving it reachable by explicit import or
; through the module object.
;
; Before alpha.31 (alpha.11 through alpha.30), nothing left a module without an
; `export` prefix: this script loaded with "never assigned" warnings and died
; at the first call with "This global variable has not been assigned a value."

; --- 1. The library ------------------------------------------------------------
#Module Geometry

global Pi := 3.14159265358979          ; exported, no keyword
CircleArea(r) => Pi * r ** 2            ; exported
class Point {                           ; exported
    __New(x, y) {
        this.x := x
        this.y := y
    }
    Dist(other) => Sqrt((this.x - other.x) ** 2 + (this.y - other.y) ** 2)
}
Scale := 2                              ; a plain top-level assignment is exported too

; Private by convention: skipped by {*}, still callable inside the module.
_Clamp(v, lo, hi) => Min(Max(v, lo), hi)
ClampedArea(r) => CircleArea(_Clamp(r, 0, 10))

; `Export` is an ordinary identifier again (alpha.20 reserved it).
Export(obj) => "exported a " Type(obj)

; --- 2. The consumer -----------------------------------------------------------
#Module __Main
#Import Geometry {*}

Print("CircleArea(2) = {}", Round(CircleArea(2), 3))
Print("Point(3, 4).Dist(Point(0, 0)) = {}", Point(3, 4).Dist(Point(0, 0)))
Print("Scale = {}", Scale)
Print("ClampedArea(50) = {} (radius clamped to 10)", Round(ClampedArea(50), 3))

; The underscore helper did not come through the wildcard...
Print("_Clamp after {{}*{}} import: {}", IsSet(_Clamp) ? "imported" : "skipped")
; ...but the module object still reaches it, as it reaches every module global.
Print("Geometry._Clamp(15, 0, 10) = {}", Geometry._Clamp(15, 0, 10))
Print("Geometry.Pi = {}", Geometry.Pi)

Print("Export(Point(1, 1)) = {}", Export(Point(1, 1)))
```

Output:

```text
CircleArea(2) = 12.566
Point(3, 4).Dist(Point(0, 0)) = 5.0
Scale = 2
ClampedArea(50) = 314.159 (radius clamped to 10)
_Clamp after {*} import: skipped
Geometry._Clamp(15, 0, 10) = 10
Geometry.Pi = 3.14159265358979
Export(Point(1, 1)) = exported a Point
```

Source: [`01_implied_export.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha31/01_implied_export.ahk)

---

## 2. Facades: what a module imports stays private

Imports are the one kind of name a module does not export, so `Facade`, which imports `Core`, hides `Greet` and `Version` from its own importers. `OpenFacade` forwards them with `#Import Export Core {*}`, and the consumer renames them with `as`. On alpha.30 the script dies at `Shout`, which was never exported.

```ahk2
#Requires AutoHotkey v2.1-alpha.31

; alpha.31: imported names stay private to the importer unless re-exported.
;
; "Everything is exported" has one exception: the names a module itself
; imported. That makes a facade module a real boundary. What it imports with
; a plain #Import is its own business; what it imports with #Import Export is
; forwarded to its callers. A facade can therefore wrap a core module and
; decide, per import, how much of the core leaks through.
;
; Before alpha.31 the same layering needed `export` on every forwarded name,
; and a plain import was private for the opposite reason: nothing was public.

; --- The core nobody is meant to call directly --------------------------------
#Module Core
Greet(name) => "hi " name
Version := "core 1.0"

; --- A closed facade: Core is an implementation detail ------------------------
#Module Facade
#Import Core {*}                           ; private to Facade
Shout(name) => StrUpper(Greet(name))
Describe() => "Facade over " Version       ; uses Core's Version internally

; --- An open facade: Core is part of the contract -----------------------------
#Module OpenFacade
#Import Export Core {*}                    ; re-exported to OpenFacade's importers
Whisper(name) => StrLower(Greet(name)) "..."

; --- The caller ---------------------------------------------------------------
#Module __Main
#Import Facade {*}
#Import OpenFacade {Whisper, Greet as CoreGreet, Version as CoreVersion}

Print("Shout(`"bob`") = {}", Shout("bob"))
Print("Describe() = {}", Describe())

; Facade used Greet and Version, but did not pass them on.
Print("Greet via Facade {{}*{}}: {}", IsSet(Greet) ? "visible" : "not visible")
Print("Version via Facade {{}*{}}: {}", IsSet(Version) ? "visible" : "not visible")

; OpenFacade re-exported them, so they can be imported from it, renamed here.
Print("Whisper(`"BOB`") = {}", Whisper("BOB"))
Print("CoreGreet(`"ann`") = {}", CoreGreet("ann"))
Print("CoreVersion = {}", CoreVersion)
```

Output:

```text
Shout("bob") = HI BOB
Describe() = Facade over core 1.0
Greet via Facade {*}: not visible
Version via Facade {*}: not visible
Whisper("BOB") = hi bob...
CoreGreet("ann") = hi ann
CoreVersion = core 1.0
```

Source: [`02_facade_reexport.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha31/02_facade_reexport.ahk)

---

## 3. A project prelude with `#Module AHK`

`#Module AHK` reopens the built-in module, the fallback namespace for every other module, so anything defined there is visible everywhere without an import. Alpha.31 fixed `#Import` inside it, which used to load and bind nothing. The script imports three helpers from `StrKit.ahk` into the prelude by name (a `{*}` import there binds lazily, see pitfalls) and uses them from a `Report` module and `__Main`; only file modules can be imported there.

```ahk2
; StrKit.ahk: a single-module file. Since alpha.31 every name here is
; exported without a keyword, so `#Import "StrKit.ahk" {*}` binds all three.
#Requires AutoHotkey v2.1-alpha.31

Repeat(s, n) {
    out := ""
    loop n
        out .= s
    return out
}

Reverse(s) {
    out := ""
    loop parse s
        out := A_LoopField out
    return out
}

Pad(s, width, ch := " ") => s Repeat(ch, Max(0, width - StrLen(s)))
```

```ahk2
#Requires AutoHotkey v2.1-alpha.31

; alpha.31: #Import inside #Module AHK is resolved.
;
; #Module AHK reopens the built-in module, the namespace every other module
; falls back to when a name is not found locally or through an import. A
; function defined there behaves like a built-in: visible from every module,
; no #Import needed. alpha.31 fixed the one thing that made this useless as a
; project prelude: an #Import written inside #Module AHK was silently never
; resolved, so the names it brought in stayed unset and the first call died
; at run time with "This local variable has not been assigned a value."
;
; Only file modules can be imported from #Module AHK (an in-file #Module
; section is "Module not found" there). StrKit.ahk sits beside this script.

; --- The prelude: a file module promoted to built-in status -------------------
#Module AHK
#Import "StrKit.ahk" {Repeat, Reverse, Pad}   ; alpha.30: loaded, but all three stayed unset

Banner(text) => Repeat("=", StrLen(text)) "`n" text "`n" Repeat("=", StrLen(text))
Row(label, value) => Pad(label, 12, ".") " " value

; --- Any module can use the prelude, and StrKit, without importing anything ---
#Module Report
Title(t) => Banner(StrUpper(t))
Lines(pairs*) {
    out := ""
    loop pairs.Length // 2
        out .= Row(pairs[A_Index * 2 - 1], pairs[A_Index * 2]) "`n"
    return RTrim(out, "`n")
}

#Module __Main
#Import Report {*}

Print(Title("alpha.31 prelude"))
Print(Lines("Reverse", Reverse("stressed"), "Banner", "defined in #Module AHK", "Row", "same"))
Print("Row is universal: {}", IsSet(Row) ? "yes" : "no")
Print("Pad is universal too: {}", IsSet(Pad) ? "yes" : "no")
```

Output:

```text
================
ALPHA.31 PRELUDE
================
Reverse..... desserts
Banner...... defined in #Module AHK
Row......... same
Row is universal: yes
Pad is universal too: yes
```

Source: [`03_builtin_prelude.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha31/03_builtin_prelude.ahk), [`StrKit.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha31/StrKit.ahk)

---

## 4. "No value" means the same thing everywhere

Three unset fixes. A global imported through two hops (`Defaults` to `Settings` to `__Main`) now reaches `??` as unset instead of an empty string; `RegExMatch` leaves its output variable unset on no match in v2.1 mode, so `IsSet(m)` is the match test; `Props(v)` enumerates a copy of the value, so a getter that runs during the loop sees it. A fourth fix, blank output parameters from `PixelSearch`, `ImageSearch` and `MouseGetPos`, needs a real desktop and is not shown.

```ahk2
#Requires AutoHotkey v2.1-alpha.31

; alpha.31: three fixes that make "no value" mean the same thing everywhere.
;
;   1. A global imported through two modules keeps its unset state
;      (alpha.30: `??` saw an empty string after the second hop).
;   2. RegExMatch leaves its output variable unset on no match in v2.1 mode,
;      so IsSet(m) is the "did it match?" test (alpha.31 restored this after
;      an intermediate commit blanked it; alpha.30 already behaved this way).
;   3. Props(v) enumerates a copy of v, not the variable
;      (alpha.30: a getter saw whatever v held by the time the loop ran).
;
; A fourth fix in the same release is not shown because it needs a real
; desktop: output parameters of PixelSearch, ImageSearch and MouseGetPos are
; now "made blank" when nothing is stored, as the docs say, instead of unset.

; --- 1. An optional setting threaded through two layers ----------------------
#Module Defaults
global Proxy                         ; declared on purpose, never assigned
global Theme := "dark"

#Module Settings
#Import Export Defaults {Proxy, Theme}   ; first hop
Summary() => "theme=" Theme ", proxy=" (Proxy ?? "none")

#Module __Main
#Import Settings {Summary, Proxy, Theme} ; second hop

Print("IsSet(Proxy) = {}", IsSet(Proxy))
Print("Proxy ?? `"<unset>`" = {}", Proxy ?? "<unset>")      ; alpha.30: "" (empty string)
Print("Summary() = {}", Summary())

; --- 2. RegExMatch: unset on no match (v2.1 mode) -----------------------------
Extract(text, pattern) => RegExMatch(text, pattern, &m) ? m[0] : (IsSet(m) ? "blank" : "unset")
Print("Extract(`"hello`", `"l+`") = {}", Extract("hello", "l+"))
Print("Extract(`"hello`", `"x`") = {}", Extract("hello", "x"))

; --- 3. Props(v) keeps the value ----------------------------------------------
; Primitive prototypes do not inherit DefineProp; borrow Object's.
Object.Prototype.DefineProp.Call(String.Prototype, "Len", {get: (this) => StrLen(this)})
v := "hello"
e := Props(v)                        ; the enumerator now holds a copy of "hello"
v := "hi"
for name, val in e
    Print("Props enumerated {}={}", name, val)   ; alpha.30: Len=2
```

Output:

```text
IsSet(Proxy) = 0
Proxy ?? "<unset>" = <unset>
Summary() = theme=dark, proxy=none
Extract("hello", "l+") = ll
Extract("hello", "x") = unset
Props enumerated Len=5
```

Source: [`04_unset_semantics.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha31/04_unset_semantics.ahk)

---

## 5. Struct views, split properties, virtual references

Three fixes outside modules. Releasing a `StructClass.At(ptr)` view whose layout holds a nested struct array crashed (exit 11); a property's getter and setter may be declared in two separate blocks in either order (alpha.30 said "Duplicate declaration"); and `a := src` where `src` is a `&param` bound to an object with `__Value` no longer throws. The simple-assignment case gives `Integer / 42` on alpha.37 where the alpha.31 notes saw `Cell`, so the script prints both forms.

```ahk2
#Requires AutoHotkey v2.1-alpha.31

; alpha.31: three fixes outside the module system.
;
;   1. Releasing a StructClass.At(ptr) view whose layout holds a nested struct
;      array no longer crashes (alpha.30: "Invalid memory read/write", exit 11).
;   2. A property's getter and setter may be declared in separate blocks in
;      either order (v2.0.27; alpha.30 rejected getter-then-setter as
;      "Duplicate declaration").
;   3. `a := src` where src is a &param bound to an object with __Value no
;      longer throws "This parameter has not been assigned a value".

; --- 1. A view over a buffer that owns nothing --------------------------------
struct Inner {
    a : Int32
}
struct Outer {
    items : Inner[3]                  ; nested struct array
    b     : Int32
}
buf := Buffer(64, 0)
view := Outer.At(buf.Ptr)             ; boxed pointer into buf
view.items[2].a := 5
view.b := 9
Print("view.items[2].a = {}, view.b = {}, Outer size = {}", view.items[2].a, view.b, Outer().Size)
view := ""                            ; alpha.30 died here
Print("view released, buffer still readable: items[2].a = {}", NumGet(buf, 4, "Int"))

; --- 2. Split getter and setter declarations ----------------------------------
; Useful when a mixin or a later section of a class adds the setter.
class Cfg {
    Level {
        get => 42
    }
    Level {                           ; alpha.30: "Duplicate declaration"
        set => this._log := "set " value
    }
}
c := Cfg()
c.Level := 7
Print("c.Level = {}, c._log = {}", c.Level, c._log)

; --- 3. Simple assignment from a virtual reference ----------------------------
class Cell {
    __New(v) => this._v := v
    __Value {
        get => this._v
        set => this._v := value
    }
}
CopyOut(&src) {
    plain := src                      ; alpha.30: threw; alpha.31: copies the reference object
    value := src + 0                  ; any expression form reads __Value
    return Type(plain) " / " value
}
Print("CopyOut(Cell(42)) = {}", CopyOut(Cell(42)))
x := 7
Print("CopyOut(&x) = {}", CopyOut(&x))
```

Output:

```text
view.items[2].a = 5, view.b = 9, Outer size = 16
view released, buffer still readable: items[2].a = 5
c.Level = 42, c._log = set 7
CopyOut(Cell(42)) = Integer / 42
CopyOut(&x) = Integer / 7
```

Source: [`05_struct_and_property_fixes.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha31/05_struct_and_property_fixes.ahk)

---

## The breaking change, by symptom

`export` is an ordinary identifier now. What an old module does depends on the form:

- `export Fn(x) {` ... `}` loads with a warning and exits 10 at the call: "This global variable has not been assigned a value. Specifically: export".
- `export global X := 1` is a load error, exit 12: "The following reserved word must not be used as a variable name: global".
- `export class K {` ... `}` is a load error, exit 12: "Unexpected `{`".

Fix: delete the keyword. To hide a helper, prefix it with `_` or move it inside a function; `export default` is gone too.

---

## Things I tripped over writing these

- **`{*}` into `#Module AHK` binds lazily.** A name becomes universal only once something in the prelude references it; import by name instead.
- **A literal `{*}` through `Print` is `{{}*{}}`.** `Format` escapes braces as `{{}` and `{}}`.
- **`PixelSearch` and `MouseGetPos` fail on a hidden desktop**, so the blank-output-parameter fix is described, not shown.

---

## Running them

`#Requires AutoHotkey v2.1-alpha.31` on every script. Script 3 needs `StrKit.ahk` beside it. Fork: run as-is. Stock: add the `Print` line and pipe through `| more`.

```powershell
# +Console fork
.\bin\AutoHotkey64Console.exe 01_implied_export.ahk

# stock AutoHotkey v2.1-alpha.31 or later (GUI exe), with the Print line added
AutoHotkey64.exe 01_implied_export.ahk | more
```

*Scripts and text by Claude Fable 5.1, run on `2.1-alpha.37+Console` (`a911f73d`); "before" behaviour from the fork's release notes, re-run on an alpha.30 engine.*
