# AutoHotkey v2.1 Alpha 20-30: Modules, Structs, and Missing Values

The alpha.20 to alpha.30 run looks less like a pile of unrelated preview features and more like the language settling its next set of rules. The big direction is clear: AutoHotkey v2.1 is becoming more explicit about modules, more type-aware around native interop, and much stricter about the difference between an empty string and no value at all.

This guide uses the local alpha notes from `v2.1-alpha.20.md` through `v2.1-alpha.30.md`. Alpha.30 is the latest release covered by those notes, dated 2026-05-22.

## The Short Version

If you are trying to understand the last few alpha releases as one arc:

- **alpha.20-alpha.21** made the module system feel real: `#Import`, file-local `#Module` scopes, `"file:module"` imports, first-reference initialization, and the final `!~=` spelling.
- **alpha.22-alpha.24** introduced the serious native interop story: `Struct`, numeric type classes, typed arrays, typed callbacks, and union-like overlays.
- **alpha.25-alpha.27** tightened practical behavior: per-call window matching with `ahk_opt`, modal-dialog and reload fixes, and a major internal cleanup of struct allocation and lifetime.
- **alpha.28-alpha.29** made `unset` the center of v2.1 semantics: `#Requires` controls compatibility mode, built-ins increasingly return `unset` when nothing meaningful exists, and the maybe operator propagates missing values more consistently.
- **alpha.30** removes old compatibility shortcuts: use `(a?)()` instead of `a?.()`, use `Int32` instead of `i32`, and give raw struct storage an explicit type.

## Guide 1: Treat Modules as File-Scoped Namespaces

The module work in alpha.20 and alpha.21 moves AHK toward a compile-time module graph. The important change is not just that `#Import` exists. It is that module names now have clearer scope, initialization is deferred until first reference, and a file can contain multiple targetable modules.

```ahk2
#Requires AutoHotkey v2.1-alpha.30

; Import a named module from inside a file.
#Import "shapes.ahk:Circle" as CircleMod
#Import "shapes.ahk:Rectangle" as RectMod

; Import specific public names from another module.
#Import {Clamp, Lerp} from Math

r := CircleMod.RadiusFromArea(100)
x := Clamp(12, 0, 10)
```

Inside a module file, prefer explicit exports:

```ahk2
; math.ahk
#Requires AutoHotkey v2.1-alpha.30
#Module Math

export Clamp(value, min, max) {
    if value < min
        return min
    if value > max
        return max
    return value
}

export Lerp(a, b, t) => a + (b - a) * t
export global Tau := 6.283185307179586
```

The practical rule: put `#Import` at the top level, use `#Module` as a namespace boundary, and do not depend on import order for initialization side effects. In v2.1 alpha, first use matters more than textual order.

### Migration Notes

```ahk2
; alpha.20 spelling, now removed:
; if haystack ~!= pattern

; alpha.21+ spelling:
if haystack !~= pattern
    MsgBox("No match")

; Removed:
; Import SomeModule

; Current form:
#Import SomeModule
```

## Guide 2: Write Structs With Real Type Classes

Alpha.22 introduced `Struct`, alpha.23 added numeric type classes and fixed-length struct arrays, and alpha.30 removes the older string shorthand forms. The current direction is that a struct field should name the real type class, not a compact type string.

```ahk2
#Requires AutoHotkey v2.1-alpha.30

Struct POINT {
    x: Int32
    y: Int32
}

Struct RECT {
    left:   Int32
    top:    Int32
    right:  Int32
    bottom: Int32
}

pt := POINT()
pt.x := 100
pt.y := 200

rc := RECT()
rc.left := 0
rc.top := 0
rc.right := 1920
rc.bottom := 1080

MsgBox(Format("POINT({}, {}), RECT size={} bytes", pt.x, pt.y, rc.Size))
```

Typed arrays are the other major addition. They replace a lot of hand-written `Buffer`, `NumPut`, and `NumGet` code when you need contiguous native memory.

```ahk2
#Requires AutoHotkey v2.1-alpha.30

Struct Vec2 {
    x: Float64
    y: Float64
}

points := Vec2[3]()
points[1].x := 10,  points[1].y := 20
points[2].x := 100, points[2].y := 200
points[3].x := 50,  points[3].y := 150

loop points.Length
    FileAppend(Format("{}: {}, {}`n", A_Index, points[A_Index].x, points[A_Index].y), "*")
```

For raw byte storage, prefer an explicit byte array rather than the old untyped size reservation.

```ahk2
; Removed in alpha.30:
; Struct Packet {
;     payload: 128
; }

; Explicit typed storage:
Struct Packet {
    opcode: UInt16
    payload: UInt8[128]
}

p := Packet()
p.opcode := 0x1001
p.payload[1] := 0x48
p.payload[2] := 0x49
```

## Guide 3: Use Structs Directly at Native Boundaries

The type system work is aimed squarely at Win32 and COM interop. You can define native layouts, pass struct types to `DllCall`, use `.At(ptr)` to view existing memory, and use typed callback signatures when a plain pointer-sized parameter count is not enough.

```ahk2
#Requires AutoHotkey v2.1-alpha.30

Struct SYSTEMTIME {
    wYear:         UInt16
    wMonth:        UInt16
    wDayOfWeek:    UInt16
    wDay:          UInt16
    wHour:         UInt16
    wMinute:       UInt16
    wSecond:       UInt16
    wMilliseconds: UInt16
}

st := SYSTEMTIME()
DllCall("GetLocalTime", SYSTEMTIME, st, "Void")

MsgBox(Format("{:04}-{:02}-{:02} {:02}:{:02}:{:02}",
    st.wYear, st.wMonth, st.wDay, st.wHour, st.wMinute, st.wSecond))
```

Alpha.30 adds `"Void"` as an explicit return type for `DllCall`, `ComCall`, and `CallbackCreate`. That matters because many native functions return no useful value. In v2.1 style, saying `"Void"` is better than pretending there was an integer result.

```ahk2
#Requires AutoHotkey v2.1-alpha.30

; The Win32 return value is intentionally ignored.
DllCall("MessageBeep", "UInt", 0, "Void")

AddFloats(a, b) => a + b

; Typed callback: [param1, param2, return]
cb := CallbackCreate(AddFloats, , [Float64, Float64, Float64])
try {
    result := DllCall(cb, "Double", 1.5, "Double", 2.25, "Double")
    MsgBox(result)
} finally {
    CallbackFree(cb)
}
```

Use `.At(ptr)` when a Windows callback gives you a pointer to a struct that already exists.

```ahk2
Struct NMHDR {
    hwndFrom: UIntPtr
    idFrom:   UIntPtr
    code:     Int32
}

OnMessage(0x4E, WM_NOTIFY)

WM_NOTIFY(wParam, lParam, msg, hwnd) {
    hdr := NMHDR.At(lParam)
    FileAppend("notify code: " hdr.code "`n", "*")
}
```

The direction here is important: native interop code is moving from "remember byte offsets manually" to "describe the layout once and let the runtime enforce it."

## Guide 4: Handle `unset` as a First-Class Result

The most obvious semantic change in alpha.28 and alpha.29 is that `unset` is no longer just an edge case for optional parameters. It is becoming the v2.1 answer to "there is no value here."

The compatibility switch is now tied to `#Requires`:

```ahk2
#Requires AutoHotkey v2.1-alpha.30

NoResult() {
    return
}

value := NoResult()
MsgBox(IsSet(value) ? "set" : "unset")
```

Many built-ins and object operations now return `unset` for missing or no-result cases in v2.1 mode. That means `??` and `IsSet()` should become normal boundary tools.

```ahk2
#Requires AutoHotkey v2.1-alpha.30

arr := [1, , 3]
removed := arr.RemoveAt(2) ?? "<missing>"
MsgBox(removed)

obj := {name: "demo"}
method := obj.GetMethod("missing") ?? unset

if IsSet(method)
    method.Call(obj)
else
    FileAppend("method not available`n", "*")
```

The maybe operator also becomes more useful because alpha.29 lets it short-circuit through most expression operators.

```ahk2
#Requires AutoHotkey v2.1-alpha.30

; maybeCount is intentionally unset in this example.
score := (maybeCount? * 10) ?? 0
MsgBox(score)  ; 0

GetHandler(name) {
    handlers := Map("save", () => "saved")
    return handlers.Has(name) ? handlers[name] : unset
}

result := (GetHandler("save")?)() ?? "no handler"
missing := (GetHandler("open")?)() ?? "no handler"

MsgBox(result "`n" missing)
```

Alpha.30 removed the special `a?.()` and `a?.[]` forms. Wrap the maybe expression, then call or index it:

```ahk2
; Removed:
; result := callback?.()
; item := items?.[2]

; Current:
result := (callback?)() ?? "no callback"
item := (items?)[2] ?? "no item"
```

## Guide 5: Expect Parser Cleanup and Fewer Aliases

The alpha line is not just adding features. It is also removing spellings that create ambiguity or duplicate the same concept.

The clearest examples:

- `~!=` was replaced by `!~=`.
- The `Import` statement was removed in favor of top-level `#Import`.
- `#DefaultReturn` was removed; use `#Requires AutoHotkey v2.1-alpha.X`.
- `a?.()` and `a?.[]` were removed; use `(a?)()` and `(a?)[]`.
- Struct field shorthands like `i32`, `u32`, and `f64` were removed; use `Int32`, `UInt32`, `Float64`, and the other type classes.
- Untyped struct storage like `payload: 128` was removed; use `UInt8[128]`, a nested struct, or an external `Buffer`.

That is a good signal about the design direction. v2.1 alpha is keeping the powerful pieces, but it is pruning the grammar around them before they harden.

## A Practical Migration Checklist

Use this when moving alpha.20-alpha.29 experiments toward alpha.30-style code:

1. Replace `~!=` with `!~=`.
2. Replace bare `Import X` with top-level `#Import X`.
3. Replace `#DefaultReturn` with an appropriate `#Requires AutoHotkey v2.1-alpha.X`.
4. Replace `a?.()` with `(a?)()` and `a?.[]` with `(a?)[]`.
5. Replace struct field type strings with type classes: `i32` -> `Int32`, `u8` -> `UInt8`, `f64` -> `Float64`.
6. Replace raw untyped struct slots with typed arrays, nested structs, or a separate `Buffer`.
7. Audit missing-value logic. Empty string is not the same as `unset`; use `??` and `IsSet()` intentionally.
8. Avoid changing `.Base` on objects/classes involved in typed properties after layout is established.
9. Prefer `"Void"` for native calls whose return value is documented as void.

## Where AHK v2.1 Alpha Seems To Be Going

The language seems to be moving in four coordinated directions.

First, modules are becoming boring in the best sense: top-level declarations, file-local scoping, explicit imports, and predictable initialization. That makes larger AHK projects easier for humans and LLMs to reason about because dependencies are visible before executable code starts running.

Second, native interop is becoming type-first. `Struct`, typed arrays, `.Ptr` classes, `.At(ptr)`, typed callbacks, and `"Void"` all point to the same goal: less manual pointer arithmetic and fewer fake return values at the boundary between AHK and Win32.

Third, v2.1 is drawing a hard semantic line between `""` and `unset`. That is probably the most important language-level direction. Empty string is data. `unset` means no value. The alpha releases are pushing built-ins, functions, maybe expressions, and error types toward that distinction.

Fourth, ambiguous convenience syntax is being removed while the series is still alpha. That can feel noisy during migration, but it is a healthy sign for the final shape of v2.1. The surface is getting smaller, stricter, and more explicit.

For script authors, the safest style is already visible: start files with `#Requires AutoHotkey v2.1-alpha.30`, use `#Import` and `#Module` deliberately, write struct fields with type classes, and make every no-value case explicit with `unset`, `??`, or `IsSet()`.

