#Requires AutoHotkey v2.1-alpha.35

; alpha.35: #Include <Name> looks in the directory of the *including* file
; first (v2.1 mode only), then the Lib\ folders as before.

#Include <TextTools>          ; Lib\TextTools.ahk beside this script

; tools\Report.ahk does its own #Include <Fmt>; Fmt.ahk sits in tools\, not in
; any Lib folder, so only the including-file rule can find it.
#Include tools\Report.ahk

Where(file) => SubStr(file, StrLen(A_ScriptDir) + 2)   ; path relative to this script

Print("TextTools came from {}", Where(TextToolsFile))
Print("Report came from    {}", Where(ReportFile))
Print("Fmt came from       {}", Where(FmtFile))
Print("{}", Report("alpha.35", ["search path follows the including file", "AhkLibPath overrides the list"]))
