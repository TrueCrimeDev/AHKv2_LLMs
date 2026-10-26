# AutoHotkey v2.1-alpha.35: Strict Keys and a Search Path That Follows the File

Alpha.35 was tagged on October 11, 2026, and has two themes. In v2.1 mode `Map` and `Array` stop guessing about key types: a `Float` key or index is a `TypeError`. And `#Include <Name>` and `#Import` get a real search path, starting with the directory of the including file, plus an `AhkLibPath` environment variable that replaces the whole list. Three short scripts, one per idea.

**About `Print`.** The scripts write their output with `Print`, which is not stock AutoHotkey: it is a built-in of the [+Console fork](https://github.com/TrueCrimeDev/AutoHotkey). `Print("x = {}, y = {}", x, y)` runs its arguments through `Format` and writes the result plus a newline to stdout; a single argument is written as-is, and `Print()` writes a blank line. To run the scripts on stock AutoHotkey, add this one line under `#Requires` (it reproduces those three shapes) and pipe the output through `| more`, because the GUI executable only shows stdout when it is redirected:

```ahk2
Print(fmt := "", args*) => FileAppend((args.Length ? Format(fmt, args*) : fmt) "`n", "*")
```

---

## 1. A `Float` key is a bug, and now it says so

Bucketing by tens with integer division gives `Integer` keys; one stray `/` instead of `//` gives `4.5`, which the `Map` used to store as a second key beside `4`, so the lookup that followed found nothing. In v2.1 mode the write throws `TypeError` "Expected an Integer but got a Float." and stores nothing, which points at the real fix, an explicit `Integer()`. `Array` gets the same treatment: `arr[1.0]` and `arr[""]` throw "Invalid index." where `1.0` used to be accepted and `""` threw `IndexError`. The top-level `#Requires` is what selects v2.1 mode; without it the old behaviour stays.

```ahk2
#Requires AutoHotkey v2.1-alpha.35

; alpha.35: in v2.1 mode a Map rejects Float keys and an Array rejects Float
; and empty-string indexes. The top-level #Requires is what selects v2.1 mode.

; --- 1. A computed key that is secretly a Float -----------------------------
; Integer division gives Integer keys; a stray "/" gives a Float.
bucket := Map()
for n in [10, 20, 30, 45]
    bucket[n // 10] := n                 ; keys 1, 2, 3, 4

try bucket[45 / 10] := "oops"            ; 4.5 is a Float
catch TypeError as e
    Print("bucket[4.5]: {}", e.Message)
Print("bucket.Count = {}: the Float write stored nothing", bucket.Count)
; Before alpha.35: five entries, one under 4 and one under 4.5, and no error.

; The error points at the real bug: the key needs an explicit conversion.
key := Integer(45 / 10)
Print("Integer(4.5) = {} -> bucket[{}] = {}", key, key, bucket[key])

; --- 2. Array indexes get the same treatment --------------------------------
arr := ["ten", "twenty", "thirty"]
for idx in [1.0, ""] {
    try
        Print("arr[{}] = {}", idx, arr[idx])
    catch TypeError as e
        Print("arr[{}]: {}", idx = "" ? '""' : idx, e.Message)
}
; Before alpha.35, arr[1.0] returned arr[1] and arr[""] threw IndexError.
```

Output:

```text
bucket[4.5]: Expected an Integer but got a Float.
bucket.Count = 4: the Float write stored nothing
Integer(4.5) = 4 -> bucket[4] = 45
arr[1.0]: Invalid index.
arr[""]: Invalid index.
```

Source: [`01_strict_keys.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha35/01_strict_keys.ahk)

---

## 2. The search path follows the including file

`#Include <Name>` now looks in the directory of the including file before the module's `Lib\`, the script's `Lib\`, the user library and the standard library, and in v2.1 mode `<A_B>` no longer falls back to `A.ahk`. So a helper private to one subsystem can live next to that subsystem's file. The script includes `tools\Report.ahk` by a relative path; `Report.ahk` does `#Include <Fmt>` and `Fmt.ahk` sits in `tools\`, where only the new rule finds it. Before alpha.35, and in v2.0 mode today, that nested include fails with "Script library not found."

```ahk2
#Requires AutoHotkey v2.1-alpha.35

; alpha.35: #Include <Name> looks in the directory of the *including* file
; first (v2.1 mode only), then the Lib\ folders as before.

#Include <TextTools>          ; Lib\TextTools.ahk beside this script

; tools\Report.ahk does its own #Include <Fmt>; Fmt.ahk sits in tools\, not in
; any Lib folder, so only the including-file rule can find it.
#Include tools\Report.ahk

Where(file) => SubStr(file, StrLen(A_ScriptDir) + 2)   ; path relative to this script

Print("TextTools came from {}", Where(TextToolsFile))
Print("Report came from    {}", Where(ReportFile))
Print("Fmt came from       {}", Where(FmtFile))
Print("{}", Report("alpha.35", ["search path follows the including file", "AhkLibPath overrides the list"]))
```

Output:

```text
TextTools came from Lib\TextTools.ahk
Report came from    tools\Report.ahk
Fmt came from       tools\Fmt.ahk
alpha.35
========
  1. search path follows the including file
  2. AhkLibPath overrides the list
```

Source: [`02_library_search.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha35/02_library_search.ahk). Companions: [`Lib/TextTools.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha35/Lib/TextTools.ahk), [`tools/Report.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha35/tools/Report.ahk) and [`tools/Fmt.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha35/tools/Fmt.ahk).

---

## 3. `AhkLibPath` as a per-process library switch

Library lookup happens at load time, so the script writes a one-line child script and a library to a temp folder and runs the child through `RunWait(A_ComSpec ' /c ""' A_AhkPath '" /ErrorStdOut "' script '" > log 2>&1"')`, which captures output and load errors from the GUI executable too. With `AhkLibPath` naming the folder the child finds `Greet.ahk`, with it cleared the child fails with "Script library not found.", and with two folders listed the first one that has the file wins. Before alpha.35 there was no override. On the official alpha.35 build a listed folder that does not exist made every later entry vanish; the +Console fork fixed that on October 12 and upstream took the fix in alpha.36 (`abe3ff20`).

```ahk2
#Requires AutoHotkey v2.1-alpha.35

; alpha.35: the AhkLibPath environment variable replaces the library search
; list. Lookup happens at load time, so a child script is run through the
; shell with its output and load errors captured (works for the GUI exe too).

root := A_Temp "\ahk35_libpath_" A_TickCount
DirCreate(root "\shared")
FileAppend('Greet(who) => "hello from " who " via the shared folder"`n', root "\shared\Greet.ahk", "UTF-8")
FileAppend("#Requires AutoHotkey v2.1-alpha.35`n#Include <Greet>`nFileAppend(Greet(`"AhkLibPath`") `"``n`", `"*`")`n", root "\child.ahk", "UTF-8")

RunChild(script) {
    log := script ".log"
    RunWait(A_ComSpec ' /c ""' A_AhkPath '" /ErrorStdOut "' script '" > "' log '" 2>&1"',, "Hide")
    out := Trim(FileRead(log), "`r`n")
    FileDelete(log)
    return StrReplace(out, root "\", "")       ; keep the temp path out of the output
}

; --- 1. AhkLibPath names the folder: the child finds Greet.ahk ---------------
EnvSet("AhkLibPath", root "\shared")
Print("with AhkLibPath:    {}", RunChild(root "\child.ahk"))

; --- 2. Without it, the default list applies and the library is not there ----
EnvSet("AhkLibPath", "")
Print("without AhkLibPath: {}", RunChild(root "\child.ahk"))

; --- 3. The variable is a list; the first folder that has the file wins -------
DirCreate(root "\override")
FileAppend('Greet(who) => "hello from the OVERRIDE folder"`n', root "\override\Greet.ahk", "UTF-8")
EnvSet("AhkLibPath", root "\override;" root "\shared")
Print("override first:     {}", RunChild(root "\child.ahk"))

EnvSet("AhkLibPath", "")
DirDelete(root, true)
```

Output:

```text
with AhkLibPath:    hello from AhkLibPath via the shared folder
without AhkLibPath: child.ahk (0) : ==> Script library not found.
     Specifically: #Include <Greet>
override first:     hello from the OVERRIDE folder
```

Source: [`03_ahklibpath.ahk`](https://github.com/TrueCrimeDev/AHKv2_LLMs/blob/main/examples/alpha35/03_ahklibpath.ahk)

---

## Running them

Every script starts with `#Requires AutoHotkey v2.1-alpha.35`. On the +Console fork they run as they are; on stock AutoHotkey add the `Print` line from the top of this post and pipe through `| more`.

```powershell
# +Console fork
.\bin\AutoHotkey64Console.exe 01_strict_keys.ahk

# stock AutoHotkey v2.1-alpha.35 or later (GUI exe), with the Print line added
AutoHotkey64.exe 01_strict_keys.ahk | more
```

*Disclosure: Claude Fable 5.1 wrote the scripts, ran them on the +Console fork build `a911f73d` (`2.1-alpha.37+Console`), and drafted this post; the alpha.34 comparisons come from the fork's release notes and its `qa/tests/test_alpha35.ahk`.*
