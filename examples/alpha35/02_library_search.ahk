#Requires AutoHotkey v2.1-alpha.35
Echo(fmt, args*) => FileAppend(Format(fmt, args*) "`n", "*")   ; native stdout

; alpha.35: #Include <Name> searches, in order,
;   1. the directory of the *including* file   (new, v2.1 mode only)
;   2. the current module's directory \Lib\
;   3. A_ScriptDir\Lib\                       (local library)
;   4. A_MyDocuments\AutoHotkey\Lib\          (user library)
;   5. the AutoHotkey.exe directory \Lib\     (standard library)
; and the AhkLibPath environment variable replaces that list when set.
; In v2.1 mode <A_B> means A_B.ahk only; the v2.0 fallback to A.ahk is gone.

; Rule 3: TextTools.ahk lives in Lib\ beside this script.
#Include <TextTools>

; A plain relative include. tools\Report.ahk then does #Include <Fmt>, and
; Fmt.ahk sits in tools\ -- not in any Lib folder. Rule 1 finds it because the
; including file is tools\Report.ahk. In v2.0 mode that include would fail with
; "Script library not found."
#Include tools\Report.ahk

Where(file) => SubStr(file, StrLen(A_ScriptDir) + 2)   ; path relative to this script

Echo("TextTools came from {}", Where(TextToolsFile))
Echo("Report came from    {}", Where(ReportFile))
Echo("Fmt came from       {}", Where(FmtFile))
Echo("")
Echo("{}", Report("alpha.35", ["search path follows the including file", "AhkLibPath overrides the list", "no A_B -> A fallback"]))
Echo("")
Echo("Slug(`"Hello, Library World`") = {}", Slug("Hello, Library World"))
