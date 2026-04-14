# AutoHotkey v2.1-alpha.26: Memory Optimization and Modal Dialog Fixes

Alpha.26 is a performance and stability release. The headline change is a memory allocation optimization for structs that improves construction speed and cache locality. It also fixes keyboard shortcuts in modal dialogs -- a long-standing annoyance.

## Object Construction: Memory Co-Allocation

The most impactful change in alpha.26 is internal: typed property memory is now allocated together with the main object in a single allocation.

### Before Alpha.26

Each struct instance required two allocations:
1. The AHK object header
2. A separate block for the typed field data

This meant every `Particle()` call hit the allocator twice, and the object header and field data could end up in different cache lines.

### After Alpha.26

One allocation holds both the object header and the field data contiguously. Benefits:

- **Fewer allocations**: 1 instead of 2 per struct
- **Better cache locality**: object metadata and field values are adjacent in memory
- **Lower GC pressure**: fewer objects for the garbage collector to track

```cpp
Struct Particle {
    x: Float32
    y: Float32
    z: Float32
    vx: Float32
    vy: Float32
    vz: Float32
    mass: Float32
    lifetime: Float32
}

; 10,000 particles -- measurably faster in alpha.26
particles := []
loop 10000
    particles.Push(Particle())
```

This matters most in hot loops: particle systems, physics simulations, batch Win32 API calls, or any code that creates many short-lived structs.

## Struct Array Alignment Fix

Alpha.25 had alignment bugs when arrays were embedded inside structs. Alpha.26 correctly aligns array elements to their natural boundary:

```cpp
Struct AlignedRecord {
    id: u8              ; 1 byte
    values: Float64[3]  ; 8-byte aligned, even after 1-byte id
    flags: u32
}
```

In alpha.25, the `Float64[3]` array might start at an unaligned offset (byte 1 instead of byte 8), causing incorrect reads on architectures that require natural alignment. Alpha.26 inserts the correct padding.

Standalone struct arrays also align correctly:

```cpp
Struct Vec2 {
    x: Float64
    y: Float64
}
points := Vec2[4]()
; Size = 64 bytes (4 * 16, no padding waste)
```

## StructClass.Ptr Seal Fix

Previously, accessing `StructClass.Ptr` on a struct class would "seal" the struct definition, preventing any further modifications via `DefineProp`. This was a subtle bug that caused confusing errors if you accessed `.Ptr` before adding union overlays:

```cpp
Struct Header {
    magic: u32
    version: u16
}

; This used to seal the struct:
ptrType := Header.Ptr

; Now this still works after accessing .Ptr:
h := Header()
h.magic := 0x46465542
h.version := 26
```

## DllCall with Unset Struct Parameters

When you pass `unset` for a struct parameter in `DllCall`, alpha.26 now creates a default instance automatically if the type has no `__value` setter. This simplifies output parameters:

```cpp
Struct SYSTEMTIME {
    wYear: u16
    wMonth: u16
    wDayOfWeek: u16
    wDay: u16
    wHour: u16
    wMinute: u16
    wSecond: u16
    wMilliseconds: u16
}

; DllCall creates a SYSTEMTIME() for output
DllCall("GetLocalTime", SYSTEMTIME, st := SYSTEMTIME())
```

This is a convenience -- it means you don't need to pre-allocate the struct when the API fills it in entirely.

## IsSet(var?) Fix

Alpha.25 incorrectly errored on `IsSet()` with expressions ending in `?` (the maybe-unset operator). Alpha.26 permits this:

```cpp
; Works in alpha.26, errored in alpha.25
IsSet(someVar?)
```

The `?` suffix makes an unset variable evaluate to `unset` instead of throwing. `IsSet()` now correctly handles this combined pattern.

## #SingleInstance / Reload Uses WM_CLOSE

The shutdown mechanism for `#SingleInstance` and `Reload` has been rewritten. Previously, these sent an undocumented internal message to close the old instance. Now they post `WM_CLOSE` -- the standard Windows close message.

```cpp
#SingleInstance Force
OnExit((*) => FileAppend(A_Now "`n", "exit_log.txt"))

; When a new instance starts:
; 1. Old instance receives WM_CLOSE
; 2. OnExit callback fires normally
; 3. Cleanup code runs as expected
```

This means `OnExit` callbacks, `__Delete` destructors, and any `WM_CLOSE` handlers work correctly during reload. No more silent shutdowns that skip cleanup.

## Modal Dialog Keyboard Shortcuts

Alpha.26 rewrites the internal message handling loop so that keyboard shortcuts work correctly while a modal dialog (MsgBox, InputBox) is displayed.

### The Problem

In previous versions, showing a MsgBox from a GUI script would break keyboard shortcuts:
- `Ctrl+C` in an Edit control behind the MsgBox would fail
- Tab navigation in multi-window GUIs would stop working
- Accelerator keys would be ignored

### The Fix

The message loop now correctly dispatches keyboard messages to all windows, not just the active modal dialog. This means:

- Edit shortcuts (`Ctrl+A`, `Ctrl+C`, `Ctrl+V`) work in background Gui windows
- Tab navigation works in Gui windows with nested `+Parent` relationships
- All keyboard accelerators function normally

## Callback Fixes

Fixed reference-counting errors in `CallbackCreate` (PR #356) that could cause crashes when:
- A callback was freed while still referenced internally
- A typed callback returned a struct value

Also fixed: the Start menu now opens correctly when admin/UIAccess scripts have active context menus. Previously, the script's menu would capture the foreground window activation, blocking the Start button.
