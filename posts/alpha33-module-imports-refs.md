# AutoHotkey v2.1-alpha.33: Modules Get Local Imports and References

Alpha.33 shipped on October 3, 2026 (upstream tag `v2.1-alpha.33`). It is a small release that rounds out the module system: `#Import` works inside a function body, the reference operator works on a module object's variables, two crashes become ordinary errors, and a cluster of 32-bit struct and callback bugs is fixed. Nothing in it is breaking for x64 scripts; the scripts below keep their modules in the same file as `#Module` sections.

**`Print` is a fork built-in**, not stock AutoHotkey. `Print("x = {}", x)` formats through `Format` and writes one line to stdout; a single argument is written as-is. On stock AutoHotkey add this line under `#Requires` and pipe through `| more`:

```ahk2
Print(fmt := "", args*) => FileAppend((args.Length ? Format(fmt, args*) : fmt) "`n", "*")
```

---

## 1. `#Import` inside a function

A function body may now contain `#Import`, and the names it brings in are scoped to that function, so a helper can lean on a module without adding anything to the file's namespace. The script defines two modules that both export a `PI`, one numeric and one deliberately not, and gives each function the one it wants; at the top level that would be a name conflict, and `IsSet(PI)` is still 0 there after `Area` has imported it. The last function imports a whole module as a namespace, the shape to use when a helper needs several names. Before alpha.33, `#Import` inside a function was a load error.

```ahk2
#Requires AutoHotkey v2.1-alpha.33
; alpha.33: #Import inside a function
; The names it brings in are scoped to that function, so a helper can use a
; module without adding anything to the file's namespace. Before alpha.33,
; #Import was only valid at the top level of a module.

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

; --- 2. The import did not leak: __Main has no PI of its own ----------------
Print("top-level PI is set: {}", IsSet(PI))

; --- 3. Two functions, two modules, one name --------------------------------
; At the top level this would be a conflict; inside a function it is local.
Describe() {
    #Import Temperature {PI}
    return "Temperature's PI is '" PI "'"
}
Print("{}", Describe())

; --- 4. Or import the whole module as a namespace ---------------------------
Convert(c) {
    #Import Temperature
    return Temperature.ToF(c)
}
Print("Convert(100) = {}", Convert(100))
```

Output:

```text
Area(2) = 12.5664
top-level PI is set: 0
Temperature's PI is 'not a number'
Convert(100) = 212.0
```

Source: [`01_import_in_function.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha33/01_import_in_function.ahk)

---

## 2. `&Module.Var`: a reference to a module variable

`&Stats.Count` is now a `VarRef` to the module-level variable, so a module's state can be handed to a ByRef helper or to a built-in output parameter such as `SplitPath` without importing the name into the caller; the script does both, then holds the reference in a variable, reads and writes through `%ref%`, and releases it. That release is the part that mattered: upstream alpha.33 returned the reference without an `AddRef`, so on the official build `Bump(&Mod.X)` leaves `Mod.X` unset and `ref := ""` or script exit dies with `0xC0000374`. The [+Console fork](https://github.com/TrueCrimeDev/AutoHotkey) fixed it on the day it merged alpha.33 and wrote it up in [`docs/upstream/alpha33-module-ref-addref.md`](https://github.com/TrueCrimeDev/AutoHotkey/blob/alpha/docs/upstream/alpha33-module-ref-addref.md); on the official build use `#Import Stats {Count}` and `&Count` instead. Before alpha.33, `&Stats.Count` was an error because module objects had no `__Ref`.

```ahk2
#Requires AutoHotkey v2.1-alpha.33
; alpha.33: &Module.Var (Module.__Ref)
; &Stats.Count is a VarRef to the module-level variable, so it can go to a
; ByRef parameter or a built-in output parameter without importing the name.
; Before alpha.33 it was an error: modules had no __Ref. Upstream alpha.33
; returned it without a reference count and corrupted the heap on release;
; the fork fixed that (see the post).

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

; --- 3. The reference is a real VarRef you can hold, reuse and release --------
ref := &Stats.Count
%ref% += 1
Print("through the ref: {}  module sees: {}", %ref%, Stats.Count)
Stats.Count := 100
Print("module write, ref sees: {}", %ref%)
ref := ""                       ; releasing it is safe on the fixed engine
Print("after release: {}", Stats.Count)
```

Output:

```text
Stats.Count = 11
Stats.Last = today.txt
through the ref: 12  module sees: 12
module write, ref sees: 100
after release: 100
```

Source: [`02_module_ref.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha33/02_module_ref.ahk)

---

## 3. Two crashes become errors

`a.b[c]` when `a.b` returns unset used to take the process down and now throws `UnsetError`; `ObjSetCapacity`, `ObjGetCapacity` and their relatives used to corrupt a `Struct` and now throw `TypeError`. The script shows both as catchable, with the struct intact afterwards, and the `IsSet(reg.table?)` guard that turns the first into a clean fallback. The release also fixes four 32-bit regressions from alpha.24 (`EditGetLine` and two `Control` functions, `DllCall(..., Struct.Ptr, unset)`, `Struct.Array` marshaling, and typed callbacks with 64-bit parameters), none of which an x64 script can show.

```ahk2
#Requires AutoHotkey v2.1-alpha.33
; alpha.33: two crashes become errors
;   a.b[c] when a.b returns unset      -> UnsetError (was: process crash)
;   ObjSetCapacity(struct, n) and kin  -> TypeError  (was: corrupted the struct)

; --- 1. Indexing through an unset property is an ordinary error -----------
class Registry {
    table => unset      ; a lookup table that may not be configured yet
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

Output:

```text
Registry().table["key"]: No value was returned.
Lookup: (no table)
ObjGetCapacity: Expected an Object but got a Pixel.
ObjSetCapacity: Expected an Object but got a Pixel.
Pixel intact: r=255 Size=3
```

Source: [`03_struct_guards.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha33/03_struct_guards.ahk)

---

## Running them

`#Requires AutoHotkey v2.1-alpha.33` on every script. Fork: run as-is. Stock: add the `Print` line and pipe through `| more`.

```powershell
# +Console fork
.\bin\AutoHotkey64Console.exe 01_import_in_function.ahk

# stock AutoHotkey v2.1-alpha.33 or later (GUI exe), with the Print line added
AutoHotkey64.exe 01_import_in_function.ahk | more
```

*Scripts and text by Claude Fable 5.1, run on `2.1-alpha.37+Console` (`a911f73d`); "before" behaviour from the fork's release notes.*
