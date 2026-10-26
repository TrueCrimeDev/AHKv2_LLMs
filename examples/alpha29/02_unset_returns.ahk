#Requires AutoHotkey v2.1-alpha.29

; alpha.29: functions that return nothing now say so
;
; Two changes to return conventions in v2.1 mode:
;   1. A function with at least one `return expr` that falls off the end
;      returns unset, not "". Forgetting a branch becomes visible.
;   2. A fat-arrow tail call, f() => g(), passes g's blank-unset return
;      (a bare `return`, or no return at all) through instead of turning it
;      into "".
;
; Before alpha.29, FindIndex below returned "" on a miss and Forward()
; returned "" whatever Reset() did, so callers could not tell "no result"
; from "empty".

; --- 1. A finder with no sentinel value -------------------------------------------
; Returns the index, or nothing. The caller chooses the fallback with ??.
FindIndex(items, pred) {
    for i, item in items
        if pred(item)
            return i
    ; falls off the end: unset, because the function has a `return expr`
}
nums := [4, 9, 16, 23]
Print("first > 10 at index {}", FindIndex(nums, x => x > 10) ?? "none")
Print("first > 50 at index {}", FindIndex(nums, x => x > 50) ?? "none")

; --- 2. Consuming an unset result -------------------------------------------------
; A plain assignment of nothing is an error, which is the point: the mistake
; surfaces where it happens instead of as an empty string three calls later.
try {
    idx := FindIndex(nums, x => x > 50)
    Print("idx = {}", idx)
} catch UnsetError as e
    Print("idx := FindIndex(...): {}", e.Message)

; --- 3. Tail calls pass a blank return through -------------------------------------
class Counter {
    n := 0
    Reset() {
        this.n := 0
        return                      ; bare return: blank-unset
    }
    Bump() => ++this.n
}
Forward(c) => c.Reset()             ; alpha.29: also blank-unset, not ""
Chain(c) => Forward(c)              ; and so on through any depth
c := Counter()
c.Bump(), c.Bump()
Print("Forward(c) ?? 'nothing' = {}   n = {}", Forward(c) ?? "nothing", c.n)
c.Bump()
Print("Chain(c) ?? 'nothing' = {}   n = {}", Chain(c) ?? "nothing", c.n)

; --- 4. The limit: an explicit unset is not forwarded ----------------------------------
; Propagation covers blank-unset only. The unset that EvenOrUnset returns by
; falling through (section 1's rule) is an explicit "no value", so a fat-arrow
; wrapper around it throws at its own expression. Put the ?? inside the wrapper.
EvenOrUnset(n) {
    if Mod(n, 2) = 0
        return n
}
Wrap(n) => EvenOrUnset(n)
try
    Print("Wrap(5) = {}", Wrap(5) ?? "odd")
catch UnsetError as e
    Print("Wrap(5): {}", e.Message)
SafeWrap(n) => EvenOrUnset(n) ?? "odd"
Print("SafeWrap(4) = {}   SafeWrap(5) = {}", SafeWrap(4), SafeWrap(5))

; --- 5. Functions with no `return expr` are unchanged ---------------------------------------
; Only a bare return (or none): blank-unset as before. IsSet on a call is
; alpha.37 syntax, so test it the alpha.29 way, through ??.
Log(msg) {
    return
}
Print("Log('x') ?? 'blank' = {}", Log("x") ?? "blank")
