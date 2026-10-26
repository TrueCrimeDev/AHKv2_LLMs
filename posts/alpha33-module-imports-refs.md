# AutoHotkey v2.1-alpha.33: Modules Get Local Imports and References

Alpha.33 shipped on October 3, 2026 (upstream tag `v2.1-alpha.33`). It rounds out the module system: `#Import` works inside a function body, and the reference operator works on a module object's variables. A cluster of 32-bit struct and callback bugs is fixed, and two crashes become ordinary errors. Nothing in it is breaking for x64 scripts.

Three scripts follow, one per theme. The module examples keep their modules in the same file with `#Module` sections so each script is self-contained; `#Import` behaves the same for a module in its own file.

One of the two headline features shipped broken upstream. `&Module.Var` works until the reference is released, then the process dies with a heap-corruption exit, and passing it to a ByRef parameter leaves the module variable unset. The [+Console fork](https://github.com/TrueCrimeDev/AutoHotkey) found that on the day it merged alpha.33, fixed it, and wrote it up for upstream; script 2 says more.

**About `Print`.** The scripts write their output with `Print`, which is not stock AutoHotkey: it is a built-in of the [+Console fork](https://github.com/TrueCrimeDev/AutoHotkey). `Print("x = {}, y = {}", x, y)` runs its arguments through `Format` and writes the result plus a newline to stdout; a single argument is written as-is, and `Print()` writes a blank line. To run the scripts on stock AutoHotkey, add this one line under `#Requires` (it reproduces those three shapes) and pipe the output through `| more`, because the GUI executable only shows stdout when it is redirected:

```ahk2
Print(fmt := "", args*) => FileAppend((args.Length ? Format(fmt, args*) : fmt) "`n", "*")
```

---

## 1. `#Import` inside a function

A function body may now contain `#Import`. The names it brings in are scoped to that function, so a helper can lean on a module without adding anything to the file's own namespace. The script defines two modules that both export a `PI`, one numeric and one deliberately not, and gives each function the one it wants. At the top level that would be a name conflict; inside a function it is just a local import.

Section 2 shows the other half of the story: after `Area` imports `PI`, the top level of the file still has no `PI`. `IsSet(PI)` is 0 there. Section 4 imports a whole module as a namespace inside a function, which is the shape to use when a helper needs several names.

Before alpha.33, `#Import` was accepted only at the top level of a module; inside a function it was a load error.

```ahk2
#Requires AutoHotkey v2.1-alpha.33
; alpha.33: #Import inside a function
;
; A function body may contain #Import. The names it brings in are scoped to
; that function, so a helper can lean on a module without adding anything to
; the file's own namespace. Before alpha.33, #Import was only valid at the top
; level of a module.
;
; The modules live in this file so the example is self-contained; #Import
; works the same for a module in its own file.

#Module Geometry
global PI := 3.14159265
Circle(r) => PI * r * r

#Module Temperature
global PI := "not a number"     ; the same name, a different module
ToF(c) => c * 9 / 5 + 32

#Module __Main

; --- 1. A helper imports exactly what it needs, where it needs it -----------
Area(r) {
    #Import Geometry {PI}
    return PI * r * r
}
Print("Area(2) = {:.4f}", Area(2))

; --- 2. The import did not leak into the file's scope ------------------------
; PI is not defined at the top level of __Main: it is an unset global here,
; not Geometry's constant.
Print("top-level PI is set: {}", IsSet(PI))

; --- 3. Two functions, two modules, one name -------------------------------
; Each function sees its own PI. At the top level that would have been a
; conflict; inside a function it is just a local import.
Describe() {
    #Import Temperature {PI}
    return "Temperature's PI is '" PI "'"
}
Print("{}", Describe())
Print("Area(1) = {:.5f}", Area(1))

; --- 4. Importing the whole module as a namespace ---------------------------
Convert(c) {
    #Import Temperature
    return Temperature.ToF(c)
}
Print("Convert(100) = {}", Convert(100))
```

Source: [`01_import_in_function.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha33/01_import_in_function.ahk)

---

## 2. `&Module.Var`: a reference to a module variable

`&Stats.Count` is now a `VarRef` to the module-level variable, so a module's state can be handed to a ByRef helper, or to a built-in output parameter such as `SplitPath` or `RegExMatch`, without importing the name into the caller. The script bumps a counter through a ByRef function, fills a module variable from `SplitPath`, holds the reference in a variable and reads and writes through `%ref%`, and passes it to a higher-order `Apply(fn, &target)`.

The last two lines are the part that mattered. Upstream alpha.33's `ScriptModule::__Ref` returned the engine's internal uncounted reference without an `AddRef`. The expression evaluator releases a method result when the expression ends, so the first `&Stats.Count` left the module variable aliased to a reference whose only count belonged to the caller; the next one freed it while the variable still pointed at it. On the official alpha.33 build, `Bump(&Mod.X)` then `Mod.X` throws `UnsetError`, and `ref := ""` or script exit dies with `0xC0000374`. The fork's `source/script_module.cpp` adds the missing `AddRef`, pins both symptoms in `qa/tests/test_alpha33.ahk`, and keeps the upstream report in [`docs/upstream/alpha33-module-ref-addref.md`](https://github.com/TrueCrimeDev/AutoHotkey/blob/alpha/docs/upstream/alpha33-module-ref-addref.md). On the official build, use `#Import Stats {Count}` and `&Count` instead.

Before alpha.33, `&Stats.Count` was an error: module objects had no `__Ref`.

```ahk2
#Requires AutoHotkey v2.1-alpha.33
; alpha.33: &Module.Var (Module.__Ref)
;
; The reference operator works on a module object's variables. &Stats.Count
; is a VarRef to the module-level variable, so it can be handed to a ByRef
; parameter or to a built-in output parameter without importing the name.
; Before alpha.33, &Stats.Count was an error: modules had no __Ref.
;
; Upstream alpha.33 returned that reference without a reference count, which
; corrupted the heap once it was released (the fork fixed it; see the post).

#Module Stats
global Count := 0
global Last := ""

#Module __Main
#Import Stats

; --- 1. A ByRef helper mutates a module variable in place --------------------
Bump(&v, by := 1) => v += by
Bump(&Stats.Count)
Bump(&Stats.Count, 10)
Print("Stats.Count = {}", Stats.Count)

; --- 2. Built-in output parameters accept it too ------------------------------
SplitPath("C:\logs\today.txt", &Stats.Last)
Print("Stats.Last = {}", Stats.Last)
RegExMatch("v2.1-alpha.33", "alpha\.(\d+)", &m)
Stats.Count := m[1]
Print("Stats.Count = {}", Stats.Count)

; --- 3. The reference is a real VarRef you can hold and reuse ------------------
ref := &Stats.Count
%ref% += 1
Print("through the ref: {}  module sees: {}", %ref%, Stats.Count)
Stats.Count := 100
Print("module write, ref sees: {}", %ref%)

; --- 4. Pass the same reference around like any other ------------------------
Apply(fn, &target) => target := fn(target)
Apply(x => x * 2, &Stats.Count)
Print("doubled: {}", Stats.Count)
ref := ""                       ; releasing it is safe on the fixed engine
Print("after release: {}", Stats.Count)
```

Source: [`02_module_ref.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha33/02_module_ref.ahk)

---

## 3. Two crashes become errors

`a.b[c]` when `a.b` returns unset used to take the process down; it now throws `UnsetError`. The capacity functions (`ObjSetCapacity`, `ObjGetCapacity` and relatives) used to corrupt a `Struct` they were pointed at; they now throw `TypeError`. The script shows both as catchable, with the struct intact afterwards, and the `IsSet(reg.table?)` guard that turns the first one into a clean fallback.

The release also fixes four 32-bit regressions that had been there since alpha.24: `EditGetLine`, `ControlChooseIndex` and `ControlDeleteItem`; `DllCall(..., Struct.Ptr, unset)` allocating its out-struct; `Struct.Array` parameter marshaling; and typed callbacks with 64-bit numeric parameters reading the right stack slots. None of those can be shown from an x64 script, so they stay a list.

Before alpha.33, `Registry().table["key"]` exited the process and `ObjSetCapacity(px, 8)` wrote over the struct's fields.

```ahk2
#Requires AutoHotkey v2.1-alpha.33
; alpha.33: two crashes become errors
;
;   a.b[c] when a.b returns unset      -> UnsetError (was: process crash)
;   ObjSetCapacity(struct, n) and kin  -> TypeError  (was: corrupted the struct)

; --- 1. Indexing through an unset property is an ordinary error -----------
class Registry {
    ; A lookup table that may not be configured yet.
    table => unset
}
try Registry().table["key"]
catch UnsetError as e
    Print("Registry().table[`"key`"]: {}", e.Message)

; Guard it the usual way and fall back.
Lookup(reg, key) => IsSet(reg.table?) ? reg.table[key] : "(no table)"
Print("Lookup: {}", Lookup(Registry(), "key"))

; --- 2. Capacity functions refuse a Struct ---------------------------------
struct Pixel {
    r : UInt8
    g : UInt8
    b : UInt8
}
px := Pixel()
px.r := 255
for name, fn in Map("ObjSetCapacity", ObjSetCapacity.Bind(px, 8), "ObjGetCapacity", ObjGetCapacity.Bind(px)) {
    try fn()
    catch TypeError as e
        Print("{}: {}", name, e.Message)
}
Print("Pixel intact: r={} Size={}", px.r, px.Size)
```

Source: [`03_struct_guards.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha33/03_struct_guards.ahk)

---

## Running them

Every script starts with `#Requires AutoHotkey v2.1-alpha.33`. On the +Console fork they run as they are; on stock AutoHotkey add the `Print` line from the top of this post and pipe through `| more`.

```powershell
# +Console fork
.\bin\AutoHotkey64Console.exe 01_import_in_function.ahk

# stock AutoHotkey v2.1-alpha.33 or later (GUI exe), with the Print line added
AutoHotkey64.exe 01_import_in_function.ahk | more
```

*Disclosure: Claude Fable 5.1 wrote the scripts, ran them, and drafted this post. Every behaviour claim was observed on `2.1-alpha.37+Console` (`a911f73d`), which carries this release, or comes from the fork's release notes for it; the "before" lines are from those notes.*
