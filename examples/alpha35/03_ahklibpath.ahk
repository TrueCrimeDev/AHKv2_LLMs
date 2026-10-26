#Requires AutoHotkey v2.1-alpha.35

; alpha.35: the AhkLibPath environment variable replaces the library search
; list. Lookup happens at load time, so a child script is run through the
; shell with its output and load errors captured (works for the GUI exe too).

root := A_Temp "\ahk35_libpath_" A_TickCount
DirCreate(root "\shared")
FileAppend('Greet(who) => "hello from " who " via the shared folder"`n', root "\shared\Greet.ahk", "UTF-8")
FileAppend("#Requires AutoHotkey v2.1-alpha.35`n#Include <Greet>`nFileAppend(Greet(`"AhkLibPath`") `"``n`", `"*`")`n", root "\child.ahk", "UTF-8")

RunChild(script) {
    log := script ".log"
    RunWait(A_ComSpec ' /c ""' A_AhkPath '" /ErrorStdOut "' script '" > "' log '" 2>&1"',, "Hide")
    out := Trim(FileRead(log), "`r`n")
    FileDelete(log)
    return StrReplace(out, root "\", "")       ; keep the temp path out of the output
}

; --- 1. AhkLibPath names the folder: the child finds Greet.ahk ---------------
EnvSet("AhkLibPath", root "\shared")
Print("with AhkLibPath:    {}", RunChild(root "\child.ahk"))

; --- 2. Without it, the default list applies and the library is not there ----
EnvSet("AhkLibPath", "")
Print("without AhkLibPath: {}", RunChild(root "\child.ahk"))

; --- 3. The variable is a list; the first folder that has the file wins -------
DirCreate(root "\override")
FileAppend('Greet(who) => "hello from the OVERRIDE folder"`n', root "\override\Greet.ahk", "UTF-8")
EnvSet("AhkLibPath", root "\override;" root "\shared")
Print("override first:     {}", RunChild(root "\child.ahk"))

EnvSet("AhkLibPath", "")
DirDelete(root, true)
