# Building OOP GUIs in AutoHotkey v2

Object-oriented programming transforms how you build GUI applications in AutoHotkey v2. Instead of scattered functions and global variables, OOP encapsulates your GUI's state and behavior into cohesive, reusable units.

## Why OOP for GUIs?

Benefits of OOP-based GUI development:

- **Encapsulation:** Control references, state, and handlers stay together
- **Reusability:** Create component libraries you can use across projects
- **Maintainability:** Changes are localized to specific classes
- **Testability:** Classes can be tested in isolation

## The Base GUI Class Pattern

Start with a base class that handles common GUI operations:

```cpp
class BaseGui {
    __New(title := "Application", options := "") {
        this.gui := Gui(options, title)
        this.gui.OnEvent("Close", this.OnClose.Bind(this))
        this.gui.OnEvent("Escape", this.OnClose.Bind(this))
        this.controls := Map()
    }

    AddControl(type, name, options := "", text := "") {
        ctrl := this.gui.Add(type, options, text)
        this.controls[name] := ctrl
        return ctrl
    }

    Show(options := "") {
        this.gui.Show(options)
        return this
    }

    OnClose(*) {
        this.gui.Hide()
    }

    __Delete() {
        if this.gui
            this.gui.Destroy()
    }
}
```

## Building a Settings Dialog

Here's a practical example using OOP principles:

```cpp
class SettingsDialog extends BaseGui {
    static DefaultSettings := Map(
        "theme", "dark",
        "fontSize", 12,
        "autoSave", true
    )

    __New(currentSettings := "") {
        super.__New("Settings", "+Resize")
        this.settings := currentSettings ? currentSettings : SettingsDialog.DefaultSettings.Clone()
        this.onSaveCallback := ""
        this._BuildUI()
    }

    _BuildUI() {
        this.gui.MarginX := 20
        this.gui.MarginY := 15

        ; Theme section
        this.gui.Add("Text", , "Theme:")
        this.AddControl("DropDownList", "theme", "w150", ["Dark", "Light", "System"])

        ; Font section
        this.gui.Add("Text", "y+15", "Font Size:")
        this.AddControl("Edit", "fontSize", "w60 Number")

        ; Buttons
        this.gui.Add("Button", "y+20 w100 Default", "Save").OnEvent("Click", this.OnSave.Bind(this))
        this.gui.Add("Button", "x+10 w100", "Cancel").OnEvent("Click", this.OnClose.Bind(this))
    }

    OnSave(*) {
        this.settings["theme"] := StrLower(this.controls["theme"].Text)
        this.settings["fontSize"] := Integer(this.controls["fontSize"].Value)

        if this.onSaveCallback
            this.onSaveCallback.Call(this.settings)

        this.gui.Hide()
    }
}
```

## Component-Based Architecture

For complex applications, break your GUI into reusable components:

```cpp
class SearchBar {
    __New(gui, options := "") {
        this.gui := gui
        this.onSearch := ""

        this.input := gui.Add("Edit", options " w300")
        this.button := gui.Add("Button", "x+5 w75", "Search")

        this.button.OnEvent("Click", this._OnSearchClick.Bind(this))
    }

    _OnSearchClick(*) {
        if this.onSearch
            this.onSearch.Call(this.input.Value)
    }

    Value {
        get => this.input.Value
        set => this.input.Value := value
    }
}
```

## State Management

Keep your GUI state organized with dedicated state classes:

```cpp
class FormState {
    __New() {
        this._data := Map()
        this._dirty := false
        this._validators := Map()
    }

    Set(field, value) {
        if this._data.Get(field, "") != value {
            this._data[field] := value
            this._dirty := true
        }
        return this
    }

    Get(field, default := "") {
        return this._data.Get(field, default)
    }

    IsDirty => this._dirty

    Reset() {
        this._data.Clear()
        this._dirty := false
        return this
    }
}
```

## Event Handling Patterns

Clean event handling with an EventEmitter pattern:

```cpp
class EventEmitter {
    __New() {
        this._handlers := Map()
    }

    On(event, handler) {
        if !this._handlers.Has(event)
            this._handlers[event] := []
        this._handlers[event].Push(handler)
        return this
    }

    Emit(event, args*) {
        if this._handlers.Has(event) {
            for handler in this._handlers[event]
                handler.Call(args*)
        }
    }
}
```

## Key Takeaway

OOP transforms GUI development from scattered scripts into maintainable applications. Start with base classes, build reusable components, and always properly bind event handlers with `.Bind(this)`.
