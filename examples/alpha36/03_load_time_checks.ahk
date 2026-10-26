#Requires AutoHotkey v2.1-alpha.36
Echo(fmt, args*) => FileAppend(Format(fmt, args*) "`n", "*")   ; native stdout

; alpha.36 fixes two load-time behaviours. Both can only be seen by loading a
; script, so this file writes small scripts to a temp folder and runs each in
; a child AutoHotkey, capturing its output and load errors through the shell.
;
;   1. AhkLibPath: a folder listed after one that does not exist is searched.
;      Before: everything after the missing folder was dropped (fixed in the
;      +Console fork on 2026-10-12, then upstream in abe3ff20).
;   2. #Import inside a function is a load error when a local, a parameter or
;      an "as" alias of the same name exists. Before: the local silently
;      shadowed the import.

root := A_Temp "\ahk36_load_" A_TickCount
DirCreate(root "\lib")
FileAppend('Greet() => "found Greet.ahk"`n', root "\lib\Greet.ahk", "UTF-8")

RunChild(name, source) {
    global root
    script := root "\" name ".ahk", log := script ".log"
    FileAppend(source, script, "UTF-8")
    RunWait(A_ComSpec ' /c ""' A_AhkPath '" /ErrorStdOut "' script '" > "' log '" 2>&1"',, "Hide")
    out := FileExist(log) ? Trim(FileRead(log), "`r`n") : "(no output)"
    return StrReplace(out, root "\", "")       ; keep the temp path out of the output
}

; --- 1. A missing folder no longer swallows the rest of AhkLibPath -----------------
EnvSet("AhkLibPath", root "\does-not-exist;" root "\lib")
Echo("missing;lib -> {}", RunChild("libpath", "#Requires AutoHotkey v2.1-alpha.36`n#Include <Greet>`nFileAppend(Greet() `"``n`", `"*`")`n"))
EnvSet("AhkLibPath", "")

; --- 2. #Import inside a function, with and without a clash -------------------------
module := "`n#Module Settings`nTimeout := 30`n"
ok := "
(
F() {
    #Import Settings {Timeout}
    return Timeout
}
FileAppend("F() = " F() "``n", "*")
)"
Echo("no conflict        -> {}", RunChild("import_ok", ok module))

clash := "
(
F() {
    #Import Settings {Timeout}
    local Timeout := 5          ; before alpha.36 this quietly won: F() = 5
    return Timeout
}
FileAppend("F() = " F() "``n", "*")
)"
Echo("local of same name -> {}", RunChild("import_local", clash module))

param := "
(
F(Timeout := 5) {
    #Import Settings {Timeout}
    return Timeout
}
FileAppend("F() = " F() "``n", "*")
)"
Echo("parameter clash    -> {}", RunChild("import_param", param module))

alias := "
(
F() {
    local Limit := 5
    #Import Settings {Timeout as Limit}
    return Limit
}
FileAppend("F() = " F() "``n", "*")
)"
Echo("alias clash        -> {}", RunChild("import_alias", alias module))

DirDelete(root, true)
