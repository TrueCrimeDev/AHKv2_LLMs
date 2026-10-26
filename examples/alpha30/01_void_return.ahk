#Requires AutoHotkey v2.1-alpha.30
Echo(fmt, args*) => FileAppend(Format(fmt, args*) "`n", "*")   ; native stdout

; alpha.30: "Void" as a return type for DllCall, ComCall and CallbackCreate
;
; Many Win32 functions return nothing. Before alpha.30 you still had to name
; a return type, so the expression produced a meaningless integer that could
; be assigned, compared or printed by mistake. "Void" discards the register
; entirely: the call expression has no value, and trying to keep one is an
; UnsetError at the call site.
;
; In a CallbackCreate type array, "Void" in the last slot says the AHK
; function returns nothing, so the thunk does not try to convert a missing
; return value into a number.

struct SYSTEMTIME {
    wYear: UInt16
    wMonth: UInt16
    wDayOfWeek: UInt16
    wDay: UInt16
    wHour: UInt16
    wMinute: UInt16
    wSecond: UInt16
    wMilliseconds: UInt16
}

; --- 1. A void API whose result is the struct it filled ------------------------------
now := SYSTEMTIME()
DllCall("kernel32\GetLocalTime", "Ptr", now, "Void")
Echo("GetLocalTime: {:04}-{:02}-{:02} {:02}:{:02}", now.wYear, now.wMonth, now.wDay, now.wHour, now.wMinute)

; --- 2. A Void call has no value ----------------------------------------------------------------
; ?? sees unset; a plain assignment is an UnsetError. Before alpha.30 this
; slot would have held whatever happened to be in the return register.
Echo("DllCall(..., 'Void') ?? 'no value' = {}", DllCall("kernel32\GetLocalTime", "Ptr", now, "Void") ?? "no value")
try
    stamp := DllCall("kernel32\GetLocalTime", "Ptr", now, "Void")
catch UnsetError as e
    Echo("stamp := DllCall(..., 'Void'): {}", e.Message)

; --- 3. Void is a return type only ------------------------------------------------------------
try
    DllCall("kernel32\GetLocalTime", "Void", 0)
catch ValueError as e
    Echo("DllCall(..., 'Void', 0): {}", e.Message)

; --- 4. A callback that returns nothing --------------------------------------------------------
; The type array is [param types..., return type]. With "Void" the handler
; may fall off the end; with Int32 in that slot the same handler would fail
; inside the callback with "Expected a Number but got an unset."
seen := []
OnValue(n) {
    seen.Push(n * 2)
}
cb := CallbackCreate(OnValue, , [Int32, "Void"])
loop 3
    DllCall(cb, "Int", A_Index * 7, "Void")
CallbackFree(cb)
Echo("callback saw: {}", seen[1] ", " seen[2] ", " seen[3])

; A Void parameter slot is rejected the same way as in DllCall.
try
    CallbackCreate(OnValue, , ["Void", Int32])
catch ValueError as e
    Echo("CallbackCreate(..., ['Void', Int32]): {}", e.Message)
