#Requires AutoHotkey v2.1-alpha.29
Echo(fmt, args*) => FileAppend(Format(fmt, args*) "`n", "*")   ; native stdout

; alpha.29: the maybe operator (?) short-circuits most operators
;
; var? turns an unset variable into the unset sentinel instead of throwing.
; In alpha.29 that sentinel passes through arithmetic, comparison, string
; concatenation, logical and ternary operators: the whole subexpression
; becomes unset, and you supply the fallback once, at the boundary you
; control, with ??.
;
; Before alpha.29 only a few operators tolerated the sentinel; an unset
; operand inside * or > raised "This variable has not been assigned a value."

; --- 1. Optional parameters in arithmetic --------------------------------------
; factor is optional. If the caller omitted it, v * factor? is unset and ?? v
; returns the input unchanged. No IsSet, no second code path.
Scale(v, factor?) => (v * factor?) ?? v
Echo("Scale(10) = {}   Scale(10, 3) = {}", Scale(10), Scale(10, 3))

; --- 2. Optional limits in comparisons ------------------------------------------
; A missing limit means "no limit": the comparison is unset, so ?? false wins.
Over(spent, limit?) => (spent > limit?) ?? false
Echo("Over(120) = {}   Over(120, 100) = {}   Over(80, 100) = {}", Over(120), Over(120, 100), Over(80, 100))

; --- 3. Optional parts of a string ---------------------------------------------------
; The parenthesised piece is unset as a whole when suffix is, so nothing is
; appended rather than a stray " ()". (suffix?) is wrapped on purpose; see 6.
Label(name, suffix?) => name . ((" (" . (suffix?) . ")") ?? "")
Echo("{}  /  {}", Label("build"), Label("build", "release"))

; --- 4. Ternary and logical operators short-circuit too ------------------------------
Describe(flag?) => (flag? ? "on" : "off") ?? "unknown"
Echo("Describe() = {}   Describe(1) = {}   Describe(0) = {}", Describe(), Describe(1), Describe(0))
Echo("(missing? || 5) ?? 'unset' = {}", (missing? || 5) ?? "unset")

; --- 5. The IIFE that crashed the alpha.28 parser ----------------------------------------
; (() => a? || 1)() failed to parse before alpha.29. Now it evaluates, and the
; unset sentinel still propagates through || to the outer ??.
Echo("(() => zz? || 1)() ?? 'unset' = {}", (() => zz? || 1)() ?? "unset")

; --- 6. Two things ? does not do --------------------------------------------------------
; It applies to a variable, not to an expression: (a? + 1)? is a syntax error.
; And the parser still has to decide whether ? starts a ternary: `missing? + 1`
; (a ? +1 : ...) fails to load, and so did `suffix? . ")"` above. Wrapping
; the maybe as (var?) removes the ambiguity everywhere.
total := ((missing?) + 1) ?? 0
Echo("((missing?) + 1) ?? 0 = {}", total)
