; Lib\TextTools.ahk -- found through A_ScriptDir\Lib\ (search rule 3).
global TextToolsFile := A_LineFile

Slug(text) {
    text := StrLower(RegExReplace(text, "[^A-Za-z0-9]+", "-"))
    return Trim(text, "-")
}
