#Requires AutoHotkey v2.1-alpha.29
Echo(fmt, args*) => FileAppend(Format(fmt, args*) "`n", "*")   ; native stdout

; alpha.29: built-ins return unset for "nothing there" in v2.1 mode
;
; ObjGetBase / .Base at the top of a chain, RegExMatch's output variable on
; no match, Array.Pop / RemoveAt / Delete on a hole, Object.DeleteProp /
; GetMethod / GetOwnPropDesc on a missing member, and the Gui / Menu handle
; lookups all return unset instead of "" or 0. "Is there one?" becomes
; IsSet or ??, with no sentinel to compare against.
;
; Before alpha.29 each of these returned "" (ObjGetBase, RegExMatch's
; variable, the handle lookups) or an empty value, so a loop over a
; prototype chain needed a `= ""` test and a regex miss looked like an
; empty match.

; --- 1. Walk a prototype chain to the top -------------------------------------------
class Animal {
}
class Dog extends Animal {
}
Chain(obj) {
    names := ""
    p := obj
    loop {
        names .= p.__Class " > "
        p := ObjGetBase(p) ?? unset         ; unset past Any.Prototype
    } until !IsSet(p)
    return RTrim(names, " >")
}
Echo("chain: {}", Chain(Dog.Prototype))
Echo("Any.Prototype.Base ?? 'unset' = {}", Any.Prototype.Base ?? "unset")

; --- 2. A regex miss leaves the output variable unset ---------------------------------
; A tokenizer can test IsSet(m) instead of comparing m[0] against "".
NextNumber(text, &pos) {
    if RegExMatch(text, "\d+", &m, pos) {
        pos := m.Pos + m.Len
        return m[0]
    }
    Echo("  no match: IsSet(m) = {}", IsSet(m))
}
pos := 1
Echo("token: {}", NextNumber("a1b22c333", &pos) ?? "none")
Echo("token: {}", NextNumber("a1b22c333", &pos) ?? "none")
Echo("token: {}", NextNumber("a1b22c333", &pos) ?? "none")
Echo("token: {}", NextNumber("a1b22c333", &pos) ?? "none")

; --- 3. Removing a hole from an array -------------------------------------------------------
sparse := [1, , 3]                      ; element 2 is a hole
Echo("RemoveAt(2) on a hole = {}", sparse.RemoveAt(2) ?? "unset")
Echo("RemoveAt(1) on a value = {}", sparse.RemoveAt(1) ?? "unset")
holed := [1], holed.Length := 2         ; extend with a hole at the end
Echo("Pop() of a hole = {}   Pop() of a value = {}", holed.Pop() ?? "unset", holed.Pop() ?? "unset")

; --- 4. Object reflection without sentinels ------------------------------------------------
class Plain {
}
class Loud {
    Describe() => "I can describe myself"
}
; Call a method if the object has one. GetMethod returns unset otherwise, and
; ?? unset carries that into a local the next line can test.
CallIfPresent(obj, name) {
    m := obj.GetMethod(name) ?? unset
    return IsSet(m) ? m(obj) : "(no " name ")"
}
for obj in [Plain(), Loud()]
    Echo("{}: {}", Type(obj), CallIfPresent(obj, "Describe"))
o := {a: 1}
Echo("DeleteProp('a') = {}   DeleteProp('a') again = {}", o.DeleteProp("a") ?? "unset", o.DeleteProp("a") ?? "unset")
Echo("GetOwnPropDesc('b') = {}", o.GetOwnPropDesc("b") ?? "unset")

; --- 5. Handle lookups --------------------------------------------------------------------
; 0 is never a Gui, control or menu handle. Each lookup says so with unset.
Echo("GuiFromHwnd(0) = {}   GuiCtrlFromHwnd(0) = {}   MenuFromHandle(0) = {}", GuiFromHwnd(0) ?? "unset", GuiCtrlFromHwnd(0) ?? "unset", MenuFromHandle(0) ?? "unset")
g := Gui()                              ; created, never shown
Echo("g.MenuBar = {}   g.FocusedCtrl = {}   g['nope'] = {}", g.MenuBar ?? "unset", g.FocusedCtrl ?? "unset", g["nope"] ?? "unset")
ih := InputHook()
Echo("InputHook().OnEnd = {}", ih.OnEnd ?? "unset")
