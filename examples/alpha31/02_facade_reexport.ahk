#Requires AutoHotkey v2.1-alpha.31
Echo(fmt, args*) => FileAppend(Format(fmt, args*) "`n", "*")   ; native stdout

; alpha.31: imported names stay private to the importer unless re-exported.
;
; "Everything is exported" has one exception: the names a module itself
; imported. That makes a facade module a real boundary. What it imports with
; a plain #Import is its own business; what it imports with #Import Export is
; forwarded to its callers. A facade can therefore wrap a core module and
; decide, per import, how much of the core leaks through.
;
; Before alpha.31 the same layering needed `export` on every forwarded name,
; and a plain import was private for the opposite reason: nothing was public.

; --- The core nobody is meant to call directly --------------------------------
#Module Core
Greet(name) => "hi " name
Version := "core 1.0"

; --- A closed facade: Core is an implementation detail ------------------------
#Module Facade
#Import Core {*}                           ; private to Facade
Shout(name) => StrUpper(Greet(name))
Describe() => "Facade over " Version       ; uses Core's Version internally

; --- An open facade: Core is part of the contract -----------------------------
#Module OpenFacade
#Import Export Core {*}                    ; re-exported to OpenFacade's importers
Whisper(name) => StrLower(Greet(name)) "..."

; --- The caller ---------------------------------------------------------------
#Module __Main
#Import Facade {*}
#Import OpenFacade {Whisper, Greet as CoreGreet, Version as CoreVersion}

Echo("Shout(`"bob`") = {}", Shout("bob"))
Echo("Describe() = {}", Describe())

; Facade used Greet and Version, but did not pass them on.
Echo("Greet via Facade {{}*{}}: {}", IsSet(Greet) ? "visible" : "not visible")
Echo("Version via Facade {{}*{}}: {}", IsSet(Version) ? "visible" : "not visible")

; OpenFacade re-exported them, so they can be imported from it, renamed here.
Echo("Whisper(`"BOB`") = {}", Whisper("BOB"))
Echo("CoreGreet(`"ann`") = {}", CoreGreet("ann"))
Echo("CoreVersion = {}", CoreVersion)
