#Requires AutoHotkey v2.1-alpha.36

; alpha.36 fixes two load-time behaviours, so this file writes small scripts
; to a temp folder and runs each in a child AutoHotkey through the shell.
;   1. AhkLibPath: a folder listed after one that does not exist is searched.
;      Before: everything after the missing folder was dropped.
;   2. #Import inside a function is a load error when a local or a parameter
;      of the same name exists. Before: the local silently shadowed the import.

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

; --- 1. A missing folder no longer swallows the rest of AhkLibPath ----------
EnvSet("AhkLibPath", root "\does-not-exist;" root "\lib")
Print("missing;lib -> {}", RunChild("libpath", "#Requires AutoHotkey v2.1-alpha.36`n#Include <Greet>`nFileAppend(Greet() `"``n`", `"*`")`n"))
EnvSet("AhkLibPath", "")

; --- 2. #Import inside a function that clashes with a local or a parameter --
; Without the clash F() returns 30. Inside a continuation section a backtick
; is processed by the parent, so ``n reaches the child as `n.
module := "`n#Module Settings`nTimeout := 30`n"
clash := "
(
F() {
    #Import Settings {Timeout}
    local Timeout := 5          ; before alpha.36 this quietly won: F() = 5
    return Timeout
}
FileAppend("F() = " F() "``n", "*")
)"
Print("local of same name -> {}", RunChild("import_local", clash module))

param := "
(
F(Timeout := 5) {
    #Import Settings {Timeout}
    return Timeout
}
FileAppend("F() = " F() "``n", "*")
)"
Print("parameter clash    -> {}", RunChild("import_param", param module))

DirDelete(root, true)
