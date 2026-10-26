#Requires AutoHotkey v2.1-alpha.35

; alpha.35: the AhkLibPath environment variable replaces the default library
; search list. Library lookup happens at load time, so this script builds a
; tiny library in a temp folder, writes a one-line child script that includes
; it, and runs the child twice: once with AhkLibPath pointing at the folder,
; once without. The child's output (and any load error) is captured through
; the shell, which works for the GUI AutoHotkey64.exe too.

root := A_Temp "\ahk35_libpath_" A_TickCount
DirCreate(root "\shared")
FileAppend('Greet(who) => "hello from " who " via " RegExReplace(A_LineFile, ".*\\([^\\]+\\[^\\]+)$", "$1")`n', root "\shared\Greet.ahk", "UTF-8")
FileAppend("#Requires AutoHotkey v2.1-alpha.35`n#Include <Greet>`nFileAppend(Greet(`"AhkLibPath`") `"``n`", `"*`")`n", root "\child.ahk", "UTF-8")

; Run the child and return everything it printed, errors included.
RunChild(script) {
    log := script ".log"
    RunWait(A_ComSpec ' /c ""' A_AhkPath '" /ErrorStdOut "' script '" > "' log '" 2>&1"',, "Hide")
    out := FileExist(log) ? Trim(FileRead(log), "`r`n") : "(no output)"
    try FileDelete(log)
    return StrReplace(out, root "\", "")       ; keep the temp path out of the output
}

; --- 1. AhkLibPath names the folder: the child finds Greet.ahk -------------------
; The child lives in a folder with no Lib\ and the library is nowhere near it.
EnvSet("AhkLibPath", root "\shared")
Print("with AhkLibPath:    {}", RunChild(root "\child.ahk"))

; --- 2. Without it, the default list applies and the library is not there --------
EnvSet("AhkLibPath", "")
Print("without AhkLibPath: {}", RunChild(root "\child.ahk"))

; --- 3. The variable is a list; order is search order ----------------------------
; A second copy of Greet.ahk in another folder wins when its folder is listed first.
DirCreate(root "\override")
FileAppend('Greet(who) => "hello from the OVERRIDE folder"`n', root "\override\Greet.ahk", "UTF-8")
EnvSet("AhkLibPath", root "\override;" root "\shared")
Print("override first:     {}", RunChild(root "\child.ahk"))
EnvSet("AhkLibPath", root "\shared;" root "\override")
Print("shared first:       {}", RunChild(root "\child.ahk"))
; Note: on the official alpha.35 build, a listed folder that does not exist
; made every later entry vanish, so "missing;shared" failed. The +Console fork
; fixed that on 2026-10-12 and upstream took the same fix in alpha.36.

EnvSet("AhkLibPath", "")
DirDelete(root, true)
