; Template: Tooltip Notifier
interval := {{INTERVAL}}
message := "{{MESSAGE}}"
duration := {{DURATION}}

code := "#Requires AutoHotkey v2.0`n"
code .= "#SingleInstance Force`n"
code .= "`n"
code .= "SetTimer ShowNotification, " . interval . "`n"
code .= "`n"
code .= "ShowNotification() {`n"
code .= "    ToolTip `"" . message . "`"`n"
code .= "    SetTimer () => ToolTip(), -" . duration . "`n"
code .= "}`n"

FileAppend code, "*"
