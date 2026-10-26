#Requires AutoHotkey v2.1-alpha.37
Echo(fmt, args*) => FileAppend(Format(fmt, args*) "`n", "*")   ; native stdout

; --- 1. Optional hooks: an unset getter is an empty slot ----------------------
class Pipeline {
    ; Hooks default to "nothing". Subclasses or instances supply real callables.
    onStart => unset
    onItem  => unset
    onDone  => unset

    Run(items) {
        this.Fire("onStart")
        for item in items
            this.Fire("onItem", item)
        this.Fire("onDone", items.Length)
    }

    ; Fire a hook that may be empty: IsSet(this.%name%) reads the slot without
    ; calling it. this.%name%(args*) then calls the slot's value as a method,
    ; so every hook receives the pipeline as its first parameter.
    Fire(name, args*) {
        if IsSet(this.%name%)
            this.%name%(args*)
    }
}
class LoggingPipeline extends Pipeline {
    onItem => (self, item) => Echo("  item {}", item)
    onDone => (self, n) => Echo("  done, {} items", n)
}
Echo("Pipeline with no hooks:")
Pipeline().Run([1, 2])
Echo("LoggingPipeline:")
LoggingPipeline().Run(["a", "b", "c"])

; Calling an empty slot directly is an ordinary error now.
try Pipeline().onStart()
catch UnsetError as e
    Echo("Pipeline().onStart(): {}: {}", Type(e), e.Message)

; --- 2. A method is not an indexable property --------------------------------
class Grid {
    Cell(i) => i * 10
}
try Grid().Cell[2]
catch PropertyError as e
    Echo("Grid().Cell[2]: {}", e.Message)
Echo("Grid().Cell(2) = {}", Grid().Cell(2))

; --- 3. Validate NumGet/NumPut type names from data --------------------------
layout := Map("version", "UShort", "flags", "UInt", "ratio", "Quad")   ; "Quad" is not a type
buf := Buffer(16, 0)
offset := 0
for name, kind in layout {
    try {
        NumPut(kind, 1, buf, offset)
        Echo("{} as {}: ok at offset {}", name, kind, offset)
        offset += kind ~= "i)Short" ? 2 : 4
    } catch ValueError as e
        Echo("{} as {}: {}", name, kind, e.Message)
}

; --- 4. DllCall rejects an object where a pointer-sized integer is expected --
try DllCall("msvcrt\abs", IntPtr, {}, "Int")
catch TypeError as e
    Echo("DllCall(IntPtr, {{}}): {}", e.Message)

; --- 5. Fork fix: a throwing getter keeps its exception when called ---------------
class Guarded {
    handler {
        get {
            throw ValueError("handler is not configured")
        }
    }
}
try Guarded().handler()
catch Error as e
    Echo("Guarded().handler(): {}: {}", Type(e), e.Message)
; Upstream alpha.37 reported UnsetError "No value was returned." here, hiding
; the real message; the fork (a911f73d) restores the ValueError.
