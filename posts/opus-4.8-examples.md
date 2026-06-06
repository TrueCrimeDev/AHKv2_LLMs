# Claude Opus 4.8: AHK v2 Output Examples

Each new Claude model shifts the baseline for AutoHotkey v2 code generation. This post collects real, unedited outputs from **Claude Opus 4.8** for AHK v2 tasks, with notes on what changed compared to earlier models. The short version: the v1-to-v2 slips that used to need a correction pass — object literals where a `Map()` belongs, `0`-indexed loops, lost `this` context in callbacks — now show up far less often, and the model reaches for v2.1 alpha features when they fit.

A complete, runnable script combining several of these patterns lives in [`examples/Opus48_Example.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/Opus48_Example.ahk).

---

## 1. It defaults to `Map()`, not object literals

The single most common v2 mistake from older models was using `{key: value}` for string-keyed data. Object literals in AHK v2 are for *properties*, not lookups — `obj.key` works but `obj[variable]` does not behave like a dictionary. Opus 4.8 reaches for `Map()` without being told.

Prompt: *"Count word frequencies in a string."*

```cpp
WordFrequencies(text) {
    counts := Map()
    counts.CaseSense := false           ; "The" and "the" collapse together
    for word in StrSplit(Trim(text), [" ", "`t", "`n"], " `t`r`n") {
        if (word = "")
            continue
        counts[word] := counts.Has(word) ? counts[word] + 1 : 1
    }
    return counts
}
```

The unprompted `counts.CaseSense := false` is the kind of detail that used to require a follow-up. It also correctly passes the omit-characters argument to `StrSplit` to drop stray whitespace.

---

## 2. Event callbacks keep `this`

Binding `this` into GUI and hotkey callbacks is the v2 footgun that trips up almost every model. When you write `OnEvent("Click", this.OnClick)`, the method loses its instance context. The fix is `.Bind(this)`, and Opus 4.8 applies it consistently.

Prompt: *"A small counter GUI as a class."*

```cpp
class Counter {
    __New() {
        this.value := 0
        this.gui := Gui("+AlwaysOnTop", "Counter")
        this.gui.SetFont("s14")
        this.display := this.gui.Add("Text", "w120 Center", "0")
        this.gui.Add("Button", "w58", "-").OnEvent("Click", this.Step.Bind(this, -1))
        this.gui.Add("Button", "x+4 w58", "+").OnEvent("Click", this.Step.Bind(this, 1))
        this.gui.Show()
    }

    Step(delta, *) {                 ; bound args come first, event args after
        this.value += delta
        this.display.Text := this.value
    }
}
```

Two things worth highlighting: `this.Step.Bind(this, -1)` curries the `delta` argument, and the handler signature `Step(delta, *)` correctly puts the bound parameter *before* the variadic `*` that swallows the GUI control and info arguments. Older models frequently flipped that order.

---

## 3. Properties with real getters and setters

Opus 4.8 uses computed and validated properties instead of leaving raw fields exposed, and it gets the v2 `get`/`set` syntax right.

Prompt: *"A temperature class that stores Celsius but exposes Fahrenheit."*

```cpp
class Temperature {
    __New(celsius := 0) => this._c := celsius

    Celsius {
        get => this._c
        set => this._c := value < -273.15 ? -273.15 : value   ; clamp to absolute zero
    }

    Fahrenheit {
        get => this._c * 9 / 5 + 32
        set => this.Celsius := (value - 32) * 5 / 9            ; route through the clamp
    }
}

t := Temperature()
t.Fahrenheit := 98.6
MsgBox(Round(t.Celsius, 1) " C")     ; => 37.0 C
```

Setting `Fahrenheit` routes back through the `Celsius` setter so the validation only lives in one place — a small design choice the model made on its own.

---

## 4. Structured error handling

Rather than returning sentinel values, Opus 4.8 tends to define typed `Error` subclasses and use `try`/`catch` with specific filters.

Prompt: *"Parse a config line of the form key=value, with errors."*

```cpp
class ConfigError extends Error {
}

ParseLine(line) {
    line := Trim(line)
    if (line = "" || SubStr(line, 1, 1) = ";")
        return ""                         ; blank line or comment

    pos := InStr(line, "=")
    if (!pos)
        throw ConfigError("Missing '=' in line: " line)

    key := Trim(SubStr(line, 1, pos - 1))
    if (key = "")
        throw ConfigError("Empty key in line: " line)

    return Map("key", key, "value", Trim(SubStr(line, pos + 1)))
}

try {
    entry := ParseLine("theme = dark")
    MsgBox(entry["key"] " -> " entry["value"])
} catch ConfigError as err {
    MsgBox("Config problem: " err.Message)
}
```

Catching `ConfigError as err` specifically — rather than swallowing every `Error` — is the pattern you want, and it is now the default rather than something you have to ask for.

---

## 5. It knows the v2.1 alpha surface

When the task suits them, Opus 4.8 reaches for the newer alpha features covered elsewhere on this site — native `Struct`, typed numeric fields, and `DefineProp` overlays — instead of falling back to `NumPut`/`NumGet` arithmetic.

Prompt: *"Read the raw bytes of a 32-bit RGBA color."* (requires `v2.1-alpha.22`+)

```ahk2
Struct Color {
    rgba: UInt32
}
DefineProp(Color.Prototype, "r", {Type: UInt8, Offset: 0})
DefineProp(Color.Prototype, "g", {Type: UInt8, Offset: 1})
DefineProp(Color.Prototype, "b", {Type: UInt8, Offset: 2})
DefineProp(Color.Prototype, "a", {Type: UInt8, Offset: 3})

c := Color()
c.r := 0xFF, c.g := 0x80, c.b := 0x00, c.a := 0xFF
; c.rgba => 0xFF0080FF  (the four bytes, read as one little-endian u32)
```

The union overlay — four `UInt8` views over the same four bytes as a `u32` — is exactly the idiom we cover in the [Alpha Tricks](post.html?slug=alpha-tricks) post. Seeing a model produce it unprompted is a good sign it has internalised the alpha struct model rather than just memorising v2.0 snippets.

---

## How to read these examples

These are illustrative, not a benchmark. The point is the *shape* of the output: idiomatic v2, correct binding, sensible defaults, and a willingness to use newer language features. As always, treat generated AHK as a draft — run it, read it, and validate it against the [AHK v2 docs](https://www.autohotkey.com/docs/v2/) before trusting it in a real automation. The [Prompt Engineering](post.html?slug=prompt-engineering-ahk) post has guidance on getting output this clean consistently.
