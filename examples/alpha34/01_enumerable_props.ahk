#Requires AutoHotkey v2.1-alpha.34
; alpha.34: Enumerable: false hides a property from Props() while it stays an
; own property. DefineProp also validates its descriptor now, and
; a.%name?% ?? default short-circuits when name is unset.

; A record carries a dirty flag and a version that anything walking Props()
; (a serializer, a diff, a debugger) never sees.
class Record {
    __New(fields) {
        for name, value in fields.OwnProps()
            this.%name% := value
        this.DefineProp("_dirty", {Value: false, Enumerable: false})
        this.DefineProp("_version", {Value: 1, Enumerable: false})
    }
    Touch() => (this._dirty := true, this._version += 1)
}
Serialize(obj) {
    out := ""
    for name in obj.Props()
        out .= name "=" obj.%name% " "
    return Trim(out)
}
rec := Record({id: 7, title: "alpha.34"})
rec.Touch()
Print("Props():    {}", Serialize(rec))
Print("HasOwnProp(_dirty) {}  ObjOwnPropCount {}  _version {}", rec.HasOwnProp("_dirty"), ObjOwnPropCount(rec), rec._version)

; The flag works on accessors too.
rec.DefineProp("summary", {Get: this => this.id ": " this.title, Enumerable: false})
Print("summary = {}  (Props() still: {})", rec.summary, Serialize(rec))

; A typo in the descriptor used to be ignored; now it throws.
try rec.DefineProp("oops", {Vlaue: 1})
catch ValueError as e
    Print("DefineProp with Vlaue: {}", e.Message)

; a.%name?% ?? default: with name unset the whole access is skipped.
Field(obj, name?) => obj.%name?% ?? "(no field)"
Print("Field(rec, `"title`") = {}   Field(rec) = {}", Field(rec, "title"), Field(rec))
