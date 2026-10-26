#Requires AutoHotkey v2.1-alpha.32
Echo(fmt, args*) => FileAppend(Format(fmt, args*) "`n", "*")   ; native stdout
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
Echo("FontHandle 0x{:X}: face {} height {} weight {}", hFont,
    StrGet(lf.Ptr + 28, 32), NumGet(lf, 0, "Int"), NumGet(lf, 16, "Int"))

; --- 2. Every new control gets that handle ---------------------------------
; FontHandle is a 32-bit value (GDI handles are), while WM_GETFONT returns
; the HFONT sign-extended to 64 bits, so compare the low 32 bits.
FontOf(ctrl) => SendMessage(0x31, 0, 0, ctrl) & 0xFFFFFFFF   ; WM_GETFONT
edit := g.AddEdit("w200", "sample")
Echo("edit WM_GETFONT = FontHandle: {}", FontOf(edit) = hFont)

; --- 3. SetFont again: a new handle, old controls keep theirs ---------------
g.SetFont("s14 bold", "Consolas")
Echo("after SetFont: changed {}, edit still on the old font {}",
    g.FontHandle != hFont, FontOf(edit) = hFont)

; --- 4. Give the Gui's font to something the Gui did not create -------------
; A control owned by another Gui (or any HWND) can be told to use it with
; WM_SETFONT. The second Gui is never shown either.
other := Gui()
label := other.AddText("w200", "borrowed font")
SendMessage(0x30, g.FontHandle, 1, label)   ; WM_SETFONT, redraw = 1
Echo("other Gui's text now uses g's font: {}", FontOf(label) = g.FontHandle)

; --- 5. Feature detection for older engines --------------------------------
; (g.FontHandle?) is unset on alpha.31 and earlier, where the property does
; not exist, so the maybe operator falls back to asking a control.
Probe(gui, ctrl) => (gui.FontHandle?) ?? FontOf(ctrl)
Echo("Probe matches FontHandle: {}", Probe(g, edit) = g.FontHandle)

other.Destroy()
g.Destroy()
