#Requires AutoHotkey v2.1-alpha.35
Echo(fmt, args*) => FileAppend(Format(fmt, args*) "`n", "*")   ; native stdout

; alpha.35: in v2.1 mode a Map rejects Float keys and an Array rejects Float
; and empty-string indexes. This file is in v2.1 mode because of its top-level
; #Requires; a script without one keeps the v2.0 behaviour described below.

; --- 1. A computed key that is secretly a Float -------------------------------
; Bucket values by tens. Integer division gives Integer keys; a stray "/" gives
; a Float, which used to be stored as a *second* key beside the integer one.
bucket := Map()
for n in [10, 20, 30, 45]
    bucket[n // 10] := n                 ; keys 1, 2, 3, 4
Echo("integer keys: {}", bucket.Count)

try bucket[45 / 10] := "oops"            ; 4.5 is a Float
catch TypeError as e
    Echo("bucket[4.5]: {}", e.Message)
; Before alpha.35 this was accepted: bucket had five entries, one under 4 and one under 4.5.

bucket["4.5"] := "a String key is still fine"
Echo("bucket.Count = {}: four Integer keys and one String key; the Float write stored nothing", bucket.Count)

; --- 2. Say what you mean ------------------------------------------------------
; The error points at the real bug: the key needs an explicit conversion.
key := Integer(45 / 10)
Echo("Integer(4.5) = {} -> bucket[{}] = {}", key, key, bucket[key])

; --- 3. Array indexes get the same treatment -------------------------------------
arr := ["ten", "twenty", "thirty"]
for idx in [1.0, ""] {
    try
        Echo("arr[{}] = {}", idx, arr[idx])
    catch TypeError as e
        Echo("arr[{}]: {}: {}", idx = "" ? '""' : idx, Type(e), e.Message)
}
; Before alpha.35, arr[1.0] returned arr[1] and arr[""] threw IndexError.

; Numeric strings still convert, so an index read from text keeps working.
Echo("arr[`"2`"] = {}   arr[`" 3`"] = {}", arr["2"], arr[" 3"])

; --- 4. A lookup that validates its input instead of guessing -------------------
; Map keys are never converted: 2 and "2" are different keys, and 2.0 is now an
; error rather than a third one. (Array indexes are converted; Map keys are not.)
Lookup(table, key) {
    try
        return table.Has(key) ? table[key] : "absent"
    catch TypeError as e
        return "rejected (" e.Message ")"
}
for k in [2, 2.0, "2", "2.0"]
    Echo("Lookup({}) -> {}", Type(k) = "String" ? '"' k '"' : k, Lookup(bucket, k))
