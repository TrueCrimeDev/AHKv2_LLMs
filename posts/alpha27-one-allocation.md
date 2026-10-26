# AutoHotkey v2.1-alpha.27: Structs Become One Block of Memory

Alpha.27 shipped on April 19, 2026 (upstream tag `v2.1-alpha.27`). Nothing in it changes the syntax of a script that does not use typed properties. Everything in it changes how a struct is laid out and torn down: a struct that contains other structs is now one allocation with the nested objects embedded in definition order, the typed properties of a prototype live in an ordered list instead of being rescanned on every construction, and the `Base` of anything with typed properties is frozen so a layout computed from one base can no longer be silently paired with another.

Three scripts below, each built around what that buys you in practice rather than the internals. The first passes a struct made of structs to Win32 as a single block and walks an array of them with stride arithmetic. The second leans on the destructor fixes to build a handle wrapper that releases itself, even when stored in a typed array. The third shows what the new `Base` guard rejects and how to get the same effect at definition time. All three run with exit 0 on the `2.1-alpha.37+Console` build; the comments say what alpha.26 did instead.

---

## 1. A struct of structs is one allocation

`RECT2` is two `POINT` fields. In alpha.27 those two `POINT` objects are embedded in the `RECT2` block, so `r.tl.Ptr` is `r.Ptr` and `r.br.Ptr` is `r.Ptr + 8`. The sixteen bytes are exactly a Win32 `RECT`, which means the outer `.Ptr` goes straight into `OffsetRect` and `SetRect`, and reading `br.x` back through `NumGet` at offset 8 agrees with the field.

A typed array of them, `RECT2[3]()`, is one block as well: 48 bytes with a stride of 16, so a batch of rectangles can be prepared by script and consumed by C without copying. The script fills each element through `SetRect` and reads the sizes back through the nested fields.

Before alpha.27 the layout was the same but each nested field was a separate heap object cross-linked through an index array, so every `RECT2()` cost three allocations and the objects could land in different cache lines.

```ahk2
#Requires AutoHotkey v2.1-alpha.27
Echo(fmt, args*) => FileAppend(Format(fmt, args*) "`n", "*")   ; native stdout

; alpha.27: a struct that contains other structs is one allocation.
; The nested objects are embedded in the outer block in definition order,
; so the bytes of RECT2 below are exactly the bytes of a Win32 RECT and the
; outer .Ptr can be handed to any API that expects one.
; Before alpha.27 each nested field was a separate heap object cross-linked
; through an index array; the layout was the same but every RECT2() cost
; three allocations instead of one.

struct POINT {
    x : Int32
    y : Int32
}

struct RECT2 {
    tl : POINT      ; top-left
    br : POINT      ; bottom-right
}

; --- 1. The nested fields sit inside the outer block ---------------------------
r := RECT2()
Echo("RECT2 size {}  tl at +{}  br at +{}", r.Size, r.tl.Ptr - r.Ptr, r.br.Ptr - r.Ptr)

; --- 2. Win32 sees a plain RECT ------------------------------------------------
r.tl.x := 1, r.tl.y := 2, r.br.x := 30, r.br.y := 40
DllCall("user32\OffsetRect", "Ptr", r.Ptr, "Int", 5, "Int", 7)
Echo("after OffsetRect(+5,+7): ({},{})-({},{})", r.tl.x, r.tl.y, r.br.x, r.br.y)
Echo("NumGet(r.Ptr, 8) = {}  (br.x through raw memory)", NumGet(r.Ptr, 8, "Int"))

; --- 3. An array of nested structs is one contiguous block too ----------------
rects := RECT2[3]()
rects[2].tl.x := 100, rects[2].br.x := 200
Echo("RECT2[3] size {}  stride {}  rects[2].tl.x = {}", rects.Size, rects[2].Ptr - rects[1].Ptr, NumGet(rects.Ptr, 16, "Int"))

; --- 4. Which means a whole batch can go to C at once ------------------------
; Pass the array's base pointer; the callee walks it with ordinary stride math.
loop 3
    DllCall("user32\SetRect", "Ptr", rects[A_Index].Ptr, "Int", 0, "Int", 0, "Int", A_Index * 10, "Int", A_Index * 10)
out := ""
loop 3
    out .= Format("[{}: {}x{}] ", A_Index, rects[A_Index].br.x, rects[A_Index].br.y)
Echo("SetRect on each element: {}", out)
```

Source: [`01_nested_struct_layout.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha27/01_nested_struct_layout.ahk)

---

## 2. Destructors you can rely on

Two of the alpha.27 bug fixes are about `__Delete`. Elements of a typed array with nested objects were not always destructed (`e6ed8924`), and a `Ptr` class whose target had no fields leaked its typed properties (`74db0a0b`). With both fixed, a struct whose `__Delete` releases a resource is safe to keep in an array.

The script wraps a GDI brush: `Brush.Create` calls `CreateSolidBrush`, and `__Delete` calls `DeleteObject`. Dropping the last reference releases the handle immediately. The `Toolkit`/`Pen` pair shows the order the engine uses: the outer `__Delete` runs first, then the embedded struct's, and for a `Toolkit[3]` every element gets both. The final section drops a `Brush[2]` and both handles are released.

Before alpha.27 the array cases could skip the element destructors, which for a handle wrapper means a leaked GDI object per element.

```ahk2
#Requires AutoHotkey v2.1-alpha.27
Echo(fmt, args*) => FileAppend(Format(fmt, args*) "`n", "*")   ; native stdout

; alpha.27: destructors of nested structs and of structs inside typed arrays
; now run reliably. __Delete runs on the outer object first, then on each
; embedded struct, and every element of a Struct[N] array is destructed when
; the array goes away.
; Before alpha.27 an array element with nested objects could skip its
; destructor and keep its Base reference alive (e6ed8924), so a wrapper that
; releases a handle in __Delete could leak when stored in an array.

; --- 1. A GDI handle that releases itself --------------------------------------
struct Brush {
    h : IntPtr
    Create(rgb) {
        this.h := DllCall("gdi32\CreateSolidBrush", "UInt", rgb, "Ptr")
        return this
    }
    __Delete() {
        if this.h {
            DllCall("gdi32\DeleteObject", "Ptr", this.h)
            Echo("  released brush 0x{:X}", this.h)
        }
    }
}
b := Brush().Create(0x0000FF)
Echo("brush 0x{:X} created", b.h)
b := ""                                 ; last reference gone: __Delete runs now

; --- 2. Outer first, then nested -----------------------------------------------
struct Pen {
    id : Int32
    __Delete() => Echo("  ~Pen {}", this.id)
}
struct Toolkit {
    pen : Pen
    __Delete() => Echo("  ~Toolkit (pen {})", this.pen.id)
}
t := Toolkit()
t.pen.id := 7
Echo("dropping a Toolkit:")
t := ""

; --- 3. Every element of an array is destructed ---------------------------------
Echo("dropping a Toolkit[3]:")
kits := Toolkit[3]()
loop 3
    kits[A_Index].pen.id := A_Index
kits := ""

; --- 4. Brushes in an array are all released ------------------------------------
Echo("dropping a Brush[2]:")
brushes := Brush[2]()
brushes[1].Create(0xFF0000), brushes[2].Create(0x00FF00)
brushes := ""
Echo("done")
```

Source: [`02_struct_lifecycle.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha27/02_struct_lifecycle.ahk)

---

## 3. `Base` is fixed once typed properties exist

`Object.SetBase` gained two guards in alpha.27. The object being re-based may not already be laid out from its current base, and the proposed new base may not define typed properties. Both throw `ValueError`. The script shows the three shapes that hit the guards: a plain object adopting `POINT.Prototype` ("Invalid base."), a `POINT` instance taking a plain base, and `POINT.Prototype` itself being re-based (both "Property is read-only.").

The replacement is to inherit at definition time. `struct Labeled extends POINT` appends its own field after the base fields, keeps `POINT`'s `Len` method, and satisfies `is POINT`; the size arithmetic in the output confirms where `tag` landed. Behaviour that varies per instance goes into a field and a property that reads it, as the `Shape` struct does, rather than into a base swap.

Before alpha.27 `a.Base := b` with typed properties on either side was accepted and left the object's layout and its data out of step, with no error to point at.

```ahk2
#Requires AutoHotkey v2.1-alpha.27
Echo(fmt, args*) => FileAppend(Format(fmt, args*) "`n", "*")   ; native stdout

; alpha.27: the Base of anything with typed properties is fixed. Assigning
; .Base to or from a struct instance or prototype throws instead of silently
; corrupting the memory layout that was computed from the old base.
; Before alpha.27 `a.Base := b` with typed properties on either side was
; accepted and left the object's layout and its data out of step.

struct POINT {
    x : Int32
    y : Int32
    Len => Sqrt(this.x ** 2 + this.y ** 2)
}

; --- 1. A plain object cannot adopt a struct prototype ---------------------------
o := {}
try o.Base := POINT.Prototype
catch ValueError as e
    Echo("{{}}.Base := POINT.Prototype -> {}", e.Message)

; --- 2. A struct instance cannot be re-based either ----------------------------
p := POINT()
try p.Base := {}
catch ValueError as e
    Echo("POINT().Base := {{}} -> {}", e.Message)
try POINT.Prototype.Base := Object.Prototype
catch ValueError as e
    Echo("POINT.Prototype.Base := ... -> {}", e.Message)

; --- 3. Inheritance happens at definition time instead ----------------------------
; A derived struct appends its fields after the base fields, keeps the base
; methods, and the layout is fixed once, when the class is created.
struct Labeled extends POINT {
    tag : Int32
}
q := Labeled()
q.x := 3, q.y := 4, q.tag := 9
Echo("Labeled size {} (POINT {} + tag {}), Len {} from the base method", q.Size, POINT().Size, q.Size - POINT().Size, q.Len)
Echo("q is POINT: {}   tag at +{}", q is POINT, q.Size - 4)

; --- 4. Behaviour that varies per instance goes in a property, not a Base swap ----
; Keep the struct as the data layout and attach the varying part as a value.
struct Shape {
    kind : Int32
    w    : Int32
    h    : Int32
    Area => this.kind = 1 ? this.w * this.h : 3.14159 * this.w * this.h / 4
}
box := Shape(), box.kind := 1, box.w := 10, box.h := 4
oval := Shape(), oval.kind := 2, oval.w := 10, oval.h := 4
Echo("box area {}  oval area {:.2f}", box.Area, oval.Area)
```

Source: [`03_base_is_fixed.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha27/03_base_is_fixed.ahk)

---

## Running them

Every script starts with `#Requires AutoHotkey v2.1-alpha.27`. Every script is plain AutoHotkey: `FileAppend` with `*` as the file name is the native stdout, and the one-line `Echo` helper at the top is the only output routine. The stock GUI executable only shows stdout when it is piped or redirected, so the `| more` is not optional there. The +Console fork prints directly.

```powershell
# stock AutoHotkey (GUI exe): pipe or redirect to see stdout
AutoHotkey64.exe 01_nested_struct_layout.ahk | more

# +Console fork: stdout is a real console stream
.\AutoHotkey64Console.exe examples\alpha27\01_nested_struct_layout.ahk
```

*Disclosure: Claude Fable 5.1 wrote the three scripts, ran them, and drafted this post. Every behaviour claim was observed on `2.1-alpha.37+Console` (`a911f73d`); the alpha.26 comparisons come from the alpha.27 commit history, not from running an alpha.26 engine.*
