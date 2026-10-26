# AutoHotkey v2.1-alpha.32: One Property, Three Fixes

Alpha.32 (September 12, 2026) is the smallest release in the series: one Gui property, three fixes. One script covers it.

**`Print` is a fork built-in**, not stock AutoHotkey. `Print("x = {}", x)` formats through `Format` and writes one line to stdout; a single argument is written as-is. On stock AutoHotkey add this line under `#Requires` and pipe through `| more`:

```ahk2
Print(fmt := "", args*) => FileAppend((args.Length ? Format(fmt, args*) : fmt) "`n", "*")
```

---

## `Gui.FontHandle`: the font before any control exists

`g.FontHandle` is the `HFONT` that `SetFont` selected and every new control will get; before, you added a throwaway control and asked it with `WM_GETFONT`. The script reads the font back through `GetObject`, shows a new `Edit` carrying it, changes the font and shows the old control keeping the old handle, then lends the font to a second Gui's `Text` with `WM_SETFONT`. Pitfall: the property is 32-bit, `WM_GETFONT` returns it sign-extended, so `FontOf` masks with `& 0xFFFFFFFF`.

```ahk2
#Requires AutoHotkey v2.1-alpha.32
; alpha.32: Gui.FontHandle is the HFONT the Gui applies to new controls.
; Before alpha.32 the only way to get it was to add a control and ask it
; with WM_GETFONT. Nothing here shows a window.

; --- 1. Read the font before any control exists ----------------------------
g := Gui()
g.SetFont("s11", "Segoe UI")
hFont := g.FontHandle

; GetObject fills a LOGFONTW: lfHeight at 0, lfWeight at 16, lfFaceName at 28.
lf := Buffer(92, 0)
DllCall("GetObject", "Ptr", hFont, "Int", lf.Size, "Ptr", lf)
Print("FontHandle 0x{:X}: face {} height {} weight {}", hFont,
    StrGet(lf.Ptr + 28, 32), NumGet(lf, 0, "Int"), NumGet(lf, 16, "Int"))

; --- 2. Every new control gets that handle ---------------------------------
; FontHandle is a 32-bit value, while WM_GETFONT returns the HFONT
; sign-extended to 64 bits, so compare the low 32 bits.
FontOf(ctrl) => SendMessage(0x31, 0, 0, ctrl) & 0xFFFFFFFF   ; WM_GETFONT
edit := g.AddEdit("w200", "sample")
Print("edit WM_GETFONT = FontHandle: {}", FontOf(edit) = hFont)

; --- 3. SetFont again: a new handle, old controls keep theirs ---------------
g.SetFont("s14 bold", "Consolas")
Print("after SetFont: changed {}, edit still on the old font {}",
    g.FontHandle != hFont, FontOf(edit) = hFont)

; --- 4. Give the Gui's font to a control the Gui did not create ------------
other := Gui()
label := other.AddText("w200", "borrowed font")
SendMessage(0x30, g.FontHandle, 1, label)   ; WM_SETFONT, redraw = 1
Print("other Gui's text now uses g's font: {}", FontOf(label) = g.FontHandle)

other.Destroy()
g.Destroy()
```

Output (the handle will differ):

```text
FontHandle 0x80A0F42: face Segoe UI height -22 weight 400
edit WM_GETFONT = FontHandle: 1
after SetFont: changed 1, edit still on the old font 1
other Gui's text now uses g's font: 1
```

Source: [`01_font_handle.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha32/01_font_handle.ahk)

---

## The fixes

`t := r` where `r` is a `&x` reference no longer throws, `Until` as the last line of a `#Module` no longer crashes the loader, and `Gui.Move` DPI-scales only width and height, like `Gui.Show`.

---

## Running them

`#Requires AutoHotkey v2.1-alpha.32` on every script. Fork: run as-is. Stock: add the `Print` line and pipe through `| more`.

```powershell
# +Console fork
.\bin\AutoHotkey64Console.exe 01_font_handle.ahk

# stock AutoHotkey v2.1-alpha.32 or later (GUI exe), with the Print line added
AutoHotkey64.exe 01_font_handle.ahk | more
```

*Scripts and text by Claude Fable 5.1, run on `2.1-alpha.37+Console` (`a911f73d`); "before" behaviour from the fork's release notes.*
