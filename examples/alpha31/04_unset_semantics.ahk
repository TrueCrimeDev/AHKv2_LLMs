#Requires AutoHotkey v2.1-alpha.31
Echo(fmt, args*) => FileAppend(Format(fmt, args*) "`n", "*")   ; native stdout

; alpha.31: three fixes that make "no value" mean the same thing everywhere.
;
;   1. A global imported through two modules keeps its unset state
;      (alpha.30: `??` saw an empty string after the second hop).
;   2. RegExMatch leaves its output variable unset on no match in v2.1 mode,
;      so IsSet(m) is the "did it match?" test (alpha.31 restored this after
;      an intermediate commit blanked it; alpha.30 already behaved this way).
;   3. Props(v) enumerates a copy of v, not the variable
;      (alpha.30: a getter saw whatever v held by the time the loop ran).
;
; A fourth fix in the same release is not shown because it needs a real
; desktop: output parameters of PixelSearch, ImageSearch and MouseGetPos are
; now "made blank" when nothing is stored, as the docs say, instead of unset.

; --- 1. An optional setting threaded through two layers ----------------------
#Module Defaults
global Proxy                         ; declared on purpose, never assigned
global Theme := "dark"

#Module Settings
#Import Export Defaults {Proxy, Theme}   ; first hop
Summary() => "theme=" Theme ", proxy=" (Proxy ?? "none")

#Module __Main
#Import Settings {Summary, Proxy, Theme} ; second hop

Echo("IsSet(Proxy) = {}", IsSet(Proxy))
Echo("Proxy ?? `"<unset>`" = {}", Proxy ?? "<unset>")      ; alpha.30: "" (empty string)
Echo("Summary() = {}", Summary())

; --- 2. RegExMatch: unset on no match (v2.1 mode) -----------------------------
Extract(text, pattern) => RegExMatch(text, pattern, &m) ? m[0] : (IsSet(m) ? "blank" : "unset")
Echo("Extract(`"hello`", `"l+`") = {}", Extract("hello", "l+"))
Echo("Extract(`"hello`", `"x`") = {}", Extract("hello", "x"))

; --- 3. Props(v) keeps the value ----------------------------------------------
; Primitive prototypes do not inherit DefineProp; borrow Object's.
Object.Prototype.DefineProp.Call(String.Prototype, "Len", {get: (this) => StrLen(this)})
v := "hello"
e := Props(v)                        ; the enumerator now holds a copy of "hello"
v := "hi"
for name, val in e
    Echo("Props enumerated {}={}", name, val)   ; alpha.30: Len=2
