/*
Opus48_Example.ahk -- Idiomatic AHK v2 output from Claude Opus 4.8

A self-contained Clipboard History Manager, generated as an example of the
kind of AHK v2 code Opus 4.8 produces unprompted: correct v2 idioms, clean
OOP, proper event-callback binding, and resource cleanup.

Patterns demonstrated:
  1. Class encapsulation with static config + instance state
  2. Map() / Array usage (no v1 object-literal slips)
  3. OnClipboardChange + Hotkey registered to bound methods
  4. .Bind(this) so `this` survives inside event callbacks
  5. Property getter/setter with validation
  6. GUI built from a method, events wired correctly
  7. __Delete cleanup that unhooks the clipboard listener

Hotkeys:
  Win+Shift+V   Toggle the history window
  Double-click  Paste the selected entry into the previous window

Run: AutoHotkey64.exe Opus48_Example.ahk   (AutoHotkey v2.0+)
*/
#Requires AutoHotkey v2.0
#SingleInstance Force

history := ClipboardHistory()

class ClipboardHistory {
    ; Static configuration shared by every instance.
    static MaxEntries := 25
    static PreviewLen := 60

    __New() {
        this.entries := []            ; Array of strings, newest at the end
        this._visible := false
        this._BuildGui()

        ; Bound method references keep `this` alive inside the callbacks.
        this._clipHook := this._OnClipChange.Bind(this)
        OnClipboardChange(this._clipHook)
        Hotkey("#+v", this._Toggle.Bind(this))
    }

    ; --- GUI ----------------------------------------------------------------

    _BuildGui() {
        this.gui := Gui("+Resize -MinimizeBox", "Clipboard History")
        this.gui.SetFont("s10", "Segoe UI")
        this.gui.OnEvent("Close", (*) => this.Hide())
        this.gui.OnEvent("Escape", (*) => this.Hide())

        this.list := this.gui.Add("ListBox", "w420 r14")
        this.list.OnEvent("DoubleClick", this._PasteSelected.Bind(this))

        this.gui.Add("Button", "w130", "Paste")
            .OnEvent("Click", this._PasteSelected.Bind(this))
        this.gui.Add("Button", "x+10 w130", "Clear")
            .OnEvent("Click", this._Clear.Bind(this))
        this.status := this.gui.Add("Text", "x+10 yp+4 w130", "0 items")
    }

    ; --- Clipboard handling -------------------------------------------------

    _OnClipChange(dataType) {
        if (dataType != 1)            ; 1 = the clipboard now holds text
            return

        text := A_Clipboard
        if (text = "")
            return

        ; Skip exact duplicates of the most recent entry.
        if (this.entries.Length && this.entries[this.entries.Length] == text)
            return

        this.entries.Push(text)
        while (this.entries.Length > ClipboardHistory.MaxEntries)
            this.entries.RemoveAt(1)

        this._Refresh()
    }

    _Refresh() {
        items := []
        for entry in this.entries
            items.Push(this._Preview(entry))

        this.list.Delete()
        if (items.Length)
            this.list.Add(items)
        this.status.Text := this.entries.Length " item"
                          . (this.entries.Length = 1 ? "" : "s")
    }

    _Preview(text) {
        clean := RegExReplace(text, "\s+", " ")
        limit := ClipboardHistory.PreviewLen
        return StrLen(clean) > limit ? SubStr(clean, 1, limit - 3) "..." : clean
    }

    ; --- Actions ------------------------------------------------------------

    _PasteSelected(*) {
        index := this.list.Value         ; 1-based, 0 when nothing selected
        if (!index || index > this.entries.Length)
            return

        A_Clipboard := this.entries[index]
        this.Hide()
        if !ClipWait(1)                  ; let the OS settle the new clipboard
            return
        Send("^v")
    }

    _Clear(*) {
        this.entries := []
        this._Refresh()
    }

    ; --- Window visibility (property with validation) -----------------------

    Visible {
        get => this._visible
        set {
            this._visible := !!value     ; coerce to a clean boolean
            if (this._visible)
                this.gui.Show("AutoSize")
            else
                this.gui.Hide()
        }
    }

    Show()   => this.Visible := true
    Hide()   => this.Visible := false
    _Toggle(*) => this.Visible := !this.Visible

    ; --- Cleanup ------------------------------------------------------------

    __Delete() {
        OnClipboardChange(this._clipHook, 0)   ; remove the listener
    }
}
