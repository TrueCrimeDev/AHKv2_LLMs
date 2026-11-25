These five puzzles are harder than the warm-up set, and each is built so that a v2.1-alpha feature is the subject of the puzzle, not an optional extra.

A keycap counts only when the answer is right and the solution meets that day's alpha requirements. The page can only check the answer. The requirements are on your honor, and they are the point: each answer can be computed in any language, but the requirements force you through the alpha feature.

| Day | Title | Alpha focus | Puzzle core |
| :-- | :-- | :-- | :-- |
| 1 | Flight Recorder | `struct`, alignment, `#StructPack` | Decode binary records compiled with four different packings |
| 2 | Union Station | `union` blocks, nested structs, typed arrays, `At()` | Replay a window journal, then replay it as a linked list |
| 3 | Maybe Next Year | `?`, `??`, `??=`, `?.`, `unset`, v2.1 mode | A sparse ledger with fallbacks, aliasing and time-stamped queries |
| 4 | Plugin Pileup | `#Module`, `#Import`, module objects | The input is code: twelve modules that all export the same names |
| 5 | Schema Sleigh | `Class(Struct)`, `DefineProp`, run-time types | Build every struct from a schema you only see at run time |

**Setup.** Start each solution with `#Requires AutoHotkey v2.1-alpha.39`. That line also switches the script into v2.1 mode, where missing Map and Array items come back as `unset`.

**Binary input.** Days 1, 2 and 5 ship binary data as hex text: two hex digits per byte, 32 bytes per line. Ignore the line breaks. All numbers are little-endian.

**Layout rules.** These are the usual C rules, and every binary day uses them:

1. A numeric field's alignment equals its size. An array's alignment is its element's alignment.
2. Each struct has a pack value of 1, 2, 4 or 8. The default is 8.
3. Each field sits at the next offset that is a multiple of its alignment or of the pack value, whichever is smaller.
4. A struct's alignment is the largest alignment its fields were placed with. Its size is rounded up to a multiple of that alignment.
5. Every member of a union starts at the union's offset. The union is as large as its largest member.
6. Padding bytes and unused union bytes hold junk, not zeros.

The alpha's [Structs page](https://www.autohotkey.com/docs/alpha/Structs.htm) does not spell out default alignment, so part of each binary day is proving that your struct's `Size` agrees with these rules before you trust it.
