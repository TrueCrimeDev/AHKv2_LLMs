# AHK-Eval — Per-Task Prompt Template

Unlike the other benchmarks, AHK-Eval is not one prompt — it is **36 prompts from one template**, one independent API call per task. The four placeholders (`{sig}`, `{spec}`, `{example}`, `{fn}`) are filled per task from the suite definition; everything else is identical for every model and every task. The full task list (signatures, specs, public examples) is in the [benchmark post's appendix](post.html?slug=ahk-eval-benchmark); the 181 hidden test cases are not published.

Generation parameters: one user message, no system prompt, `temperature 0.2` (Anthropic API rejects the parameter, so Fable 5 ran at default sampling), `max_tokens 8000`, no retries, no tools.

---

```
You are completing one task of an AutoHotkey v2 coding benchmark.

Write a single AutoHotkey v2 function:

    {sig}

{spec}

Example: {example}

Rules:
- Pure AHK v2 (v2.1) syntax: ':=' assignment, Map()/Array, 1-based indexing.
- Return the value. Do not print, show a MsgBox, touch the clipboard, files, or any GUI.
- Submit only the function {fn} (private helper functions are allowed). No top-level code.
- Do not include #Requires or other directives.
- Reply with ONLY one fenced code block containing the function(s).
```

---

## Rendered example — the exact prompt one model received for `AE_NaturalSort`

```
You are completing one task of an AutoHotkey v2 coding benchmark.

Write a single AutoHotkey v2 function:

    AE_NaturalSort(s)

s is a comma-separated list of lowercase alphanumeric items. Sort them in natural order: split each item into alternating letter and digit runs; compare run by run — digit runs compare as integers, letter runs compare as plain text. So item2 comes before item10. Return the sorted list joined by commas.

Example: AE_NaturalSort("item10,item2,item1") returns "item1,item2,item10"

Rules:
- Pure AHK v2 (v2.1) syntax: ':=' assignment, Map()/Array, 1-based indexing.
- Return the value. Do not print, show a MsgBox, touch the clipboard, files, or any GUI.
- Submit only the function AE_NaturalSort (private helper functions are allowed). No top-level code.
- Do not include #Requires or other directives.
- Reply with ONLY one fenced code block containing the function(s).
```

Grading wraps the submitted function in a driver that calls it against the hidden cases on the v2.1-alpha.30+Console fork: parse gate (`/validate`), run gate, then exact string comparison per case. A task is solved only at full marks.
