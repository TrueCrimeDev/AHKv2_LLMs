#Requires AutoHotkey v2.1-alpha.28
Echo(fmt, args*) => FileAppend(Format(fmt, args*) "`n", "*")   ; native stdout

; alpha.28, two correctness fixes that matter in ordinary scripts:
;   A ByRef parameter aliasing a *global* stays aliased through recursion.
;   Before, a recursive call could back the alias up as if it were a local
;   and the global looked unset on return.
;   An OnMessage callback that returns unset (the v2.1 default for a bare
;   return) behaves as if it returned "": the message passes on to the next
;   callback and then to default handling, instead of raising an error.

; --- 1. A global counter threaded through recursion by reference -----------------------
global counter := 0
Increment(&val, limit) {
    val += 1
    if val < limit
        Increment(&val, limit)      ; same alias, same global
}
Increment(&counter, 3)
Echo("counter = {} after Increment(&counter, 3)", counter)

; A local works the same way, which is the point: one rule for both.
total := 0
Increment(&total, 5)
Echo("total = {} after Increment(&total, 5)", total)

; --- 2. OnMessage callbacks that decline a message ----------------------------------------
WM_APP_PING := 0x8001
Observer(wParam, lParam, msg, hwnd) {
    Echo("  observer saw ping {}", wParam)
    ; bare return: unset in v2.1 mode, treated as "" -> pass the message on
    return
}
Responder(wParam, lParam, msg, hwnd) {
    Echo("  responder answers ping {}", wParam)
    return wParam * 2                  ; a value stops the chain and is the result
}
OnMessage(WM_APP_PING, Observer)
OnMessage(WM_APP_PING, Responder)
reply := SendMessage(WM_APP_PING, 21, 0, , A_ScriptHwnd)
Echo("SendMessage returned {}", reply)

; Only the observer registered: the message falls through to default handling.
OnMessage(WM_APP_PING, Responder, 0)
reply := SendMessage(WM_APP_PING, 7, 0, , A_ScriptHwnd)
Echo("without a responder SendMessage returned {}", reply)
