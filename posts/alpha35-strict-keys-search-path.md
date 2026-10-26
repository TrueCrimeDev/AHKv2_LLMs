# AutoHotkey v2.1-alpha.35: Strict Keys and a Search Path That Follows the File

Alpha.35 was tagged on October 11, 2026. It is a small release with two themes. In v2.1 mode, `Map` and `Array` stop guessing about key and index types: a `Float` key is a `TypeError`, and so is a `Float` or empty-string index. And `#Include <Name>` and `#Import` get a real search path: the directory of the including file first, then the module's `Lib\`, the script's `Lib\`, the user library and the standard library, with an `AhkLibPath` environment variable that replaces the whole list. In v2.1 mode `<A_B>` means `A_B.ahk` only; the old fallback to `A.ahk` is gone.

Three short scripts below, one per idea. Each is built around a pattern the change makes pleasant rather than a bare demonstration, the comments record what alpha.34 did instead, and all three run with exit 0 on the `2.1-alpha.37+Console` build. Scripts 2 and 3 come with companion files, linked from their sections.

One thing to know before you rely on `AhkLibPath` on the official alpha.35 build: a listed folder that does not exist made every later folder vanish, including the user and standard libraries. The +Console fork fixed that on October 12 and upstream took the same fix in alpha.36 (`abe3ff20`). Script 3 avoids the case; the alpha.36 post demonstrates the fix.

**About `Print`.** The scripts write their output with `Print`, which is not stock AutoHotkey: it is a built-in of the [+Console fork](https://github.com/TrueCrimeDev/AutoHotkey). `Print("x = {}, y = {}", x, y)` runs its arguments through `Format` and writes the result plus a newline to stdout; a single argument is written as-is, and `Print()` writes a blank line. To run the scripts on stock AutoHotkey, add this one line under `#Requires` (it reproduces those three shapes) and pipe the output through `| more`, because the GUI executable only shows stdout when it is redirected:

```ahk2
Print(fmt := "", args*) => FileAppend((args.Length ? Format(fmt, args*) : fmt) "`n", "*")
```

---

## 1. A `Float` key is a bug, and now it says so

Bucketing by tens with integer division gives `Integer` keys. One stray `/` instead of `//` gives `4.5`, and before alpha.35 the `Map` happily stored it as a *second* key beside `4`, so the lookup that followed found nothing and nobody knew why. In v2.1 mode the write throws `TypeError` "Expected an Integer but got a Float." and nothing is stored. A `String` key such as `"4.5"` is still allowed; `Map` keys are never converted, which is also why `Lookup("2")` reports `absent` in the last section while `arr["2"]` works in the one before it.

`Array` gets the same treatment: `arr[1.0]` and `arr[""]` throw `TypeError` "Invalid index." where `1.0` used to be accepted and `""` threw `IndexError`. Numeric strings still convert, so an index read from text keeps working. The file is in v2.1 mode because of its top-level `#Requires`; a script without one keeps the old behaviour.

Before alpha.35, `m[1.5] := x` stored a `Float` key and `arr[1.0]` returned `arr[1]`.

```ahk2
#Requires AutoHotkey v2.1-alpha.35

; alpha.35: in v2.1 mode a Map rejects Float keys and an Array rejects Float
; and empty-string indexes. This file is in v2.1 mode because of its top-level
; #Requires; a script without one keeps the v2.0 behaviour described below.

; --- 1. A computed key that is secretly a Float -------------------------------
; Bucket values by tens. Integer division gives Integer keys; a stray "/" gives
; a Float, which used to be stored as a *second* key beside the integer one.
bucket := Map()
for n in [10, 20, 30, 45]
    bucket[n // 10] := n                 ; keys 1, 2, 3, 4
Print("integer keys: {}", bucket.Count)

try bucket[45 / 10] := "oops"            ; 4.5 is a Float
catch TypeError as e
    Print("bucket[4.5]: {}", e.Message)
; Before alpha.35 this was accepted: bucket had five entries, one under 4 and one under 4.5.

bucket["4.5"] := "a String key is still fine"
Print("bucket.Count = {}: four Integer keys and one String key; the Float write stored nothing", bucket.Count)

; --- 2. Say what you mean ------------------------------------------------------
; The error points at the real bug: the key needs an explicit conversion.
key := Integer(45 / 10)
Print("Integer(4.5) = {} -> bucket[{}] = {}", key, key, bucket[key])

; --- 3. Array indexes get the same treatment -------------------------------------
arr := ["ten", "twenty", "thirty"]
for idx in [1.0, ""] {
    try
        Print("arr[{}] = {}", idx, arr[idx])
    catch TypeError as e
        Print("arr[{}]: {}: {}", idx = "" ? '""' : idx, Type(e), e.Message)
}
; Before alpha.35, arr[1.0] returned arr[1] and arr[""] threw IndexError.

; Numeric strings still convert, so an index read from text keeps working.
Print("arr[`"2`"] = {}   arr[`" 3`"] = {}", arr["2"], arr[" 3"])

; --- 4. A lookup that validates its input instead of guessing -------------------
; Map keys are never converted: 2 and "2" are different keys, and 2.0 is now an
; error rather than a third one. (Array indexes are converted; Map keys are not.)
Lookup(table, key) {
    try
        return table.Has(key) ? table[key] : "absent"
    catch TypeError as e
        return "rejected (" e.Message ")"
}
for k in [2, 2.0, "2", "2.0"]
    Print("Lookup({}) -> {}", Type(k) = "String" ? '"' k '"' : k, Lookup(bucket, k))
```

Source: [`01_strict_keys.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha35/01_strict_keys.ahk)

---

## 2. The search path follows the including file

The new rule that changes how you lay out a project is the first one: `#Include <Name>` looks in the directory of the file that contains the include before it looks in any `Lib\` folder, and that applies to nested includes. So a helper that is private to one subsystem can live next to that subsystem's file instead of being promoted to the script's `Lib\` where everything can see it. The script includes `Lib\TextTools.ahk` by rule 3 and `tools\Report.ahk` by a plain relative path; `Report.ahk` then does `#Include <Fmt>` and `Fmt.ahk` sits in `tools\`, where only rule 1 can find it.

Each library records its own `A_LineFile`, and the script prints the three paths relative to its own directory so you can see which rule won. Companions: [`Lib/TextTools.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha35/Lib/TextTools.ahk), [`tools/Report.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha35/tools/Report.ahk) and [`tools/Fmt.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha35/tools/Fmt.ahk).

Before alpha.35, the nested `#Include <Fmt>` failed with "Script library not found." unless `Fmt.ahk` was moved into a `Lib\` folder, and in v2.0 mode it still does.

```ahk2
#Requires AutoHotkey v2.1-alpha.35

; alpha.35: #Include <Name> searches, in order,
;   1. the directory of the *including* file   (new, v2.1 mode only)
;   2. the current module's directory \Lib\
;   3. A_ScriptDir\Lib\                       (local library)
;   4. A_MyDocuments\AutoHotkey\Lib\          (user library)
;   5. the AutoHotkey.exe directory \Lib\     (standard library)
; and the AhkLibPath environment variable replaces that list when set.
; In v2.1 mode <A_B> means A_B.ahk only; the v2.0 fallback to A.ahk is gone.

; Rule 3: TextTools.ahk lives in Lib\ beside this script.
#Include <TextTools>

; A plain relative include. tools\Report.ahk then does #Include <Fmt>, and
; Fmt.ahk sits in tools\ -- not in any Lib folder. Rule 1 finds it because the
; including file is tools\Report.ahk. In v2.0 mode that include would fail with
; "Script library not found."
#Include tools\Report.ahk

Where(file) => SubStr(file, StrLen(A_ScriptDir) + 2)   ; path relative to this script

Print("TextTools came from {}", Where(TextToolsFile))
Print("Report came from    {}", Where(ReportFile))
Print("Fmt came from       {}", Where(FmtFile))
Print("")
Print("{}", Report("alpha.35", ["search path follows the including file", "AhkLibPath overrides the list", "no A_B -> A fallback"]))
Print("")
Print("Slug(`"Hello, Library World`") = {}", Slug("Hello, Library World"))
```

Source: [`02_library_search.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha35/02_library_search.ahk)

---

## 3. `AhkLibPath` as a per-process library switch

Library lookup happens at load time, so this script builds a tiny library in a temp folder, writes a one-line child script that includes it, and runs the child through the shell with its output and load errors redirected to a file. That technique works for the GUI executable too, which is why the script uses it rather than assuming a console. With `AhkLibPath` naming the folder the child finds `Greet.ahk`; with the variable cleared the same child fails with "Script library not found.", because the default list has nothing near it.

The last section shows the variable is an ordered list. Two folders each hold a `Greet.ahk`, and whichever is listed first wins. That makes `AhkLibPath` a clean way to run a script against a staging copy of a library, or to give a CI job a library set that has nothing to do with the user's Documents folder.

Before alpha.35, there was no override: the local, user and standard library folders were the whole search, in that order.

```ahk2
#Requires AutoHotkey v2.1-alpha.35

; alpha.35: the AhkLibPath environment variable replaces the default library
; search list. Library lookup happens at load time, so this script builds a
; tiny library in a temp folder, writes a one-line child script that includes
; it, and runs the child twice: once with AhkLibPath pointing at the folder,
; once without. The child's output (and any load error) is captured through
; the shell, which works for the GUI AutoHotkey64.exe too.

root := A_Temp "\ahk35_libpath_" A_TickCount
DirCreate(root "\shared")
FileAppend('Greet(who) => "hello from " who " via " RegExReplace(A_LineFile, ".*\\([^\\]+\\[^\\]+)$", "$1")`n', root "\shared\Greet.ahk", "UTF-8")
FileAppend("#Requires AutoHotkey v2.1-alpha.35`n#Include <Greet>`nFileAppend(Greet(`"AhkLibPath`") `"``n`", `"*`")`n", root "\child.ahk", "UTF-8")

; Run the child and return everything it printed, errors included.
RunChild(script) {
    log := script ".log"
    RunWait(A_ComSpec ' /c ""' A_AhkPath '" /ErrorStdOut "' script '" > "' log '" 2>&1"',, "Hide")
    out := FileExist(log) ? Trim(FileRead(log), "`r`n") : "(no output)"
    try FileDelete(log)
    return StrReplace(out, root "\", "")       ; keep the temp path out of the output
}

; --- 1. AhkLibPath names the folder: the child finds Greet.ahk -------------------
; The child lives in a folder with no Lib\ and the library is nowhere near it.
EnvSet("AhkLibPath", root "\shared")
Print("with AhkLibPath:    {}", RunChild(root "\child.ahk"))

; --- 2. Without it, the default list applies and the library is not there --------
EnvSet("AhkLibPath", "")
Print("without AhkLibPath: {}", RunChild(root "\child.ahk"))

; --- 3. The variable is a list; order is search order ----------------------------
; A second copy of Greet.ahk in another folder wins when its folder is listed first.
DirCreate(root "\override")
FileAppend('Greet(who) => "hello from the OVERRIDE folder"`n', root "\override\Greet.ahk", "UTF-8")
EnvSet("AhkLibPath", root "\override;" root "\shared")
Print("override first:     {}", RunChild(root "\child.ahk"))
EnvSet("AhkLibPath", root "\shared;" root "\override")
Print("shared first:       {}", RunChild(root "\child.ahk"))
; Note: on the official alpha.35 build, a listed folder that does not exist
; made every later entry vanish, so "missing;shared" failed. The +Console fork
; fixed that on 2026-10-12 and upstream took the same fix in alpha.36.

EnvSet("AhkLibPath", "")
DirDelete(root, true)
```

Source: [`03_ahklibpath.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha35/03_ahklibpath.ahk)

---

## Things I tripped over writing these

- **`Map` keys are not converted, `Array` indexes are.** `arr["2"]` is `arr[2]`; `m["2"]` is a different key from `m[2]`. Alpha.35 did not change that, it only removed the `Float` case from both.
- **The including-file rule is v2.1 only.** Drop the top-level `#Requires` and the nested `<Fmt>` include in script 2 stops resolving.
- **Capturing a GUI child's output needs the shell.** `RunWait(A_ComSpec ' /c ""' A_AhkPath '" /ErrorStdOut "' script '" > log 2>&1"')` with the doubled outer quotes is the incantation; `/ErrorStdOut` is what turns a load error into text you can read back.

---

## Running them

Every script starts with `#Requires AutoHotkey v2.1-alpha.35`. On the +Console fork they run as they are; on stock AutoHotkey add the `Print` line from the top of this post and pipe through `| more`.

```powershell
# +Console fork
.\bin\AutoHotkey64Console.exe 01_strict_keys.ahk

# stock AutoHotkey v2.1-alpha.35 or later (GUI exe), with the Print line added
AutoHotkey64.exe 01_strict_keys.ahk | more
```

*Disclosure: Claude Fable 5.1 wrote the scripts, ran them on the +Console fork build `a911f73d` (`2.1-alpha.37+Console`), and drafted this post. The alpha.34 comparisons and the search-path rules come from the fork's release notes and its `qa/tests/test_alpha35.ahk`, which pins them against the alpha.33 engine.*
