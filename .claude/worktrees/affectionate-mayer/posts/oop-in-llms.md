# Object-Oriented Programming in LLMs

Large Language Models have been trained on billions of lines of code, giving them a deep understanding of object-oriented patterns. When working with AHK v2, understanding how LLMs process OOP concepts can help you get better code generation results.

## How LLMs Understand OOP

LLMs excel at recognizing and reproducing common patterns. They understand that classes encapsulate state and behavior, that inheritance creates hierarchies, and that polymorphism enables flexible design. However, their understanding is statistical rather than semantic—they predict what code *should* look like based on patterns, not what it *means*.

## Patterns LLMs Excel At

### Class Structure and Organization

LLMs are remarkably good at generating well-structured class definitions:

```cpp
class ConfigManager {
    static Instance := ""

    __New() {
        this.settings := Map()
        this.configPath := A_ScriptDir "\config.ini"
        this._LoadSettings()
    }

    _LoadSettings() {
        if FileExist(this.configPath) {
            ; Load logic here
        }
    }

    Get(key, default := "") {
        return this.settings.Has(key) ? this.settings[key] : default
    }

    Set(key, value) {
        this.settings[key] := value
        return this  ; Method chaining
    }
}
```

### Common Design Patterns

LLMs have strong representations of classic patterns like Singleton, Factory, Observer, and Builder:

```cpp
class Logger {
    static _instance := ""

    static GetInstance() {
        if !this._instance
            this._instance := Logger()
        return this._instance
    }

    __New() {
        if Logger._instance
            throw Error("Use Logger.GetInstance() instead")
    }
}
```

### Property Descriptors

Modern LLMs understand AHK v2's getter/setter syntax well:

```cpp
class Rectangle {
    __New(width, height) {
        this._width := width
        this._height := height
    }

    Width {
        get => this._width
        set => this._width := Max(0, value)
    }

    Area => this._width * this._height
}
```

## Where LLMs Struggle

### AHK-Specific Quirks

LLMs trained primarily on JavaScript, Python, and C# may confuse patterns:

- **Map vs Object:** They sometimes use `{key: value}` instead of `Map("key", value)`
- **Array indexing:** They may generate 0-indexed code when AHK uses 1-indexing
- **Assignment operator:** Occasionally generate `=` instead of `:=`

### Event Binding Context

One area where LLMs frequently make mistakes is preserving `this` context in callbacks:

```cpp
; WRONG - LLM might generate this
class MyGui {
    __New() {
        this.gui := Gui()
        this.gui.Add("Button", , "Click").OnEvent("Click", this.OnClick)
    }
}

; CORRECT - Proper binding
class MyGui {
    __New() {
        this.gui := Gui()
        this.gui.Add("Button", , "Click").OnEvent("Click", this.OnClick.Bind(this))
    }
}
```

## Leveraging LLMs for Better OOP Design

### Provide Context About AHK v2

When prompting, explicitly state AHK v2 requirements. Include phrases like "Use Map() for key-value storage, not object literals" and "Remember AHK v2 uses 1-indexed arrays and := for assignment".

### Request Pattern-Based Structure

LLMs respond well to pattern names:

- "Create a Factory pattern for generating different control types"
- "Implement an Observer pattern for state change notifications"
- "Build a Builder pattern for constructing complex GUI layouts"

### Use Iterative Refinement

Start with a basic class structure, then ask for specific enhancements:

1. Generate the basic class structure
2. Add error handling
3. Implement validation in setters
4. Add method chaining support
5. Include resource cleanup in __Delete

## Key Takeaway

LLMs understand OOP deeply but need guidance on AHK v2 specifics. Provide context, name patterns, and always validate generated code against v2 requirements.
