# Advent of Hotkeys: Ten Puzzles for AutoHotkey v2.1-alpha

Advent of Hotkeys is a set of ten two-part puzzles in the style of Advent of Code, written for AutoHotkey v2. Five warm-ups run on any v2 release. Five more are built around v2.1-alpha.39 features: structs, unions, the maybe operators, modules and run-time types.

**[Play Advent of Hotkeys](advent.html)**

---

## How it works

- One puzzle opens at midnight EST each day, December 1 to 10. The five warm-ups come first, then the five alpha days.
- Each puzzle has a story, a worked example with known answers, an input file and two parts. Part 2 unlocks when you solve Part 1.
- Every answer is an integer. The page checks it in your browser and awards a golden keycap for each part, 20 in all.
- Everyone gets the same input, so answers can be compared.
- Progress is kept in your browser's local storage and nowhere else.

## The warm-up tier

The [warm-up tier](advent.html?tier=warmup) uses AutoHotkey for flavor. The puzzles are the familiar kinds: parse, simulate, search, then scale up. Each day ends with an optional alpha challenge.

| Day | Title | Puzzle type | Part 2 twist |
| :-- | :-- | :-- | :-- |
| 1 | Send Help | Parsing and counting | Reinterpret the same text as physical key wear |
| 2 | Hotstring Hangover | Text expansion | Recursive growth too large to build as a string |
| 3 | Window Pains | Rectangles on a grid | Z-order decides who owns each pixel |
| 4 | Caret Maze | Shortest path | New moves that slide until they hit a wall |
| 5 | Alt-Tab Avalanche | List simulation | Repeat the macro a trillion times |

## The alpha tier

In the [alpha tier](advent.html?tier=alpha) the alpha feature is the subject of the puzzle. Each day lists alpha requirements, such as reading every record through a `struct` with `At()` and calling no `NumGet`. A keycap counts only when the answer is right and the solution meets them. The page can check the answer; the requirements are on your honor.

| Day | Title | Alpha focus | Puzzle core |
| :-- | :-- | :-- | :-- |
| 1 | Flight Recorder | `struct`, alignment, `#StructPack` | Decode binary records compiled with four different packings |
| 2 | Union Station | `union` blocks, nested structs, typed arrays, `At()` | Replay a window journal, then replay it as a linked list |
| 3 | Maybe Next Year | `?`, `??`, `??=`, `?.`, `unset`, v2.1 mode | A sparse ledger with fallbacks, aliasing and time-stamped queries |
| 4 | Plugin Pileup | `#Module`, `#Import`, module objects | The input is code: twelve modules that all export the same names |
| 5 | Schema Sleigh | `Class(Struct)`, `DefineProp`, run-time types | Build every struct from a schema you only see at run time |

Each alpha day also names what the docs leave for you to discover, such as how far a `#StructPack` directive reaches or when a module's body runs.

## Answer checking

The repository holds salted SHA-256 hashes of the answers, not the answers. Your browser hashes what you type and compares. Nothing is sent anywhere. A short integer can be recovered from its hash by brute force, so the keycaps are an honor system.

## Status

- Two independent Python solvers agree on every example and every full-input answer. The binary layouts were also checked against Python's `ctypes`, which lays structs out the way a C compiler does.
- No reference solution has run in AutoHotkey yet. The Day 4 input follows the `#Module` style from the [alpha.31 post](post.html?slug=alpha31-modules-export-everything) but has not been loaded in alpha.39.
- The alpha requirements were written from the [alpha docs](https://www.autohotkey.com/docs/alpha/). If a requirement turns out stricter than alpha.39 allows, relax it and keep the answer.
