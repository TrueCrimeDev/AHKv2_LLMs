#Requires AutoHotkey v2.1-alpha.30
Echo(fmt, args*) => FileAppend(Format(fmt, args*) "`n", "*")   ; native stdout

; alpha.30: four small fixes that each remove a special case
;
;   String(obj) when ToString() returns nothing   -> unset (was a crash)
;   StrGet(buf, 0)                                 -> "" of type String (was an Integer; broken by alpha.28)
;   out := unset through a &ref parameter          -> caller's variable becomes unset (was rejected)
;   ClassObj.Base := Other                         -> works again (broken by alpha.28)

; --- 1. String() on an object that declines to describe itself ---------------------------------
class Silent {
    ToString() {
    }
}
class Named {
    ToString() => "Named#1"
}
Describe(v) => String(v) ?? "(no text)"
Echo("Describe(Named()) = {}   Describe(Silent()) = {}", Describe(Named()), Describe(Silent()))
try
    s := String(Silent())
catch UnsetError as e
    Echo("s := String(Silent()): {}", e.Message)

; --- 2. StrGet with a zero length ------------------------------------------------------------------
; A length-prefixed reader can pass 0 straight through and still get a String.
buf := Buffer(64, 0)
StrPut("hello", buf, "UTF-16")
ReadPrefixed(ptr, n) => StrGet(ptr, n, "UTF-16")
for n in [0, 2, 5] {
    v := ReadPrefixed(buf, n)
    Echo("StrGet(buf, {}) = '{}' ({})", n, v, Type(v))
}

; --- 3. Clearing a caller's variable through a reference -----------------------------------------
; A TryParse that leaves the output unset on failure, instead of storing "".
TryParseInt(text, &out) {
    if text ~= "^-?\d+$" {
        out := Integer(text)
        return true
    }
    out := unset
    return false
}
for text in ["42", "4x2"] {
    ok := TryParseInt(text, &value)
    Echo("TryParseInt('{}') = {}   IsSet(value) = {}   value = {}", text, ok, IsSet(value), value ?? "unset")
}

; --- 4. Re-basing a class object -----------------------------------------------------------------------
class Plugin {
    static Kind => "plugin"
}
class Widget {
}
Widget.Base := Plugin                          ; static inheritance after the fact
Echo("Widget.Kind = {}   Widget.Base is Plugin: {}", Widget.Kind, Widget.Base == Plugin)
