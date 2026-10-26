#Requires AutoHotkey v2.1-alpha.33
Echo(fmt, args*) => FileAppend(Format(fmt, args*) "`n", "*")   ; native stdout
; alpha.33: &Module.Var (Module.__Ref)
;
; The reference operator works on a module object's variables. &Stats.Count
; is a VarRef to the module-level variable, so it can be handed to a ByRef
; parameter or to a built-in output parameter without importing the name.
; Before alpha.33, &Stats.Count was an error: modules had no __Ref.
;
; Upstream alpha.33 returned that reference without a reference count, which
; corrupted the heap once it was released (the fork fixed it; see the post).

#Module Stats
global Count := 0
global Last := ""

#Module __Main
#Import Stats

; --- 1. A ByRef helper mutates a module variable in place --------------------
Bump(&v, by := 1) => v += by
Bump(&Stats.Count)
Bump(&Stats.Count, 10)
Echo("Stats.Count = {}", Stats.Count)

; --- 2. Built-in output parameters accept it too ------------------------------
SplitPath("C:\logs\today.txt", &Stats.Last)
Echo("Stats.Last = {}", Stats.Last)
RegExMatch("v2.1-alpha.33", "alpha\.(\d+)", &m)
Stats.Count := m[1]
Echo("Stats.Count = {}", Stats.Count)

; --- 3. The reference is a real VarRef you can hold and reuse ------------------
ref := &Stats.Count
%ref% += 1
Echo("through the ref: {}  module sees: {}", %ref%, Stats.Count)
Stats.Count := 100
Echo("module write, ref sees: {}", %ref%)

; --- 4. Pass the same reference around like any other ------------------------
Apply(fn, &target) => target := fn(target)
Apply(x => x * 2, &Stats.Count)
Echo("doubled: {}", Stats.Count)
ref := ""                       ; releasing it is safe on the fixed engine
Echo("after release: {}", Stats.Count)
