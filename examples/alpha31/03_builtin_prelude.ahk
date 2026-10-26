#Requires AutoHotkey v2.1-alpha.31

; alpha.31: #Import inside #Module AHK is resolved.
;
; #Module AHK reopens the built-in module, the namespace every other module
; falls back to when a name is not found locally or through an import. A
; function defined there behaves like a built-in: visible from every module,
; no #Import needed. alpha.31 fixed the one thing that made this useless as a
; project prelude: an #Import written inside #Module AHK was silently never
; resolved, so the names it brought in stayed unset and the first call died
; at run time with "This local variable has not been assigned a value."
;
; Only file modules can be imported from #Module AHK (an in-file #Module
; section is "Module not found" there). StrKit.ahk sits beside this script.

; --- The prelude: a file module promoted to built-in status -------------------
#Module AHK
#Import "StrKit.ahk" {Repeat, Reverse, Pad}   ; alpha.30: loaded, but all three stayed unset

Banner(text) => Repeat("=", StrLen(text)) "`n" text "`n" Repeat("=", StrLen(text))
Row(label, value) => Pad(label, 12, ".") " " value

; --- Any module can use the prelude, and StrKit, without importing anything ---
#Module Report
Title(t) => Banner(StrUpper(t))
Lines(pairs*) {
    out := ""
    loop pairs.Length // 2
        out .= Row(pairs[A_Index * 2 - 1], pairs[A_Index * 2]) "`n"
    return RTrim(out, "`n")
}

#Module __Main
#Import Report {*}

Print(Title("alpha.31 prelude"))
Print(Lines("Reverse", Reverse("stressed"), "Banner", "defined in #Module AHK", "Row", "same"))
Print("Row is universal: {}", IsSet(Row) ? "yes" : "no")
Print("Pad is universal too: {}", IsSet(Pad) ? "yes" : "no")
