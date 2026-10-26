#Requires AutoHotkey v2.1-alpha.28

; alpha.28: reading a Map key or Array index that has no value raises
; UnsetItemError, a subclass of UnsetError, so a handler can tell "this slot
; is empty" from "this variable was never assigned" and from "that index is
; out of range" (still IndexError).
; Before alpha.28 the empty-slot case raised the generic UnsetError.

; --- 1. A sparse array of slots -----------------------------------------------------
slots := [1, unset, 3]
Print("Length {}  Has(1) {}  Has(2) {}", slots.Length, slots.Has(1), slots.Has(2))
try v := slots[2]
catch UnsetItemError as e
    Print("slots[2] -> {}: {}", Type(e), e.Message)
try v := slots[9]
catch IndexError as e
    Print("slots[9] -> {}: {}", Type(e), e.Message)
Print("slots[2] ?? 'free' = {}", slots[2] ?? "free")

; --- 2. One handler, three different situations ---------------------------------------
Describe(fn) {
    try
        return "value " fn()
    catch UnsetItemError as e
        return "empty slot (" e.Message ")"
    catch UnsetError as e
        return "unset variable (" StrSplit(e.Message, "`n")[1] ")"
    catch IndexError as e
        return "bad index (" e.Message ")"
}
ReadUnset(assign := false) {
    if assign
        v := 1
    return v                           ; plain UnsetError: a variable, not an item
}
m := Map("a", 1)
Print("m['a']  : {}", Describe(() => m["a"]))
Print("m['zz'] : {}", Describe(() => m["zz"]))
Print("slots[2]: {}", Describe(() => slots[2]))
Print("slots[0]: {}", Describe(() => slots[0]))
Print("variable: {}", Describe(ReadUnset))

; --- 3. Assigning unset to a Map key removes it ----------------------------------------
m["b"] := 2
Print("Count {} after adding b", m.Count)
m["b"] := unset
Print("Count {} Has(b) {} after m['b'] := unset", m.Count, m.Has("b"))

; --- 4. The hierarchy, so a broad catch still works ---------------------------------------
Print("UnsetItemError extends UnsetError: {}", UnsetItemError.Prototype.Base = UnsetError.Prototype)
try v := slots[2]
catch UnsetError as e
    Print("caught as UnsetError: {}", Type(e))
