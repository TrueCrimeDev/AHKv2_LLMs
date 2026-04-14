; Template: GUI Generator
title := "{{TITLE}}"
width := {{WIDTH}}
height := {{HEIGHT}}

code := "#Requires AutoHotkey v2.0`n"
code .= "#SingleInstance Force`n"
code .= "`n"
code .= "myGui := Gui(`"+Resize`", `"" . title . "`")`n"
code .= "myGui.SetFont(`"s10`")`n"
code .= "`n"
code .= "myGui.Add(`"Text`", `"x20 y20`", `"Enter your name:`")`n"
code .= "nameEdit := myGui.Add(`"Edit`", `"x20 y50 w" . (width - 40) . "`")`n"
code .= "`n"
code .= "btn := myGui.Add(`"Button`", `"x20 y90 w100`", `"Submit`")`n"
code .= "btn.OnEvent(`"Click`", (*) => MsgBox(`"Hello, `" . nameEdit.Value))`n"
code .= "`n"
code .= "myGui.Show(`"w" . width . " h" . height . "`")`n"

FileAppend code, "*"
