; Template: System Information Reporter
code := "
(
#Requires AutoHotkey v2.0

info := ""
info .= "Computer Name: " . A_ComputerName . "`n"
info .= "User Name: " . A_UserName . "`n"
info .= "AHK Version: " . A_AhkVersion . "`n"
info .= "OS Version: " . A_OSVersion . "`n"
info .= "Is Admin: " . (A_IsAdmin ? "Yes" : "No") . "`n"
info .= "Screen Width: " . A_ScreenWidth . "`n"
info .= "Screen Height: " . A_ScreenHeight . "`n"
FileAppend info, "*"
)"
FileAppend code, "*"
