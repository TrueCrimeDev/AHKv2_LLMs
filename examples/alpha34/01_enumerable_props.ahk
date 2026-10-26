#Requires AutoHotkey v2.1-alpha.34
Echo(fmt, args*) => FileAppend(Format(fmt, args*) "`n", "*")   ; native stdout
; alpha.34: Enumerable: false in a DefineProp descriptor
;
; A property defined with Enumerable: false is skipped by Props() and by the
; debugger's variable list, but it is still an own property: OwnProps(),
; HasOwnProp and ObjOwnPropCount see it and it reads and writes normally.
; Before alpha.34, Enumerable was an unknown descriptor key and DefineProp
; threw ValueError.

; --- 1. Bookkeeping that stays out of the data -----------------------------
; A record carries a dirty flag and a version. Anything that walks Props()
; (a serializer, a diff, a debugger) sees only the real fields.
class Record {
    __New(fields) {
        for name, value in fields.OwnProps()
            this.%name% := value
        this.DefineProp("_dirty", {Value: false, Enumerable: false})
        this.DefineProp("_version", {Value: 1, Enumerable: false})
    }
    Touch() {
        this._dirty := true
        this._version += 1
    }
}
Serialize(obj) {
    out := ""
    for name in obj.Props()
        out .= name "=" obj.%name% " "
    return Trim(out)
}
rec := Record({id: 7, title: "alpha.34"})
rec.Touch()
Echo("Props():    {}", Serialize(rec))
own := ""
for name in rec.OwnProps()
    own .= name " "
Echo("OwnProps(): {}", Trim(own))
Echo("HasOwnProp(_dirty) {}  ObjOwnPropCount {}  _version {}",
    rec.HasOwnProp("_dirty"), ObjOwnPropCount(rec), rec._version)

; --- 2. The flag works on accessors as well as values ------------------------
rec.DefineProp("summary", {Get: this => this.id ": " this.title, Enumerable: false})
Echo("summary = {}  (still not in Props: {})", rec.summary, Serialize(rec))

; --- 3. alpha.34 validates the descriptor -----------------------------------
; An unknown key, or Value mixed with Get/Set/Call, is a ValueError instead of
; being silently ignored.
for keys, bad in Map("Vlaue", {Vlaue: 1}, "Value+Get", {Value: 1, Get: (*) => 2}) {
    try rec.DefineProp("oops", bad)
    catch ValueError as e
        Echo("DefineProp with {}: {}", keys, e.Message)
}

; --- 4. Also new: a.%name?% ?? default short-circuits -----------------------
; With name unset the whole access is skipped and the default wins; before
; alpha.34 the engine tried the default property instead.
Field(obj, name?) => obj.%name?% ?? "(no field)"
Echo("Field(rec, `"title`") = {}   Field(rec) = {}", Field(rec, "title"), Field(rec))
