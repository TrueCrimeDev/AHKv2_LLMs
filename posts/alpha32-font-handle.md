# AutoHotkey v2.1-alpha.32: One Property, Three Fixes

Alpha.32 shipped on September 12, 2026 (upstream tag `v2.1-alpha.32`). It is the smallest release in the series: one new Gui property, three fixes, and the v2.0 merge that came with it. The fork skipped it on the day and picked it up together with alpha.33 in October.

The property is `Gui.FontHandle`, the `HFONT` a Gui currently applies to new controls. That sounds minor until you have written a custom-draw callback, or needed a control that the Gui object did not create to match the rest of the window. Both cases used to mean adding a throwaway control and asking it with `WM_GETFONT`. One script covers the whole release.

**About `Print`.** The scripts write their output with `Print`, which is not stock AutoHotkey: it is a built-in of the [+Console fork](https://github.com/TrueCrimeDev/AutoHotkey). `Print("x = {}, y = {}", x, y)` runs its arguments through `Format` and writes the result plus a newline to stdout; a single argument is written as-is, and `Print()` writes a blank line. To run the scripts on stock AutoHotkey, add this one line under `#Requires` (it reproduces those three shapes) and pipe the output through `| more`, because the GUI executable only shows stdout when it is redirected:

```ahk2
Print(fmt := "", args*) => FileAppend((args.Length ? Format(fmt, args*) : fmt) "`n", "*")
```

---

## 1. `Gui.FontHandle`: the font before any control exists

`g.SetFont("s11", "Segoe UI")` selects a font, and `g.FontHandle` is its handle. The script reads the `LOGFONTW` back through `GetObject` to prove it is the right one, adds an `Edit` and shows that the control carries the same handle, changes the Gui font and shows that the old control keeps the old handle, and then hands the Gui's font to a `Text` control owned by a second Gui with `WM_SETFONT`. Neither window is ever shown.

The last section is the feature-detection idiom from the release notes: `(g.FontHandle?) ?? FontOf(ctrl)`. On alpha.31 and earlier the property does not exist, the maybe operator yields unset, and the fallback asks a control instead.

Before alpha.32, `g.FontHandle` was a `PropertyError`; the only route to the handle was `SendMessage(0x31, 0, 0, someControl)`.

```ahk2
#Requires AutoHotkey v2.1-alpha.32
; alpha.32: Gui.FontHandle
;
; Gui.FontHandle is the HFONT the Gui currently applies to new controls, the
; one Gui.SetFont selected. Before alpha.32 the only way to get it was to add
; a control and ask it with WM_GETFONT. Nothing here shows a window.

; --- 1. Read the font the Gui will use, before any control exists ---------
g := Gui()
g.SetFont("s11", "Segoe UI")
hFont := g.FontHandle

; GetObject fills a LOGFONTW: lfHeight at 0, lfWeight at 16, lfFaceName at 28.
lf := Buffer(92, 0)
DllCall("GetObject", "Ptr", hFont, "Int", lf.Size, "Ptr", lf)
Print("FontHandle 0x{:X}: face {} height {} weight {}", hFont,
    StrGet(lf.Ptr + 28, 32), NumGet(lf, 0, "Int"), NumGet(lf, 16, "Int"))

; --- 2. Every new control gets that handle ---------------------------------
; FontHandle is a 32-bit value (GDI handles are), while WM_GETFONT returns
; the HFONT sign-extended to 64 bits, so compare the low 32 bits.
FontOf(ctrl) => SendMessage(0x31, 0, 0, ctrl) & 0xFFFFFFFF   ; WM_GETFONT
edit := g.AddEdit("w200", "sample")
Print("edit WM_GETFONT = FontHandle: {}", FontOf(edit) = hFont)

; --- 3. SetFont again: a new handle, old controls keep theirs ---------------
g.SetFont("s14 bold", "Consolas")
Print("after SetFont: changed {}, edit still on the old font {}",
    g.FontHandle != hFont, FontOf(edit) = hFont)

; --- 4. Give the Gui's font to something the Gui did not create -------------
; A control owned by another Gui (or any HWND) can be told to use it with
; WM_SETFONT. The second Gui is never shown either.
other := Gui()
label := other.AddText("w200", "borrowed font")
SendMessage(0x30, g.FontHandle, 1, label)   ; WM_SETFONT, redraw = 1
Print("other Gui's text now uses g's font: {}", FontOf(label) = g.FontHandle)

; --- 5. Feature detection for older engines --------------------------------
; (g.FontHandle?) is unset on alpha.31 and earlier, where the property does
; not exist, so the maybe operator falls back to asking a control.
Probe(gui, ctrl) => (gui.FontHandle?) ?? FontOf(ctrl)
Print("Probe matches FontHandle: {}", Probe(g, edit) = g.FontHandle)

other.Destroy()
g.Destroy()
```

Source: [`01_font_handle.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha32/01_font_handle.ahk)

---

## The fixes

Three fixes ride along. Assigning a variable that holds a reference (`t := r` where `r` came from `&x` or `&obj.prop`) no longer throws. `Until` as the last line of a `#Module` section no longer crashes the loader. `Gui.Move` stops DPI-scaling its X and Y arguments and scales only width and height, which is what `Gui.Show` already did. The v2.0 merge adds a `GuiType::Move` fix for owned windows and opens files with `FILE_WRITE_ATTRIBUTES` in `FileSetTime`.

---

## Things I tripped over writing these

- **`FontHandle` is 32 bits wide; `WM_GETFONT` is not.** The property is declared as a `UInt32` in the engine, so a handle such as `0xDE0A0D23` comes back as exactly that, while `SendMessage(0x31, ...)` returns the same `HFONT` sign-extended to 64 bits (`0xFFFFFFFFDE0A0D23`). About half of the handles have the top bit set, so a plain `=` comparison fails at random. GDI handles are 32-bit values, so compare `& 0xFFFFFFFF`; the script's `FontOf` does that. Passing the 32-bit value to `WM_SETFONT` works.

---

## Running them

Every script starts with `#Requires AutoHotkey v2.1-alpha.32`. On the +Console fork they run as they are; on stock AutoHotkey add the `Print` line from the top of this post and pipe through `| more`.

```powershell
# +Console fork
.\bin\AutoHotkey64Console.exe 01_font_handle.ahk

# stock AutoHotkey v2.1-alpha.32 or later (GUI exe), with the Print line added
AutoHotkey64.exe 01_font_handle.ahk | more
```

*Disclosure: Claude Fable 5.1 wrote the scripts, ran them, and drafted this post. Every behaviour claim was observed on `2.1-alpha.37+Console` (`a911f73d`), which carries this release, or comes from the fork's release notes for it; the "before" lines are from those notes.*
