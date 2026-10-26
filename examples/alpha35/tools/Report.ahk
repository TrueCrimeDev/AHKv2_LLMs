; tools\Report.ahk -- included by a relative path from the main script.
; Its own #Include <Fmt> resolves against *this* file's directory (rule 1),
; so Fmt.ahk can live next to it instead of in a Lib folder.
#Include <Fmt>
global ReportFile := A_LineFile

Report(title, items) {
    out := Heading(title)
    for i, item in items
        out .= "`n" Bullet(i, item)
    return out
}
