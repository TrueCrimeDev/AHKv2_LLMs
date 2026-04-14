; Template: Hotkey Generator
hotkeyCombo := "{{HOTKEY}}"
message := "{{MESSAGE}}"

code := "#Requires AutoHotkey v2.0`n"
code .= "#SingleInstance Force`n"
code .= "`n"
code .= "Hotkey(`"" . hotkeyCombo . "`", ShowMessage)`n"
code .= "`n"
code .= "ShowMessage(*) {`n"
code .= "    MsgBox `"" . message . "`"`n"
code .= "}`n"

FileAppend code, "*"
