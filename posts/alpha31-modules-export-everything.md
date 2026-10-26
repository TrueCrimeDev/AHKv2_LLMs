# AutoHotkey v2.1-alpha.31: Modules Export Everything

Alpha.31 shipped on August 28, 2026 as upstream tag `v2.1-alpha.31`. It is a module-system release, and its headline change runs the other way from everything alpha.11 through alpha.30 built: the `export` keyword is gone, every name defined in a `#Module` section is exported, and the only names a module keeps to itself are the ones it imported. Two conventions fill the gap the keyword left: a leading underscore keeps a name out of `{*}` imports, and `#Import Export` forwards an import to the importer's own callers.

Around that sit a fix that makes `#Import` work inside `#Module AHK`, a cluster of unset-value fixes (a global imported through two modules, `RegExMatch` on no match, `Props(v)`), two Struct and reference fixes, and the v2.0.27 fixes that arrived through the v2.0 merge. This post is five short scripts, one per theme, each built around a pattern the change makes pleasant rather than a bare demonstration. Every script runs with exit 0 on the `2.1-alpha.37+Console` build and writes to stdout through one line of plain AutoHotkey, `FileAppend(..., "*")`; the comments record what alpha.30 did instead, and each claim about alpha.30 was re-run on an alpha.30 engine.

If any of your modules still carry `export` in front of a function, class or `global`, they will not load on alpha.31. The migration is mechanical: delete the keyword. The breaking-change section at the end gives the three failure modes so you can recognise them.

---

## 1. A module is a library by default

Inside a `#Module`, functions, classes, `global` declarations and plain top-level assignments are all exported. Nothing needs a keyword, and `Export` itself is an ordinary identifier again, so a function called `Export()` loads and runs. The underscore convention is the one new thing to learn: `_Clamp` is skipped by `#Import Geometry {*}`, still callable from inside `Geometry`, importable by name, and reachable through the module object as `Geometry._Clamp`.

The script defines a small `Geometry` module and imports it wholesale. The interesting lines are the last four: the wildcard left `_Clamp` out, the module object still reaches it, and `Geometry.Pi` reads a module global the way it has since alpha.20.

Before alpha.31, nothing left a module without `export`: on an alpha.30 engine this script loads with four "never assigned" warnings and exits 10 at the first call, "This global variable has not been assigned a value. Specifically: CircleArea".

```ahk2
#Requires AutoHotkey v2.1-alpha.31
Echo(fmt, args*) => FileAppend(Format(fmt, args*) "`n", "*")   ; native stdout

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

Echo("CircleArea(2) = {}", Round(CircleArea(2), 3))
Echo("Point(3, 4).Dist(Point(0, 0)) = {}", Point(3, 4).Dist(Point(0, 0)))
Echo("Scale = {}", Scale)
Echo("ClampedArea(50) = {} (radius clamped to 10)", Round(ClampedArea(50), 3))

; The underscore helper did not come through the wildcard...
Echo("_Clamp after {{}*{}} import: {}", IsSet(_Clamp) ? "imported" : "skipped")
; ...but the module object still reaches it, as it reaches every module global.
Echo("Geometry._Clamp(15, 0, 10) = {}", Geometry._Clamp(15, 0, 10))
Echo("Geometry.Pi = {}", Geometry.Pi)

Echo("Export(Point(1, 1)) = {}", Export(Point(1, 1)))
```

Source: [`01_implied_export.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha31/01_implied_export.ahk)

---

## 2. Facades: what a module imports stays private

The one category of name that is *not* exported is an import. When `Facade` imports `Core` with a plain `#Import Core {*}`, `Core`'s names are usable inside `Facade` but flagged as imported, so a module that imports `Facade` does not see them. That makes a facade a real boundary: it can wrap a core module and decide, per import, how much leaks through. `#Import Export Core {*}` is the forwarding form, and the `as` rename on the consumer side lets the forwarded names land under whatever name suits the caller.

The script has two facades over the same core. `Facade` keeps `Greet` and `Version` to itself; the consumer's `IsSet` checks come back "not visible". `OpenFacade` re-exports them, so the consumer imports `Greet as CoreGreet` and `Version as CoreVersion` from it. Nothing in `Core` changed between the two.

Before alpha.31 the same layering needed `export` on every forwarded name, and a plain import was private for the opposite reason: nothing was public to begin with. On alpha.30 this script dies at `Shout`, which was never exported.

```ahk2
#Requires AutoHotkey v2.1-alpha.31
Echo(fmt, args*) => FileAppend(Format(fmt, args*) "`n", "*")   ; native stdout

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

Echo("Shout(`"bob`") = {}", Shout("bob"))
Echo("Describe() = {}", Describe())

; Facade used Greet and Version, but did not pass them on.
Echo("Greet via Facade {{}*{}}: {}", IsSet(Greet) ? "visible" : "not visible")
Echo("Version via Facade {{}*{}}: {}", IsSet(Version) ? "visible" : "not visible")

; OpenFacade re-exported them, so they can be imported from it, renamed here.
Echo("Whisper(`"BOB`") = {}", Whisper("BOB"))
Echo("CoreGreet(`"ann`") = {}", CoreGreet("ann"))
Echo("CoreVersion = {}", CoreVersion)
```

Source: [`02_facade_reexport.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha31/02_facade_reexport.ahk)

---

## 3. A project prelude with `#Module AHK`

`#Module AHK` reopens the built-in module, the namespace every other module falls back to when a name is not found locally or through an import. A function defined there is visible from every module without any `#Import`. Alpha.31 fixed the thing that kept this from being a useful prelude: the built-in module was not on the list while imports were resolved, so an `#Import` written inside `#Module AHK` loaded, did nothing, and the names it should have bound stayed unset until a call hit them at run time.

The script imports three helpers from the companion file `StrKit.ahk` into `#Module AHK`, defines `Banner` and `Row` on top of them, and then uses all five from a `Report` module and from `__Main` without a single import of `StrKit`. Only file modules can be imported from `#Module AHK`; an in-file `#Module` section is "Module not found" there. Note the import is by name, not `{*}`, for a reason covered under pitfalls below.

Before alpha.31, the `#Import` inside `#Module AHK` was silently unresolved and the first call to `Repeat` failed with "This local variable has not been assigned a value." (This exact script fails earlier on alpha.30, at `Title`, because nothing in `Report` was exported either.)

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
Echo(fmt, args*) => FileAppend(Format(fmt, args*) "`n", "*")   ; native stdout

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

Echo(Title("alpha.31 prelude"))
Echo(Lines("Reverse", Reverse("stressed"), "Banner", "defined in #Module AHK", "Row", "same"))
Echo("Row is universal: {}", IsSet(Row) ? "yes" : "no")
Echo("Pad is universal too: {}", IsSet(Pad) ? "yes" : "no")
```

Source: [`03_builtin_prelude.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha31/03_builtin_prelude.ahk), [`StrKit.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha31/StrKit.ahk)

---

## 4. "No value" means the same thing everywhere

Three fixes tidy up what unset means across module boundaries and built-ins. A global imported through two hops (`Defaults` to `Settings` to `__Main`) used to arrive as an empty string in a `??` expression even though `IsSet` said 0, because the alias chain was only checked one level deep. `RegExMatch` leaves its output variable unset on no match in v2.1 mode, so `IsSet(m)` is the "did it match?" test; an intermediate commit had blanked it and release day put it back. And `Props(v)` now enumerates a copy of `v`'s value, not the variable, so a getter evaluated during the loop sees the value `Props` was given.

The pattern in section 1 is an optional setting threaded through layers: `Defaults` declares `Proxy` without assigning it, `Settings` re-exports it, and `__Main` reads `Proxy ?? "<unset>"` and gets the fallback. Section 3 needs a computed property on `String.Prototype`, which does not inherit `DefineProp`, so the script borrows `Object.Prototype.DefineProp.Call`.

Before alpha.31, the two-hop `??` produced an empty string and `Props` enumerated `Len=2`, the length of the string `v` held by the time the loop ran. Both were confirmed on an alpha.30 engine. A fourth fix in the same release is not in the script because it needs a real desktop: output parameters of `PixelSearch`, `ImageSearch` and `MouseGetPos` are now made blank when nothing is stored, as the documentation says, instead of being left unset.

```ahk2
#Requires AutoHotkey v2.1-alpha.31
Echo(fmt, args*) => FileAppend(Format(fmt, args*) "`n", "*")   ; native stdout

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

Echo("IsSet(Proxy) = {}", IsSet(Proxy))
Echo("Proxy ?? `"<unset>`" = {}", Proxy ?? "<unset>")      ; alpha.30: "" (empty string)
Echo("Summary() = {}", Summary())

; --- 2. RegExMatch: unset on no match (v2.1 mode) -----------------------------
Extract(text, pattern) => RegExMatch(text, pattern, &m) ? m[0] : (IsSet(m) ? "blank" : "unset")
Echo("Extract(`"hello`", `"l+`") = {}", Extract("hello", "l+"))
Echo("Extract(`"hello`", `"x`") = {}", Extract("hello", "x"))

; --- 3. Props(v) keeps the value ----------------------------------------------
; Primitive prototypes do not inherit DefineProp; borrow Object's.
Object.Prototype.DefineProp.Call(String.Prototype, "Len", {get: (this) => StrLen(this)})
v := "hello"
e := Props(v)                        ; the enumerator now holds a copy of "hello"
v := "hi"
for name, val in e
    Echo("Props enumerated {}={}", name, val)   ; alpha.30: Len=2
```

Source: [`04_unset_semantics.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha31/04_unset_semantics.ahk)

---

## 5. Struct views, split properties, virtual references

Three fixes outside the module system. A `StructClass.At(ptr)` view whose layout contains a nested struct *array* crashed when released, because the destructor walked nested slots that a boxed pointer never constructs; it now checks for a vtable first. A property's getter and setter may be declared in two separate blocks in either order, which v2.0.27 fixed and the merge brought over; alpha.30 rejected getter-then-setter as "Duplicate declaration". And a plain `a := src` where `src` is a `&param` bound to an object with `__Value` no longer throws "This parameter has not been assigned a value".

The first section is the useful one: a view over a `Buffer` that owns nothing, written through, released, and the buffer read back directly. The split-declaration case matters when a later section of a class, or a mixin, adds the setter. For the virtual reference, the alpha.31 notes recorded the simple form copying the `Cell` object itself; on the alpha.37 build used here it reads `__Value` and gives `Integer / 42`, so the script prints both the simple form and an expression form and the comment calls the simple form unsettled across versions.

Before alpha.31, releasing the view exited 11 with "Invalid memory read/write", and the split `Level` declaration was a load error. On alpha.30 this script stops at load with "Duplicate declaration. Specifically: Level".

```ahk2
#Requires AutoHotkey v2.1-alpha.31
Echo(fmt, args*) => FileAppend(Format(fmt, args*) "`n", "*")   ; native stdout

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
Echo("view.items[2].a = {}, view.b = {}, Outer size = {}", view.items[2].a, view.b, Outer().Size)
view := ""                            ; alpha.30 died here
Echo("view released, buffer still readable: items[2].a = {}", NumGet(buf, 4, "Int"))

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
Echo("c.Level = {}, c._log = {}", c.Level, c._log)

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
Echo("CopyOut(Cell(42)) = {}", CopyOut(Cell(42)))
x := 7
Echo("CopyOut(&x) = {}", CopyOut(&x))
```

Source: [`05_struct_and_property_fixes.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha31/05_struct_and_property_fixes.ahk)

---

## The breaking change, by symptom

`export` was removed from the action table and from the function and class scanners, so it is an ordinary identifier now. What an old module does on alpha.31 depends on which form it used, and only one of the three fails at load:

- `export Fn(x) {` ... `}` loads, with a warning that `export` is never assigned, and dies when execution reaches the line: "This global variable has not been assigned a value. Specifically: export" (exit 10).
- `export global X := 1` is a load error: "The following reserved word must not be used as a variable name: global" (exit 12).
- `export class K {` ... `}` is a load error: "Unexpected `{`" (exit 12).

Delete the keyword and nothing else changes. If a module relied on *not* exporting a helper, give it a leading underscore or move it inside a function; there is no other way to hide a module-level name. `export default` is gone with the rest.

---

## Things I tripped over writing these

- **A wildcard import into `#Module AHK` binds names lazily.** With `#Import "StrKit.ahk" {*}` in the prelude, a name became visible to other modules only after something *in* `#Module AHK` referenced it: `Repeat` (used by `Banner`) was universal, `Reverse` and `Pad` were not. Importing by name, `{Repeat, Reverse, Pad}`, makes all three universal at once. In an ordinary module an import is private either way.
- **`Format` escapes braces as `{{}` and `{}}`.** Writing `{{*}}` prints `{{*}}` literally; the output helper here routes every string through `Format`, so a literal `{*}` is spelled `{{}*{}}`.
- **`PixelSearch` and `MouseGetPos` cannot be exercised headless.** On a hidden desktop they fail with "The handle is invalid" and "Access is denied", so the made-blank output-parameter fix is described, not demonstrated.
- **The simple-assignment-from-virtual-reference result moved.** The alpha.31 notes observed `Type(a)` as `Cell`; alpha.37 gives `Integer`. Use an expression form when you need `__Value`.

---

## Running them

Every script starts with `#Requires AutoHotkey v2.1-alpha.31`, so an older engine stops at line 1 with a clear message. Script 3 needs `StrKit.ahk` in the same folder; the engine changes to the script's directory before the auto-execute section, so the relative import works from any current directory.

```powershell
# stock AutoHotkey v2.1-alpha.31 or later (GUI exe): pipe or redirect to see stdout
AutoHotkey64.exe 01_implied_export.ahk | more

# +Console fork: stdout is a real console stream
AutoHotkey64Console.exe 01_implied_export.ahk
```

Nothing in the scripts is fork-specific. `FileAppend` with `*` as the file name is AutoHotkey's native stdout; the stock GUI executable only shows it when its output is piped or redirected, so the `| more` is not optional there.

*Disclosure: Claude Fable 5.1 wrote the five scripts and this post. Every behaviour claim was observed on `2.1-alpha.37+Console` (`a911f73d`), and each "before" claim was re-run on a `2.1-alpha.30+Console` engine with the `#Requires` line lowered; the release-note facts come from the fork's `docs/alpha/v2.1-alpha.31.md`.*
