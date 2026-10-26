#Requires AutoHotkey v2.1-alpha.37
Echo(fmt, args*) => FileAppend(Format(fmt, args*) "`n", "*")   ; native stdout

; --- 1. Optional settings on a plain object -----------------------------------
defaults := {retries: 3, timeout: 30}
user := {timeout: 5}

Setting(name) => IsSet(user.%name%) ? user.%name% : defaults.%name%
Echo("retries = {}  timeout = {}", Setting("retries"), Setting("timeout"))

; --- 2. A function that returns unset for "no result" ------------------------
; A finder can return nothing instead of a sentinel such as 0 or "", and the
; caller tests the call itself.
FindFirst(items, pred) {
    for item in items
        if pred(item)
            return item
    ; falls off the end: returns unset
}
nums := [4, 9, 16, 23]
Echo("first > 10: {}", IsSet(FindFirst(nums, x => x > 10)) ? FindFirst(nums, x => x > 10) : "none")
Echo("first > 50: {}", IsSet(FindFirst(nums, x => x > 50)) ? FindFirst(nums, x => x > 50) : "none")

; --- 3. Feature detection on objects you did not write -----------------------
class Plain {
}
class Loud {
    Describe() => "I can describe myself"
}
for obj in [Plain(), Loud()]
    Echo("{}: {}", Type(obj), IsSet(obj.Describe) ? obj.Describe() : "(no Describe)")

; --- 4. Optional handler slots (pairs with 05_safer_errors.ahk) --------------
; A getter that returns unset is an empty slot. IsSet(b.onClick) reads it as
; "not wired"; the wired instance supplies a value through DefineProp. Calling
; btn.onClick() invokes the getter's value as a method, so the handler receives
; the button as its first parameter.
class Button {
    onClick => unset
}
b := Button()
wired := Button()
wired.DefineProp("onClick", {Get: (*) => (self) => Type(self) " clicked"})
for name, btn in Map("b", b, "wired", wired)
    Echo("{}.onClick: {}", name, IsSet(btn.onClick) ? btn.onClick() : "not wired")

; --- 5. Only the last access is optional ----------------------------------------
cfg := {net: {proxy: "proxy.local"}}
Echo("cfg.net.proxy set: {}", IsSet(cfg.net.proxy))
Echo("cfg.net.port set:  {}", IsSet(cfg.net.port))
try IsSet(cfg.disk.path)                 ; cfg.disk does not exist
catch PropertyError as e
    Echo("IsSet(cfg.disk.path): {}", e.Message)
Echo("guarded: {}", IsSet(cfg.disk) && IsSet(cfg.disk.path) ? "set" : "not set")

; The explicit form still works and means the same thing.
Echo("IsSet(cfg.net.proxy?) = {}", IsSet(cfg.net.proxy?))
