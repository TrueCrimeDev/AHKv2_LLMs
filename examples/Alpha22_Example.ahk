/*
Alpha22_Example.ahk -- AutoHotkey v2.1-alpha.22 feature showcase

Features demonstrated:
  1. Native Struct keyword with typed fields and memory layout
  2. Automatic Struct.Ptr subclasses (replaces StructFromPtr)
  3. DefineProp() as a top-level function
  4. Type() returns "unset" for omitted parameters
  5. IsSet() permits unset expressions
  6. Win32 API integration with structs

Run: bin\AutoHotkey64.exe Alpha22_Example.ahk
*/
#Requires AutoHotkey v2.1-alpha.22

; ═══════════════════════════════════════════════════════
; STRUCT DEFINITIONS -- typed memory layouts
; ═══════════════════════════════════════════════════════

Struct POINT {
    x: i32
    y: i32
}

Struct RECT {
    left: i32
    top: i32
    right: i32
    bottom: i32
}

Struct Color {
    r: u8
    g: u8
    b: u8
    a: u8
}

; Nested structs -- the compiler handles layout automatically
Struct NMHDR {
    hwndFrom: uptr
    idFrom: uptr
    code: i32
}

Struct NMCUSTOMDRAW {
    hdr: NMHDR
    dwDrawStage: u32
    hdc: uptr
    rc: RECT
    dwItemSpec: uptr
    uItemState: u32
    lItemlParam: iptr
}

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

Struct MEMORYSTATUSEX {
    dwLength: u32
    dwMemoryLoad: u32
    ullTotalPhys: u64
    ullAvailPhys: u64
    ullTotalPageFile: u64
    ullAvailPageFile: u64
    ullTotalVirtual: u64
    ullAvailVirtual: u64
    ullAvailExtendedVirtual: u64
}

; ═══════════════════════════════════════════════════════
; STRUCT USAGE -- create instances, set fields
; ═══════════════════════════════════════════════════════

pt := POINT()
pt.x := 100
pt.y := 200

rc := RECT()
rc.left := 0, rc.top := 0, rc.right := 1920, rc.bottom := 1080

c := Color()
c.r := 255, c.g := 128, c.b := 0, c.a := 255

; Nested struct access -- dot notation through the hierarchy
ncd := NMCUSTOMDRAW()
ncd.hdr.code := -12  ; NM_CUSTOMDRAW
ncd.dwDrawStage := 1
ncd.rc.left := 10
ncd.rc.top := 20

; ═══════════════════════════════════════════════════════
; WIN32 API CALLS with Struct types
; ═══════════════════════════════════════════════════════

; DllCall uses the Struct class directly as the type parameter
st := SYSTEMTIME()
DllCall("GetLocalTime", SYSTEMTIME, st)

ms := MEMORYSTATUSEX()
ms.dwLength := ms.Size
DllCall("GlobalMemoryStatusEx", MEMORYSTATUSEX, ms)

cursorPt := POINT()
DllCall("GetCursorPos", POINT, cursorPt)

; ═══════════════════════════════════════════════════════
; STRUCT.PTR -- zero-copy pointer views
; ═══════════════════════════════════════════════════════

; Every Struct auto-generates a .Ptr subclass.
; Use Struct.At(ptr) for zero-copy views into existing memory.
;
; Real-world pattern -- in a WM_NOTIFY handler:
;   WM_NOTIFY(wParam, lParam, msg, hwnd) {
;       hdr := NMHDR.At(lParam)
;       if hdr.code == -12
;           ncd := NMCUSTOMDRAW.At(lParam)
;   }

; ═══════════════════════════════════════════════════════
; DEFINEPROP() -- top-level function
; ═══════════════════════════════════════════════════════

; Getter/setter pair on a plain object
obj := {}
DefineProp(obj, "Name", {
    Get: (this) => this._name ?? "unnamed",
    Set: (this, value) => this._name := value
})
obj.Name := "alpha22"

; Computed read-only property
coords := { x: 3, y: 4 }
DefineProp(coords, "Magnitude", {
    Get: (this) => Sqrt(this.x ** 2 + this.y ** 2)
})

; Add properties to a class prototype dynamically
class Counter {
    __New() => this._count := 0
}

DefineProp(Counter.Prototype, "Count", {
    Get: (this) => this._count,
    Set: (this, value) => this._count := Max(0, value)
})

ctr := Counter()
ctr.Count := 42

; Factory: attach a live timestamp to any object
AddTimestamp(target, propName) {
    DefineProp(target, propName, {
        Get: (*) => FormatTime(, "yyyy-MM-dd HH:mm:ss")
    })
}

record := {}
AddTimestamp(record, "CreatedAt")

; ═══════════════════════════════════════════════════════
; TYPE() "unset" + ISSET() -- optional param handling
; ═══════════════════════════════════════════════════════

; Type-dispatch that handles missing arguments cleanly
FormatValue(val?) {
    if !IsSet(val)
        return "(unset)"
    switch Type(val) {
        case "Integer", "Float": return Format("Number: {}", val)
        case "String":           return Format('String: "{}"', val)
        case "Array":            return Format("Array[{}]", val.Length)
        default:                 return Format("Object: {}", Type(val))
    }
}

; IsSet() with optional params directly
SmartFunc(a, b?, c?) {
    parts := [Format("a={}", a)]
    parts.Push(IsSet(b) ? Format("b={}", b) : "b=unset")
    parts.Push(IsSet(c) ? Format("c={}", c) : "c=unset")
    return parts
}

; ═══════════════════════════════════════════════════════
; EXPORT SYNTAX CHANGE (module code)
; ═══════════════════════════════════════════════════════

; `export func() => expr` is now a function CALL, not a definition.
; Use block syntax for exported module functions:
;
;   export MyFunc(x) {
;       return x * 2
;   }

; ═══════════════════════════════════════════════════════
; OUTPUT SUMMARY
; ═══════════════════════════════════════════════════════

stdout := FileOpen("*", "w", "UTF-8")
P(text := "") => stdout.Write(text "`n")

P "=== Alpha.22 Results ==="
P ""
P Format("POINT({}, {})  Type={}  Size={} bytes", pt.x, pt.y, Type(pt), pt.Size)
P Format("RECT({},{} to {},{})  {} bytes", rc.left, rc.top, rc.right, rc.bottom, rc.Size)
P Format("Color RGBA({},{},{},{})  {} bytes", c.r, c.g, c.b, c.a, c.Size)
P Format("NMCUSTOMDRAW: hdr.code={}, rc.left={}  {} bytes", ncd.hdr.code, ncd.rc.left, ncd.Size)
P ""
P Format("System time: {}-{:02}-{:02} {:02}:{:02}:{:02}",
    st.wYear, st.wMonth, st.wDay, st.wHour, st.wMinute, st.wSecond)
P Format("Memory: {:.1f} GB / {:.1f} GB ({}% used)",
    ms.ullAvailPhys / (1024**3), ms.ullTotalPhys / (1024**3), ms.dwMemoryLoad)
P Format("Cursor: ({}, {})", cursorPt.x, cursorPt.y)
P ""
P Format("obj.Name = '{}'", obj.Name)
P Format("coords.Magnitude = {}", coords.Magnitude)
P Format("Counter.Count = {}", ctr.Count)
P Format("record.CreatedAt = '{}'", record.CreatedAt)
P ""
P Format("Type()='{}' | Type(42)='{}' | Type('hi')='{}' | Type([])='{}'",
    Type(), Type(42), Type("hi"), Type([]))
P Format("FormatValue(100) = {}", FormatValue(100))
P Format("FormatValue() = {}", FormatValue())
