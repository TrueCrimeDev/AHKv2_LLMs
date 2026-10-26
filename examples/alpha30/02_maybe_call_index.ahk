#Requires AutoHotkey v2.1-alpha.30
Echo(fmt, args*) => FileAppend(Format(fmt, args*) "`n", "*")   ; native stdout

; alpha.30: (a?)() and (a?)[] replace a?.() and a?.[]
;
; The maybe-call and maybe-index shorthands are gone: ?. already means
; "maybe-property", and stacking () or [] on it made the grammar ambiguous.
; The replacement parenthesises the maybe first. (a?) is unset when a is,
; and a call or index applied to unset short-circuits to unset, so the whole
; chain collapses to the ?? on the right.
;
; Two related parser fixes landed with it: x?.%y% (maybe-property with a
; dynamic name) now parses, and the ambiguous forms `!a ?? b` and
; `b + a ?? c` are rejected at load time until you add parentheses.

; --- 1. Optional callbacks ---------------------------------------------------------------
; An emitter with optional hooks calls each one only if it was supplied.
Run(items, onItem?, onDone?) {
    for item in items
        (onItem?)(item)
    return (onDone?)(items.Length) ?? "(no onDone)"
}
Echo("silent run: {}", Run([1, 2]))
Echo("logged run: {}", Run(["a", "b", "c"], x => Echo("  item {}", x), n => n " items"))

; --- 2. Optional collections -------------------------------------------------------------
First(list?) => (list?)[1] ?? "(empty)"
Echo("First() = {}   First([9, 8]) = {}", First(), First([9, 8]))

; --- 3. Dynamic property on a maybe receiver -------------------------------------------------
; cfg?.%key% was a syntax error before alpha.30. It reads like cfg.%key% and
; short-circuits when cfg is unset, so one helper serves "no config at all"
; and "config without that key" (the latter needs the property to exist, so
; it is guarded with HasOwnProp).
Setting(key, cfg?) => (cfg?.%key%) ?? "default"
theme := {theme: "dark"}
Echo("Setting('theme') = {}   Setting('theme', theme) = {}", Setting("theme"), Setting("theme", theme))
Echo("HasOwnProp guard: {}", theme.HasOwnProp("lang") ? theme.lang : "default")

; --- 4. Precedence is spelled out, not guessed --------------------------------------------------
; `!a ?? b` and `b + a ?? c` no longer load. Write the grouping you mean. The
; other reading, (!a) ?? b, is rejected for a different reason: the left side
; of ?? must be something that can be unset, and !a never is.
a := unset
b := 42
Echo("!(a ?? b) = {}   b + (a ?? 100) = {}", !(a ?? b), b + (a ?? 100))
