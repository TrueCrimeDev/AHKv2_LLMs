#Requires AutoHotkey v2.1-alpha.35

; alpha.35: in v2.1 mode a Map rejects Float keys and an Array rejects Float
; and empty-string indexes. The top-level #Requires is what selects v2.1 mode.

; --- 1. A computed key that is secretly a Float -----------------------------
; Integer division gives Integer keys; a stray "/" gives a Float.
bucket := Map()
for n in [10, 20, 30, 45]
    bucket[n // 10] := n                 ; keys 1, 2, 3, 4

try bucket[45 / 10] := "oops"            ; 4.5 is a Float
catch TypeError as e
    Print("bucket[4.5]: {}", e.Message)
Print("bucket.Count = {}: the Float write stored nothing", bucket.Count)
; Before alpha.35: five entries, one under 4 and one under 4.5, and no error.

; The error points at the real bug: the key needs an explicit conversion.
key := Integer(45 / 10)
Print("Integer(4.5) = {} -> bucket[{}] = {}", key, key, bucket[key])

; --- 2. Array indexes get the same treatment --------------------------------
arr := ["ten", "twenty", "thirty"]
for idx in [1.0, ""] {
    try
        Print("arr[{}] = {}", idx, arr[idx])
    catch TypeError as e
        Print("arr[{}]: {}", idx = "" ? '""' : idx, e.Message)
}
; Before alpha.35, arr[1.0] returned arr[1] and arr[""] threw IndexError.
