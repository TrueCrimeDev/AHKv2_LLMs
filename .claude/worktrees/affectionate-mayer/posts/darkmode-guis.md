# Creating Dark Mode GUIs in AHK v2

Windows 10 and 11 support dark mode at the system level, but enabling it for custom applications requires interacting with undocumented Windows APIs. This tutorial covers the techniques to make your AHK v2 GUIs respect system dark mode settings.

## Compatibility Note

These techniques work on Windows 10 1809+ and Windows 11. Some APIs are undocumented and may change in future Windows versions.

## The Core Dark Mode Functions

Create a utility class to handle dark mode operations:

```cpp
class DarkMode {
    static DWMWA_USE_IMMERSIVE_DARK_MODE := 20

    static IsEnabled {
        get {
            try {
                value := RegRead("HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize", "AppsUseLightTheme")
                return value = 0
            }
            return false
        }
    }

    static EnableForWindow(hwnd) {
        return DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", hwnd,
                       "UInt", this.DWMWA_USE_IMMERSIVE_DARK_MODE,
                       "UInt*", 1, "UInt", 4) = 0
    }

    static SetPreferredAppMode(mode := 1) {
        ; 0 = Default, 1 = AllowDark, 2 = ForceDark, 3 = ForceLight
        try {
            DllCall("uxtheme\SetPreferredAppMode", "Int", mode)
            return true
        }
        return false
    }

    static RefreshTitleBar(hwnd) {
        DllCall("SetWindowPos", "Ptr", hwnd, "Ptr", 0,
                "Int", 0, "Int", 0, "Int", 0, "Int", 0,
                "UInt", 0x27)
    }
}
```

## Creating a Dark-Themed GUI Class

Wrap the dark mode functionality into a reusable GUI base class:

```cpp
class DarkGui {
    static Colors := Map(
        "background", "0x1e1e1e",
        "backgroundAlt", "0x252526",
        "foreground", "0xd4d4d4",
        "accent", "0x0078d4",
        "border", "0x3c3c3c",
        "inputBg", "0x2d2d2d"
    )

    __New(title := "Dark Application", options := "") {
        DarkMode.SetPreferredAppMode(1)

        this.gui := Gui(options, title)
        this.gui.BackColor := DarkGui.Colors["background"]
        this.controls := Map()

        this.gui.OnEvent("Size", this._OnFirstShow.Bind(this), -1)
    }

    _OnFirstShow(*) {
        static applied := Map()
        hwnd := this.gui.Hwnd

        if !applied.Has(hwnd) {
            applied[hwnd] := true
            DarkMode.EnableForWindow(hwnd)
            DarkMode.RefreshTitleBar(hwnd)
        }
    }

    AddText(options := "", text := "") {
        return this.gui.Add("Text", options " c" DarkGui.Colors["foreground"], text)
    }

    AddEdit(name, options := "", text := "") {
        ctrl := this.gui.Add("Edit", options " Background" DarkGui.Colors["inputBg"]
                             " c" DarkGui.Colors["foreground"], text)
        this.controls[name] := ctrl
        return ctrl
    }

    AddButton(options := "", text := "") {
        return this.gui.Add("Button", options, text)
    }

    Show(options := "") {
        this.gui.Show(options)
        return this
    }
}
```

## Using the Dark GUI Class

```cpp
class FileSearchApp extends DarkGui {
    __New() {
        super.__New("Dark File Search", "+Resize")

        this.gui.MarginX := 15
        this.gui.MarginY := 10

        this.AddText("Section", "Search Pattern:")
        this.AddEdit("searchInput", "xs w300")
        searchBtn := this.AddButton("x+10 w80 Default", "Search")
        searchBtn.OnEvent("Click", this.OnSearch.Bind(this))

        this.AddText("xs y+15", "Results:")
        this.results := this.gui.Add("ListView", "xs w400 h300 Background"
            DarkGui.Colors["backgroundAlt"] " c" DarkGui.Colors["foreground"],
            ["Name", "Path", "Size"])

        this.status := this.AddText("xs y+10 w400", "Ready")
    }

    OnSearch(*) {
        pattern := this.controls["searchInput"].Value
        if pattern = "" {
            this.status.Text := "Please enter a search pattern"
            return
        }
        this.status.Text := "Searching..."
    }
}

app := FileSearchApp()
app.Show()
```

## Handling System Theme Changes

React to system theme changes in real-time:

```cpp
class ThemeAwareApp extends DarkGui {
    static WM_SETTINGCHANGE := 0x001A

    __New(title) {
        super.__New(title)
        OnMessage(ThemeAwareApp.WM_SETTINGCHANGE, this._OnSettingChange.Bind(this))
    }

    _OnSettingChange(wParam, lParam, msg, hwnd) {
        try {
            setting := StrGet(lParam)
            if setting = "ImmersiveColorSet"
                this._ApplyCurrentTheme()
        }
    }

    _ApplyCurrentTheme() {
        if DarkMode.IsEnabled {
            this.gui.BackColor := DarkGui.Colors["background"]
            DarkMode.EnableForWindow(this.gui.Hwnd)
        } else {
            this.gui.BackColor := "Default"
        }
        DarkMode.RefreshTitleBar(this.gui.Hwnd)
    }
}
```

## Dark Mode Checklist

- Call `SetPreferredAppMode(1)` before creating any windows
- Apply `DwmSetWindowAttribute` to enable dark title bars
- Set appropriate background colors on the GUI and controls
- Use light text colors (`c` option) for readability
- Style Edit controls with dark backgrounds
- Handle ListView/TreeView with custom colors
- Consider handling `WM_SETTINGCHANGE` for live theme switching

## Key Takeaway

Dark mode in AHK v2 requires both Windows API calls for the title bar and manual color management for control surfaces. Encapsulate this in a base class for reusability.
