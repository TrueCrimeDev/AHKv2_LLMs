; StrKit.ahk: a single-module file. Since alpha.31 every name here is
; exported without a keyword, so `#Import "StrKit.ahk" {*}` binds all three.
#Requires AutoHotkey v2.1-alpha.31

Repeat(s, n) {
    out := ""
    loop n
        out .= s
    return out
}

Reverse(s) {
    out := ""
    loop parse s
        out := A_LoopField out
    return out
}

Pad(s, width, ch := " ") => s Repeat(ch, Max(0, width - StrLen(s)))
