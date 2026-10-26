#Requires AutoHotkey v2.1-alpha.28
Echo(fmt, args*) => FileAppend(Format(fmt, args*) "`n", "*")   ; native stdout

; alpha.28: the #Requires line above puts this file in v2.1 mode. In v2.1
; mode a bare `return`, falling off the end of a function, and every built-in
; that has nothing to say all produce *no value* (unset) instead of "".
; "No value" and "empty string" are different things now, and ?? tells them
; apart in one token.
; Before alpha.28 the same switch needed the separate #DefaultReturn unset
; directive, which is gone; a #Requires AutoHotkey v2.0 file keeps "" instead.

; --- 1. A finder that returns nothing, not a sentinel -------------------------------
FindFirst(items, pred) {
    for item in items
        if pred(item)
            return item
    ; falling off the end returns unset in v2.1 mode
}
nums := [4, 9, 16, 23]
Echo("first > 10: {}", FindFirst(nums, x => x > 10) ?? "none")
Echo("first > 50: {}", FindFirst(nums, x => x > 50) ?? "none")

; --- 2. The empty string is a real result now ------------------------------------------
; A lookup whose value is "" is distinguishable from a lookup that found nothing.
settings := Map("name", "", "retries", 3)
Lookup(key) {
    if settings.Has(key)
        return settings[key]
}
Echo("name: '{}'   missing: '{}'", Lookup("name") ?? "(unset)", Lookup("missing") ?? "(unset)")

; --- 3. Using nothing is an error, not a silent "" ------------------------------------
Bare() {
    return
}
try v := Bare()
catch UnsetError as e
    Echo("v := Bare() -> {}: {}", Type(e), e.Message)

; --- 4. Built-ins follow the same rule -------------------------------------------------
; FileAppend returns nothing. In v2.0 mode that was ""; here it is unset.
try r := FileAppend("", "*")
catch UnsetError as e
    Echo("r := FileAppend(...) -> {}", e.Message)
Echo("FileAppend(...) ?? 'ok' = {}", FileAppend("", "*") ?? "ok")
; Functions with a real "not found" value are unchanged: InStr still returns 0.
Echo("InStr('abc', 'z') = {}", InStr("abc", "z"))
