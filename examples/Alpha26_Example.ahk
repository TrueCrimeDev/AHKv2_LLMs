/*
Alpha26_Example.ahk -- AutoHotkey v2.1-alpha.26 feature showcase

Features demonstrated:
  1. IsSet(var?) fix
  2. Struct array alignment fix
  3. StructClass.Ptr no longer seals the structure
  4. DllCall(F, StructType, unset) auto-creates default instance
  5. Object construction memory optimization (co-allocation)
  6. #SingleInstance / Reload uses WM_CLOSE
  7. Modal dialog keyboard shortcuts fixed
  8. CallbackCreate reference counting fix

Run: bin\AutoHotkey64.exe Alpha26_Example.ahk
*/
#Requires AutoHotkey v2.1-alpha.26

; ═══════════════════════════════════════════════════════
; ISSET(VAR?) FIX
; ═══════════════════════════════════════════════════════

; The '?' maybe-unset suffix now works inside IsSet().
myVar := "hello"
isMyVarSet := IsSet(myVar)
isNopeSet := IsSet(nope)

; ═══════════════════════════════════════════════════════
; STRUCT ARRAY ALIGNMENT
; ═══════════════════════════════════════════════════════

; Float64 arrays inside structs align to 8-byte boundaries
; even after smaller fields. Fixed padding.

Struct AlignedRecord {
    id: u8
    values: Float64[3]
    flags: u32
}

rec := AlignedRecord()
rec.id := 42
rec.values[1] := 1.111
rec.values[2] := 2.222
rec.values[3] := 3.333
rec.flags := 0xFF

; Standalone struct arrays align correctly too
Struct Vec2 {
    x: Float64
    y: Float64
}

points := Vec2[4]()
loop 4 {
    points[A_Index].x := A_Index * 10.5
    points[A_Index].y := A_Index * 20.5
}
expectedSize := 4 * 16

; ═══════════════════════════════════════════════════════
; STRUCTCLASS.PTR -- no longer seals the struct
; ═══════════════════════════════════════════════════════

Struct Header {
    magic: u32
    version: u16
}

ptrType := Header.Ptr  ; used to seal the struct -- now safe

h := Header()
h.magic := 0x46465542
h.version := 26

; ═══════════════════════════════════════════════════════
; DLLCALL + UNSET STRUCT PARAM
; ═══════════════════════════════════════════════════════

; Unset struct param auto-creates StructType() for output

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

st := SYSTEMTIME()
DllCall("GetLocalTime", SYSTEMTIME, st)

; ═══════════════════════════════════════════════════════
; MEMORY OPTIMIZATION -- co-allocated typed properties
; ═══════════════════════════════════════════════════════

; Single allocation for object header + field data.
; Fewer allocs, better cache locality.

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

count := 10000
particles := []
start := A_TickCount
loop count
    particles.Push(Particle())
elapsed := A_TickCount - start
particleSize := Particle().Size
particles := ""

; ═══════════════════════════════════════════════════════
; #SINGLEINSTANCE / RELOAD -- WM_CLOSE
; ═══════════════════════════════════════════════════════

; Old instance receives WM_CLOSE. OnExit and __Delete fire normally.
;
; #SingleInstance Force
; OnExit((*) => FileAppend(A_Now "`n", "exit_log.txt"))

; ═══════════════════════════════════════════════════════
; MODAL DIALOG KEYBOARD SHORTCUTS
; ═══════════════════════════════════════════════════════

; Ctrl+C, Tab, accelerators now work while MsgBox is displayed.
;
; Interactive test (uncomment):
; myGui := Gui()
; myGui.Add("Edit", "w300 vInput", "Try Ctrl+A, Ctrl+C here")
; myGui.Add("Button", "Default w300", "Show MsgBox").OnEvent("Click",
;     (*) => MsgBox("Keyboard shortcuts work in the background!"))
; myGui.Show()

; ═══════════════════════════════════════════════════════
; CALLBACK FIXES (PR #356)
; ═══════════════════════════════════════════════════════

AddNums(a, b) => a + b
cb := CallbackCreate(AddNums, , 2)
cbResult := DllCall(cb, "Int", 15, "Int", 27, "Int")
CallbackFree(cb)

; ═══════════════════════════════════════════════════════
; OUTPUT SUMMARY
; ═══════════════════════════════════════════════════════

stdout := FileOpen("*", "w", "UTF-8")
P(text := "") => stdout.Write(text "`n")

P "=== Alpha.26 Results ==="
P Format("Version: {}", A_AhkVersion)
P ""
P "── IsSet Fix ──"
P Format("  IsSet(myVar): {}  IsSet(nope): {}", isMyVarSet, isNopeSet)
P ""
P "── Struct Array Alignment ──"
P Format("  AlignedRecord: {} bytes  id={}, flags=0x{:02X}", rec.Size, rec.id, rec.flags)
P Format("  values: [{:.3f}, {:.3f}, {:.3f}]",
    rec.values[1], rec.values[2], rec.values[3])
P Format("  Vec2[4]: {} bytes (expect {})", points.Size, expectedSize)
loop 4
    P Format("    [{}] = ({:.1f}, {:.1f})", A_Index, points[A_Index].x, points[A_Index].y)
P ""
P "── StructClass.Ptr Fix ──"
P Format("  Header still works after .Ptr access: magic=0x{:08X}, version={}",
    h.magic, h.version)
P ""
P "── DllCall ──"
P Format("  System time: {}-{:02}-{:02} {:02}:{:02}:{:02}",
    st.wYear, st.wMonth, st.wDay, st.wHour, st.wMinute, st.wSecond)
P ""
P "── Memory Optimization ──"
P Format("  {} Particle structs ({} bytes each) in {} ms", count, particleSize, elapsed)
P ""
P "── Callback Fix ──"
P Format("  AddNums(15, 27) = {}", cbResult)
