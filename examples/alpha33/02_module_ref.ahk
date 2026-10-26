#Requires AutoHotkey v2.1-alpha.33
; alpha.33: &Module.Var (Module.__Ref)
; &Stats.Count is a VarRef to the module-level variable, so it can go to a
; ByRef parameter or a built-in output parameter without importing the name.
; Before alpha.33 it was an error: modules had no __Ref. Upstream alpha.33
; returned it without a reference count and corrupted the heap on release;
; the fork fixed that (see the post).

#Module Stats
global Count := 0
global Last := ""

#Module __Main
#Import Stats

; --- 1. A ByRef helper mutates a module variable in place --------------------
Bump(&v, by := 1) => v += by
Bump(&Stats.Count)
Bump(&Stats.Count, 10)
Print("Stats.Count = {}", Stats.Count)

; --- 2. Built-in output parameters accept it too ------------------------------
SplitPath("C:\logs\today.txt", &Stats.Last)
Print("Stats.Last = {}", Stats.Last)

; --- 3. The reference is a real VarRef you can hold, reuse and release --------
ref := &Stats.Count
%ref% += 1
Print("through the ref: {}  module sees: {}", %ref%, Stats.Count)
Stats.Count := 100
Print("module write, ref sees: {}", %ref%)
ref := ""                       ; releasing it is safe on the fixed engine
Print("after release: {}", Stats.Count)
